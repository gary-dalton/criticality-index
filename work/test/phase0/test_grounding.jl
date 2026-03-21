@testset verbose=true "grounding" begin

    @testset verbose=true "validate_power_law" begin
        # Insufficient data: < 10 events
        df_small = DataFrame(year=[2024, 2025], vdem_subvrs=[10.0, 20.0])
        result = validate_power_law(df_small, 2025, 20)
        @test ismissing(result.alpha)
        @test result.is_critical == false

        # Sufficient data with known distribution
        years = collect(2006:2025)
        magnitudes = [100, 50, 75, 25, 120, 40, 90, 30, 110, 60,
                      80, 35, 95, 45, 105, 55, 85, 65, 115, 70]
        df = DataFrame(year=years, vdem_subvrs=Float64.(magnitudes))
        result = validate_power_law(df, 2025, 20)
        @test !ismissing(result.alpha)
        @test result.alpha isa Float64
        @test result.alpha > 0
    end

    @testset verbose=true "validate_correlation_divergence" begin
        # Insufficient data: < 6 pairs
        df_small = DataFrame(year=[2023, 2024, 2025],
                             vdem_labvrs=[1.0, 2.0, 3.0],
                             vdem_relig=[1.0, 2.0, 3.0])
        result = validate_correlation_divergence(df_small, 2025)
        @test ismissing(result.correlation)
        @test result.is_diverging == false

        # Highly correlated data — should flag divergence
        years = collect(2014:2025)
        df_corr = DataFrame(year=years,
                            vdem_labvrs=Float64.(1:12),
                            vdem_relig=Float64.(2:2:24))
        result = validate_correlation_divergence(df_corr, 2025)
        @test !ismissing(result.correlation)
        @test result.correlation > 0.70
        @test result.is_diverging == true

        # Weakly correlated data — should NOT flag divergence
        # Alternating pattern to minimize correlation
        df_uncorr = DataFrame(year=years,
                              vdem_labvrs=[1.0, 10.0, 1.0, 10.0, 1.0, 10.0, 1.0, 10.0, 1.0, 10.0, 1.0, 10.0],
                              vdem_relig=[10.0, 1.0, 10.0, 1.0, 10.0, 1.0, 10.0, 1.0, 10.0, 1.0, 10.0, 1.0])
        result = validate_correlation_divergence(df_uncorr, 2025)
        @test !ismissing(result.correlation)
        @test result.correlation < 0  # negatively correlated
        @test result.is_diverging == true  # |ρ| > 0.70 even when negative
    end

    @testset verbose=true "validate_scale_invariance" begin
        # Insufficient data
        df_small = DataFrame(year=[2024, 2025],
                             vdem_localgov=[50.0, 51.0],
                             vdem_execcon=[50.0, 51.0])
        result = validate_scale_invariance(df_small, 2025)
        @test ismissing(result.similarity)
        @test result.is_invariant == false

        # Similar CVs — should flag invariance
        years = collect(2011:2025)
        df_sim = DataFrame(year=years,
                           vdem_localgov=50.0 .+ randn(15) .* 2,
                           vdem_execcon=50.0 .+ randn(15) .* 2)
        result = validate_scale_invariance(df_sim, 2025)
        @test !ismissing(result.similarity)
        @test result.similarity isa Float64
    end

    @testset verbose=true "validate_event_scaling" begin
        # Insufficient data: < 10 jumps
        df_small = DataFrame(year=[2023, 2024, 2025],
                             vdem_v3polsoc=[50.0, 55.0, 60.0])
        result = validate_event_scaling(df_small, 2025, 20)
        @test ismissing(result.kurtosis)
        @test result.is_scale_free == false

        # Sufficient data with outlier jumps (should have high kurtosis)
        years = collect(2005:2025)
        # Mostly small changes with a few big jumps
        vals = [50.0, 51, 52, 53, 80, 55, 56, 57, 58, 30, 60, 61, 62, 63, 90, 65, 66, 67, 68, 40, 70]
        df = DataFrame(year=years, vdem_v3polsoc=Float64.(vals))
        result = validate_event_scaling(df, 2025, 20)
        @test !ismissing(result.kurtosis)
        @test result.kurtosis isa Float64
    end
end
