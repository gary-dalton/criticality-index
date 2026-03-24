# ==============================================================================
# PHASE 2 — MODULE LOADER
# ==============================================================================
#
# Single entry point for all Phase 2 functions. Loads Phase 0 and Phase 1
# first (since Phase 2 depends on prior infrastructure).
#
# Usage (from work/ directory):
#   include("phase2/functions/load_phase2.jl")
#
# With Revise (notebooks):
#   using Revise
#   includet("phase2/functions/load_phase2.jl")
#
# ==============================================================================

const _PHASE2_DIR = @__DIR__

# Load Phase 1 first (which loads Phase 0)
if !isdefined(Main, :include_phase1)
    include(joinpath(dirname(_PHASE2_DIR), "..", "phase1", "functions", "load_phase1.jl"))
end

"""
Load all Phase 2 modules in dependency order.

Arguments:
- modules::Vector{Symbol}: Specific modules to load (default: all)

Available modules:
  :network_data
"""
function include_phase2(modules::Vector{Symbol} = Symbol[])
    all_modules = [
        :network_data => "network_data.jl",
    ]

    load_all = isempty(modules)

    for (mod_sym, filename) in all_modules
        if load_all || mod_sym in modules
            include(joinpath(_PHASE2_DIR, filename))
        end
    end
end

# Auto-load all modules when this file is included
include_phase2()
