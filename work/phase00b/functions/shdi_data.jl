# ==============================================================================
# PHASE 0b — SHDI SUBNATIONAL HUMAN DEVELOPMENT PREPROCESSING
# ==============================================================================
#
# Loads and preprocesses the Global Data Lab SHDI (Subnational Human Development
# Index) into Arrow format. Provides subnational HDI data for testing Signatures
# 3 (scale invariance) and 4 (fractal structure). Secondary confirmation layer.
#
# Data source:
#   - SHDI V10.0 (Global Data Lab / Smits & Permanyer)
#     https://globaldatalab.org/shdi/
#     File: Subnational HDI Data v10.0.csv
#     65,031 rows, 188 countries, 1,993 regions, 1990–2023
#     Includes gender-disaggregated indicators
#
# Output:
#   - data/shdi_v10.arrow (full dataset: national + subnational rows)
#
# ==============================================================================

using DataFrames
using CSV
using Arrow


# ==============================================================================
# CONSTANTS
# ==============================================================================

"""Path to SHDI CSV file."""
const PATH_SHDI_CSV = "data/Subnational HDI Data v10.0.csv"

"""Path to output Arrow file."""
const PATH_SHDI_ARROW = "data/shdi_v10.arrow"

"""ISO3 remapping for SHDI (same legacy codes as CEPII)."""
const SHDI_ISO3_REMAP = Dict(
    "ROM" => "ROU",  # Romania
    "ZAR" => "COD",  # DR Congo
    "TMP" => "TLS",  # Timor-Leste
)


# ==============================================================================
# LOADING
# ==============================================================================

"""
Load SHDI data from CSV, apply ISO3 remapping and temporal floor.

Returns
    DataFrame with national + subnational HDI panel.

Rules
    - Reads from PATH_SHDI_CSV
    - Applies SHDI_ISO3_REMAP to isocode3
    - Applies TEMPORAL_FLOOR (from constants.jl)
    - Preserves both National and Subnat level rows
    - Does not modify source file

Usage
    df = shdi_load()
"""
function shdi_load()
    raw = CSV.read(PATH_SHDI_CSV, DataFrame)

    # ISO3 remapping
    raw[!, :isocode3] = [get(SHDI_ISO3_REMAP, String(v), String(v)) for v in raw.isocode3]

    # Temporal floor
    filter!(r -> r.year >= TEMPORAL_FLOOR, raw)

    # Drop datasource column (100% empty)
    select!(raw, Not(:datasource))

    return raw
end


"""
Extract subnational rows only.

Arguments
    shdi::DataFrame — output of shdi_load()

Returns
    DataFrame with subnational rows only (level == "Subnat").

Usage
    all = shdi_load()
    sub = shdi_subnational(all)
"""
function shdi_subnational(shdi::DataFrame)
    return filter(r -> r.level == "Subnat", shdi)
end


"""
Extract national rows only.

Arguments
    shdi::DataFrame — output of shdi_load()

Returns
    DataFrame with national rows only (level == "National").

Usage
    all = shdi_load()
    nat = shdi_national(all)
"""
function shdi_national(shdi::DataFrame)
    return filter(r -> r.level == "National", shdi)
end


# ==============================================================================
# ARROW EXPORT
# ==============================================================================

"""
Full pipeline: load SHDI, write Arrow.

Returns
    DataFrame (full dataset)

Rules
    - Writes to PATH_SHDI_ARROW
    - Does not modify source file

Usage
    shdi = shdi_process_all()
"""
function shdi_process_all()
    println("Loading SHDI from $(PATH_SHDI_CSV)...")
    shdi = shdi_load()
    n_nat = count(x -> x == "National", shdi.level)
    n_sub = count(x -> x == "Subnat", shdi.level)
    println("  $(nrow(shdi)) rows ($n_nat national, $n_sub subnational)")
    println("  Years: $(minimum(shdi.year)) – $(maximum(shdi.year))")
    println("  Countries: $(length(unique(shdi.isocode3)))")
    println("  Regions: $(length(unique(shdi.gdlcode)))")

    # String conversion for Arrow
    for col in names(shdi)
        if nonmissingtype(eltype(shdi[!, col])) <: AbstractString
            shdi[!, col] = passmissing(String).(shdi[!, col])
        end
    end

    println("Writing Arrow...")
    Arrow.write(PATH_SHDI_ARROW, shdi)
    println("  → $(PATH_SHDI_ARROW)  ($(round(filesize(PATH_SHDI_ARROW) / 1024^2, digits=1)) MB)")

    return shdi
end
