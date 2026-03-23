# ==============================================================================
# SLUG CLUSTERING BY COUNTRY COVERAGE (JACCARD / BINARY)
# ==============================================================================
#
# Groups slugs by their country coverage patterns using Jaccard similarity
# on binary presence matrices. Missingness is signal.
#
# Dependency: qog_augmented_standard.jl (loaded via load_phase0.jl)
#
# ==============================================================================

using SparseArrays
using LinearAlgebra
using Graphs
using Statistics
using CommunityDetection
using SimpleWeightedGraphs

# ==============================================================================
# CONSTANTS (all configurable via function kwargs)
# ==============================================================================

"""Minimum reporting density for a (slug, country) pair to count as 'present'."""
const SC_PRESENCE_MIN_PCT = 0.10

"""Upper bound — flag slugs exceeding this for nearly all countries."""
const SC_PRESENCE_MAX_PCT = 0.95

"""After presence filtering, slug must cover >= this fraction of countries to enter clustering."""
const SC_MIN_COUNTRY_COVERAGE = 0.05

"""Top-k most similar neighbors to keep per slug."""
const SC_JACCARD_TOP_K = 20

"""Minimum Jaccard similarity to create an edge."""
const SC_JACCARD_MIN_SIM = 0.10


# ==============================================================================
# STEP 0: PARTITION SLUGS
# ==============================================================================

"""
Partition slugs into global (set aside) and cluster candidates.

Arguments:
- meta_df::DataFrame: Metadata with :slug and :ggis_geo_classification columns

Returns:
- NamedTuple with :global_slugs and :cluster_slugs (Vector{String} each)

Rules:
- Global slugs (ggis_geo_classification == "global") are set aside — not clustered
- Regional and other slugs are candidates for clustering
"""
function partition_slugs(meta_df::DataFrame)
    @assert :slug in propertynames(meta_df) "meta_df must have :slug"
    @assert :ggis_geo_classification in propertynames(meta_df) "meta_df must have :ggis_geo_classification"

    global_slugs = String[]
    cluster_slugs = String[]

    for row in eachrow(meta_df)
        s = string(row.slug)
        geo = ismissing(row.ggis_geo_classification) ? "other" : string(row.ggis_geo_classification)
        if geo == "global"
            push!(global_slugs, s)
        else
            push!(cluster_slugs, s)
        end
    end

    println("=" ^ 72)
    println("Step 0 — Slug Partitioning")
    println("=" ^ 72)
    println("    Total slugs:   $(nrow(meta_df))")
    println("    Global (set aside): $(length(global_slugs))")
    println("    Cluster candidates: $(length(cluster_slugs))")
    println("=" ^ 72)

    return (global_slugs = global_slugs, cluster_slugs = cluster_slugs)
end


# ==============================================================================
# STEP 1: BUILD SLUG × COUNTRY BINARY PRESENCE MATRIX
# ==============================================================================

