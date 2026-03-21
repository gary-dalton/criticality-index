@testset "qog_augmented_standard" begin

    @testset "constants defined" begin
        # Key path constants exist
        @test isdefined(Main, :PATH_DATA_DIR)
        @test isdefined(Main, :PATH_TS_RAW)

        # Key mapping constants exist
        @test isdefined(Main, :HISTORICAL_CCODE_MAP)
        @test isdefined(Main, :COLLISION_PRIORITY_ALPHAS)
        @test isdefined(Main, :IDENT_MAPPING)
        @test isdefined(Main, :RESCUED_ENTITY_REGIONS)

        # HISTORICAL_CCODE_MAP covers expected entities
        @test haskey(HISTORICAL_CCODE_MAP, "VDR")
        @test haskey(HISTORICAL_CCODE_MAP, "XTI")
        @test haskey(HISTORICAL_CCODE_MAP, "DEU")
        @test haskey(HISTORICAL_CCODE_MAP, "ETH")
        @test haskey(HISTORICAL_CCODE_MAP, "YEM")
        @test haskey(HISTORICAL_CCODE_MAP, "SCG")
        @test haskey(HISTORICAL_CCODE_MAP, "VNM")
        @test haskey(HISTORICAL_CCODE_MAP, "MHL")

        # Known code values
        @test HISTORICAL_CCODE_MAP["VDR"] == 704
        @test HISTORICAL_CCODE_MAP["VNM"] == 704
        @test HISTORICAL_CCODE_MAP["XTI"] == 9156
        @test HISTORICAL_CCODE_MAP["DEU"] == 276
    end

    @testset "COLLISION_PRIORITY_ALPHAS" begin
        @test "VNM" in COLLISION_PRIORITY_ALPHAS
        @test "DEU" in COLLISION_PRIORITY_ALPHAS
        @test "YEM" in COLLISION_PRIORITY_ALPHAS
        # VDR is NOT a successor — it should not be in the priority list
        @test !("VDR" in COLLISION_PRIORITY_ALPHAS)
    end

    @testset "RESCUED_ENTITY_REGIONS" begin
        @test RESCUED_ENTITY_REGIONS["VDR"] == 7   # Southeast Asia
        @test RESCUED_ENTITY_REGIONS["XTI"] == 6   # East Asia
        @test RESCUED_ENTITY_REGIONS["DDR"] == 1   # Eastern Europe
        @test RESCUED_ENTITY_REGIONS["SCG"] == 1   # Eastern Europe
    end

    if has_data() && isdefined(Main, :load_augmented_qog) && isdefined(Main, :df)
        @testset "integration: load_augmented_qog" begin
            # Use the df already loaded by enrich_metadata at module level
            # rather than re-running the full pipeline
            df = Main.df

            # Row count preserved
            @test nrow(df) > 0

            # ggis_rowid is unique
            @test allunique(df.ggis_rowid)

            # Required identity columns present
            for col in [:ident_ccode, :ident_year, :ident_ccodealp, :ggis_rowid, :ggis_region]
                @test col in propertynames(df)
            end

            # No missing regions
            @test count(ismissing, df.ggis_region) == 0

            # No missing ccodes (all rescued)
            @test count(ismissing, df.ident_ccode) == 0
        end
    end
end
