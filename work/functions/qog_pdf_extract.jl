using PDFIO
using DataFrames
using CSV
using StatsBase  # for countmap

# --- Manual Provenance Overrides ---
# These are checked when heuristic classification returns UNCERTAIN.
# Format: prefix => provenance category
const PROVENANCE_OVERRIDES = Dict{String, String}(
    "aid"    => "EVENT/FACTUAL",  # Records discrete development finance activities (1947-2013)
    "ajr"    => "IMPUTED",       # Academic Reconstruction of Patchy Historical Records
    "biu"    => "EXPERT",         # Multidimensional Index of Bureaucratic Underrepresentation
    "chga"   => "EVENT/FACTUAL",  # Political regimes based on discrete turnover/election events
    "ef"     => "PHYSICAL",       # Ecological footprint and biocapacity accounts
    "fe"     => "EVENT/FACTUAL",  # Ethnic/ethnoreligious group proportions for fractionalization
    "gc"     => "SURVEY",         # Global Corruption Barometer (mass public perceptions)
    "gendip" => "EVENT/FACTUAL",  # Biographical details on cabinet composition
    "gtm"    => "EXPERT",         # Centripetal Democratic Governance theory scores
    "h"      => "OFFICIAL",       # Human Development Report (IGO-aggregated statistics)
    "idf"    => "OFFICIAL",       # Health statistics on diabetes prevalence
    "ipu"    => "OFFICIAL",       # IPU Parline database of national parliaments
    "jht"    => "OFFICIAL",       # COVID-19 case tracking (officially reported)
    "lis"    => "SURVEY",         # Luxembourg Income Study (household survey data)
    "lld"    => "EXPERT",         # Leviathan's Latent Dimensions (state capacity estimates)
    "ross"   => "IMPUTED",        # Forensic Reconstruction of Historical Records
    "wr"     => "EVENT/FACTUAL",  # Discrete regime transitions/breakdowns (1946-2010)
)

# --- Internal Helper (can be shared/imported from qog_augmented_standard.jl) ---
"""
Internal helper: assert that a vector of names is unique.
Throws an error with a readable list of duplicates if any are found.
"""
function _assert_unique_names(names_vec::AbstractVector{<:AbstractString}; context::AbstractString="")
    counts = countmap(String.(names_vec))
    dups = sort([k for (k, v) in counts if v > 1])
    if !isempty(dups)
        ctx = isempty(context) ? "" : " ($context)"
        error("Duplicate names detected$ctx: " * join(dups, ", "))
    end
    return true
end

