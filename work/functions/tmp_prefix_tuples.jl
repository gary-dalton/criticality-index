# """
# Registry of source prefixes to a tuple of:
# 1) Topology class (e.g., "Official", "Imputed", "Expert")
# 2) Citation string (human-readable provenance)

# Used by:
# - auditing / reporting layers to classify sensors by origin and expected footprint.
# """
# const PREFIX_REGISTRY = Dict{String, Tuple{String, String}}(
#     # --- OFFICIAL (State-Reported / IGOs) ---
#     "wdi"    => ("Official", "World Bank (2025). World Development Indicators."),
#     "un"     => ("Official", "United Nations Statistics Division (2024)."),
#     "who"    => ("Official", "WHO (2024). Global Health Observatory."),
#     "ilo"    => ("Official", "ILO (2024). ILOSTAT Database."),
#     "itu"    => ("Official", "ITU (2024). World Telecommunication Indicators."),
#     "unesco" => ("Official", "UNESCO Institute for Statistics (2024)."),
#     "fao"    => ("Official", "FAO (2024). FAOSTAT."),
#     "oecd"   => ("Official", "OECD (2024). OECD Statistics."),
#     "imf"    => ("Official", "IMF (2024). International Financial Statistics."),
#     "gfs"    => ("Official", "IMF (2024). Government Finance Statistics."),
#     "undp"   => ("Official", "UNDP (2024). Human Development Reports."),
#     "eu"     => ("Official", "Eurostat (2024). EU Regional Statistics."),
#     "wwbi"   => ("Official", "World Bank (2024). Worldwide Bureaucracy Indicators."),
#     "ictd"   => ("Official", "ICTD/UNU-WIDER (2024). Government Revenue Dataset."),
#     "wpp"    => ("Official", "United Nations (2024). World Population Prospects."),
#     "egov"   => ("Official", "United Nations (2024). E-Government Development Index."),
#     "ipu"    => ("Official", "Inter-Parliamentary Union (2024)."),
#     "iea"    => ("Official", "International Energy Agency (2024)."),
#     "lis"    => ("Official", "Luxembourg Income Study (LIS) Database."),
#     "idf"    => ("Official", "International Diabetes Federation (2024)."),
#     "ihme"   => ("Official", "Institute for Health Metrics and Evaluation."),
#     "ideavt" => ("Official", "International IDEA. Voter Turnout Database."),
#     "ohi"    => ("Official", "Ocean Health Index (2024)."),
#     "gpcr"   => ("Official", "Global Poverty and Inequality Report."),
#     "lld"    => ("Official", "UN-OHRLLS (Landlocked Developing Countries)."),
#     "gea"    => ("Official", "Global Energy Assessment (2024)."),
#     "icd"    => ("Official", "IMF (2024). Capital Data."),
#     "dev"    => ("Official", "Development Assistance Committee (OECD)."),
#     "rd"     => ("Official", "UNESCO/OECD (2024). R&D Statistics."),
#     "une"    => ("Official", "UNESCO Institute for Statistics (UIS). SDG Global and Thematic Indicators."),
#     "une4"   => ("Official", "UNESCO Institute for Statistics (UIS). Feature Films (UIS)."),
#     "nrmi"   => ("Official", "Natural Resource Management Index / NRPI (MCC selection criteria release)."),