"""
Build a binary presence matrix: slugs × countries.

Arguments:
- df::DataFrame: Augmented QoG timeseries (must have :ident_ccode, :ident_year)
- slugs::Vector{String}: Slugs to include (cluster candidates)
- presence_min_pct::Float64: Minimum reporting density to count as present
- presence_max_pct::Float64: Upper bound for flagging near-global slugs
- min_country_coverage::Float64: Minimum fraction of countries a slug must cover

Returns:
- NamedTuple with :X (SparseMatrixCSC), :slug_index, :country_index, :filtered_slugs

Rules:
- density = n_nonmissing / n_country_years per (slug, country)
- Present if density >= presence_min_pct
- Slugs covering < min_country_coverage fraction of countries are filtered out
"""
function build_slug_country_matrix(
    df::DataFrame,
    slugs::AbstractVector{<:AbstractString};
    clean_ccodes::Union{Set{Int}, Nothing} = nothing,
    presence_min_pct::Float64 = SC_PRESENCE_MIN_PCT,
    presence_max_pct::Float64 = SC_PRESENCE_MAX_PCT,
    min_country_coverage::Float64 = SC_MIN_COUNTRY_COVERAGE,
    verbose::Bool = true
)
    # Unique countries and their year counts (exclude missing ccodes)
    df_valid = filter(row -> !ismissing(row.ident_ccode), df)

    # If clean_ccodes provided, restrict to those countries only
    if clean_ccodes !== nothing
        df_valid = filter(row -> Int(row.ident_ccode) in clean_ccodes, df_valid)
    end

    country_years = combine(groupby(df_valid, :ident_ccode), nrow => :n_years)
    countries = sort(Int.(country_years.ident_ccode))
    n_countries = length(countries)
    country_to_idx = Dict(c => i for (i, c) in enumerate(countries))
    year_counts = Dict(Int(row.ident_ccode) => row.n_years for row in eachrow(country_years))

    # Filter slugs to those that exist in df
    df_cols = Set(propertynames(df))
    valid_slugs = [s for s in slugs if Symbol(s) in df_cols]

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 1 — Building slug × country presence matrix")
        println("=" ^ 72)
        println("    Countries: $n_countries")
        println("    Candidate slugs: $(length(slugs))")
        println("    Valid in DataFrame: $(length(valid_slugs))")
        println("    presence_min_pct: $presence_min_pct")
        println("    presence_max_pct: $presence_max_pct")
        println("    min_country_coverage: $min_country_coverage")
    end

    # Group by country (using valid-only DataFrame)
    g = groupby(df_valid, :ident_ccode)

    # Build presence counts: slug → Dict(ccode → n_nonmissing)
    slug_presence = Dict{String, Dict{Int, Int}}()
    for s in valid_slugs
        slug_presence[s] = Dict{Int, Int}()
    end

    for sdf in g
        ccode = Int(first(sdf.ident_ccode))
        for s in valid_slugs
            col = sdf[!, Symbol(s)]
            n_nonmiss = count(!ismissing, col)
            if n_nonmiss > 0
                slug_presence[s][ccode] = n_nonmiss
            end
        end
    end

    # Apply presence threshold and build sparse matrix
    # Also track which slugs pass the coverage filter
    passing_slugs = String[]
    flagged_near_global = String[]

    for s in valid_slugs
        n_present = 0
        for (ccode, n_nonmiss) in slug_presence[s]
            n_total = year_counts[ccode]
            density = n_nonmiss / n_total
            if density >= presence_min_pct
                n_present += 1
            end
        end
        coverage = n_present / n_countries
        if coverage >= min_country_coverage
            push!(passing_slugs, s)
            if coverage >= presence_max_pct
                push!(flagged_near_global, s)
            end
        end
    end

    # Build sparse matrix for passing slugs
    n_slugs = length(passing_slugs)
    slug_to_idx = Dict(s => i for (i, s) in enumerate(passing_slugs))

    I_idx = Int[]
    J_idx = Int[]

    for (si, s) in enumerate(passing_slugs)
        for (ccode, n_nonmiss) in slug_presence[s]
            n_total = year_counts[ccode]
            density = n_nonmiss / n_total
            if density >= presence_min_pct
                ci = country_to_idx[ccode]
                push!(I_idx, si)
                push!(J_idx, ci)
            end
        end
    end

    X = sparse(I_idx, J_idx, ones(Float64, length(I_idx)), n_slugs, n_countries)

    filtered_count = length(valid_slugs) - n_slugs
    nnzX = nnz(X)
    dens = n_slugs > 0 && n_countries > 0 ? nnzX / (n_slugs * n_countries) : 0.0

    if verbose
        println("    Passing slugs: $n_slugs (filtered $filtered_count below coverage threshold)")
        if !isempty(flagged_near_global)
            println("    ⚠️  Near-global slugs flagged: $(length(flagged_near_global))")
        end
        println("    Matrix: $n_slugs slugs × $n_countries countries")
        println("    Non-zeros: $nnzX ($(round(dens * 100, digits=2))% density)")
        println("=" ^ 72)
    end

    return (
        X = X,
        slug_index = passing_slugs,
        country_index = countries,
        filtered_slugs = setdiff(valid_slugs, passing_slugs),
        flagged_near_global = flagged_near_global
    )
end


# ==============================================================================
# STEP 2: JACCARD SIMILARITY
# ==============================================================================