"""
    extract_qog_slugs(pdf_path::String, output_path::String; 
                      prefix_df::Union{DataFrame, Nothing}=nothing,
                      verbose::Bool=false) -> Union{DataFrame, Nothing}

Extracts variable-level metadata from a QoG codebook PDF.

## Output schema
Writes and returns a `DataFrame` with columns:
- `slug`        :: String — the QoG variable code (e.g., `wdi_gdp`), **lowercase**
- `prefix`      :: String — inferred prefix (substring before first `_`; `"base"` if none)
- `description` :: String — first paragraph of variable description
- `type`        :: String — variable type (captured from `Type of variable: <type>`)
- `provenance`  :: String — provenance category (classified from slug description, fallback to prefix)

## Classification strategy
1. Classify each slug using its **own full description**
2. If result is `"UNCERTAIN"`, fall back to prefix-level provenance from `prefix_df`
3. If prefix not found or `prefix_df` not provided, remains `"UNCERTAIN"`

## Arguments
- `pdf_path`    — Path to the QoG codebook PDF
- `output_path` — Path to write the output CSV
- `prefix_df`   — (Optional) DataFrame from `extract_qog_prefix` with `prefix` and `provenance` columns.
                  Used as fallback when slug-level classification is uncertain.
- `verbose`     — Print detailed extraction info

## Notes
This function is designed to be run once per year when a new QoG codebook is released.
"""
function extract_qog_slugs(pdf_path::String, output_path::String; 
                           prefix_df::Union{DataFrame, Nothing}=nothing,
                           verbose::Bool=false)
    println(">>> Phase 0: Initiating PDF Extraction...")

    full_text = IOBuffer()
    doc = nothing

    try
        doc = pdDocOpen(pdf_path)
        n_pages = pdDocGetPageCount(doc)
        println("    Loaded PDF: $n_pages pages detected.")

        for i in 1:n_pages
            page = pdDocGetPage(doc, i)
            pdPageExtractText(full_text, page)
        end
    catch e
        println("!!! CRITICAL FAILURE: Could not read PDF: $pdf_path")
        showerror(stdout, e); println()
        return nothing
    finally
        if doc !== nothing
            pdDocClose(doc)
        end
    end

    lines = split(String(take!(full_text)), "\n")
    println("    Text Extraction Complete. Parsing $(length(lines)) lines...")

    # --- Build provenance lookup from prefix_df (for fallback) ---
    prov_lookup = Dict{String, String}()
    if prefix_df !== nothing && :prefix in propertynames(prefix_df) && :provenance in propertynames(prefix_df)
        for row in eachrow(prefix_df)
            prov_lookup[lowercase(row.prefix)] = row.provenance
        end
        println("    Provenance fallback lookup loaded: $(length(prov_lookup)) prefixes")
    else
        println("    Provenance fallback: none (prefix_df not provided or missing columns)")
    end

    # --- Data Structure (all lowercase column names) ---
    data = DataFrame(
        slug = String[],
        prefix = String[],
        description = String[],
        type = String[],
        provenance = String[]
    )

    # --- Regex Patterns (case-insensitive, whitespace-tolerant) ---
    rx_slug = r"(?i)^\s*QoG\s*Code\s*:\s*(.+?)\s*$"
    rx_type = r"(?i)^\s*Type\s+of\s+variable\s*:\s*(.+?)\s*$"

    # --- State Machine ---
    current_slug = ""
    desc_buf = IOBuffer()
    capturing = false

    n_extracted = 0
    n_slug_classified = 0
    n_prefix_fallback = 0
    n_uncertain = 0

    function flush_current!(var_type::AbstractString)
        if !isempty(current_slug)
            # Normalize to lowercase
            slug = lowercase(strip(current_slug))
            prefix = occursin("_", slug) ? String(split(slug, "_")[1]) : "base"
            
            # Get FULL description for classification
            full_desc = strip(String(take!(desc_buf)))
            
            # Step 1: Classify using slug's OWN description (include prefix for override lookup)
            slug_row = (source_name = "", description = full_desc, prefix = prefix)
            slug_prov = classify_provenance(slug_row)
            
            # Step 2: If UNCERTAIN, fall back to prefix-level from prefix_df
            if slug_prov == "UNCERTAIN"
                prefix_prov = get(prov_lookup, prefix, "UNCERTAIN")
                if prefix_prov != "UNCERTAIN"
                    provenance = prefix_prov
                    n_prefix_fallback += 1
                    if verbose
                        @info "Fallback to prefix" slug=slug prefix=prefix provenance=provenance
                    end
                else
                    provenance = "UNCERTAIN"
                    n_uncertain += 1
                    if verbose
                        @warn "Could not classify" slug=slug prefix=prefix
                    end
                end
            else
                provenance = slug_prov
                n_slug_classified += 1
            end
            
            # Truncate description for storage
            first_para = extract_first_paragraph(full_desc)

            push!(data, (
                String(slug),
                String(prefix),
                String(first_para),
                String(lowercase(strip(var_type))),
                String(provenance)
            ))
            n_extracted += 1

            if verbose
                @info "Extracted" slug=slug prefix=prefix provenance=provenance type=var_type
            end
        else
            take!(desc_buf)  # clear buffer
        end
    end

    for line in lines
        clean_line = strip(line)
        isempty(clean_line) && continue

        # Check for QoG Code line (start of a new variable)
        m_slug = match(rx_slug, clean_line)
        if m_slug !== nothing
            # Flush previous variable if capturing
            if capturing
                flush_current!("")
            end

            current_slug = String(m_slug.captures[1])
            take!(desc_buf)  # clear description buffer
            capturing = true
            continue
        end

        # Check for Type of variable line (end of current variable block)
        m_type = match(rx_type, clean_line)
        if m_type !== nothing
            var_type = String(m_type.captures[1])
            flush_current!(var_type)

            current_slug = ""
            capturing = false
            continue
        end

        # If capturing, accumulate description (FULL for classification)
        if capturing
            write(desc_buf, ' ')
            write(desc_buf, clean_line)
        end
    end

    # Flush any trailing variable at EOF
    if capturing
        flush_current!("")
    end

    # --- Finalize ---
    # Check for duplicate slugs
    _assert_unique_names(data.slug; context="extracted QoG slugs")

    # Sort alphabetically by slug (lowercase)
    sort!(data, :slug)

    # Print classification summary
    println(">>> Classification Summary:")
    println("    Classified from slug description: $n_slug_classified")
    println("    Fallback to prefix: $n_prefix_fallback")
    println("    Uncertain: $n_uncertain")
    
    # Print provenance breakdown
    counts = countmap(data.provenance)
    println(">>> Provenance breakdown:")
    for (k, v) in sort(collect(counts), by=x->x[2], rev=true)
        println("    $k: $v")
    end

    CSV.write(output_path, data)

    println(">>> Extraction Complete.")
    println("    Variables extracted: $(nrow(data))")
    println("    Unique prefixes: $(length(unique(data.prefix)))")
    println(">>> Saved to: $output_path")

    return data