#     # --- IMPUTED (Forensic / Reconstructed / Academic-Historical) ---
#     "gle"     => ("Imputed", "Gleditsch, K. S. (2002). Expanded Trade and GDP Data."),
#     "mad"     => ("Imputed", "Bolt, J., & van Zanden, J. L. (2024). Maddison Project."),
#     "pwt"     => ("Imputed", "Feenstra, R. C., et al. (2015). Penn World Table."),
#     "bmr"     => ("Imputed", "Boix, C., et al. (2013). Political Regimes."),
#     "bl"      => ("Imputed", "Barro, R. J., & Lee, J. W. (2013). Educational Attainment."),
#     "br"      => ("Imputed", "Bjørnskov, C., & Rode, M. (2024). Democracy–Dictatorship."),
#     "chga"    => ("Imputed", "Cheibub, J. A., et al. (2010). Democracy and Dictatorship."),
#     "van"     => ("Imputed", "Vanhanen, T. (2019). Measures of Democracy."),
#     "gol"     => ("Imputed", "Golder, M. (2005). Democratic Electoral Systems."),
#     "warc"    => ("Imputed", "UCDP/PRIO (2024). Armed Conflict Dataset."),
#     "ross"    => ("Imputed", "Ross, M. L. (2024). Oil and Gas Data."),
#     "gwf"     => ("Imputed", "Geddes, B., et al. (2014). Autocratic Regimes."),
#     "ht"      => ("Imputed", "Hadenius, A., & Teorell, J. (2007). Democracy Measures."),
#     "ucdp"    => ("Imputed", "Uppsala Conflict Data Program (2024)."),
#     "ajr"     => ("Imputed", "Acemoglu, D., et al. (2001). Colonial Origins."),
#     "gti"     => ("Imputed", "Institute for Economics & Peace. Global Terrorism Index."),
#     "p"       => ("Imputed", "Marshall, M. G., et al. (2024). Polity5 Project."),
#     "atop"    => ("Imputed", "Alliance Treaty Obligations and Provisions (ATOP)."),
#     "gted"    => ("Imputed", "Global Terrorism Database (START)."),
#     "wr"      => ("Imputed", "World Regimes Dataset (Historical)."),
#     "chisols" => ("Imputed", "Change in Source of Leader Support (CHISOLS)."),
#     "hief"    => ("Imputed", "Historical Index of Ethnic Fractionalization."),
#     "gtr"     => ("Imputed", "Andersson & Brambor. Financing the State: Government Tax Revenue from 1800 to 2012."),
#     "aid"     => ("Imputed", "AidData v. 3.1 (AidData)."),
#     "evep"    => ("Imputed", "Emanuele et al. Dataset of Electoral Volatility in European Parliament elections since 1979."),
#     "psi"     => ("Imputed", "New Parties and Party System Innovation in Western Europe (party system innovation since 1945)."),
#     "sai"     => ("Imputed", "Borcan, Olsson, & Putterman (2018). Extended State History Index."),
#     "fe"      => ("Imputed", "Fearon, J. D. (2003). Ethnic and cultural diversity by country."),
#     "hrv"     => ("Imputed", "Hollyer, Rosendorff, & Vreeland (2014). Measuring transparency (HRV Index)."),
#     "gtm"     => ("Imputed", "Gerring, Thacker, & Moreno (2005). Centripetal democratic governance."),
#     "cam"     => ("Imputed", "Coppedge, Alvarez & Maldonado. Contestation and Inclusiveness, 1950–2000."),
#     "ied"     => ("Imputed", "World Bank Prospects Group. Informal Economy Database (1990–2020)."),
#     "gc"      => ("Imputed", "Guillén & Capron (2016). State capacity, minority shareholder protections, and stock market development."),
#     "top"     => ("Imputed", "Alvaredo et al. (2024). World Inequality Database (WID.world)."),

