# ==============================================================================
# PHASE 0b — LAEVEN & VALENCIA SYSTEMIC CRISIS DATABASE PREPROCESSING
# ==============================================================================
#
# Loads and preprocesses the IMF Systemic Banking Crises Database into Arrow
# format. Provides discrete crisis event markers for backtesting — when the
# model identifies a country moving toward super-critical, do crisis dates align?
#
# Data source:
#   - Laeven & Valencia (2018), "Systemic Banking Crises Revisited"
#     IMF Working Paper WP/18/206
#     File: wp18206.zip → SYSTEMIC BANKING CRISES DATABASE_2018.xlsx
#     Coverage: 1970–2017, ~190 countries, 152 banking crisis episodes
#
# Output:
#   - data/lv_crisis_panel.arrow   (country-year panel, one row per crisis-active year)
#   - data/lv_outcomes.arrow       (crisis episode outcomes — fiscal costs, output losses)
#
# ==============================================================================

using DataFrames
using XLSX
using Arrow
using ZipFile


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Path to Laeven & Valencia zip archive."""
const PATH_LV_ZIP = "data/wp18206.zip"

"""Arrow output: country-year crisis panel."""
const PATH_LV_CRISIS_PANEL_ARROW = "data/lv_crisis_panel.arrow"

"""Arrow output: crisis episode outcomes."""
const PATH_LV_OUTCOMES_ARROW = "data/lv_outcomes.arrow"

"""Country name → ISO3 mapping for names that don't match QoG directly."""
const LV_NAME_TO_ISO3 = Dict(
    "Bolivia" => "BOL",
    "Cape Verde" => "CPV",
    "Central African Rep" => "CAF",
    "China, Mainland" => "CHN",
    "Congo, Dem Rep" => "COD",
    "Congo, Rep" => "COG",
    "Cote d'Ivoire" => "CIV",
    "Czech Republic" => "CZE",
    "Dominican Rep" => "DOM",
    "Korea" => "KOR",
    "Kyrgyz Rep" => "KGZ",
    "Macedonia, FYR" => "MKD",
    "Moldova" => "MDA",
    "Netherlands" => "NLD",
    "Niger" => "NER",
    "Philippines" => "PHL",
    "Russia" => "RUS",
    "Slovak Rep" => "SVK",
    "Swaziland" => "SWZ",
    "São Tomé & Príncipe" => "STP",
    "Tanzania" => "TZA",
    "United Kingdom" => "GBR",
    "United States" => "USA",
    "Venezuela" => "VEN",
    "Vietnam" => "VNM",
)


# ==============================================================================
# HELPERS
# ==============================================================================

"""
Extract the Excel file from the zip to a temp location for XLSX.jl.

Returns
    String — path to extracted temporary file

Usage
    tmp = lv_extract_xlsx()
    # ... use tmp ...
    rm(tmp)
"""
function lv_extract_xlsx()
    zf = ZipFile.Reader(PATH_LV_ZIP)
    entry = first(filter(f -> endswith(f.name, ".xlsx"), zf.files))
    tmp = tempname() * ".xlsx"
    open(tmp, "w") do io
        write(io, read(entry))
    end
    close(zf)
    return tmp
end


"""
Parse crisis year values — handles Int, String with comma-separated years, and missing.

Arguments
    val — a cell value from the crisis years sheet

Returns
    Vector{Int} of parsed years

Usage
    parse_years(1997)           # [1997]
    parse_years("1997, 2008")   # [1997, 2008]
    parse_years(missing)        # Int[]
"""
function lv_parse_years(val)
    ismissing(val) && return Int[]
    if val isa Number
        return [Int(val)]
    end
    s = string(val)
    years = Int[]
    for part in split(s, ",")
        p = strip(part)
        y = tryparse(Int, p)
        !isnothing(y) && push!(years, y)
    end
    return years
end


