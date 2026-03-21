# ==============================================================================
# PHASE 0 — MODULE LOADER
# ==============================================================================
#
# Single entry point for all Phase 0 functions. Ensures each module is loaded
# exactly once in the correct dependency order.
#
# Usage (from work/ directory):
#   include("phase0/functions/load_phase0.jl")
#
# With Revise (notebooks):
#   using Revise
#   includet("phase0/functions/load_phase0.jl")
#
# Selective loading (pass modules kwarg):
#   include_phase0([:augmented_standard, :metadata_join])
#
# ==============================================================================

const _PHASE0_DIR = @__DIR__

# Modules that call load_dataframes() or load_qog_timeseries() at module level
# and therefore require data files to be present.
const _DATA_DEPENDENT_MODULES = Set([:enrich_metadata, :cluster_analysis, :xcluster_analysis])

"""
Load all Phase 0 modules in dependency order.

Arguments:
- modules::Vector{Symbol}: Specific modules to load (default: all)
- skip_data_dependent::Bool: Skip modules that require data files (default: false)

Available modules (in load order):
  :augmented_standard, :pdf_extract, :metadata_join,
  :enrich_metadata, :cluster_analysis, :xcluster_analysis,
  :grounding, :order
"""
function include_phase0(modules::Vector{Symbol} = Symbol[]; skip_data_dependent::Bool = false)
    all_modules = [
        # --- Layer 1: Foundation (no internal dependencies) ---
        :augmented_standard  => "qog_augmented_standard.jl",
        :pdf_extract         => "qog_pdf_extract.jl",
        :grounding           => "grounding.jl",
        :order               => "order.jl",
        # --- Layer 2: Depends on augmented_standard ---
        :metadata_join       => "qog_metadata_join.jl",
        :enrich_metadata     => "enrich_metadata.jl",
        :cluster_analysis    => "cluster_analysis.jl",
        :xcluster_analysis   => "xcluster_analysis.jl",
    ]

    load_all = isempty(modules)

    for (mod_sym, filename) in all_modules
        if load_all || mod_sym in modules
            if skip_data_dependent && mod_sym in _DATA_DEPENDENT_MODULES
                println("    ⚠️  Skipping $filename (requires data files)")
                continue
            end
            include(joinpath(_PHASE0_DIR, filename))
        end
    end
end

# Auto-load all modules when this file is included.
# Skip data-dependent modules if data files aren't present.
_data_available = isfile(joinpath(pwd(), "data", "qog_std_ts_jan25.arrow"))
include_phase0(; skip_data_dependent = !_data_available)