end

"""
    extract_first_paragraph(text::AbstractString) -> String

Extracts the first paragraph from a description text.
Uses heuristics to find paragraph boundaries in PDF-extracted text.
"""
function extract_first_paragraph(text::AbstractString)
    isempty(text) && return ""
    
    # Strategy 1: Look for explicit paragraph breaks (double spaces or clear section markers)
    # Only split on numbered lists if they start at beginning of a "sentence" after a period+space
    # AND the number is 1 or 2 (indicating a true list start, not "Question no. 4")
    m = match(r"^(.+?[.!?])\s+[12][\.\)]\s+[A-Z]", text)
    if m !== nothing && length(m.captures[1]) > 50
        return strip(m.captures[1])
    end
    
    # Strategy 2: Look for sentence-ending punctuation followed by scoring/response patterns
    m = match(r"^(.+?[.!?])\s+(?:Responses?:|Scoring|Clarification:|Clariﬁcation:|Scale:|Sources?:|Note:|The (?:index|variable|indicator|data))", text, Base.PCRE.CASELESS)
    if m !== nothing
        return strip(m.captures[1])
    end
    
    # Strategy 3: Look for common QoG codebook section breaks
    # These often indicate the end of the main description
    m = match(r"^(.+?[.!?])\s+(?:For more|See also|Available at|Data from|Based on)", text, Base.PCRE.CASELESS)
    if m !== nothing && length(m.captures[1]) > 30
        return strip(m.captures[1])
    end
    
    # Strategy 4: Take first 2-3 sentences (more generous than before)
    sentences = split(text, r"(?<=[.!?])\s+(?=[A-Z])")
    if length(sentences) >= 1
        # Accumulate sentences until we hit ~300 chars or 3 sentences
        result = sentences[1]
        for i in 2:min(3, length(sentences))
            if length(result) >= 300
                break
            end
            result *= " " * sentences[i]
        end
        
        # Truncate if still too long
        if length(result) > 600
            truncated = result[1:min(600, length(result))]
            last_period = findlast('.', truncated)
            if last_period !== nothing && last_period > 100
                return strip(truncated[1:last_period])
            end
        end
        return strip(result)
    end
    
    # Fallback: return first 500 chars
    return strip(text[1:min(500, length(text))])
end

