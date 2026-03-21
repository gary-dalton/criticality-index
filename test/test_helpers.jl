# ==============================================================================
# TEST HELPERS
# ==============================================================================

using Test
using DataFrames

# --- Path Setup ---

const PROJECT_ROOT = dirname(@__DIR__)
const WORK_DIR = joinpath(PROJECT_ROOT, "work")
const DATA_DIR = joinpath(WORK_DIR, "data")
const PHASE0_FUNCTIONS = joinpath(WORK_DIR, "phase0", "functions")

"""
Check if real data files are available for integration tests.
"""
function has_data()
    isfile(joinpath(DATA_DIR, "qog_std_ts_jan25.arrow"))
end

"""
Load a Phase 0 module by name (without .jl extension).
Must be called from the work/ directory context.
"""
function load_phase0_module(name::String)
    path = joinpath(PHASE0_FUNCTIONS, name * ".jl")
    isfile(path) || error("Module not found: $path")
    include(path)
end
