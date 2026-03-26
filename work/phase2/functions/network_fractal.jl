using Graphs
using SimpleWeightedGraphs
using CommunityDetection
using LinearAlgebra
using Statistics
using DataFrames

"""
Perform network renormalization (coarse-graining) on a weighted graph.

Detects communities, then collapses each community into a single super-node.
Edges between super-nodes are the sum of edge weights between their member nodes.
Self-loops (within-community edges) are discarded.

Arguments
- `g::SimpleWeightedGraph`: Input weighted graph
- `membership::Vector{Int}`: Community assignment for each node (from community detection)

Returns
- `SimpleWeightedGraph`: Coarse-grained graph where each node is a community
- `Vector{Int}`: Number of original nodes in each super-node

Rules
- Pure function; does not modify input graph
- Edge weights are summed across community boundaries
- Self-loops are excluded

Usage
    communities = community_detection_louvain(g)
    coarse_g, sizes = renormalize_network(g, communities)
"""
function renormalize_network(g::SimpleWeightedGraph, membership::Vector{Int})
    n_communities = maximum(membership)

    # Build coarse-grained adjacency
    coarse_weights = zeros(Float64, n_communities, n_communities)
    community_sizes = zeros(Int, n_communities)

    for v in vertices(g)
        community_sizes[membership[v]] += 1
    end

    for e in edges(g)
        c_src = membership[src(e)]
        c_dst = membership[dst(e)]
        if c_src != c_dst
            w = weight(e)
            coarse_weights[c_src, c_dst] += w
            coarse_weights[c_dst, c_src] += w
        end
    end

    # Build coarse graph
    coarse_g = SimpleWeightedGraph(n_communities)
    for i in 1:n_communities
        for j in (i+1):n_communities
            if coarse_weights[i, j] > 0
                add_edge!(coarse_g, i, j, coarse_weights[i, j])
            end
        end
    end

    return coarse_g, community_sizes
end

"""
Compare structural properties of a graph at two scales (original vs. coarse-grained).
Tests Signature 4: fractal structure via network renormalization.

Arguments
- `g_original::SimpleWeightedGraph`: Original network
- `g_coarse::SimpleWeightedGraph`: Coarse-grained (renormalized) network

Returns
- `Dict{String, Any}`: Comparison metrics:
    - `degree_ks`: KS distance between degree distributions (lower = more similar)
    - `clustering_ks`: KS distance between clustering coefficient distributions
    - `density_original`: Graph density at original scale
    - `density_coarse`: Graph density at coarse scale
    - `density_ratio`: Ratio of densities
    - `spectral_gap_original`: Spectral gap of original graph
    - `spectral_gap_coarse`: Spectral gap of coarse graph
    - `fractal_score`: Composite similarity (0 = no similarity, 1 = perfect self-similarity)

Rules
- All comparisons are scale-aware (normalized by graph size)
- Requires both graphs to have at least 3 nodes

Usage
    metrics = compare_network_scales(g_original, g_coarse)
    println("Fractal score: ", metrics["fractal_score"])
"""
function compare_network_scales(g_original::SimpleWeightedGraph, g_coarse::SimpleWeightedGraph)
    nv_orig = nv(g_original)
    nv_coarse = nv(g_coarse)

    if nv_coarse < 3
        error("Coarse-grained graph has fewer than 3 nodes; renormalization too aggressive")
    end

    # Degree distributions (normalized by max possible degree)
    deg_orig = degree(g_original) ./ max(1, nv_orig - 1)
    deg_coarse = degree(g_coarse) ./ max(1, nv_coarse - 1)
    degree_ks = _ks_statistic(deg_orig, deg_coarse)

    # Clustering coefficient distributions
    cc_orig = local_clustering_coefficient(g_original)
    cc_coarse = local_clustering_coefficient(g_coarse)
    clustering_ks = _ks_statistic(cc_orig, cc_coarse)

    # Graph density
    density_orig = ne(g_original) / (nv_orig * (nv_orig - 1) / 2)
    density_coarse = ne(g_coarse) / (nv_coarse * (nv_coarse - 1) / 2)
    density_ratio = density_coarse > 0 ? density_orig / density_coarse : Inf

    # Spectral gaps
    sg_orig = _spectral_gap(g_original)
    sg_coarse = _spectral_gap(g_coarse)

    # Composite fractal score (mean of individual similarities)
    degree_sim = 1.0 - degree_ks
    clustering_sim = 1.0 - clustering_ks
    density_sim = 1.0 - abs(log(density_ratio + 1e-10))  # log-ratio close to 0 = similar
    density_sim = clamp(density_sim, 0.0, 1.0)
    fractal_score = mean([degree_sim, clustering_sim, density_sim])

    return Dict{String, Any}(
        "degree_ks" => degree_ks,
        "clustering_ks" => clustering_ks,
        "density_original" => density_orig,
        "density_coarse" => density_coarse,
        "density_ratio" => density_ratio,
        "spectral_gap_original" => sg_orig,
        "spectral_gap_coarse" => sg_coarse,
        "fractal_score" => fractal_score,
        "n_original" => nv_orig,
        "n_coarse" => nv_coarse
    )
end

