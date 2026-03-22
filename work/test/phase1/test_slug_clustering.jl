@testset verbose=true "slug_clustering" begin

    @testset verbose=true "partition_slugs" begin
        meta = DataFrame(
            slug = ["wdi_gdp", "vdem_libdem", "iiag_gov", "fh_score"],
            ggis_geo_classification = ["global", "global", "regional", "other"]
        )
        result = redirect_stdout(devnull) do
            partition_slugs(meta)
        end
        @test length(result.global_slugs) == 2
        @test length(result.cluster_slugs) == 2
        @test "wdi_gdp" in result.global_slugs
        @test "iiag_gov" in result.cluster_slugs
        @test "fh_score" in result.cluster_slugs

        # Missing classification treated as "other" → cluster candidate
        meta2 = DataFrame(slug = ["a"], ggis_geo_classification = [missing])
        result2 = redirect_stdout(devnull) do
            partition_slugs(meta2)
        end
        @test length(result2.cluster_slugs) == 1
    end

    @testset verbose=true "build_slug_country_matrix" begin
        # Synthetic data: 3 countries, 10 years each, 2 slugs
        df = DataFrame(
            ident_ccode = repeat([1, 2, 3], inner=10),
            ident_year = repeat(2014:2023, 3),
            slug_a = vcat(fill(1.0, 10), fill(1.0, 10), fill(missing, 10)),  # covers countries 1,2
            slug_b = vcat(fill(missing, 10), fill(1.0, 10), fill(1.0, 10))   # covers countries 2,3
        )
        slugs = ["slug_a", "slug_b"]

        result = redirect_stdout(devnull) do
            build_slug_country_matrix(df, slugs; presence_min_pct=0.10, min_country_coverage=0.01)
        end

        @test size(result.X) == (2, 3)  # 2 slugs × 3 countries
        @test result.slug_index == ["slug_a", "slug_b"]
        @test length(result.country_index) == 3

        # slug_a present for countries 1,2 (density = 10/10 = 1.0)
        a_idx = findfirst(==(1), result.country_index)
        @test result.X[1, a_idx] == 1.0  # slug_a, country 1

        # slug_b absent for country 1
        @test result.X[2, a_idx] == 0.0  # slug_b, country 1
    end

    @testset verbose=true "build_slug_country_matrix density filter" begin
        # slug_c has data in only 1 out of 10 years for each country → density = 0.1
        df = DataFrame(
            ident_ccode = repeat([1, 2], inner=10),
            ident_year = repeat(2014:2023, 2),
            slug_c = vcat(1.0, fill(missing, 9), 1.0, fill(missing, 9))
        )

        # With min 10% → present (1/10 = 0.10 exactly)
        r1 = redirect_stdout(devnull) do
            build_slug_country_matrix(df, ["slug_c"]; presence_min_pct=0.10, min_country_coverage=0.01)
        end
        @test size(r1.X, 1) == 1  # slug passes

        # With min 20% → absent (1/10 = 0.10 < 0.20)
        r2 = redirect_stdout(devnull) do
            build_slug_country_matrix(df, ["slug_c"]; presence_min_pct=0.20, min_country_coverage=0.01)
        end
        @test size(r2.X, 1) == 0  # slug filtered out
    end

    @testset verbose=true "jaccard_topk_edges" begin
        # 3 slugs, 4 countries
        # slug_a: {1,2,3}  slug_b: {1,2,3}  slug_c: {3,4}
        # J(a,b) = 3/3 = 1.0
        # J(a,c) = 1/4 = 0.25
        # J(b,c) = 1/4 = 0.25
        I = [1,1,1, 2,2,2, 3,3]
        J = [1,2,3, 1,2,3, 3,4]
        X = sparse(I, J, ones(Float64, 8), 3, 4)
        slugs = ["slug_a", "slug_b", "slug_c"]

        edges = redirect_stdout(devnull) do
            jaccard_topk_edges(X, slugs; k=5, min_sim=0.0)
        end

        # Should have edges for all pairs
        @test nrow(edges) > 0

        # Find the a↔b edge (should be ~1.0)
        ab = filter(r -> (r.slug_i == "slug_a" && r.slug_j == "slug_b"), edges)
        @test nrow(ab) == 1
        @test ab.sim[1] ≈ 1.0

        # a↔c edge should be 0.25
        ac = filter(r -> (r.slug_i == "slug_a" && r.slug_j == "slug_c"), edges)
        @test nrow(ac) == 1
        @test ac.sim[1] ≈ 0.25
    end

    @testset verbose=true "symmetrize_edges" begin
        edges = DataFrame(
            slug_i = ["a", "b", "a"],
            slug_j = ["b", "a", "c"],
            sim = [0.8, 0.9, 0.5]
        )
        und = redirect_stdout(devnull) do
            symmetrize_edges(edges; mode=:max)
        end

        @test nrow(und) == 2  # (a,b) and (a,c)
        ab = filter(r -> r.slug_a == "a" && r.slug_b == "b", und)
        @test ab.weight[1] == 0.9  # max of 0.8, 0.9
        @test ab.n_dir[1] == 2     # bidirectional
    end

    if has_data() && isfile("data/qog_metadata_plus2.csv")
        @testset verbose=true "integration: full pipeline" begin
            # Use plus2 metadata (has ggis_geo_classification)
            meta_plus2 = CSV.read("data/qog_metadata_plus2.csv", DataFrame)
            geo_df = CSV.read("data/ggis_geographic_lookup.csv", DataFrame)
            df_aug = redirect_stdout(devnull) do
                load_qog_timeseries()
            end
            result = redirect_stdout(devnull) do
                run_slug_clustering(df_aug, meta_plus2, geo_df)
            end

            # All cluster candidates should be assigned
            @test nrow(result.slug_clusters) > 0

            # Profiles should exist
            @test nrow(result.profiles) > 0

            # No orphan slugs (every clustered slug has a cluster_id)
            @test all(!ismissing, result.slug_clusters.cluster_id)

            # ht_region validation should have results
            @test nrow(result.ht_validation) > 0
        end
    end
end
