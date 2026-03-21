# ==============================================================================
# CRITICALITY INDEX — TEST RUNNER
# ==============================================================================
#
# Usage (from project root):
#   cd ~/projects/criticality-index
#   julia test/runtests.jl
#
# Or from work/ directory:
#   cd ~/projects/criticality-index/work
#   julia ../test/runtests.jl
#
# ==============================================================================

using Test

include(joinpath(@__DIR__, "test_helpers.jl"))

# --- Ensure we're in work/ directory (required for module includes) ---
if !isdir("data") && isdir(WORK_DIR)
    cd(WORK_DIR)
end

println("=" ^ 70)
println("  CRITICALITY INDEX — TEST SUITE")
println("=" ^ 70)
println("  Working directory: $(pwd())")
println("  Data available:    $(has_data())")
println("=" ^ 70)

# --- Load Phase 0 modules (order matters: augmented_standard first) ---
println("\n>>> Loading Phase 0 modules...")
include(joinpath(PHASE0_FUNCTIONS, "qog_augmented_standard.jl"))
include(joinpath(PHASE0_FUNCTIONS, "qog_pdf_extract.jl"))
include(joinpath(PHASE0_FUNCTIONS, "qog_metadata_join.jl"))
include(joinpath(PHASE0_FUNCTIONS, "grounding.jl"))
include(joinpath(PHASE0_FUNCTIONS, "order.jl"))
println("    ✓ Modules loaded")

# Note: enrich_metadata.jl includes qog_augmented_standard.jl internally,
# but since it's already loaded, Julia will skip the re-include.
# We load classify_temporal_profile and classify_geographic_profile
# by including enrich_metadata.jl only if the functions aren't defined yet.
if !isdefined(Main, :classify_temporal_profile)
    include(joinpath(PHASE0_FUNCTIONS, "enrich_metadata.jl"))
    println("    ✓ enrich_metadata loaded separately")
end

println("\n>>> Running tests...\n")

@testset "Criticality Index" begin

    @testset "Phase 0: Preprocessing" begin
        include(joinpath(@__DIR__, "phase0", "test_augmented_standard.jl"))
        include(joinpath(@__DIR__, "phase0", "test_pdf_extract.jl"))
        include(joinpath(@__DIR__, "phase0", "test_metadata_join.jl"))
        include(joinpath(@__DIR__, "phase0", "test_enrich_metadata.jl"))
        include(joinpath(@__DIR__, "phase0", "test_grounding.jl"))
        include(joinpath(@__DIR__, "phase0", "test_order.jl"))
    end

    # Future phases:
    # @testset "Phase 1: Model Definition" begin ... end
    # @testset "Phase 2: Variable Mapping" begin ... end

end
