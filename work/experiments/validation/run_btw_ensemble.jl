# ==============================================================================
# EXPERIMENT 01.01 — BTW ENSEMBLE RUNNER (headless)
# ==============================================================================
#
# Thin wrapper: loads the validation module, then calls run_btw_ensemble
# with defaults. Intended to run in the headless Julia container, NOT in
# Jupyter. For custom parameters, call run_btw_ensemble directly with
# kwargs rather than editing this file.
#
# Example invocations (from inside the Julia container):
#   julia --project experiments/validation/run_btw_ensemble.jl
#
#   # smoke test (custom parameters):
#   julia --project -e '
#       include("experiments/validation/load_validation.jl")
#       run_btw_ensemble(L_seeds=Dict(64=>3), n_record=10_000,
#                        out_dir="data/exp01_01_test")'
#
# See WORKFLOW.md for the full three-phase workflow.
# ==============================================================================

include(joinpath(@__DIR__, "load_validation.jl"))

run_btw_ensemble()
