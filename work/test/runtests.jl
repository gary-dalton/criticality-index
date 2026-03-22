# ==============================================================================
# CRITICALITY INDEX — TEST RUNNER
# ==============================================================================
#
# Usage (from project root):
#   cd ~/projects/criticality-index
#   docker compose exec -w /home/jovyan/work jupyter julia test/runtests.jl
#
# From notebook:
#   using Test
#   include("test/runtests.jl")
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

# --- Load modules (suppress verbose output) ---
println("\n>>> Loading Phase 0 modules...")
redirect_stdout(devnull) do
    include(joinpath(PHASE0_FUNCTIONS, "load_phase0.jl"))
end
if !data_available
    println("    ⚠️  Data-dependent modules skipped (no data files)")
else
    println("    ✓ All Phase 0 modules loaded")
end

println(">>> Loading Phase 1 modules...")
redirect_stdout(devnull) do
    include(joinpath(PHASE1_FUNCTIONS, "load_phase1.jl"))
end
println("    ✓ Phase 1 modules loaded")

println("\n>>> Running tests...\n")

@testset verbose=true "Criticality Index" begin

    @testset verbose=true "Phase 0: Preprocessing" begin
        include(joinpath(@__DIR__, "phase0", "test_augmented_standard.jl"))
        include(joinpath(@__DIR__, "phase0", "test_pdf_extract.jl"))
        include(joinpath(@__DIR__, "phase0", "test_metadata_join.jl"))
        include(joinpath(@__DIR__, "phase0", "test_grounding.jl"))
        include(joinpath(@__DIR__, "phase0", "test_order.jl"))

        if data_available
            include(joinpath(@__DIR__, "phase0", "test_enrich_metadata.jl"))
            include(joinpath(@__DIR__, "phase0", "test_output_integrity.jl"))
        else
            @testset "enrich_metadata (SKIPPED — no data)" begin
                @test_skip true
            end
            @testset "output integrity (SKIPPED — no data)" begin
                @test_skip true
            end
        end
    end

    @testset verbose=true "Phase 1: Model Definition" begin
        include(joinpath(@__DIR__, "phase1", "test_slug_clustering.jl"))
        include(joinpath(@__DIR__, "phase1", "test_country_missingness.jl"))
    end

end