"""
Clean a numeric column — convert "...", "…", and unparseable strings to missing.

Arguments
    df::DataFrame — the DataFrame to modify
    col::Symbol — column to clean

Returns
    DataFrame (modified in place)
"""
function lv_clean_numeric!(df::DataFrame, col::Symbol)
    df[!, col] = map(df[!, col]) do v
        ismissing(v) && return missing
        v isa Number && return Float64(v)
        s = strip(string(v))
        (s == "..." || s == "…" || s == "") && return missing
        y = tryparse(Float64, s)
        return y
    end
    df[!, col] = [isnothing(v) ? missing : v for v in df[!, col]]
    return df
end


"""
Build country name → ISO3 mapping using QoG augmented dataset + manual overrides.

Returns
    Dict{String, String} mapping cleaned country names to ISO3 codes
"""
function lv_build_name_mapping()
    qog = DataFrame(Arrow.Table("data/qog_std_ts_jan25_aug.arrow"))
    qog_names = unique(select(dropmissing(qog, [:ident_cname, :ident_ccodealp]),
                              :ident_cname, :ident_ccodealp))

    name_to_iso3 = Dict{String, String}()

    # QoG exact matches
    for r in eachrow(qog_names)
        name_to_iso3[r.ident_cname] = r.ident_ccodealp
    end

    # Manual overrides
    merge!(name_to_iso3, LV_NAME_TO_ISO3)

    return name_to_iso3
end


# ==============================================================================
# LOADING
# ==============================================================================

"""
Load and expand crisis years into a country-year panel.

Reads the "Crisis Years" sheet (wide format with comma-separated years),
then loads the "Crisis Resolution and Outcomes" sheet to get start/end dates
for each episode. Expands into one row per crisis-active year.

Returns
    DataFrame with columns: country, year, crisis_start, crisis_end, iso3

Rules
    - Uses outcomes sheet for start/end dates (more precise than crisis years)
    - One row per year a banking crisis was active [start, end]
    - Country names stripped of footnote annotations
    - ISO3 mapped via QoG + manual overrides

Usage
    panel = lv_load_crisis_panel()
"""
function lv_load_crisis_panel()
    tmp = lv_extract_xlsx()
    outcomes_raw = DataFrame(XLSX.readtable(tmp, "Crisis Resolution and Outcomes"))
    rm(tmp)

    # Rename
    rename!(outcomes_raw,
        names(outcomes_raw)[1] => :country,
        names(outcomes_raw)[2] => :start_year,
        names(outcomes_raw)[3] => :end_year,
    )

    # Drop footnotes row
    filter!(r -> !ismissing(r.start_year) && r.start_year isa Number, outcomes_raw)

    # Clean country names — strip footnote annotations ("Argentina 8/" → "Argentina")
    outcomes_raw[!, :country] = [replace(strip(string(v)), r"\s*\d+/\s*$" => "")
                                  for v in outcomes_raw.country]

    # Clean end_year — strip footnote annotations, parse to Int
    outcomes_raw[!, :end_year_clean] = map(outcomes_raw.end_year) do v
        ismissing(v) && return nothing
        s = replace(strip(string(v)), r"\s*\d+/\s*$" => "")
        return tryparse(Int, s)
    end

    # Build name mapping
    name_to_iso3 = lv_build_name_mapping()

    # Expand to country-year panel
    rows = NamedTuple[]
    for r in eachrow(outcomes_raw)
        end_yr = r.end_year_clean
        if isnothing(end_yr) || ismissing(end_yr)
            end_yr = Int(r.start_year)
        end
        iso3 = get(name_to_iso3, r.country, missing)
        for yr in Int(r.start_year):end_yr
            push!(rows, (
                country = r.country,
                year = yr,
                crisis_start = Int(r.start_year),
                crisis_end = end_yr,
                iso3 = iso3
            ))
        end
    end

    return DataFrame(rows)
end


