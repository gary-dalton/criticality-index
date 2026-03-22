# ==============================================================================
# PHASE 1 — MODULE LOADER
# ==============================================================================
#
# Single entry point for all Phase 1 functions. Loads Phase 0 first
# (since Phase 1 depends on Phase 0 infrastructure).
#
# Usage (from work/ directory):
#   include("phase1/functions/load_phase1.jl")
#
# With Revise (notebooks):
#   using Revise
#   includet("phase1/functions/load_phase1.jl")
#
# ==============================================================================

const _PHASE1_DIR = @__DIR__

# Load Phase 0 first (if not already loaded)
if !isdefined(Main, :load_qog_timeseries)
    include(joinpath(dirname(_PHASE1_DIR), "..", "phase0", "functions", "load_phase0.jl"))
end

"""
Load all Phase 1 modules in dependency order.

Arguments:
- modules::Vector{Symbol}: Specific modules to load (default: all)

Available modules:
  :slug_clustering
"""
function include_phase1(modules::Vector{Symbol} = Symbol[])
    all_modules = [
        :slug_clustering => "slug_clustering.jl",
    ]

    load_all = isempty(modules)

    for (mod_sym, filename) in all_modules
        if load_all || mod_sym in modules
            include(joinpath(_PHASE1_DIR, filename))
        end
    end
end

# Auto-load all modules when this file is included
include_phase1()