"""
Compute Jaccard top-k neighbor edges between slugs.

Arguments:
- X::SparseMatrixCSC: Binary slug × country matrix
- slug_index::Vector{String}: Row labels
- k::Int: Top-k neighbors per slug
- min_sim::Float64: Minimum Jaccard to keep

Returns:
- DataFrame with columns: slug_i, slug_j, sim

Rules:
- Jaccard(A, B) = |A ∩ B| / |A ∪ B|
- For binary rows: intersection = dot product, union = sum of union set
"""
function jaccard_topk_edges(
    X::SparseMatrixCSC,
    slug_index::Vector{String};
    k::Int = SC_JACCARD_TOP_K,
    min_sim::Float64 = SC_JACCARD_MIN_SIM,
    verbose::Bool = true
)
    n = size(X, 1)
    @assert n == length(slug_index) "Matrix rows must match slug_index length"

    # Precompute row cardinalities (number of countries per slug)
    row_cards = Vector{Int}(undef, n)
    for i in 1:n
        row_cards[i] = 0
    end
    for col in 1:size(X, 2)
        for ptr in X.colptr[col]:(X.colptr[col+1]-1)
            row_cards[X.rowval[ptr]] += 1
        end
    end

    # Build column → slug lists for intersection computation
    col_slugs = Vector{Vector{Int}}(undef, size(X, 2))
    for col in 1:size(X, 2)
        sl = Int[]
        for ptr in X.colptr[col]:(X.colptr[col+1]-1)
            push!(sl, X.rowval[ptr])
        end
        col_slugs[col] = sl
    end

    # Build row → column lists
    row_cols = Vector{Vector{Int}}(undef, n)
    for i in 1:n
        row_cols[i] = Int[]
    end
    for col in 1:size(X, 2)
        for ptr in X.colptr[col]:(X.colptr[col+1]-1)
            push!(row_cols[X.rowval[ptr]], col)
        end
    end

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 2 — Jaccard top-k edges")
        println("=" ^ 72)
        println("    Slugs: $n")
        println("    Countries: $(size(X, 2))")
        println("    k: $k, min_sim: $min_sim")
    end

    out_i = String[]
    out_j = String[]
    out_s = Float64[]

    for i in 1:n
        card_i = row_cards[i]
        card_i == 0 && continue

        # Accumulate intersection counts via shared columns
        intersection = Dict{Int, Int}()
        for col in row_cols[i]
            for j in col_slugs[col]
                j == i && continue
                intersection[j] = get(intersection, j, 0) + 1
            end
        end

        # Compute Jaccard and select top-k
        candidates = Tuple{Int, Float64}[]
        for (j, isect) in intersection
            card_j = row_cards[j]
            union_size = card_i + card_j - isect
            union_size == 0 && continue
            jacc = isect / union_size
            jacc >= min_sim && push!(candidates, (j, jacc))
        end

        if !isempty(candidates)
            sort!(candidates, by = x -> -x[2])
            take = candidates[1:min(k, length(candidates))]
            for (j, s) in take
                push!(out_i, slug_index[i])
                push!(out_j, slug_index[j])
                push!(out_s, s)
            end
        end
    end

    edges_df = DataFrame(slug_i = out_i, slug_j = out_j, sim = out_s)

    if verbose
        println("    Directed edges: $(nrow(edges_df))")
        if nrow(edges_df) > 0
            sims = edges_df.sim
            println("    Similarity range: $(round(minimum(sims), digits=3)) — $(round(maximum(sims), digits=3))")
            println("    Median similarity: $(round(median(sims), digits=3))")
        end
        println("=" ^ 72)
    end

    return edges_df
end


# ==============================================================================
# STEP 3: GRAPH CONSTRUCTION & CLUSTERING
# ==============================================================================

"""
Symmetrize directed top-k edges into undirected edge list.

Arguments:
- edges_df::DataFrame: Directed edges (slug_i, slug_j, sim)
- mode::Symbol: :max or :mean for combining bidirectional edges

Returns:
- DataFrame with columns: slug_a, slug_b, weight, n_dir
"""
function symmetrize_edges(edges_df::AbstractDataFrame; mode::Symbol = :max, verbose::Bool = true)
    @assert all(Symbol.(["slug_i", "slug_j", "sim"]) .∈ Ref(propertynames(edges_df)))

    acc = Dict{Tuple{String,String}, Vector{Float64}}()
    for r in eachrow(edges_df)
        a = String(r.slug_i); b = String(r.slug_j)
        (a == b) && continue
        p = a < b ? (a, b) : (b, a)
        if !haskey(acc, p)
            acc[p] = Float64[]
        end
        push!(acc[p], Float64(r.sim))
    end

    out_a = String[]; out_b = String[]; out_w = Float64[]; out_n = Int[]
    for (p, vals) in acc
        w = mode == :mean ? mean(vals) : maximum(vals)
        push!(out_a, p[1]); push!(out_b, p[2]); push!(out_w, w); push!(out_n, length(vals))
    end

    und = DataFrame(slug_a = out_a, slug_b = out_b, weight = out_w, n_dir = out_n)

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 3a — Symmetrize edges")
        println("=" ^ 72)
        println("    Directed edges in:   $(nrow(edges_df))")
        println("    Undirected edges out: $(nrow(und))")
        if nrow(und) > 0
            println("    Weight range: $(round(minimum(und.weight), digits=3)) — $(round(maximum(und.weight), digits=3))")
            bidir = count(==(2), und.n_dir)
            println("    Bidirectional: $bidir / $(nrow(und)) ($(round(bidir/nrow(und)*100, digits=1))%)")
        end
        println("=" ^ 72)
    end

    return und
