# ==============================================================================
# EXPERIMENT 01.02 — MANNA ENSEMBLE RUNNER (headless)
# ==============================================================================
#
# Thin wrapper: loads the validation module, then calls run_manna_ensemble
# with defaults. Intended to run in the headless Julia container, NOT in
# Jupyter. For custom parameters, call run_manna_ensemble directly with
# kwargs rather than editing this file.
#
# Example invocations (from inside the Julia container):
#   julia --project experiments/validation/run_manna_ensemble.jl
#
#   # smoke test (custom parameters):
#   julia --project -e '
#       include("experiments/validation/load_validation.jl")
#       run_manna_ensemble(L_seeds=Dict(64=>3), n_record=10_000,
#                          out_dir="data/exp01_02_test")'
#
# See WORKFLOW.md for the full three-phase workflow.
# ==============================================================================

include(joinpath(@__DIR__, "load_validation.jl"))

run_manna_ensemble()
