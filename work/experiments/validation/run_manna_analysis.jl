# ==============================================================================
# EXPERIMENT 01.02 — MANNA ANALYSIS (headless pre-compute)
# ==============================================================================
#
# Thin wrapper: loads the validation module, then calls run_manna_analysis()
# with defaults. Pre-computes all power-law fits, ensemble statistics, and
# extrapolations (including bracketed-xmin FSS and fractal dimensions) from
# the per-seed Arrow files written by run_manna_ensemble.
#
# Outputs Arrow files under data/exp01_02/analysis/ that the notebook's
# Section 2b + Section 12 fast-path load in seconds.
#
# Intended to run in the headless Julia container, NOT in Jupyter.
#
# Example invocations (from inside the Julia container):
#   julia --project experiments/validation/run_manna_analysis.jl
#
#   # Custom data dir (for smoke tests):
#   julia --project -e '
#       include("experiments/validation/load_validation.jl")
#       run_manna_analysis(data_dir="data/exp01_02_test",
#                          L_values=[64])'
#
# See WORKFLOW.md for the full three-phase workflow.
# ==============================================================================

include(joinpath(@__DIR__, "load_validation.jl"))

run_manna_analysis()