end

"""
Build a weighted undirected graph from symmetrized edges.

Arguments:
- edges_und::DataFrame: Undirected edges (slug_a, slug_b, weight)

Returns:
- NamedTuple with :graph (SimpleWeightedGraph), :slug_index, :slug_to_idx
"""
function build_slug_graph(edges_und::AbstractDataFrame; verbose::Bool = true)
    all_slugs = sort(unique(vcat(edges_und.slug_a, edges_und.slug_b)))
    n = length(all_slugs)
    slug_to_idx = Dict(s => i for (i, s) in enumerate(all_slugs))

    g = SimpleWeightedGraph(n)
    for r in eachrow(edges_und)
        i = slug_to_idx[r.slug_a]
        j = slug_to_idx[r.slug_b]
        add_edge!(g, i, j, r.weight)
    end

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 3b — Build weighted graph")
        println("=" ^ 72)
        println("    Vertices: $n")
        println("    Edges: $(ne(g))")
        cc = connected_components(g)
        println("    Connected components: $(length(cc))")
        if length(cc) > 1
            sizes = sort(length.(cc), rev=true)
            println("    Component sizes: $(join(sizes[1:min(10, length(sizes))], ", "))$(length(sizes) > 10 ? "..." : "")")
        end
        println("=" ^ 72)
    end

    return (graph = g, slug_index = all_slugs, slug_to_idx = slug_to_idx)
end

"""
Cluster slugs via label propagation on the weighted graph.

Arguments:
- graph::SimpleWeightedGraph: Weighted slug similarity graph

Returns:
- DataFrame with columns: slug, cluster_id
"""
function cluster_slugs(graph_result::NamedTuple; verbose::Bool = true)
    g = graph_result.graph
    slugs = graph_result.slug_index

    labels, _ = label_propagation(g)

    slug_cluster_df = DataFrame(slug = slugs, cluster_id = labels)

    if verbose
        n_clusters = length(unique(labels))
        cluster_sizes = sort(combine(groupby(slug_cluster_df, :cluster_id), nrow => :size).size, rev=true)

        println("\n" * "=" ^ 72)
        println("Step 3c — Label propagation clustering")
        println("=" ^ 72)
        println("    Clusters found: $n_clusters")
        println("    Cluster sizes: $(join(cluster_sizes[1:min(10, length(cluster_sizes))], ", "))$(length(cluster_sizes) > 10 ? "..." : "")")
        println("    Largest: $(cluster_sizes[1])")
        println("    Smallest: $(cluster_sizes[end])")
        println("    Median: $(Int(round(median(cluster_sizes))))")
        println("=" ^ 72)
    end

    return slug_cluster_df
end


# ==============================================================================
# STEP 4: INTERPRET CLUSTERS
# ==============================================================================

