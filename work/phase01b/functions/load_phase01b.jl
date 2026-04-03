# ==============================================================================
# PHASE 1b — MODULE LOADER
# ==============================================================================
#
# Entry point for Phase 1b (structural integration) functions.
#
# Usage (from work/ directory):
#   include("phase01b/functions/load_phase01b.jl")
#
# ==============================================================================

const _PHASE01B_DIR = @__DIR__

# Load project-wide constants
if !isdefined(Main, :TEMPORAL_FLOOR)
    include(joinpath(_PHASE01B_DIR, "..", "..", "constants.jl"))
end

"""
Load Phase 1b modules.

Arguments
    modules::Vector{Symbol} — specific modules to load (default: all active)

Available modules:
  :country_master
  :coverage_matrix
"""
function include_phase01b(modules::Vector{Symbol} = Symbol[])
    all_modules = [
        :country_master  => "country_master.jl",
        :coverage_matrix => "coverage_matrix.jl",
    ]

    load_all = isempty(modules)

    for (mod_sym, filename) in all_modules
        if load_all || mod_sym in modules
            include(joinpath(_PHASE01B_DIR, filename))
        end
    end
end

# Auto-load all active modules
include_phase01b()
