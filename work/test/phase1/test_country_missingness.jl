@testset verbose=true "country_missingness" begin

    @testset verbose=true "build_country_profiles" begin
        # Synthetic: 3 countries, some with wpp_pop
        df = DataFrame(
            ident_ccode = vcat(fill(1, 10), fill(2, 5), fill(3, 10)),
            ident_ccodealp = vcat(fill("AAA", 10), fill("BBB", 5), fill("CCC", 10)),
            ident_cname = vcat(fill("Country A", 10), fill("Country B", 5), fill("Country C", 10)),
            ident_year = vcat(collect(2010:2019), collect(2010:2014), collect(2010:2019)),
            # wpp_pop is in thousands: 1000 = 1M people, 50 = 50K people, 5000 = 5M people
            wpp_pop = vcat(fill(1000.0, 10), fill(50.0, 5), fill(5000.0, 10)),
            ggis_un_subregion_code = vcat(fill(151, 10), fill(151, 5), fill(202, 10)),
        )

        profiles = redirect_stdout(devnull) do
            build_country_profiles(df)
        end

        @test nrow(profiles) == 3

        # Country A: 2010-2019
        a = filter(r -> r.ident_ccode == 1, profiles)
        @test a.country_birth_year[1] == 2010
        @test a.country_death_year[1] == 2019
        @test a.n_years[1] == 10
        @test a.is_microstate[1] == false

        # Country B: microstate (pop 50K < 100K)
        b = filter(r -> r.ident_ccode == 2, profiles)
        @test b.is_microstate[1] == true
        @test b.country_death_year[1] == 2014

        # Dissolved state detection
        df_dissolved = DataFrame(
            ident_ccode = fill(278, 40),  # DDR
            ident_ccodealp = fill("DDR", 40),
            ident_cname = fill("German Democratic Republic", 40),
            ident_year = collect(1950:1989),
            wpp_pop = fill(16e6, 40),
            ggis_un_subregion_code = fill(151, 40),
        )
        profiles_d = redirect_stdout(devnull) do
            build_country_profiles(df_dissolved)
        end
        @test profiles_d.is_dissolved[1] == true
    end

    @testset verbose=true "classify_country_status categories" begin
        # Synthetic profiles and scores to test each classification
        profiles = DataFrame(
            ident_ccode = [1, 2, 3, 4, 5, 6, 7],
            ident_ccodealp = ["STR", "FAI", "MIC", "DIS", "REP", "NAS", "COL"],
            ident_cname = ["Strong", "Failed", "Micro", "Dissolved", "Reporting", "Nascent", "Collision"],
            country_birth_year = [1960, 1960, 1960, 1950, 1960, 2010, 1960],
            country_death_year = [2020, 2020, 2020, 1989, 2020, 2020, 2020],
            n_years = [61, 61, 61, 40, 61, 11, 61],
            year_span = [61, 61, 61, 40, 61, 11, 61],
            is_active = [true, true, true, false, true, true, true],
            is_dissolved = [false, false, false, true, false, false, false],
            dissolution_year = [missing, missing, missing, 1990, missing, missing, missing],
            is_microstate = [false, false, true, false, false, false, false],
            max_pop = [50_000.0, 10_000.0, 50.0, 16_000.0, 5_000.0, 1_000.0, 30_000.0],
            has_collision = [false, false, false, false, false, false, true],
            collision_years = [Int[], Int[], Int[], Int[], Int[], Int[], [2015]],
            un_subregion_code = [155, 202, 155, 151, 155, 202, 155],
        )

        # Scores: strong=high, failed=low, dissolved=post-dissolution, nascent=early, collision=collision year
        scores = DataFrame(
            ident_ccode = [1, 2, 3, 4, 5, 6, 7],
            ident_year = [2015, 2015, 2015, 1988, 2015, 2012, 2015],
            n_global_present = [580, 100, 300, 200, 400, 300, 500],
            n_global_total = [600, 600, 600, 600, 600, 600, 600],
            global_coverage_pct = [0.97, 0.17, 0.50, 0.33, 0.67, 0.50, 0.83],
            un_subregion_code = [155, 202, 155, 151, 155, 202, 155],
            subregion_peer_avg = [0.80, 0.60, 0.80, 0.50, 0.80, 0.60, 0.80],
            peer_deviation = [0.17, -0.43, -0.30, -0.17, -0.13, -0.10, 0.03],
            lag_affected = [false, false, false, false, false, false, false],
        )

        status = redirect_stdout(devnull) do
            classify_country_status(profiles, scores)
        end

        statuses = Dict(r.ident_ccode => r.country_status for r in eachrow(status))
        @test statuses[1] == "strong"
        @test statuses[2] == "failed"      # 0.17 < 0.40 AND -0.43 < -0.20
        @test statuses[3] == "microstate"
        @test statuses[4] == "dissolved"   # year 1988 >= 1990 - 5 (dissolution_year - lag)
        @test statuses[5] == "reporting"   # 0.67 > 0.40, deviation -0.13 > -0.20
        @test statuses[6] == "nascent"     # 2012 < 2010 + 5 (birth + nascent_years)
        @test statuses[7] == "collision"   # 2015 is in collision_years
    end

    if has_data()
        @testset verbose=true "integration: full pipeline" begin
            meta_df = CSV.read("data/qog_metadata_plus2.csv", DataFrame)
            df_aug = redirect_stdout(devnull) do
                load_augmented_or_build()
            end

            result = redirect_stdout(devnull) do
                run_country_missingness(df_aug, meta_df)
            end

            # Profiles should cover all countries
            @test nrow(result.profiles) > 0

            # Flags should cover all valid rows
            @test nrow(result.flags) > 0

            # Every flag row has a ggis_rowid
            @test all(!ismissing, result.flags.ggis_rowid)

            # Status should include known categories
            statuses = unique(result.status.country_status)
            @test "strong" in statuses
            @test "reporting" in statuses

            # DDR should be dissolved
            ddr_status = filter(r -> r.ident_ccode == 278 && r.ident_year > 1990, result.status)
            if nrow(ddr_status) > 0
                @test all(==("dissolved"), ddr_status.country_status)
            end

            # Penetration should have revised values
            @test nrow(result.penetration) > 0
            @test :revised_penetration in propertynames(result.penetration)
        end
    end
end
