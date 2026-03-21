@testset verbose=true "order" begin

    @testset verbose=true "sensor_pts" begin
        # PTS scale: 1 (best) → 100, 5 (worst) → 0
        @test sensor_pts(1) == 100.0
        @test sensor_pts(2) == 75.0
        @test sensor_pts(3) == 50.0
        @test sensor_pts(4) == 25.0
        @test sensor_pts(5) == 0.0

        # Missing passthrough
        @test ismissing(sensor_pts(missing))
    end

    @testset verbose=true "sensor_peasfrel" begin
        # Min-max normalization to 0-100
        @test sensor_peasfrel(0.0, -5.0, 5.0) == 50.0
        @test sensor_peasfrel(-5.0, -5.0, 5.0) == 0.0
        @test sensor_peasfrel(5.0, -5.0, 5.0) == 100.0
        @test sensor_peasfrel(0.0, 0.0, 10.0) == 0.0
        @test sensor_peasfrel(10.0, 0.0, 10.0) == 100.0
        @test sensor_peasfrel(5.0, 0.0, 10.0) == 50.0

        # Missing passthrough
        @test ismissing(sensor_peasfrel(missing, -5.0, 5.0))
    end

    @testset verbose=true "sensor_homicide" begin
        # Data available: normalize homicide rate
        df = DataFrame(year=[2020, 2021, 2022, 2023],
                       wdi_homs=[15.0, 16.0, 17.0, 18.0])
        result = sensor_homicide(df, 2023, false)
        @test !ismissing(result.value)
        @test result.multiplier == 1.0
        # 18.0 * 2 = 36, 100 - 36 = 64
        @test result.value == 64.0

        # No data, not global failure: penalty multiplier
        df_empty = DataFrame(year=Int[], wdi_homs=Union{Float64,Missing}[])
        result = sensor_homicide(df_empty, 2023, false)
        @test ismissing(result.value)
        @test result.multiplier == 0.85

        # No data, global failure: no penalty (everyone is missing)
        result = sensor_homicide(df_empty, 2023, true)
        @test ismissing(result.value)
        @test result.multiplier == 1.0
    end
end
