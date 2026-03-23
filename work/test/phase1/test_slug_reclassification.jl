@testset verbose=true "slug_reclassification" begin

    @testset verbose=true "build_clean_population_universe" begin
        # Synthetic: 3 countries, one is "failed"
        df = DataFrame(
            ggis_rowid = 1:6,
            ident_ccode = [1, 1, 2, 2, 3, 3],
            ident_ccodealp = fill("TST", 6),
            ident_year = [2018, 2019, 2018, 2019, 2018, 2019],
            wpp_pop = [1000.0, 1000.0, 500.0, 500.0, 200.0, 200.0],
            ggis_un_subregion_code = [155, 155, 202, 202, 155, 155],
        )
        status = DataFrame(
            ident_ccode = [1, 1, 2, 2, 3, 3],
            ident_year = [2018, 2019, 2018, 2019, 2018, 2019],
            country_status = ["strong", "strong", "strong", "strong", "failed", "failed"],
            global_coverage_pct = [0.9, 0.9, 0.8, 0.8, 0.2, 0.2],
            peer_deviation = [0.1, 0.1, 0.0, 0.0, -0.6, -0.6],
            lag_affected = [false, false, false, false, false, false],
        )

        result = redirect_stdout(devnull) do
            build_clean_population_universe(df, status)
        end

        # Country 3 (failed) should be excluded
        clean_ccodes = unique(result.clean_rows.ident_ccode)
        @test 1 in clean_ccodes
        @test 2 in clean_ccodes
        @test !(3 in clean_ccodes)
    end

    @testset verbose=true "prepare_clustering_pool" begin
        pen = DataFrame(
            slug = ["global_s", "regional_s", "partial_s", "sparse_s", "dropped_s"],
            temporal_profile = ["anchor", "modern", "current", "legacy", "experimental"],
            penetration_window = ["2018-2020", "2018-2020", "2018-2020", "2010-2014", ""],
            revised_penetration = [0.97, 0.60, 0.50, 0.02, missing],
            n_countries_covered = [180, 40, 80, 5, 0],
            drop_reason = [missing, missing, missing, missing, "experimental"],
        )
        vectors = DataFrame(
            slug = ["global_s", "regional_s", "partial_s", "sparse_s"],
            un_region_penetration = [fill(0.95, 5), [0.9, 0.1, 0.05, 0.02, 0.0], fill(0.5, 5), fill(0.01, 5)],
            un_subregion_penetration = [fill(0.95, 17), vcat(0.9, fill(0.05, 16)), fill(0.5, 17), fill(0.01, 17)],
            un_geo_classification = ["global_95", "regional", "partial", "sparse"],
        )

        result = redirect_stdout(devnull) do
            prepare_clustering_pool(pen, vectors)
        end

        @test "partial_s" in result.clustering_pool
        @test !("global_s" in result.clustering_pool)
        @test !("regional_s" in result.clustering_pool)
        @test !("sparse_s" in result.clustering_pool)
        @test !("dropped_s" in result.clustering_pool)
    end

    if has_data()
        @testset verbose=true "integration: full pipeline" begin
            meta_df = CSV.read("data/qog_metadata_plus2.csv", DataFrame)
            df_aug = redirect_stdout(devnull) do
                load_augmented_or_build()
            end
            miss = redirect_stdout(devnull) do
                run_country_missingness(df_aug, meta_df)
            end
            reclass = redirect_stdout(devnull) do
                run_slug_reclassification(df_aug, meta_df, miss.status)
            end

            # Penetration should have entries for all slugs
            @test nrow(reclass.penetration) == nrow(meta_df)

            # Some slugs should be dropped
            dropped = filter(r -> !ismissing(r.drop_reason), reclass.penetration)
            @test nrow(dropped) > 0

            # Vectors should exist for kept slugs
            @test nrow(reclass.vectors) > 0

            # Clustering pool should be non-empty and smaller than total
            @test length(reclass.clustering_pool.clustering_pool) > 0
            @test length(reclass.clustering_pool.clustering_pool) < nrow(meta_df)

            # Global slugs should be identified (either tier)
            n_global = count(s -> startswith(s, "global"), reclass.vectors.un_geo_classification)
            @test n_global > 0
        end
    end
end
