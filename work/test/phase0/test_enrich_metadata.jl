@testset "enrich_metadata" begin

    @testset "classify_temporal_profile" begin
        # Common kwargs to avoid dependency on data-loaded constants
        kw = (data_start=1946, data_end=2022, current_year=2020, active_lag=3,
              thresholds=(anchor=0.97, experimental=0.15, legacy=0.50, recent_pct=0.25))
        span = 2022 - 1946 + 1  # 77 years

        # Anchor: usage_pct >= 0.97
        @test classify_temporal_profile(1946, 2022; kw...) == :anchor
        @test classify_temporal_profile(1947, 2022; kw...) == :anchor  # 76/77 ≈ 0.987

        # Experimental: usage_pct < 0.15 (< ~11.5 years)
        @test classify_temporal_profile(2015, 2022; kw...) == :experimental  # 8/77 ≈ 0.10

        # Legacy: inactive AND usage_pct >= 0.50
        @test classify_temporal_profile(1946, 2010; kw...) == :legacy  # 65/77 ≈ 0.84, death < 2017

        # Historical: inactive AND usage_pct < 0.50
        @test classify_temporal_profile(1990, 2010; kw...) == :historical  # 21/77 ≈ 0.27, death < 2017

        # Current: active, birth >= recent_start, usage_pct in [0.15, 0.97)
        # recent_start = 2022 - round(Int, 77 * 0.25) = 2022 - 19 = 2003
        @test classify_temporal_profile(2005, 2022; kw...) == :current  # 18/77 ≈ 0.23, birth >= 2003

        # Modern: active, birth < recent_start, usage_pct in [0.15, 0.97)
        @test classify_temporal_profile(1980, 2022; kw...) == :modern  # 43/77 ≈ 0.56, birth < 2003
    end

    @testset "classify_geographic_profile" begin
        # Global: >= 95% global penetration
        @test classify_geographic_profile(0.96, fill(0.5, 10)) == :global
        @test classify_geographic_profile(0.95, fill(0.5, 10)) == :global

        # Just below global threshold
        @test classify_geographic_profile(0.94, fill(0.5, 10)) != :global

        # Regional: >= 1 region with >= 0.80 AND >= 6 regions (10-4) with <= 0.10
        regional = [0.85, 0.05, 0.03, 0.02, 0.01, 0.04, 0.08, 0.06, 0.09, 0.07]
        @test classify_geographic_profile(0.40, regional) == :regional

        # Not regional: high region but not enough low regions
        not_regional = [0.85, 0.50, 0.40, 0.30, 0.20, 0.15, 0.08, 0.06, 0.09, 0.07]
        @test classify_geographic_profile(0.40, not_regional) == :other

        # Other: doesn't meet either threshold
        @test classify_geographic_profile(0.30, fill(0.40, 10)) == :other
    end
end