"""
Summarize each cluster: composition, country footprint, internal similarity.

Arguments:
- slug_cluster_df::DataFrame: (slug, cluster_id)
- meta_df::DataFrame: Metadata with :slug, :prefix, :provenance, etc.
- X::SparseMatrixCSC: Presence matrix
- slug_index::Vector{String}: Matrix row labels
- country_index::Vector{Int}: Matrix column labels

Returns:
- DataFrame with one row per cluster
"""
function summarize_slug_clusters(
    slug_cluster_df::DataFrame,
    meta_df::DataFrame,
    X::SparseMatrixCSC,
    slug_index::Vector{String},
    country_index::Vector{Int};
    verbose::Bool = true
)
    slug_to_row = Dict(s => i for (i, s) in enumerate(slug_index))
    clusters = sort(unique(slug_cluster_df.cluster_id))

    rows = []
    for cid in clusters
        cslugs = slug_cluster_df[slug_cluster_df.cluster_id .== cid, :slug]
        n_slugs = length(cslugs)

        # Prefixes
        joined = leftjoin(DataFrame(slug = cslugs), meta_df[:, [:slug, :prefix, :provenance]], on = :slug)
        prefix_counts = sort(combine(groupby(joined, :prefix), nrow => :count), :count, rev=true)
        dominant_prefix = nrow(prefix_counts) > 0 ? first(prefix_counts.prefix) : "unknown"
        n_prefixes = nrow(prefix_counts)

        # Provenance
        prov_counts = sort(combine(groupby(dropmissing(joined, :provenance), :provenance), nrow => :count), :count, rev=true)
        dominant_provenance = nrow(prov_counts) > 0 ? first(prov_counts.provenance) : "unknown"

        # Country footprint: union of all countries covered by any slug in cluster
        covered = Set{Int}()
        for s in cslugs
            haskey(slug_to_row, s) || continue
            ri = slug_to_row[s]
            for ci in 1:length(country_index)
                if X[ri, ci] > 0
                    push!(covered, country_index[ci])
                end
            end
        end

        push!(rows, (
            cluster_id = cid,
            n_slugs = n_slugs,
            n_prefixes = n_prefixes,
            dominant_prefix = dominant_prefix,
            dominant_provenance = dominant_provenance,
            n_countries = length(covered),
            country_coverage_pct = round(length(covered) / length(country_index) * 100, digits=1)
        ))
    end

    summary = DataFrame(rows)
    sort!(summary, :n_slugs, rev=true)

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 4 — Cluster Summary")
        println("=" ^ 72)
        for r in eachrow(summary)
            println("    Cluster $(r.cluster_id): $(r.n_slugs) slugs, $(r.n_prefixes) prefixes, " *
                    "$(r.n_countries) countries ($(r.country_coverage_pct)%), " *
                    "dominant=$(r.dominant_prefix) [$(r.dominant_provenance)]")
        end
        println("=" ^ 72)
    end

    return summary
end


# ==============================================================================
# STEP 5: GEOGRAPHIC CHARACTERIZATION
# ==============================================================================

"""
Characterize each cluster's geographic profile using UN region data.

Arguments:
- slug_cluster_df::DataFrame: (slug, cluster_id)
- X::SparseMatrixCSC: Presence matrix
- slug_index::Vector{String}: Matrix row labels
- country_index::Vector{Int}: Matrix column labels
- geo_df::DataFrame: Geographic lookup with :ident_ccode, :un_region_name, :un_subregion_name

Returns:
- DataFrame with cluster_id, geographic_type, primary_region, concentration_pct

Rules:
- Global: covers ≥80% of all countries
- Regional: ≥70% of covered countries in a single UN region/subregion
- Multi-regional: concentrated in 2-3 regions
- Sparse: low coverage, no concentration
"""
function characterize_cluster_geography(
    slug_cluster_df::DataFrame,
    X::SparseMatrixCSC,
    slug_index::Vector{String},
    country_index::Vector{Int},
    geo_df::DataFrame;
    verbose::Bool = true
)
    slug_to_row = Dict(s => i for (i, s) in enumerate(slug_index))
    ccode_to_region = Dict{Int, String}()
    ccode_to_subregion = Dict{Int, String}()
    for r in eachrow(geo_df)
        ccode_to_region[r.ident_ccode] = ismissing(r.un_region_name) ? "Unknown" : string(r.un_region_name)
        ccode_to_subregion[r.ident_ccode] = ismissing(r.un_subregion_name) ? "Unknown" : string(r.un_subregion_name)
    end

    clusters = sort(unique(slug_cluster_df.cluster_id))
    n_total_countries = length(country_index)
    rows = []

    for cid in clusters
        cslugs = slug_cluster_df[slug_cluster_df.cluster_id .== cid, :slug]

        # Union of countries covered
        covered = Set{Int}()
        for s in cslugs
            haskey(slug_to_row, s) || continue
            ri = slug_to_row[s]
            for ci in 1:length(country_index)
                if X[ri, ci] > 0
                    push!(covered, country_index[ci])
                end
            end
        end

        n_covered = length(covered)
        coverage_pct = n_covered / n_total_countries

        # Region distribution
        region_counts = Dict{String, Int}()
        subregion_counts = Dict{String, Int}()
        for c in covered
            reg = get(ccode_to_region, c, "Unknown")
            subreg = get(ccode_to_subregion, c, "Unknown")
            region_counts[reg] = get(region_counts, reg, 0) + 1
            subregion_counts[subreg] = get(subregion_counts, subreg, 0) + 1
        end

        # Find dominant region
        top_region = ""
        top_region_pct = 0.0
        for (reg, cnt) in region_counts
            pct = cnt / n_covered
            if pct > top_region_pct
                top_region = reg
                top_region_pct = pct
            end
        end

        # Classify
        geo_type = if coverage_pct >= 0.80
            "global"
        elseif top_region_pct >= 0.70
            "regional"
        elseif n_covered > 0
            # Check multi-regional: top 2-3 regions cover ≥80%
            sorted_pcts = sort(collect(values(region_counts)), rev=true)
            top3_pct = sum(sorted_pcts[1:min(3, length(sorted_pcts))]) / n_covered
            top3_pct >= 0.80 ? "multi-regional" : "sparse"
        else
            "sparse"
        end

        push!(rows, (
            cluster_id = cid,
            n_countries = n_covered,
            coverage_pct = round(coverage_pct * 100, digits=1),
            geographic_type = geo_type,
            primary_region = top_region,
            primary_region_pct = round(top_region_pct * 100, digits=1)
        ))
    end

    geo_profile = DataFrame(rows)

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 5 — Geographic Characterization")
        println("=" ^ 72)
        for r in eachrow(geo_profile)
            println("    Cluster $(r.cluster_id): $(r.geographic_type) — " *
                    "$(r.n_countries) countries ($(r.coverage_pct)%), " *
                    "primary=$(r.primary_region) ($(r.primary_region_pct)%)")
        end
        type_counts = combine(groupby(geo_profile, :geographic_type), nrow => :count)
        println("\n    Types: ", join(["$(r.geographic_type): $(r.count)" for r in eachrow(type_counts)], ", "))
        println("=" ^ 72)
    end

    return geo_profile
