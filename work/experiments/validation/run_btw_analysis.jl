# ==============================================================================
# EXPERIMENT 01.01 — HEADLESS ANALYSIS RUNNER
# ==============================================================================
#
# Thin wrapper: loads the validation module, then calls run_btw_analysis
# with defaults. Intended to run in the headless Julia container after
# run_btw_ensemble has completed.
#
# Example invocation (from inside the Julia container):
#   julia --project experiments/validation/run_btw_analysis.jl
#
# For custom parameters, call run_btw_analysis directly with kwargs.
# ==============================================================================

include(joinpath(@__DIR__, "load_validation.jl"))

run_btw_analysis()
