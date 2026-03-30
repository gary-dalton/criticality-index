# ==============================================================================
# PHASE 0b — MODULE LOADER
# ==============================================================================
#
# Entry point for Phase 0b (extended preprocessing) functions. Loads external
# data sources acquired after Phase 0 — EM-DAT, DOSE, SHDI, Laeven & Valencia,
# and CEPII network data.
#
# Usage (from work/ directory):
#   include("phase00b/functions/load_phase00b.jl")
#
# With Revise (notebooks):
#   using Revise
#   includet("phase00b/functions/load_phase00b.jl")
#
# ==============================================================================

const _PHASE00B_DIR = @__DIR__

# Load project-wide constants
if !isdefined(Main, :TEMPORAL_FLOOR)
    include(joinpath(_PHASE00B_DIR, "..", "..", "constants.jl"))
end

"""
Load Phase 0b modules.

Arguments
    modules::Vector{Symbol} — specific modules to load (default: all active)

Available modules:
  :emdat_data
  :dose_data

Not yet active (pending inspection):
  :network_data
  :subnational_data
"""
function include_phase00b(modules::Vector{Symbol} = Symbol[])
    all_modules = [
        :emdat_data => "emdat_data.jl",
        :dose_data  => "dose_data.jl",
    ]

    load_all = isempty(modules)

    for (mod_sym, filename) in all_modules
        if load_all || mod_sym in modules
            include(joinpath(_PHASE00B_DIR, filename))
        end
    end
end

# Auto-load all active modules
include_phase00b()