"""
    extract_qog_prefix(pdf_path::String, output_path::String; verbose::Bool=false) -> Union{DataFrame, Nothing}

Extracts per-datasource metadata from a QoG codebook PDF (Section 4) and infers each datasource
`Prefix` from the first variable code encountered in that datasource section.

## Expected structure (Section 4)
For each datasource section `4.x`:

1) Outline heading: `4.x <Datasource>`  → `Datasource`
2) `Dataset by:` then a source name     → `Source_Name` (same line or next non-empty line)
3) Shaded box containing:
   - fixed preface including: `suggested citation for this dataset is:` (capture begins here)
   - citation text lines (captured into `Citation`)
4) `Dataset found at ...`               → ignored
5) `Last update by original source: ...`→ `Last_Update`
6) `Date of download ...`               → marks the **start** of `Description`
7) Description block                    → capture **all lines** until `4.x.1` header
8) Variable header `4.x.1 ...`          → **stops** description capture
9) `QoG Code: <prefix>_<slug>`          → infer `Prefix` (before first underscore)

## Output schema
Writes and returns a `DataFrame` with columns:
- `prefix`       :: String
- `datasource`   :: String
- `source_name`  :: String
- `citation`     :: String
- `last_update`  :: String
- `description`  :: String — **full** description (all lines from `Date of download:` to `4.x.1`)

Returns `nothing` if the PDF cannot be read.
"""
function extract_qog_prefix(pdf_path::String, output_path::String; verbose::Bool=false)
    println(">>> Phase 0: Initiating Source/Prefix Extraction...")

    # --- 1. Extract Text (High-Fidelity) ---
    full_text = IOBuffer()
    doc = nothing
    try
        doc = pdDocOpen(pdf_path)
        for i in 1:pdDocGetPageCount(doc)
            pdPageExtractText(full_text, pdDocGetPage(doc, i))
            # CRITICAL FIX: Force newline between pages to prevent Header merging
            print(full_text, "\n") 
        end
    catch e
        println("!!! CRITICAL FAILURE: Could not read PDF.")
        showerror(stdout, e); println()
        return nothing
    finally
        if doc !== nothing; pdDocClose(doc); end
    end

    lines = split(String(take!(full_text)), "\n")
    println("    Text Loaded. Lines to scan: $(length(lines))")

    # --- 2. Data Structure (all lowercase column names) ---
    # Note: description will be truncated to first paragraph before export
    data = DataFrame(
        prefix = String[],
        datasource = String[],
        source_name = String[],
        citation = String[],
        last_update = String[],
        description = String[],
        provenance = String[]
    )

    # --- 3. Regex Patterns ---
    # Header: "4.1 Name" or "4.1. Name". 
    rx_section = r"^\s*4\.(\d+)\.?\s+(.+)"
    
    # Variable Header: "4.1.1". Used as a stop-signal for descriptions.
    rx_var_header = r"^\s*4\.\d+\.\d+\s+"
    
    # Metadata Triggers
    rx_dataset_by = r"(?i)^Dataset\s+by\s*:\s*(.*)"
    rx_cite_start = r"(?i)suggested citation for this dataset is:"
    rx_cite_end   = r"(?i)Dataset found at:"
    rx_update     = r"(?i)Last update by original source:\s*(.+)"
    rx_download   = r"(?i)Date of download:"
    
    # Prefix: "QoG Code: bti_aar" -> Capture "bti"
    rx_slug_prefix = r"(?i)QoG\s*Code\s*:\s*([a-zA-Z0-9]+)_"

    # --- 4. State Machine ---
    current_ds_title = ""
    current_source_name = ""
    citation_buf = IOBuffer()
    current_update = ""
    desc_buf = IOBuffer()

    in_section = false
    capture_source_next = false
    capture_cite = false
    capture_desc = false
    
    row_count = 0

    for line in lines
        clean = strip(line)
        isempty(clean) && continue

        # --- A. New Section Detection ---
        m_sec = match(rx_section, clean)
        
        # Guard: Make sure it's not a variable header (4.1.1)
        if m_sec !== nothing && !occursin(rx_var_header, clean)
            # Reset buffers
            current_ds_title = strip(m_sec.captures[2])
            current_source_name = ""
            current_update = ""
            take!(citation_buf)
            take!(desc_buf)
            
            # Reset Flags
            in_section = true
            capture_cite = false
            capture_desc = false
            capture_source_next = false
            
            if verbose; println("  [Sec] $current_ds_title"); end
            continue
        end

        # If not inside a valid section, skip
        if !in_section
            continue
        end

        # --- B. Dataset By ---
        m_by = match(rx_dataset_by, clean)
        if m_by !== nothing
            name = strip(m_by.captures[1])
            if isempty(name)
                capture_source_next = true
            else
                current_source_name = name
            end
            continue
        end

        if capture_source_next
            if occursin(rx_cite_start, clean) || occursin(rx_download, clean)
                capture_source_next = false
            else
                current_source_name = clean
                capture_source_next = false
                continue
            end
        end

        # --- C. Citation ---
        if occursin(rx_cite_start, clean)
            capture_cite = true
            continue
        elseif occursin(rx_cite_end, clean)
            capture_cite = false
            continue
        end

        if capture_cite
            if !occursin(rx_update, clean) && !occursin(rx_download, clean)
                print(citation_buf, clean, " ")
            end
        end

        # --- D. Last Update ---
        m_up = match(rx_update, clean)
        if m_up !== nothing
            current_update = strip(m_up.captures[1])
            continue
        end

        # --- E. Description ---
        # Start: after "Date of download:"
        if occursin(rx_download, clean)
            capture_desc = true
            continue
        end

        # Stop: when we hit a Variable Header (4.x.1)
        if capture_desc && occursin(rx_var_header, clean)
            capture_desc = false
            # Don't continue; allow prefix detection below
        end

        # Capture FULL description (for classification)
        if capture_desc
            print(desc_buf, clean, " ")
        end

        # --- F. Prefix Detection (The Lock) ---
        m_slug = match(rx_slug_prefix, clean)
        if m_slug !== nothing
            prefix = lowercase(strip(m_slug.captures[1]))
            
            # Finalize Strings
            str_cite = strip(String(take!(citation_buf)))
            full_desc = strip(String(take!(desc_buf)))
            
            # CLASSIFY using FULL description AND prefix (for override lookup)
            prov_row = (source_name = current_source_name, description = full_desc, prefix = prefix)
            provenance = classify_provenance(prov_row)
            
            # TRUNCATE description to first paragraph for storage
            first_para = extract_first_paragraph(full_desc)
            
            push!(data, (
                prefix, 
                current_ds_title, 
                current_source_name, 
                str_cite, 
                current_update, 
                first_para,      # Save truncated
                provenance       # Classification based on full
            ))
            
            row_count += 1
            if verbose
                println("    + Locked: $prefix [$provenance] (full_desc=$(length(full_desc)), saved=$(length(first_para)))")
            end
            
            # Close section
            in_section = false 
        end
    end

    # --- 6. Validate, Sort and Export ---
    _assert_unique_names(data.prefix; context="extracted QoG prefixes")
    sort!(data, :prefix)
    
    # Print provenance summary
    counts = countmap(data.provenance)
    println(">>> Provenance Classification:")
    for (k, v) in sort(collect(counts), by=x->x[2], rev=true)
        println("    $k: $v")
    end
    
    CSV.write(output_path, data)
    println(">>> Extraction Complete. Rows: $(nrow(data))")
    println(">>> Saved to: $output_path")
    return data
