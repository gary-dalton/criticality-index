# Known dimensions of the raw QoG Jan 2025 Arrow file.
# If these change, the source data has been modified (violates immutability).
RAW_ARROW_PATH = "data/qog_std_ts_jan25.arrow"
EXPECTED_RAW_ROWS = 12391
EXPECTED_RAW_COLS = 2009

@testset verbose=true "output integrity" begin

    @testset verbose=true "raw source immutability" begin
        @test isfile(RAW_ARROW_PATH)
        df_raw = Arrow.Table(RAW_ARROW_PATH) |> DataFrame
        @test nrow(df_raw) == EXPECTED_RAW_ROWS
        @test ncol(df_raw) == EXPECTED_RAW_COLS
    end

    # =========================================================================
    # AUGMENTED PIPELINE: NO ROW LOSS, ONLY COLUMN ADDITIONS
    # =========================================================================

    @testset verbose=true "augmented pipeline preserves rows" begin
        df_raw = Arrow.Table(RAW_ARROW_PATH) |> DataFrame
        df_aug = redirect_stdout(devnull) do
            load_qog_timeseries()
        end

        # Row count must be identical — augmentation never adds or removes rows
        @test nrow(df_aug) == nrow(df_raw)

        # Column count must be >= raw (only additions allowed)
        @test ncol(df_aug) >= ncol(df_raw)

        # Every raw column must survive (renamed or original)
        raw_cols = Set(lowercase.(string.(names(df_raw))))
        aug_cols = Set(lowercase.(string.(names(df_aug))))

        # Build expected rename mapping
        renamed_to = Dict(lowercase(v) => lowercase(k) for (k, v) in IDENT_MAPPING)

        for raw_col in raw_cols
            # Column either exists as-is, or was renamed via IDENT_MAPPING
            renamed = get(IDENT_MAPPING, raw_col, nothing)
            if renamed !== nothing
                @test lowercase(renamed) in aug_cols
            else
                @test raw_col in aug_cols
            end
        end

        # Verify ggis_rowid checksum: sequential 1:N, unique
        @test allunique(df_aug.ggis_rowid)
        @test minimum(df_aug.ggis_rowid) == 1
        @test maximum(df_aug.ggis_rowid) == nrow(df_aug)

        # Augmented columns present (added by pipeline, not in raw)
        for col in [:ggis_rowid, :ggis_region, :ggis_ccode_rescued, :ggis_spine_collision, :ggis_un_subregion_code]
            @test col in propertynames(df_aug)
        end
    end

    # =========================================================================
    # METADATA CSV INTEGRITY
    # =========================================================================

    @testset verbose=true "qog_metadata_joined.csv" begin
        path = "data/qog_metadata_joined.csv"
        @test isfile(path)
        df = CSV.read(path, DataFrame)

        # Must have rows
        @test nrow(df) > 0

        # Required columns
        for col in [:slug, :prefix, :label]
            @test col in propertynames(df)
        end

        # Slug uniqueness (each variable appears once)
        @test length(unique(df.slug)) == nrow(df)

        # No empty slugs
        @test all(!isempty, skipmissing(df.slug))
    end

    @testset verbose=true "qog_metadata_enriched.csv" begin
        path = "data/qog_metadata_enriched.csv"
        @test isfile(path)
        df = CSV.read(path, DataFrame)

        @test nrow(df) > 0

        # Must have base columns plus enrichment columns
        for col in [:slug, :prefix]
            @test col in propertynames(df)
        end

        # Slug uniqueness
        @test length(unique(df.slug)) == nrow(df)

        # Row count should match or exceed joined metadata
        joined_path = "data/qog_metadata_joined.csv"
        if isfile(joined_path)
            df_joined = CSV.read(joined_path, DataFrame)
            @test nrow(df) >= nrow(df_joined)
        end
    end

    if isfile("data/qog_metadata_plus2.csv")
        @testset verbose=true "qog_metadata_plus2.csv" begin
            df = CSV.read("data/qog_metadata_plus2.csv", DataFrame)

            @test nrow(df) > 0

            # Must have temporal enrichment columns
            for col in [:slug, :ggis_birth_year, :ggis_death_year, :ggis_temporal_profile]
                @test col in propertynames(df)
            end

            # Must have geographic enrichment columns
            for col in [:ggis_global_penetration, :ggis_geo_classification]
                @test col in propertynames(df)
            end

            # Slug uniqueness
            @test length(unique(df.slug)) == nrow(df)

            # Temporal profiles are valid (allowing missing for unclassified vars)
            valid_profiles = Set(["anchor", "modern", "current", "experimental", "legacy", "historical", "unclassified"])
            for p in skipmissing(df.ggis_temporal_profile)
                @test string(p) in valid_profiles
            end

            # Geographic classifications are valid (allowing missing)
            valid_geo = Set(["global", "regional", "other"])
            for g in skipmissing(df.ggis_geo_classification)
                @test string(g) in valid_geo
            end

            # No row loss from joined → plus2
            if isfile("data/qog_metadata_joined.csv")
                df_joined = CSV.read("data/qog_metadata_joined.csv", DataFrame)
                @test nrow(df) >= nrow(df_joined)
            end
        end
    end

    # =========================================================================
    # CROSS-FILE CONSISTENCY
    # =========================================================================

    @testset verbose=true "cross-file slug consistency" begin
        df_raw = Arrow.Table(RAW_ARROW_PATH) |> DataFrame
        raw_cols = Set(lowercase.(string.(names(df_raw))))

        # Remove identity columns (renamed) and ht_region (anchor, not a slug)
        id_cols = Set(lowercase.(keys(IDENT_MAPPING)))
        analytical_raw_cols = setdiff(raw_cols, id_cols, Set(["ht_region", "year"]))

        if isfile("data/qog_metadata_joined.csv")
            meta = CSV.read("data/qog_metadata_joined.csv", DataFrame)
            meta_slugs = Set(lowercase.(meta.slug))

            # Every analytical column in the raw data should have a metadata entry
            unmatched = setdiff(analytical_raw_cols, meta_slugs)
            # Allow some tolerance for ggis_* and ident_* columns that aren't slugs
            real_unmatched = filter(s -> !startswith(s, "ggis_") && !startswith(s, "ident_"), unmatched)
            @test length(real_unmatched) <= 5  # small tolerance for edge cases
        end
    end
end
