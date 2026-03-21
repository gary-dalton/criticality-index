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

data_available = has_data()

println("=" ^ 70)
println("  CRITICALITY INDEX — TEST SUITE")
println("=" ^ 70)
println("  Working directory: $(pwd())")
println("  Data available:    $data_available")
println("=" ^ 70)

# --- Load Phase 0 modules via single loader ---
println("\n>>> Loading Phase 0 modules...")
include(joinpath(PHASE0_FUNCTIONS, "load_phase0.jl"))
if !data_available
    println("    ⚠️  Data-dependent modules skipped (no data files)")
    println("       enrich_metadata, cluster_analysis, xcluster_analysis tests will be skipped")
else
    println("    ✓ All Phase 0 modules loaded (including data-dependent)")
end

println("\n>>> Running tests...\n")

@testset "Criticality Index" begin

    @testset "Phase 0: Preprocessing" begin
        include(joinpath(@__DIR__, "phase0", "test_augmented_standard.jl"))
        include(joinpath(@__DIR__, "phase0", "test_pdf_extract.jl"))
        include(joinpath(@__DIR__, "phase0", "test_metadata_join.jl"))
        include(joinpath(@__DIR__, "phase0", "test_grounding.jl"))
        include(joinpath(@__DIR__, "phase0", "test_order.jl"))

        if data_available
            include(joinpath(@__DIR__, "phase0", "test_enrich_metadata.jl"))
        else
            @testset "enrich_metadata (SKIPPED — no data)" begin
                @test_skip true
            end
        end
    end

    # Future phases:
    # @testset "Phase 1: Model Definition" begin ... end
    # @testset "Phase 2: Variable Mapping" begin ... end

end