end


"""
    classify_provenance(row) -> String

Classifies a datasource into one of six provenance categories based on heuristic text matching
against `source_name` and `description` fields.

## Classification Categories (evaluated in order)

1. **PHYSICAL** — Immutable or slowly changing geospatial/environmental realities
2. **SURVEY** — Mass public opinion or household questionnaires (excludes expert surveys)
3. **EVENT/FACTUAL** — Forensic counts of objective events or biographical facts
4. **IMPUTED** — Academic modeling, interpolation, or historical reconstruction
5. **EXPERT** — Evaluative indices, scores, or ratings from subject matter experts
6. **OFFICIAL** — Administrative statistics reported by states to IGOs (default state)

## Fallback
If heuristics return `UNCERTAIN`, checks `PROVENANCE_OVERRIDES` for a manual classification.

## Arguments
- `row` — A row (NamedTuple or DataFrameRow) with fields `source_name` and `description`
- Optionally include `prefix` field for override lookup

## Returns
- `String`: One of `"PHYSICAL"`, `"SURVEY"`, `"EVENT/FACTUAL"`, `"IMPUTED"`, `"EXPERT"`, `"OFFICIAL"`, or `"UNCERTAIN"`
"""
function classify_provenance(row)
    # Normalize text for matching (use lowercase column names)
    text = lowercase(string(
        get(row, :source_name, ""), " ", 
        get(row, :description, "")
    ))
    
    # --- 1. PHYSICAL (The Board) ---
    if occursin(r"geograph|latitude|longitude|elevation|ruggedness|coast|climate|temperature|precipitation|physical|nasa|satellite|terrain|land area|soil|forest", text)
        return "PHYSICAL"
    end

    # --- 2. SURVEY (Agent Temperature) ---
    rx_survey_include = r"public opinion|household|respondent|citizen|mass survey|population survey|eurobarometer|world values survey|afrobarometer|latinobarometro|asian barometer|ess|gcb|gallup|vital statistics"
    rx_survey_exclude = r"expert survey"
    
    if occursin(rx_survey_include, text) && !occursin(rx_survey_exclude, text)
        return "SURVEY"
    end

    # --- 3. EVENT/FACTUAL (Discrete State Changes) ---
    if occursin(r"conflict|war|coup|battle death|assassination|riot|event data|nelda|ucdp|archigos|cabinet|biograph|election date|turnout|treaty|alliance", text)
        return "EVENT/FACTUAL"
    end

    # --- 4. IMPUTED (Forensic Reconstruction) ---
    if occursin(r"reconstruct|historical|interpolation|extrapolation|simulation|maddison|penn world table|barro|lee|academic estimate", text)
        return "IMPUTED"
    end

    # --- 5. EXPERT (System Parameters) ---
    if occursin(r"expert|perception|assessment|rating|score|index|coded|freedom house|v-dem|transparency international|polity|prs group|heritage|fraser|bertelsmann|check and balance|constitution|de jure", text)
        return "EXPERT"
    end

    # --- 6. OFFICIAL (Administrative State) ---
    if occursin(r"world bank|imf|united nations|who|oecd|census|statistical office|registration|admin|ministry|expenditure|gdp|tax revenue", text)
        return "OFFICIAL"
    end

    # --- 7. Check manual overrides ---
    prefix = lowercase(string(get(row, :prefix, "")))
    if !isempty(prefix) && haskey(PROVENANCE_OVERRIDES, prefix)
        return PROVENANCE_OVERRIDES[prefix]
    end

    return "UNCERTAIN"