"""
Load and clean crisis outcomes (fiscal costs, output losses, etc.).

Returns
    DataFrame with one row per crisis episode, numeric columns cleaned.

Rules
    - "..." and "…" converted to missing
    - Footnote annotations stripped from country names and end_year
    - ISO3 mapped via QoG + manual overrides

Usage
    outcomes = lv_load_outcomes()
"""
function lv_load_outcomes()
    tmp = lv_extract_xlsx()
    raw = DataFrame(XLSX.readtable(tmp, "Crisis Resolution and Outcomes"))
    rm(tmp)

    rename!(raw,
        names(raw)[1]  => :country,
        names(raw)[2]  => :start_year,
        names(raw)[3]  => :end_year,
        names(raw)[4]  => :output_loss_pct,
        names(raw)[5]  => :fiscal_cost_pct_gdp,
        names(raw)[6]  => :fiscal_cost_net_pct_gdp,
        names(raw)[7]  => :fiscal_cost_pct_fin_assets,
        names(raw)[8]  => :peak_liquidity_pct,
        names(raw)[9]  => :liquidity_support_pct,
        names(raw)[10] => :peak_npls_pct,
        names(raw)[11] => :public_debt_increase_pct,
    )

    # Drop footnotes row
    filter!(r -> !ismissing(r.start_year) && r.start_year isa Number, raw)

    # Clean country names
    raw[!, :country] = [replace(strip(string(v)), r"\s*\d+/\s*$" => "") for v in raw.country]

    # Clean end_year
    raw[!, :end_year] = map(raw.end_year) do v
        ismissing(v) && return missing
        s = replace(strip(string(v)), r"\s*\d+/\s*$" => "")
        y = tryparse(Int, s)
        return isnothing(y) ? missing : y
    end

    # Clean numeric outcome columns
    for col in [:output_loss_pct, :fiscal_cost_pct_gdp, :fiscal_cost_net_pct_gdp,
                :fiscal_cost_pct_fin_assets, :peak_liquidity_pct, :liquidity_support_pct,
                :peak_npls_pct, :public_debt_increase_pct]
        lv_clean_numeric!(raw, col)
    end

    # Add ISO3
    name_to_iso3 = lv_build_name_mapping()
    raw[!, :iso3] = [get(name_to_iso3, c, missing) for c in raw.country]

    # Reorder columns
    select!(raw, :iso3, :country, :start_year, :end_year,
            :output_loss_pct, :fiscal_cost_pct_gdp, :fiscal_cost_net_pct_gdp,
            :fiscal_cost_pct_fin_assets, :peak_liquidity_pct, :liquidity_support_pct,
            :peak_npls_pct, :public_debt_increase_pct)

    return raw
end


# ==============================================================================
# ARROW EXPORT
# ==============================================================================

"""
Full pipeline: load crisis panel + outcomes, write Arrow.

Returns
    NamedTuple (panel::DataFrame, outcomes::DataFrame)

Rules
    - Writes to PATH_LV_CRISIS_PANEL_ARROW and PATH_LV_OUTCOMES_ARROW
    - Does not modify source file

Usage
    result = lv_process_all()
    result.panel     # country-year crisis flags
    result.outcomes  # episode-level outcomes
"""
function lv_process_all()
    println("Loading Laeven & Valencia from $(PATH_LV_ZIP)...")

    panel = lv_load_crisis_panel()
    println("  Crisis panel: $(nrow(panel)) country-year rows, $(length(unique(panel.country))) countries")

    outcomes = lv_load_outcomes()
    println("  Outcomes: $(nrow(outcomes)) crisis episodes")

    # String conversion for Arrow
    for df in [panel, outcomes]
        for col in names(df)
            if nonmissingtype(eltype(df[!, col])) <: AbstractString
                df[!, col] = passmissing(String).(df[!, col])
            end
        end
    end

    println("Writing Arrow...")
    Arrow.write(PATH_LV_CRISIS_PANEL_ARROW, panel)
    println("  → $(PATH_LV_CRISIS_PANEL_ARROW)")
    Arrow.write(PATH_LV_OUTCOMES_ARROW, outcomes)
    println("  → $(PATH_LV_OUTCOMES_ARROW)")

    return (panel=panel, outcomes=outcomes)
end