#     # --- EXPERT (Evaluative / Perceptual / De Jure Codes) ---
#     "vdem" => ("Expert", "Coppedge, M., et al. (2025). V-Dem Dataset v15."),
#     "fh"   => ("Expert", "Freedom House (2024). Freedom in the World."),
#     "fhp"  => ("Expert", "Freedom House. Press Freedom Indicators."),
#     "fhn"  => ("Expert", "Freedom House. Nations in Transit."),
#     "ti"   => ("Expert", "Transparency International (2024). Corruption Perceptions Index."),
#     "gcb"  => ("Expert", "Transparency International. Global Corruption Barometer."),
#     "icrg" => ("Expert", "PRS Group (2024). International Country Risk Guide."),
#     "bti"  => ("Expert", "Bertelsmann Stiftung (2024). Transformation Index."),
#     "sgi"  => ("Expert", "Bertelsmann Stiftung (2024). Sustainable Governance Indicators."),
#     "wgi"  => ("Expert", "Kaufmann, D., et al. (2023). Worldwide Governance Indicators."),
#     "wbgi" => ("Expert", "Kaufmann, D., et al. (2023). Worldwide Governance Indicators."),
#     "wjp"  => ("Expert", "World Justice Project (2024). Rule of Law Index."),
#     "ccp"  => ("Expert", "Elkins, Z., & Ginsburg, T. (2025). Comparative Constitutions Project."),
#     "cbie" => ("Expert", "Romelli, D. (2022). Central Bank Independence Extended."),
#     "cbi"  => ("Expert", "Cukierman, A., et al. (1992). Central Bank Independence."),
#     "iaep" => ("Expert", "Institutions and Elections Project (IAEP)."),
#     "cpds" => ("Expert", "Armingeon, K., et al. (2024). Comparative Political Data Set."),
#     "wvs"  => ("Expert", "World Values Survey Association (2024)."),
#     "ess"  => ("Expert", "European Social Survey (ESS)."),
#     "rsf"  => ("Expert", "Reporters Sans Frontières (2024). Press Freedom Index."),
#     "ciri" => ("Expert", "Cingranelli, D., et al. (2024). Human Rights Data Project."),
#     "gpi"  => ("Expert", "Institute for Economics & Peace. Global Peace Index."),
#     "whr"  => ("Expert", "World Happiness Report (2024)."),
#     "aii"  => ("Expert", "Global Integrity (2024). Africa Integrity Indicators."),
#     "iiag" => ("Expert", "Mo Ibrahim Foundation (2024). Ibrahim Index of African Governance."),
#     "gain" => ("Expert", "ND-GAIN Country Index (2024). Global Adaptation Initiative."),
#     "cri"  => ("Expert", "Germanwatch (2024). Climate Risk Index."),
#     "epi"  => ("Expert", "Environmental Performance Index (Yale/Columbia)."),
#     "jw"   => ("Expert", "Johnson, J. W., & Wallack, J. S. (2010). Electoral Systems."),
#     "kun"  => ("Expert", "Kuenzi & Lambright (2024). Party Systems."),
#     "gendip" => ("Expert", "Towns, A. E., et al. (2022). Gender & Diplomacy Dataset."),
#     "yri"    => ("Expert", "Youth Representation Index (2022)."),
#     "fi"   => ("Expert", "Fraser Institute. Economic Freedom of the World."),
#     "h"    => ("Expert", "Heritage Foundation. Index of Economic Freedom."),
#     "ef"   => ("Expert", "Economic Freedom Index (Expert-coded)."),
#     "nelda" => ("Expert", "National Elections across Democracy and Autocracy (NELDA)."),
#     "pei"   => ("Expert", "Perceptions of Electoral Integrity Project."),
#     "wef"  => ("Expert", "World Economic Forum. Global Competitiveness Report."),
#     "gggi" => ("Expert", "World Economic Forum. Global Gender Gap Index."),
#     "spi"  => ("Expert", "Social Progress Index."),
#     "wui"  => ("Expert", "World Uncertainty Index."),
#     "opri" => ("Expert", "Ocean Policy Research Institute (2024)."),
#     "wgov" => ("Expert", "World Governance Project (Expert-coded)."),
#     "cai"  => ("Expert", "Coalitions and Institutions (Expert coding)."),
#     "qar"  => ("Expert", "Quality of Administrative Records (Expert)."),
#     "bicc" => ("Expert", "Bonn International Center for Conversion."),
#     "dr"   => ("Expert", "Democracy Ranking (Expert-coded)."),
#     "ibp"  => ("Expert", "International Budget Partnership. Open Budget Index."),
#     "ideaesd" => ("Expert", "International IDEA. Electoral System Design Database (de jure electoral system coding)."),
#     "diat"    => ("Expert", "Williams (2014). Dataset for Information and Accountability Transparency (global transparency/accountability indices)."),
#     "bci"     => ("Expert", "Standaert (2015). The Bayesian Corruption Index."),
#     "biu"     => ("Expert", "Fox (Religion and State Project / RAS)."),
#     "cses"    => ("Expert", "Comparative Study of Electoral Systems (CSES)."),
#     "prp"     => ("Expert", "Ouattara & Standaert (2020). Property Rights Protection Index (PRP)."),
#     "cspf"    => ("Expert", "Marshall & Elzinga-Marshall (2017). State Fragility Index and Matrix."),
#     "mibu"    => ("Expert", "Cingolani (2022). Multidimensional Index of Bureaucratic Underrepresentation (IBU)."),
# )

# --- 4. DIAGNOSTICS ---

function list_unmapped_summary(df)
    orphans = df[coalesce.(ismissing.(df.ht_region), false), :]
    if isempty(orphans) return nothing end
    return combine(groupby(orphans, [:ident_cname, :ident_ccode])) do sdf
        (Rows = nrow(sdf), Period = "$(minimum(sdf.ident_year)) - $(maximum(sdf.ident_year))")
    end
end

"""
    compare_slug_alignment(df_aug, manifest; strict=true)

Checks case-sensitive equivalence between:
- `names(df_aug)` (the dataset column slugs), and
- `manifest.Variable` (the manifest slugs).

Returns a NamedTuple:
- ok::Bool
- only_in_df::Vector{String}
- only_in_manifest::Vector{String}

If `strict=true` (default), throws an error when mismatches exist.
"""
function compare_slug_alignment(df_aug::DataFrame, manifest::DataFrame; strict::Bool=true)
    if !(:Variable in propertynames(manifest))
        error("Manifest must contain a `Variable` column.")
    end

    df_slugs = String.(names(df_aug))
    manifest_slugs = String.(manifest.Variable)

    # Optional: ensure each side is internally unique (helps catch upstream issues early)
    _assert_unique_names(df_slugs; context="df_aug column slugs")
    _assert_unique_names(manifest_slugs; context="manifest.Variable slugs")

    only_in_df = sort(collect(setdiff(Set(df_slugs), Set(manifest_slugs))))
    only_in_manifest = sort(collect(setdiff(Set(manifest_slugs), Set(df_slugs))))
    ok = isempty(only_in_df) && isempty(only_in_manifest)

    if strict && !ok
        msg = "Slug alignment failed (case-sensitive).\n" *
              "  - only_in_df ($(length(only_in_df))): $(only_in_df)\n" *
              "  - only_in_manifest ($(length(only_in_manifest))): $(only_in_manifest)"
        error(msg)
    end

    return (ok=ok, only_in_df=only_in_df, only_in_manifest=only_in_manifest)
end