end


"""
    classify_provenance!(df::DataFrame) -> DataFrame

Adds a `provenance` column to the DataFrame by applying `classify_provenance` to each row.

## Arguments
- `df` — A DataFrame with columns `source_name` and `description`

## Returns
- The input DataFrame with an added `provenance::String` column

## Side effects
- Mutates `df` in place by adding the `provenance` column
- Prints a summary of classification counts
"""
function classify_provenance!(df::DataFrame)
    df.provenance = [classify_provenance(row) for row in eachrow(df)]
    
    # Print summary
    counts = countmap(df.provenance)
    println(">>> Provenance Classification Complete:")
    for (k, v) in sort(collect(counts), by=x->x[2], rev=true)
        println("    $k: $v")
    end
    
    return df
end

"""
    list_uncertain(df::DataFrame; output_path::Union{String, Nothing}=nothing, short::Bool=false) -> DataFrame

Returns a filtered DataFrame containing only rows with `provenance == "UNCERTAIN"` for manual review.

## Arguments
- `df` — A DataFrame with a `provenance` column (from `extract_qog_prefix` or `extract_qog_slugs`)
- `output_path` — (Optional) Path to save the uncertain rows as CSV for manual review
- `short` — If `true`, prints only prefix/slug names (no descriptions or grouping)

## Returns
- A `DataFrame` containing only rows where `provenance == "UNCERTAIN"`, sorted alphabetically

## Side effects
- Prints count and summary of uncertain rows
- If `output_path` is provided, writes the filtered DataFrame to CSV

## Example
```julia
# Short list of uncertain prefixes
list_uncertain(prefix_df; short=true)

# Full details
list_uncertain(prefix_df)

# Save to file
list_uncertain(slug_df; output_path="./data/uncertain_slugs.csv")
```
"""
function list_uncertain(df::DataFrame; output_path::Union{String, Nothing}=nothing, short::Bool=false)
    if !(:provenance in propertynames(df))
        error("DataFrame must have a `provenance` column. Run classification first.")
    end
    
    uncertain = filter(row -> row.provenance == "UNCERTAIN", df)
    
    println(">>> Uncertain: $(nrow(uncertain)) / $(nrow(df))")
    
    if nrow(uncertain) == 0
        println("    None found.")
        return uncertain
    end
    
    # Determine if this is prefix or slug data based on columns
    is_prefix = :datasource in propertynames(df)
    is_slug = :slug in propertynames(df) && !is_prefix
    
    if short
        # Short list: just names
        if is_prefix
            for row in eachrow(uncertain)
                println("    $(row.prefix)")
            end
        elseif is_slug
            for row in eachrow(uncertain)
                println("    $(row.slug)")
            end
        else
            for row in eachrow(uncertain)
                println("    $(first(values(row)))")
            end
        end
    else
        # Full details
        if is_prefix
            println("    Uncertain prefixes:")
            for row in eachrow(uncertain)
                println("      - $(row.prefix): $(row.datasource)")
                if !isempty(row.description)
                    desc_preview = length(row.description) > 80 ? row.description[1:80] * "..." : row.description
                    println("        Description: $desc_preview")
                end
            end
        elseif is_slug
            # Group by prefix for cleaner output
            by_prefix = Dict{String, Vector{String}}()
            for row in eachrow(uncertain)
                prefix = row.prefix
                if !haskey(by_prefix, prefix)
                    by_prefix[prefix] = String[]
                end
                push!(by_prefix[prefix], row.slug)
            end
            
            println("    Uncertain slugs by prefix:")
            for (prefix, slugs) in sort(collect(by_prefix), by=x->x[1])
                println("      [$prefix] ($(length(slugs)) slugs):")
                for slug in slugs[1:min(5, length(slugs))]
                    println("        - $slug")
                end
                if length(slugs) > 5
                    println("        ... and $(length(slugs) - 5) more")
                end
            end
        else
            println("    First 10 uncertain rows:")
            for (i, row) in enumerate(eachrow(uncertain))
                i > 10 && break
                println("      $i. $(first(values(row)))")
            end
        end
    end
    
    # Save to CSV if path provided
    if output_path !== nothing
        CSV.write(output_path, uncertain)
        println(">>> Saved to: $output_path")
    end
    
    return uncertain
