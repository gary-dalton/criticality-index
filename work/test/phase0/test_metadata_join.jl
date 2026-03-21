@testset "qog_metadata_join" begin

    @testset "normalize_ligatures" begin
        # Standard ligature replacements (Unicode U+FB00-U+FB04)
        @test normalize_ligatures("o\uFB00ensive") == "offensive"     # ﬀ → ff
        @test normalize_ligatures("re\uFB01ned") == "refined"         # ﬁ → fi
        @test normalize_ligatures("wa\uFB02e") == "wafle"             # ﬂ → fl
        @test normalize_ligatures("tra\uFB03c") == "traffic"          # ﬃ → ffi
        @test normalize_ligatures("sca\uFB04old") == "scaffold"       # ﬄ → ffl

        # No ligatures — passthrough
        @test normalize_ligatures("normal_text") == "normal_text"
        @test normalize_ligatures("") == ""

        # Multiple ligatures in one string
        @test normalize_ligatures("o\uFB00icial_a\uFB03liation") == "official_affiliation"
    end

    @testset "has_proper_temporal_data" begin
        # Valid temporal data
        @test has_proper_temporal_data((min_year=1990, max_year=2022)) == true
        @test has_proper_temporal_data((min_year=2000, max_year=2000)) == true  # same year

        # Missing values
        @test has_proper_temporal_data((min_year=missing, max_year=2022)) == false
        @test has_proper_temporal_data((min_year=1990, max_year=missing)) == false
        @test has_proper_temporal_data((min_year=missing, max_year=missing)) == false

        # Inverted range
        @test has_proper_temporal_data((min_year=2022, max_year=1990)) == false

        # Non-integer types
        @test has_proper_temporal_data((min_year=1990.5, max_year=2022.0)) == false
        @test has_proper_temporal_data((min_year="1990", max_year=2022)) == false
    end
end