end


# ==============================================================================
# STEP 6: HT_REGION VALIDATION
# ==============================================================================

"""
Check if any clusters naturally align with ht_region groupings.

Arguments:
- slug_cluster_df::DataFrame: (slug, cluster_id)
- X, slug_index, country_index: Presence matrix and indices
- df::DataFrame: Augmented QoG (must have :ident_ccode, :ht_region)

Returns:
- DataFrame with cluster_id, best_ht_region, overlap_pct
"""
function validate_ht_region_alignment(
    slug_cluster_df::DataFrame,
    X::SparseMatrixCSC,
    slug_index::Vector{String},
    country_index::Vector{Int},
    df::DataFrame;
    verbose::Bool = true
)
    slug_to_row = Dict(s => i for (i, s) in enumerate(slug_index))

    # Build ht_region → country sets
    region_countries = Dict{Int, Set{Int}}()
    for r in eachrow(unique(select(df, :ident_ccode, :ht_region)))
        ismissing(r.ht_region) && continue
        reg = Int(r.ht_region)
        if !haskey(region_countries, reg)
            region_countries[reg] = Set{Int}()
        end
        push!(region_countries[reg], Int(r.ident_ccode))
    end

    clusters = sort(unique(slug_cluster_df.cluster_id))
    rows = []

    for cid in clusters
        cslugs = slug_cluster_df[slug_cluster_df.cluster_id .== cid, :slug]

        covered = Set{Int}()
        for s in cslugs
            haskey(slug_to_row, s) || continue
            ri = slug_to_row[s]
            for ci in 1:length(country_index)
                if X[ri, ci] > 0
                    push!(covered, country_index[ci])
                end
            end
        end

        # Find best-matching ht_region
        best_region = 0
        best_overlap = 0.0
        for (reg, reg_countries) in region_countries
            isect = length(intersect(covered, reg_countries))
            union_size = length(union(covered, reg_countries))
            overlap = union_size > 0 ? isect / union_size : 0.0
            if overlap > best_overlap
                best_overlap = overlap
                best_region = reg
            end
        end

        push!(rows, (
            cluster_id = cid,
            best_ht_region = best_region,
            ht_region_jaccard = round(best_overlap, digits=3),
            n_countries = length(covered)
        ))
    end

    ht_df = DataFrame(rows)

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 6 — ht_region Alignment Validation")
        println("=" ^ 72)
        strong = filter(r -> r.ht_region_jaccard >= 0.50, ht_df)
        println("    Clusters with strong ht_region alignment (Jaccard ≥ 0.50): $(nrow(strong))")
        for r in eachrow(strong)
            println("      Cluster $(r.cluster_id) ↔ ht_region $(r.best_ht_region) (J=$(r.ht_region_jaccard))")
        end
        weak = filter(r -> r.ht_region_jaccard < 0.30, ht_df)
        println("    Clusters with weak alignment (Jaccard < 0.30): $(nrow(weak))")
        println("=" ^ 72)
    end

    return ht_df