"""
Detect nested community structure and compare properties at each level.
Tests Signature 4 by checking whether sub-communities resemble top-level communities.

Arguments
- `g::SimpleWeightedGraph`: Input weighted graph
- `max_levels::Int`: Maximum nesting depth (default: 3)
- `min_community_size::Int`: Stop subdividing communities smaller than this (default: 5)

Returns
- `DataFrame`: One row per renormalization level with structural metrics:
    `level`, `n_nodes`, `n_edges`, `n_communities`, `density`, `mean_degree`,
    `mean_clustering`, `spectral_gap`, `degree_ks_vs_original`

Rules
- Level 0 is the original graph
- Each subsequent level coarse-grains via community detection
- Stops when graph is too small to subdivide meaningfully

Usage
    levels = hierarchical_renormalization(g; max_levels=4)
"""
function hierarchical_renormalization(g::SimpleWeightedGraph; max_levels::Int=3, min_community_size::Int=5)
    results = DataFrame(
        level=Int[], n_nodes=Int[], n_edges=Int[], n_communities=Int[],
        density=Float64[], mean_degree=Float64[], mean_clustering=Float64[],
        spectral_gap=Float64[], degree_ks_vs_original=Float64[]
    )

    # Level 0: original graph
    deg_orig = degree(g) ./ max(1, nv(g) - 1)
    cc_orig = local_clustering_coefficient(g)

    current_g = g
    for level in 0:max_levels
        n = nv(current_g)
        m = ne(current_g)

        if n < min_community_size
            println("Level $level: only $n nodes, stopping")
            break
        end

        d = m > 0 ? m / (n * (n - 1) / 2) : 0.0
        deg = degree(current_g)
        cc = local_clustering_coefficient(current_g)
        sg = _spectral_gap(current_g)

        # KS distance from original degree distribution
        deg_normalized = deg ./ max(1, n - 1)
        ks = level == 0 ? 0.0 : _ks_statistic(deg_orig, deg_normalized)

        # Community detection for next level
        n_comm = 0
        if n >= min_community_size
            try
                membership = community_detection_nback(current_g)
                n_comm = maximum(membership)
            catch
                n_comm = 1
            end
        end

        push!(results, (
            level=level, n_nodes=n, n_edges=m, n_communities=n_comm,
            density=d, mean_degree=mean(deg), mean_clustering=mean(cc),
            spectral_gap=sg, degree_ks_vs_original=ks
        ))

        # Renormalize for next level
        if n_comm <= 1 || n_comm >= n
            println("Level $level: $n_comm communities from $n nodes, stopping")
            break
        end

        try
            membership = community_detection_nback(current_g)
            current_g, _ = renormalize_network(current_g, membership)
        catch e
            println("Level $level: renormalization failed ($e), stopping")
            break
        end
    end

    return results
end

"""
Two-sample Kolmogorov-Smirnov statistic (internal helper).

Arguments
- `x::AbstractVector`: First sample
- `y::AbstractVector`: Second sample

Returns
- `Float64`: Maximum absolute difference between ECDFs

Rules
- Returns 0.0 if either sample is empty

Usage
    ks = _ks_statistic([1,2,3], [2,3,4])
"""
function _ks_statistic(x::AbstractVector, y::AbstractVector)
    nx = length(x)
    ny = length(y)
    if nx == 0 || ny == 0
        return 0.0
    end

    all_vals = sort(vcat(collect(x), collect(y)))
    max_diff = 0.0

    for v in all_vals
        ecdf_x = count(xi -> xi <= v, x) / nx
        ecdf_y = count(yi -> yi <= v, y) / ny
        diff = abs(ecdf_x - ecdf_y)
        if diff > max_diff
            max_diff = diff
        end
    end

    return max_diff
end

"""
Compute the spectral gap of a graph (internal helper).

The spectral gap is the difference between the two largest eigenvalues
of the normalized adjacency matrix. A small spectral gap indicates
slow diffusion / compartmentalized dynamics. A large gap indicates
rapid diffusion / the network behaves as a unit.

Arguments
- `g::AbstractGraph`: Input graph

Returns
- `Float64`: Spectral gap (λ₁ - λ₂). Returns 0.0 for graphs with fewer than 3 nodes.

Rules
- Uses the normalized adjacency matrix (D^{-1/2} A D^{-1/2})
- Handles disconnected nodes by adding small regularization

Usage
    sg = _spectral_gap(g)
"""
function _spectral_gap(g::AbstractGraph)
    n = nv(g)
    if n < 3
        return 0.0
    end

    A = Float64.(adjacency_matrix(g))
    deg = vec(sum(A, dims=2))

    # Regularize zero-degree nodes
    deg[deg .== 0] .= 1e-10

    D_inv_sqrt = Diagonal(1.0 ./ sqrt.(deg))
    L_norm = D_inv_sqrt * A * D_inv_sqrt

    # Get top 2 eigenvalues
    try
        evals = eigvals(Symmetric(Matrix(L_norm)))
        sorted_evals = sort(real.(evals), rev=true)
        if length(sorted_evals) >= 2
            return sorted_evals[1] - sorted_evals[2]
        end
    catch
        return 0.0
    end

    return 0.0
end
