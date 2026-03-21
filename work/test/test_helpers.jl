# ==============================================================================
# TEST HELPERS
# ==============================================================================

using Test
using DataFrames

# --- Path Setup ---
# test/ lives under work/, so @__DIR__ = work/test/

const WORK_DIR = dirname(@__DIR__)
const PROJECT_ROOT = dirname(WORK_DIR)
const DATA_DIR = joinpath(WORK_DIR, "data")
const PHASE0_FUNCTIONS = joinpath(WORK_DIR, "phase0", "functions")

"""
Check if real data files are available for integration tests.
"""
function has_data()
    isfile(joinpath(DATA_DIR, "qog_std_ts_jan25.arrow"))
end