end


# ==============================================================================
# STEP 7: CLUSTER LABELING
# ==============================================================================

"""
Build profile cards for each cluster and auto-generate labels.

Arguments:
- slug_cluster_df, meta_df, X, slug_index, country_index, geo_df: As above

Returns:
- DataFrame with full cluster profiles including auto-generated labels
"""
function build_cluster_profiles(
    slug_cluster_df::DataFrame,
    meta_df::DataFrame,
    X::SparseMatrixCSC,
    slug_index::Vector{String},
    country_index::Vector{Int},
    geo_df::DataFrame;
    verbose::Bool = true
)
    summary = summarize_slug_clusters(slug_cluster_df, meta_df, X, slug_index, country_index; verbose=false)
    geography = characterize_cluster_geography(slug_cluster_df, X, slug_index, country_index, geo_df; verbose=false)

    profiles = leftjoin(summary, geography[:, [:cluster_id, :geographic_type, :primary_region, :primary_region_pct]], on=:cluster_id)

    # Auto-label
    labels = String[]
    for r in eachrow(profiles)
        label = if r.n_prefixes == 1
            "$(r.dominant_prefix)"
        elseif r.geographic_type == "regional"
            "$(r.primary_region)-focused ($(r.dominant_prefix)+)"
        elseif r.geographic_type == "global"
            "Global $(r.dominant_provenance) ($(r.dominant_prefix)+)"
        else
            "Mixed: $(r.dominant_prefix)+ ($(r.n_slugs) slugs)"
        end
        push!(labels, label)
    end
    profiles.label = labels

    if verbose
        println("\n" * "=" ^ 72)
        println("Step 7 — Cluster Profiles")
        println("=" ^ 72)
        for r in eachrow(profiles)
            println()
            println("    ┌─ Cluster $(r.cluster_id): $(r.label)")
            println("    │  Slugs: $(r.n_slugs) across $(r.n_prefixes) prefixes")
            println("    │  Countries: $(r.n_countries) ($(r.country_coverage_pct)%)")
            println("    │  Geography: $(r.geographic_type) — $(r.primary_region) ($(r.primary_region_pct)%)")
            println("    │  Provenance: $(r.dominant_provenance)")
            println("    └──────────────────────────────────────────────────────────────")
        end
        println("=" ^ 72)
    end

    return profiles
end


# ==============================================================================
# ORCHESTRATION
# ==============================================================================

