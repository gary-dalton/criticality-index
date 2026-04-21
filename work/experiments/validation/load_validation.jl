# ==============================================================================
# EXPERIMENTS — VALIDATION MODULE LOADER
# ==============================================================================
#
# Entry point for synthetic experiment validation modules.
#
# Usage (from work/ directory):
#   include("experiments/validation/load_validation.jl")
#
# ==============================================================================

const _VALIDATION_DIR = @__DIR__

"""Load validation modules.

Arguments
    modules::Vector{Symbol} — specific modules to load (default: all)

Available modules:
  :sandpile
  :manna_sandpile
  :diagnostics
  :streaming
  :analysis
"""
function include_validation(modules::Vector{Symbol} = Symbol[])
    all_modules = [
        :sandpile       => "sandpile.jl",
        :manna_sandpile => "manna_sandpile.jl",
        :diagnostics    => "diagnostics.jl",
        :streaming      => "streaming.jl",
        :analysis       => "analysis.jl",
    ]

    load_all = isempty(modules)

    for (mod_sym, filename) in all_modules
        if load_all || mod_sym in modules
            include(joinpath(_VALIDATION_DIR, filename))
        end
    end
end

# Auto-load all modules
include_validation()