end


"""
    list_uncertain_summary(prefix_df::DataFrame, slug_df::DataFrame) -> Nothing

Prints a comprehensive summary of all uncertain classifications across both prefix and slug DataFrames.

## Arguments
- `prefix_df` — DataFrame from `extract_qog_prefix`
- `slug_df` — DataFrame from `extract_qog_slugs`

## Side effects
- Prints detailed summary to stdout
"""
function list_uncertain_summary(prefix_df::DataFrame, slug_df::DataFrame)
    println("=" ^ 60)
    println("UNCERTAIN CLASSIFICATION SUMMARY")
    println("=" ^ 60)
    
    # Prefix summary
    uncertain_prefixes = filter(row -> row.provenance == "UNCERTAIN", prefix_df)
    println("\n>>> PREFIXES: $(nrow(uncertain_prefixes)) / $(nrow(prefix_df)) uncertain")
    
    if nrow(uncertain_prefixes) > 0
        for row in eachrow(uncertain_prefixes)
            println("    $(row.prefix) — $(row.datasource)")
        end
    end
    
    # Slug summary
    uncertain_slugs = filter(row -> row.provenance == "UNCERTAIN", slug_df)
    println("\n>>> SLUGS: $(nrow(uncertain_slugs)) / $(nrow(slug_df)) uncertain")
    
    if nrow(uncertain_slugs) > 0
        # Group by prefix
        by_prefix = Dict{String, Int}()
        for row in eachrow(uncertain_slugs)
            by_prefix[row.prefix] = get(by_prefix, row.prefix, 0) + 1
        end
        
        println("    By prefix:")
        for (prefix, count) in sort(collect(by_prefix), by=x->x[2], rev=true)
            # Check if prefix itself is uncertain
            prefix_status = if prefix in uncertain_prefixes.prefix
                " (prefix also UNCERTAIN)"
            else
                ""
            end
            println("      $prefix: $count slugs$prefix_status")
        end
    end
    
    # Overall stats
    total_uncertain = nrow(uncertain_prefixes) + nrow(uncertain_slugs)
    total_rows = nrow(prefix_df) + nrow(slug_df)
    pct = round(100 * total_uncertain / total_rows, digits=1)
    
    println("\n>>> TOTAL: $total_uncertain / $total_rows ($pct%) require manual review")
    println("=" ^ 60)
    
    return nothing
end

# Execution
# extract_qog_prefix("./data/codebook_std_jan25.pdf", "./data/qog_prefixes.csv", verbose=true)

# ----------------------------------------------------------------------
# NOTE:
# Avoid top-level execution in this file. In Jupyter/Revise, it can trigger
# Julia 1.12 world-age warnings/errors. Call functions from a notebook cell.
# ----------------------------------------------------------------------

# df = extract_qog_prefix("./data/codebook_std_jan25.pdf", "./data/qog_prefixes.csv")
# df = extract_qog_slugs("./data/codebook_std_jan25.pdf", "./data/qog_slugs.csv")



# Optional: enable via env var when running non-notebook scripts
if get(ENV, "RUN_EXTRACT_QOG", "0") == "1"
    extract_qog_prefix("./data/codebook_std_jan25.pdf", "./data/qog_prefixes.csv")
    extract_qog_slugs("./data/codebook_std_jan25.pdf", "./data/qog_slugs.csv")
    # Step 1: Extract prefixes (classifies at datasource level)
    prefix_df = extract_qog_prefix("./data/codebook_std_jan25.pdf", "./data/qog_prefixes.csv")

    # Step 2: Extract slugs (classifies at slug level, falls back to prefix)
    slug_df = extract_qog_slugs("./data/codebook_std_jan25.pdf", "./data/qog_slugs.csv"; 
                                prefix_df=prefix_df)
end