"""
Run the full slug clustering pipeline.

Arguments:
- df::DataFrame: Augmented QoG timeseries
- meta_df::DataFrame: Metadata with prefix, provenance, etc.
- geo_df::DataFrame: Geographic lookup
- slugs::Union{Vector{String}, Nothing}: Pre-filtered slug list (e.g., from reclassification
  clustering pool). If nothing, falls back to partition_slugs(meta_df).

Returns:
- NamedTuple with all pipeline outputs

Usage:
    # With pre-filtered pool and clean denominator (recommended):
    pool = CSV.read("data/clustering_pool.csv", DataFrame).slug
    clean_ccodes = Set(Int.(reclass.clean_universe.clean_rows.ident_ccode))
    result = run_slug_clustering(df, meta_df, geo_df; slugs=pool, clean_ccodes=clean_ccodes)

    # Legacy: auto-partition, all countries:
    result = run_slug_clustering(df, meta_df, geo_df)
"""
function run_slug_clustering(
    df::DataFrame,
    meta_df::DataFrame,
    geo_df::DataFrame;
    slugs::Union{AbstractVector{<:AbstractString}, Nothing} = nothing,
    clean_ccodes::Union{Set{Int}, Nothing} = nothing,
    presence_min_pct::Float64 = SC_PRESENCE_MIN_PCT,
    presence_max_pct::Float64 = SC_PRESENCE_MAX_PCT,
    min_country_coverage::Float64 = SC_MIN_COUNTRY_COVERAGE,
    k::Int = SC_JACCARD_TOP_K,
    min_sim::Float64 = SC_JACCARD_MIN_SIM,
    verbose::Bool = true
)
    # Determine slug list
    if slugs === nothing
        partition = partition_slugs(meta_df)
        cluster_slugs_list = partition.cluster_slugs
        if verbose
            println("    Using auto-partition: $(length(cluster_slugs_list)) cluster candidates")
        end
    else
        cluster_slugs_list = slugs
        if verbose
            println("=" ^ 72)
            println("Slug Clustering — Pre-filtered Pool")
            println("=" ^ 72)
            println("    Input slugs: $(length(cluster_slugs_list))")
            println("=" ^ 72)
        end
    end

    # Step 1: Binary matrix (with clean denominator if provided)
    if clean_ccodes !== nothing && verbose
        println("    Clean denominator: $(length(clean_ccodes)) countries")
    end
    matrix_result = build_slug_country_matrix(df, cluster_slugs_list;
        clean_ccodes=clean_ccodes,
        presence_min_pct=presence_min_pct, presence_max_pct=presence_max_pct,
        min_country_coverage=min_country_coverage, verbose=verbose)

    # Step 2: Jaccard edges
    edges = jaccard_topk_edges(matrix_result.X, matrix_result.slug_index;
        k=k, min_sim=min_sim, verbose=verbose)

    # Step 3: Graph + cluster
    edges_und = symmetrize_edges(edges; verbose=verbose)
    graph_result = build_slug_graph(edges_und; verbose=verbose)
    slug_cluster_df = cluster_slugs(graph_result; verbose=verbose)

    # Steps 4-7: Interpretation
    profiles = build_cluster_profiles(slug_cluster_df, meta_df,
        matrix_result.X, matrix_result.slug_index, matrix_result.country_index,
        geo_df; verbose=verbose)

    ht_validation = validate_ht_region_alignment(slug_cluster_df,
        matrix_result.X, matrix_result.slug_index, matrix_result.country_index,
        df; verbose=verbose)

    return (
        matrix = matrix_result,
        edges_directed = edges,
        edges_undirected = edges_und,
        graph = graph_result,
        slug_clusters = slug_cluster_df,
        profiles = profiles,
        ht_validation = ht_validation
    )
end


# ==============================================================================
# SAMPLES
# ==============================================================================

"""
Print function intent and usage for slug_clustering.jl.

Usage:
    run_slug_clustering_samples()
"""
function run_slug_clustering_samples()
    println("\n" * "=" ^ 72)
    println("  slug_clustering.jl — Function intent and usage")
    println("=" ^ 72)

    println("""

    ┌─ partition_slugs(meta_df)
    │  Splits slugs into global (set aside) and cluster candidates.
    │  RETURNS: (global_slugs, cluster_slugs)
    └──────────────────────────────────────────────────────────────

    ┌─ build_slug_country_matrix(df, slugs; presence_min_pct, ...)
    │  Builds binary slug × country matrix with density thresholds.
    │  RETURNS: (X, slug_index, country_index, filtered_slugs)
    └──────────────────────────────────────────────────────────────

    ┌─ jaccard_topk_edges(X, slug_index; k, min_sim)
    │  Computes pairwise Jaccard similarity, keeps top-k edges.
    │  RETURNS: DataFrame(slug_i, slug_j, sim)
    └──────────────────────────────────────────────────────────────

    ┌─ run_slug_clustering(df, meta_df, geo_df; ...)
    │  Full pipeline: partition → matrix → Jaccard → cluster → interpret.
    │  RETURNS: NamedTuple with all outputs
    │
    │  USAGE:
    │    df, meta_df = load_dataframes()
    │    geo_df = CSV.read("data/ggis_geographic_lookup.csv", DataFrame)
    │    result = run_slug_clustering(df, meta_df, geo_df)
    │    result.profiles     # cluster profile cards
    │    result.slug_clusters # slug → cluster_id mapping
    └──────────────────────────────────────────────────────────────
    """)
    println("=" ^ 72)
end

println("""
╔══════════════════════════════════════════════════════════════════════════╗
║ SLUG CLUSTERING - PHASE 0 LOADED                                      ║
╚══════════════════════════════════════════════════════════════════════════╝

Quick Start:
    df, meta_df = load_dataframes()
    geo_df = CSV.read("data/ggis_geographic_lookup.csv", DataFrame)
    result = run_slug_clustering(df, meta_df, geo_df)

Adjust thresholds:
    result = run_slug_clustering(df, meta_df, geo_df;
        presence_min_pct=0.15,    # stricter presence
        min_sim=0.20,             # tighter clusters
        k=10                      # fewer edges
    )

═══════════════════════════════════════════════════════════════════════════
""")
