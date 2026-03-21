@testset "qog_pdf_extract" begin

    @testset "parse_year_value" begin
        # Standard years
        @test parse_year_value("1990") == 1990
        @test parse_year_value("2022") == 2022
        @test parse_year_value("1700") == 1700
        @test parse_year_value("2100") == 2100

        # Whitespace handling
        @test parse_year_value("  2020  ") == 2020

        # OCR corrections: O→0, l→1, S→5
        @test parse_year_value("199O") == 1990
        @test parse_year_value("20l5") == 2015

        # Missing indicators
        @test ismissing(parse_year_value("N/A"))
        @test ismissing(parse_year_value("n/a"))
        @test ismissing(parse_year_value("NA"))
        @test ismissing(parse_year_value("."))
        @test ismissing(parse_year_value("..."))
        @test ismissing(parse_year_value(""))
        @test ismissing(parse_year_value("  "))
        @test ismissing(parse_year_value("None"))
        @test ismissing(parse_year_value("missing"))
        @test ismissing(parse_year_value("undefined"))

        # Out of range
        @test ismissing(parse_year_value("1650"))
        @test ismissing(parse_year_value("2200"))

        # Non-year strings
        @test ismissing(parse_year_value("abc"))
        @test ismissing(parse_year_value("12"))
    end

    @testset "extract_first_paragraph" begin
        # Empty input
        @test extract_first_paragraph("") == ""

        # Strategy 2: Stop at "Responses:" — requires "Responses" capitalized after sentence-ending punctuation
        text2 = "This measures democratic quality in countries around the world and is used in many studies. Responses: 0 = No, 1 = Yes."
        result2 = extract_first_paragraph(text2)
        @test occursin("democratic quality", result2)

        # Strategy 4: First few sentences fallback
        text4 = "First sentence here. second continuation. third part. fourth part."
        result4 = extract_first_paragraph(text4)
        @test occursin("First sentence here.", result4)
    end

    @testset "classify_provenance" begin
        # PHYSICAL
        @test classify_provenance((source_name="Geographic data", description="Latitude and longitude from satellite")) == "PHYSICAL"
        @test classify_provenance((source_name="", description="Land area measurements from NASA")) == "PHYSICAL"

        # SURVEY (excludes expert surveys)
        @test classify_provenance((source_name="World Values Survey", description="Public opinion data from respondents")) == "SURVEY"
        # Expert survey triggers EXPERT, not SURVEY (expert keyword matches first in cascade)
        @test classify_provenance((source_name="Expert Survey", description="Expert survey on governance")) == "EXPERT"

        # EVENT/FACTUAL
        @test classify_provenance((source_name="UCDP", description="Armed conflict data with battle deaths")) == "EVENT/FACTUAL"
        @test classify_provenance((source_name="", description="Records of coup attempts since 1950")) == "EVENT/FACTUAL"

        # IMPUTED
        @test classify_provenance((source_name="Maddison Project", description="Historical GDP reconstruction")) == "IMPUTED"

        # EXPERT
        @test classify_provenance((source_name="Freedom House", description="Expert-coded index rating")) == "EXPERT"
        @test classify_provenance((source_name="V-Dem", description="Expert-coded index of liberal democracy")) == "EXPERT"

        # OFFICIAL
        @test classify_provenance((source_name="World Bank", description="GDP per capita data")) == "OFFICIAL"
        @test classify_provenance((source_name="IMF", description="Tax revenue statistics")) == "OFFICIAL"

        # UNCERTAIN (nothing matches)
        @test classify_provenance((source_name="Unknown Source", description="Some data about things")) == "UNCERTAIN"
    end
end