"""
    list_disagreements(slug_df::DataFrame, prefix_df::DataFrame; 
                       output_path::Union{String, Nothing}=nothing,
                       short::Bool=false) -> DataFrame

Returns slugs whose provenance classification disagrees with their prefix's classification.

## Arguments
- `slug_df` — DataFrame from `extract_qog_slugs` with `slug`, `prefix`, `provenance` columns
- `prefix_df` — DataFrame from `extract_qog_prefix` with `prefix`, `provenance` columns
- `output_path` — (Optional) Path to save disagreements as CSV
- `short` — If `true`, prints only slug names (no grouping or details)

## Returns
- A `DataFrame` containing slugs where `slug.provenance != prefix.provenance`,
  with an additional `prefix_provenance` column for comparison

## Example
```julia
disagreements = list_disagreements(slug_df, prefix_df)
list_disagreements(slug_df, prefix_df; short=true)
list_disagreements(slug_df, prefix_df; output_path="./data/disagreements.csv")
```
"""
function list_disagreements(slug_df::DataFrame, prefix_df::DataFrame; 
                            output_path::Union{String, Nothing}=nothing,
                            short::Bool=false)
    # Validate columns
    if !(:provenance in propertynames(slug_df)) || !(:prefix in propertynames(slug_df))
        error("slug_df must have `prefix` and `provenance` columns.")
    end
    if !(:provenance in propertynames(prefix_df)) || !(:prefix in propertynames(prefix_df))
        error("prefix_df must have `prefix` and `provenance` columns.")
    end
    
    # Build prefix -> provenance lookup
    prefix_prov = Dict{String, String}()
    for row in eachrow(prefix_df)
        prefix_prov[lowercase(row.prefix)] = row.provenance
    end
    
    # Find disagreements
    disagreements = DataFrame(
        slug = String[],
        prefix = String[],
        slug_provenance = String[],
        prefix_provenance = String[],
        description = String[]
    )
    
    for row in eachrow(slug_df)
        prefix = lowercase(row.prefix)
        slug_prov = row.provenance
        pref_prov = get(prefix_prov, prefix, "UNKNOWN")
        
        # Skip if either is UNCERTAIN or UNKNOWN (not a true disagreement)
        if slug_prov in ("UNCERTAIN", "UNKNOWN") || pref_prov in ("UNCERTAIN", "UNKNOWN")
            continue
        end
        
        if slug_prov != pref_prov
            push!(disagreements, (
                row.slug,
                row.prefix,
                slug_prov,
                pref_prov,
                get(row, :description, "")
            ))
        end
    end
    
    # Sort by prefix, then slug
    sort!(disagreements, [:prefix, :slug])
    
    # Print summary
    println(">>> Disagreements: $(nrow(disagreements)) / $(nrow(slug_df)) slugs")
    
    if nrow(disagreements) == 0
        println("    None found. All slug classifications agree with their prefix.")
        return disagreements
    end
    
    if short
        for row in eachrow(disagreements)
            println("    $(row.slug)")
        end
    else
        # Group by prefix
        by_prefix = Dict{String, Vector{NamedTuple}}()
        for row in eachrow(disagreements)
            prefix = row.prefix
            if !haskey(by_prefix, prefix)
                by_prefix[prefix] = []
            end
            push!(by_prefix[prefix], (
                slug = row.slug,
                slug_prov = row.slug_provenance,
                pref_prov = row.prefix_provenance,
                desc = row.description
            ))
        end
        
        println("    By prefix:")
        for (prefix, slugs) in sort(collect(by_prefix), by=x->x[1])
            pref_prov = slugs[1].pref_prov
            println("\n      [$prefix] (prefix=$pref_prov, $(length(slugs)) disagreements):")
            for s in slugs[1:min(10, length(slugs))]
                println("        - $(s.slug) → $(s.slug_prov)")
                if !isempty(s.desc)
                    desc_preview = length(s.desc) > 60 ? s.desc[1:60] * "..." : s.desc
                    println("          \"$desc_preview\"")
                end
            end
            if length(slugs) > 10
                println("        ... and $(length(slugs) - 10) more")
            end
        end
        
        # Summary stats
        println("\n    Summary by classification shift:")
        shifts = countmap(["$(r.prefix_provenance) → $(r.slug_provenance)" for r in eachrow(disagreements)])
        for (shift, count) in sort(collect(shifts), by=x->x[2], rev=true)
            println("      $shift: $count")
        end
    end
    
    # Save to CSV if path provided
    if output_path !== nothing
        CSV.write(output_path, disagreements)
        println(">>> Saved to: $output_path")
    end
    
    return disagreements
end