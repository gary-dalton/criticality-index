# I Initializing Julia

We need to set up the following packages in Julia to work with everything we are planning on doing. The intent is to set this up to work equally well within a jupyter notebook or as a stand alone data exploration.

## Required Packages

| Package | Purpose |
|---------|---------|
| `HTTP`, `JSON` | Downloading QoG sources from URLs |
| `CSV` | Reading/writing CSV files |
| `Arrow`, `CodecZstd` | Efficient columnar storage format |
| `DataFrames` | Primary data structure |
| `StatsBase`, `Statistics` | Statistical operations |
| `ReadStatTables` | Reading Stata `.dta` files for metadata |
| `VegaLite`, `VegaDatasets` | Cartographic visualization |
| `Plots`, `StatsPlots` | General plotting |
| `PDFIO` | Extracting metadata from QoG codebook PDF |

```julia
import Pkg
Pkg.add(["HTTP", "JSON", "DataFrames"])
Pkg.add("CSV")
Pkg.add(["Arrow", "CodecZstd"])
Pkg.add(["StatsBase", "Statistics"])
Pkg.add("Plots")
Pkg.add("StatsPlots")
Pkg.add("ReadStatTables")
Pkg.add("StatFiles")
Pkg.add(["VegaLite", "VegaDatasets"])
Pkg.add("PDFIO")
```

## Jupyter Setup

If we are running this in **jupyter**, we can setup the kernel and notebook thusly,

```julia
using Revise
using InteractiveUtils
const PATH_AUGMENT_QOG_JL = "functions/qog_augmented_standard.jl"
const PATH_EXTRACT_QOG_JL = "functions/extract_qog.jl"
includet(PATH_AUGMENT_QOG_JL)   # functions for augmenting the data
includet(PATH_EXTRACT_QOG_JL)   # functions for extracting from PDF
```

This loads the files we need to run our functions and keeps the notebook reloading any changes to the files. 

> ⚠️ **Note:** Constants do not hot-reload with `Revise`. You must restart the kernel to pick up changes to `const` declarations.

## Standalone Script Setup

For non-notebook usage:

```julia
include("phase0/functions/qog_augmented_standard.jl")
include("phase0/functions/extract_qog.jl")
```

# II Acquiring the Quality of Governance Data

The datasets are available at [The QoG Institute](https://www.gu.se/en/quality-government). We use the **Standard Time Series** dataset as the primary source.

## Available Datasets

| Dataset | Format | Description |
|---------|--------|-------------|
| Cross-section | CSV | Single snapshot per country (latest available year) |
| Time-series | CSV | Panel data: country × year observations |
| Time-series | Stata (.dta) | Same as above, with embedded metadata |
| Codebook | PDF | Variable definitions, sources, citations |

**Direct URLs (January 2025 release):**

- [Cross section data, CSV](https://www.qogdata.pol.gu.se/data/qog_std_cs_jan25.csv)
- [Time series data, CSV](https://www.qogdata.pol.gu.se/data/qog_std_ts_jan25.csv)
- [Time series data, Stata](https://www.qogdata.pol.gu.se/data/qog_std_ts_jan25.dta)
- [Codebook, PDF](https://www.qogdata.pol.gu.se/data/codebook_std_jan25.pdf)

## Downloading Sources

The pipeline provides constants and a download function:

```julia
# Constants defined in qog_augmented_standard.jl
QOG_SOURCES      # Dict of source URLs
PATH_DATA_DIR    # Target directory for downloads
```

**Function:**

```julia
download_qog_sources(PATH_DATA_DIR, QOG_SOURCES)
```

**Behavior:**
- Downloads each URL to `PATH_DATA_DIR`
- Skips files that already exist (unless `force=true`)
- Reports download progress

**Example output:**
```
>>> Downloading QoG sources to ./data/
    ✓ qog_std_ts_jan25.csv (exists, skipping)
    ↓ qog_std_cs_jan25.csv ... done (12.3 MB)
    ✓ codebook_std_jan25.pdf (exists, skipping)
```

# III Converting and Extracting Metadata

## Why Arrow Format?

Arrow provides significant advantages over CSV:

| Aspect | CSV | Arrow |
|--------|-----|-------|
| Load time | ~15 seconds | ~0.5 seconds |
| Type inference | Every load | Stored in schema |
| Missing values | Ambiguous (`""`, `NA`, `null`) | Native `missing` |
| Compression | None | Zstd (70% smaller) |

## Converting CSV to Arrow

```julia
convert_csv_to_arrow(PATH_DATA_DIR, QOG_SOURCES)
```

**Behavior:**
- Converts each CSV referenced in `QOG_SOURCES` to Arrow format
- Lowercases all column names for consistency
- Skips conversion if Arrow file exists (unless `force=true`)
- Stores files alongside originals with `.arrow` extension

**Example output:**
```
>>> Converting CSV files to Arrow format
    ✓ qog_std_ts_jan25.arrow (exists, skipping)
    → qog_std_cs_jan25.csv ... done (2.1 MB → 0.6 MB)
```

## Generating Raw Metadata Manifest

Extract variable metadata from the Stata file (which contains embedded labels):

```julia
manifest = generate_raw_manifest(PATH_TS_STRATA_RAW)
```

**Returns:** DataFrame with columns:
- `slug` — variable name (lowercase)
- `label` — human-readable description from Stata
- `type` — data type

This manifest is later merged with metadata extracted from the PDF codebook.


# IV Preprocessing the Data


## Row Identity & Spine Integrity

### Overview

The QoG Augmented Standard pipeline transforms raw Quality of Government (QoG) data into a standardized format suitable for cross-national analysis. This section describes the core design decisions around **row identity**, **country code rescue**, and **collision handling**.

---

### 1. The `ggis_rowid` Principle

#### Problem

The natural spine of country-year data is typically `(ccode, year)`. However, QoG data contains:

- **Missing ccodes**: Historical entities (e.g., South Vietnam, Tibet) lack ISO-3166-1 numeric codes
- **Spine collisions**: After code rescue, some `(ccode, year)` pairs map to multiple rows (e.g., VNM and VDR both → 704 for overlapping years)
- **Blank rows**: Some observations have no ccode or year but may contain partial data

This means `(ident_ccode, ident_year)` **cannot serve as a unique key**.

#### Solution: Immutable Row Identity

At load time, every row receives a synthetic unique identifier:

```julia
df.ggis_rowid = 1:nrow(df)
```

**Properties of `ggis_rowid`:**

| Property | Guarantee |
|----------|-----------|
| **Uniqueness** | Always unique across all rows |
| **Immutability** | Assigned once at `load_raw_ident()`, never changes |
| **Stability** | Same source file always produces same rowids |
| **Independence** | Unaffected by ccode rescue or collision detection |

**Usage guidance:**

| Operation | Recommended Key |
|-----------|-----------------|
| Joins between pipeline stages | `ggis_rowid` |
| Grouping by country-year | `(ident_ccode, ident_year, ident_ccodealp)` |
| Aggregation by country | `ident_ccode` or `ident_ccodealp` |
| Filtering collisions | `ggis_spine_collision == true` |
| Human review | `ident_ccodealp` + `ident_year` |

---

### 2. Historical Country Code Rescue

#### Problem

QoG includes observations for historical or transitional entities that lack ISO-3166-1 numeric codes:

| Alpha Code | Entity | Issue |
|------------|--------|-------|
| VDR | South Vietnam | No ISO code; data ends 1975 |
| XTI | Tibet | No ISO code; historical data only |
| DEU | Germany | Unified 1990; pre-unification rows lack ccode |
| YEM | Yemen | Unified 1990; pre-unification rows lack ccode |
| ETH | Ethiopia | Pre-1993 rows (before Eritrea split) lack ccode |
| MHL | Marshall Islands | Missing ccode in source |
| SCG | Serbia and Montenegro | Dissolved 2006 |

#### Solution: `HISTORICAL_CCODE_MAP`

We maintain a curated mapping from Alpha-3 codes to ISO-3166-1 numeric codes:

```julia
const HISTORICAL_CCODE_MAP = Dict{String, Int}(
    "DEU" => 276,   # Germany (ISO: 276)
    "ETH" => 231,   # Ethiopia (ISO: 231)
    "MHL" => 584,   # Marshall Islands (ISO: 584)
    "SCG" => 688,   # Serbia and Montenegro → Serbia (ISO: 688)
    "YEM" => 887,   # Yemen (ISO: 887)
    "VNM" => 704,   # Vietnam (ISO: 704) — SUCCESSOR
    "VDR" => 704,   # South Vietnam → unified Vietnam — INTENTIONAL COLLISION
    "XTI" => 9156,  # Tibet (synthetic placeholder; no ISO code exists)
)
```

**Important distinctions:**

- Uses **ISO-3166-1** numeric codes (`ident_ccode`), NOT Correlates of War codes (`ident_ccodecow`)
- Synthetic codes (e.g., 9156 for Tibet) use the 9xxx range to avoid collision with real ISO codes
- Some mappings are **intentionally colliding** (VDR → 704 collides with VNM → 704)

#### Rescue Process

The `rescue_historical_ccodes()` function:

1. Scans rows where `ident_ccode` is missing
2. Looks up `ident_ccodealp` in `HISTORICAL_CCODE_MAP`
3. Fills in the ccode if found
4. Marks the row with `ggis_ccode_rescued = true`

```julia
df_rescued = rescue_historical_ccodes(df_ident; verbose=true)
```

**Output:**
```
>>> Historical Ccode Rescue:
    Missing before: 234
    Rescued: 234
    Missing after: 0
    Row count: 12391 (unchanged)
    By alpha code:
      ETH → 231: 47 rows
      YEM → 887: 44 rows
      DEU → 276: 42 rows
      ...
```

---

### 3. Spine Collision Handling

#### The Collision Problem

After rescue, some `(ident_ccode, ident_year)` pairs have multiple rows:

| ccode | year | Entities | Explanation |
|-------|------|----------|-------------|
| 704 | 1960 | VNM + VDR | Vietnam and South Vietnam both existed |
| 704 | 1970 | VNM + VDR | Overlapping sovereignty claims |

This is **historically accurate** — both entities existed and have separate data.

#### Design Decision: NO ROW DELETION

**We do not delete, merge, or resolve collisions by dropping rows.**

Rationale:

1. **Data fidelity**: Each row represents a distinct observation from QoG's source datasets
2. **Historical accuracy**: VNM and VDR are different political entities with different data
3. **Analytical flexibility**: Downstream users can choose how to handle overlaps
4. **Audit trail**: All original observations remain traceable

#### Collision Metadata

Instead of deleting, we **annotate** collisions:

```julia
df.ggis_spine_collision = true  # for rows involved in (ccode, year) duplicates
```

This allows downstream filtering without data loss:

```julia
# Option 1: Analyze only non-colliding rows
df_clean = filter(r -> !r.ggis_spine_collision, df)

# Option 2: Keep all rows, aware of duplicates
df_all = df  # use ggis_rowid for joins

# Option 3: Prefer successor states
df_successors = filter(r -> r.ident_ccodealp in COLLISION_PRIORITY_ALPHAS || !r.ggis_spine_collision, df)
```

#### Collision Priority (Informational Only)

For reporting and diagnostics, we define which entity is the "successor":

```julia
const COLLISION_PRIORITY_ALPHAS = ["VNM", "DEU", "YEM", "ETH", "SCG"]
```

This is used for:
- Diagnostic reports (showing which entity would "win" if merging)
- Optional downstream aggregation strategies
- **NOT** for automatic row deletion

---

### 4. Diagnostic Functions

#### `diagnose_spine_issues()`

Identifies rows with missing spine values:

```julia
issues = diagnose_spine_issues(df_ident; output_path="./data/spine_issues.csv")
```

**Categories:**

| Issue Type | Description |
|------------|-------------|
| `BLANK_ROW` | Missing ccode AND year, no other data |
| `MISSING_CCODE_ONLY` | Has year and other data, missing ccode |
| `MISSING_YEAR_ONLY` | Has ccode and other data, missing year |
| `MISSING_BOTH` | Missing ccode and year, but has other data |

#### `diagnose_ccode_collisions()`

Validates `HISTORICAL_CCODE_MAP` before applying:

```julia
collisions = diagnose_ccode_collisions(df_ident)
```

**Status codes:**

| Status | Meaning |
|--------|---------|
| `OK (same entity)` | Proposed mapping matches existing data |
| `OK (new ccode)` | Ccode not yet in data; safe to add |
| `⚠️ INTENTIONAL` | Collision expected; handled by priority |
| `❌ CONFLICT` | Would overwrite different country's data |

#### `preview_rescue_collisions()`

Shows what collisions would occur after rescue:

```julia
preview = preview_rescue_collisions(df_ident; show_years=true)
```

**Output:**
```
>>> RESCUE COLLISION PREVIEW (informational — NO rows will be deleted):
    Total (ccode, year) pairs with >1 row: 22

    By entity combination:
      VDR + VNM: 22 years (1955-1976)
        Years: 1955, 1956, 1957, ...

    NOTE: Use `ggis_rowid` as unique key, or (ident_ccode, ident_year, ident_ccodealp)
```

---

### 5. Column Reference

#### Identity Columns (`ident_` namespace)

| Column | Type | Description |
|--------|------|-------------|
| `ident_ccode` | `Int64?` | ISO-3166-1 numeric code (may be rescued) |
| `ident_ccodealp` | `String?` | ISO-3166-1 alpha-3 code |
| `ident_cname` | `String?` | Country name |
| `ident_year` | `Int64?` | Observation year |
| `ident_ccodecow` | `Int64?` | Correlates of War code (reference only) |

#### Operational Columns (`ggis_` namespace)

| Column | Type | Description |
|--------|------|-------------|
| `ggis_rowid` | `Int64` | Immutable unique row identifier |
| `ggis_ccode_rescued` | `Bool` | True if ccode was filled from `HISTORICAL_CCODE_MAP` |
| `ggis_spine_collision` | `Bool` | True if row shares `(ccode, year)` with another row |
| `ggis_region` | `Int64?` | Standardized region (copied from `ht_region`, with imputation) |
| `ggis_isvalid` | `Int8` | Validity flag (1 if ccode exists, 0 otherwise) |

#### Anchor Column

| Column | Type | Description |
|--------|------|-------------|
| `ht_region` | `Int64?` | QoG regional classification (1-10) |

---

### 6. Standard Pipeline Workflow

```julia
# 1. Load with rowid assignment
df_ident = load_raw_ident(PATH_TS_RAW)

# 2. Diagnose spine issues (informational)
issues = diagnose_spine_issues(df_ident)

# 3. Check proposed rescue mappings for conflicts
collisions = diagnose_ccode_collisions(df_ident)

# 4. Preview what collisions will occur
preview = preview_rescue_collisions(df_ident)

# 5. Rescue historical ccodes (no rows deleted)
df_rescued = rescue_historical_ccodes(df_ident; verbose=true)

# 6. Standardize regions
df_regions = standardize_regions(df_rescued; verbose=true)

# 7. List any orphans (no region assigned)
orphans = list_region_orphans(df_regions)

# Verify: row count unchanged throughout
@assert nrow(df_regions) == nrow(df_ident)
```

---

### 7. Design Principles Summary

| Principle | Implementation |
|-----------|----------------|
| **Row preservation** | No function deletes rows; `nrow()` is invariant |
| **Immutable identity** | `ggis_rowid` assigned once, never modified |
| **Explicit metadata** | Collisions flagged, not resolved silently |
| **ISO-3166-1 primacy** | `ident_ccode` uses ISO standard, not COW |
| **Non-mutating transforms** | All functions return new DataFrames |
| **Diagnostic transparency** | Issues are reported, not hidden |

---

### 8. Appendix: ISO-3166-1 vs COW Codes

Common confusion point — these are different numbering systems:

| Country | ISO-3166-1 (`ident_ccode`) | COW (`ident_ccodecow`) |
|---------|----------------------------|------------------------|
| Germany | 276 | 255 |
| Ethiopia | 231 | 530 |
| Singapore | 702 | 830 |
| Vietnam | 704 | 816 |
| Yemen | 887 | 679 |
| Marshall Islands | 584 | 983 |

**Always use ISO-3166-1 for `HISTORICAL_CCODE_MAP`.**

---

## Region Assignment Reference

Here we describe how regional classifications are assigned and maintained in the QoG Augmented Standard pipeline.

---

### 1. QoG Native Region Codes (`ht_region`)

The QoG dataset uses a 10-region taxonomy stored in the `ht_region` column:

| Code | Region |
|------|--------|
| 1 | Eastern Europe & post-Soviet Union (including Central Asia) |
| 2 | Latin America (including Cuba, Haiti & Dominican Republic) |
| 3 | North Africa & Middle East (including Israel, Turkey & Cyprus) |
| 4 | Sub-Saharan Africa |
| 5 | Western Europe & North America (including Australia & New Zealand) |
| 6 | East Asia (including Japan & Mongolia) |
| 7 | Southeast Asia |
| 8 | South Asia |
| 9 | The Pacific (excluding Australia & New Zealand) |
| 10 | The Caribbean |

---

### 2. Region Imputation Pipeline

The `standardize_regions()` function creates `ggis_region` through a three-stage imputation:

#### Stage 1: Copy from `ht_region`
If the row already has `ht_region`, copy it directly.

#### Stage 2: Impute from same `ident_ccode`
For rows missing region but having a valid `ident_ccode`, look up other rows with the same ccode and borrow their region.

#### Stage 3: Fallback to `RESCUED_ENTITY_REGIONS`
For rescued historical entities that still lack a region, use the constant mapping.

Region assignments for historical entities rescued via `HISTORICAL_CCODE_MAP` that may lack `ht_region` in the source data.

| Alpha | Region | Entity |
|-------|--------|--------|
| `VDR` | 7 | South Vietnam → Southeast Asia |
| `XTI` | 6 | Tibet → East Asia |
| `TIB` | 6 | Tibet (alternate alpha) → East Asia |
| `DDR` | 1 | East Germany → Eastern Europe |
| `CSK` | 1 | Czechoslovakia → Eastern Europe |
| `SCG` | 1 | Serbia and Montenegro → Eastern Europe |
| `YMD` | 3 | Yemen Democratic (South) → MENA |
| `SUN` | 1 | USSR → Eastern Europe |

---

### 3. `CARTOGRAPHIC_TERRITORIES` Constant

Non-QoG territories needed for complete world map rendering. These entities do **not** exist in QoG data and are used only for cartographic visualization.

| ccode | Alpha | Region | Territory |
|-------|-------|--------|-----------|
| 238 | `FLK` | 5 | Falkland Islands |
| 260 | `ATF` | 5 | French Southern Territories |
| 275 | `PSE` | 3 | Palestine |
| 304 | `GRL` | 5 | Greenland |
| 540 | `NCL` | 5 | New Caledonia |
| 630 | `PRI` | 5 | Puerto Rico |
| 732 | `ESH` | 3 | Western Sahara |

#### Administrative Alignment Principle

Dependent territories inherit their **administering country's** regional classification, not their geographic location:

- **French territories** (ATF, NCL) → Region 5 (France)
- **US territories** (PRI) → Region 5 (USA)  
- **UK territories** (FLK) → Region 5 (UK)
- **Danish territories** (GRL) → Region 5 (Denmark)

This ensures consistency with QoG's methodology where dependent territories report with their administering state.

---

### 4. Usage Examples

#### Standard Pipeline
```julia
df = load_raw_ident(PATH_TS_RAW)
df = rescue_historical_ccodes(df; verbose=true)
df = standardize_regions(df; verbose=true)

# Check for entities without region assignment
orphans = list_region_orphans(df)
```

#### Adding a New Rescued Entity Region
```julia
# In qog_augmented_standard.jl, add to RESCUED_ENTITY_REGIONS:
const RESCUED_ENTITY_REGIONS = Dict{String, Int}(
    # ...existing entries...
    "NEW" => 4,   # New Entity → Sub-Saharan Africa
)
```

#### Adding a New Cartographic Territory
```julia
# In qog_augmented_standard.jl, add to CARTOGRAPHIC_TERRITORIES:
const CARTOGRAPHIC_TERRITORIES = [
    # ...existing entries...
    (999, "NEW", 5, "New Territory"),  # (ccode, alpha, region, name)
]
```


# Preprocessing the Variable Names

# Extracting and Augmenting Slugs and Prefixes

## 1. Methodological Overview

The process transforms the human-readable QoG Codebook PDF into two machine-readable CSV files: one detailing data sources (`prefixes`) and another for individual variables (`slugs`). The primary objective is to augment the raw metadata with a critical classification layer: **provenance**. This layer categorizes each data point according to its epistemological origin—how the number came to be. This is achieved through a two-phase extraction process, employing a state machine for text parsing and a rule-based heuristic cascade for classification.

## 2. Two-Phase Extraction Process

Extraction is performed sequentially to build a complete and context-aware dataset.

### Phase 1: Prefix & Datasource Extraction (`extract_qog_prefix`)

This phase targets Section 4 of the codebook, which describes each original data source.

*   **Objective:** To create a canonical record for each data provider (e.g., World Bank, V-Dem) and classify its general data type.
*   **Methodology:**
    1.  A state machine parses the PDF text line-by-line.
    2.  It identifies the start of a new data source section using the `4.x <Datasource Name>` pattern.
    3.  It captures key metadata fields: `Datasource`, `Source_Name`, `Citation`, and `Last_Update` by matching specific trigger phrases (e.g., "Dataset by:", "suggested citation for this dataset is:").
    4.  The full description block, starting from "Date of download:", is captured for classification purposes.
    5.  The process "locks" and writes a record for the datasource upon encountering the *first* `QoG Code:` for that section. The substring before the first underscore in this code (e.g., `vdem` from `vdem_libdem`) is inferred as the unique `prefix`.
    6.  The full extracted description is used to assign a `provenance` classification to the entire prefix.

### Phase 2: Slug & Variable Extraction (`extract_qog_slugs`)

This phase parses the main body of the codebook to extract metadata for every individual variable.

*   **Objective:** To create a detailed record for each variable (`slug`) and assign it the most specific provenance classification possible.
*   **Methodology:**
    1.  A similar state machine scans the entire document.
    2.  It identifies the start of a new variable block by matching the `QoG Code: <slug_name>` pattern.
    3.  It captures the full, multi-line description until it encounters the `Type of variable: <type>` line, which signals the end of the block.
    4.  A two-tiered classification strategy is employed:
        *   **Tier 1 (Slug-Specific):** The `provenance` is first determined using the slug's *own full description*. This allows for overrides where a specific variable's nature differs from its source's general classification (e.g., a `PHYSICAL` variable like land area from an `OFFICIAL` source like the World Bank).
        *   **Tier 2 (Prefix Fallback):** If the slug-specific classification results in `UNCERTAIN`, the system falls back to the pre-determined `provenance` of its `prefix` from the Phase 1 output. This ensures maximal classification coverage.
    5.  The final description stored in the output CSV is a truncated version representing only the first paragraph, extracted via heuristics in the `extract_first_paragraph` function.

## 3. Provenance Classification: The Heuristic Cascade

Classification is the core augmentation step, executed by the `classify_provenance` function. It uses a strict priority cascade (a series of `if`/`elseif` checks) where the first positive match determines the category. This resolves conflicts by prioritizing the nature of the data over its publisher. The text from the `source_name` and `description` fields is scanned for keywords and patterns.

The cascade is executed in the following, non-negotiable order:

1.  **`PHYSICAL`**: Data representing immutable or slowly changing geospatial, environmental, or demographic realities.
    *   **Rationale:** These are topological constraints on the system.
    *   **Triggers:** `geograph`, `land area`, `climate`, `satellite`, `population`.

2.  **`SURVEY`**: Data from mass public opinion polls or household surveys. Critically, it includes an exclusion rule to avoid misclassifying expert surveys.
    *   **Rationale:** Measures the "temperature" or state of individual agents.
    *   **Triggers:** `public opinion`, `household`, `respondent`, `afrobarometer`, `world values survey`.
    *   **Exclusion:** `expert survey`.

3.  **`EVENT/FACTUAL`**: Discrete, objective, and countable occurrences or biographical facts.
    *   **Rationale:** Represents forensic records of state changes or system events.
    *   **Triggers:** `conflict`, `coup`, `battle death`, `election date`, `cabinet`, `ucdp`.

4.  **`IMPUTED`**: Data generated via academic modeling, historical reconstruction, interpolation, or simulation.
    *   **Rationale:** Identifies data that is not directly observed but is instead a product of a model, carrying specific error properties.
    *   **Triggers:** `reconstruct`, `historical`, `interpolation`, `maddison`, `penn world table`.

5.  **`EXPERT`**: Indices, scores, or ratings generated by subject-matter experts assessing latent concepts.
    *   **Rationale:** Captures high-level, abstract system parameters that are not directly measurable.
    *   **Triggers:** `expert`, `assessment`, `score`, `index`, `v-dem`, `freedom house`, `polity`.

6.  **`OFFICIAL`**: Default category for administrative statistics reported by states or IGOs.
    *   **Rationale:** Standard governmental bookkeeping. This is the baseline category if none of the more specific, higher-priority conditions are met.
    *   **Triggers:** `world bank`, `imf`, `oecd`, `census`, `gdp`, `tax revenue`.

7.  **`PROVENANCE_OVERRIDES`**: A final manual lookup table is checked if the heuristic cascade fails to produce a classification (`UNCERTAIN`). This dictionary provides definitive classifications for known ambiguous prefixes.

## 4. Output Data Fields

The process generates two primary CSV files with the following key fields:

| Field | Source | Description |
| :--- | :--- | :--- |
| `prefix` | Prefixes/Slugs | The unique, lowercase identifier for the data source (e.g., `wdi`). |
| `datasource` | Prefixes | The full name of the data source as listed in the codebook (e.g., "World Development Indicators"). |
| `source_name` | Prefixes | The name of the institution or entity that produced the data (e.g., "World Bank"). |
| `citation` | Prefixes | The suggested citation for the original dataset. |
| `last_update` | Prefixes | The last update date reported by the original source. |
| `description` | Prefixes/Slugs | A descriptive text. For prefixes, it's the full source description. For slugs, it's the truncated first paragraph of the variable description. |
| `provenance` | Prefixes/Slugs | The assigned classification category (e.g., `PHYSICAL`, `EXPERT`). |
| `slug` | Slugs | The unique, lowercase identifier for the specific variable (e.g., `wdi_gdp`). |
| `type` | Slugs | The data type of the variable (e.g., `numeric`, `categorical`). |


## Note on slug -- prefix classification disagreement

Relying solely on the prefix classification leads to a "Parent-Source Bias," where administrative data is mistaken for expert opinion or vice-versa. Our resultant ~25% disagreement rate proves that the slug-level audit is necessary to ensure that a PHYSICAL variable isn't being modeled as if it were a SURVEY perception. These findings are highly consistent with the warnings found in the codebook's metadata.





# Selecting Slug Groups









# Section 1: Prefix Schema for the World Graph Data Model

This project uses a strict prefix schema to enforce namespace integrity, auditability, and clear separation between identity, operational logic, and observational data.

---

### 1. The `ident_` Prefix — Topological Coordinates

**Category:** Identity / Dimensions  
**Classification:** Global (G)

The `ident_` prefix is reserved for the Identification Variables defined in Section 3 of the Quality of Government (QoG) Codebook. These variables represent the *“Where”* and *“When”* of the model.

**Purpose:**  
To isolate the coordinate system from the data mass.

**Engineering Benefit:**  
Prevents `ArgumentError: Duplicate variable names` during joins. By renaming raw keys (such as `ccode`) to `ident_ccode` immediately upon ingestion, a protected namespace is created that external data sources cannot overwrite.

**Audit Logic:**  
Any column with this prefix is a **Dimension**, not a Measurement. It is used for grouping and merging, never for calculating indices.

**Protected Keys:**  
`ident_cname`, `ident_ccode`, `ident_ccodealp`, `ident_year`, etc.

---

### 2. The `ggis_` Prefix — Operational Intelligence

**Category:** Custom Logic / Quality Control  
**Classification:** Global (G)

The `ggis_` prefix identifies variables, flags, and indices created specifically for this project’s internal methodology.

**Purpose:**  
To distinguish original research and data-cleaning logic from source-provider data (e.g., World Bank, V-Dem).

**Engineering Benefit:**  
Provides instant scannability of project-specific metrics.  
Example:  
`select(df, StartsWith("ggis_"))` immediately reveals validity gates and criticality scores generated by internal functions.

**Audit Logic:**  
These are **Operational Gates**. For example, `ggis_isvalid` acts as a binary switch determining whether a ident_ccode is considered as existing during a given ident_year.

---

### 3. The `[source]_` Prefix — Analytical Sensors

**Category:** Observations / Measurements  
**Classification:** Global / Regional / Hybrid (Requires Audit)

Any variable that does not establish identity or operational logic belongs to its institutional source prefix (e.g., `wdi_`, `vdem_`, `who_`).

**Purpose:**  
To preserve data provenance.

**Audit Logic:**  
These variables are subjected to the Global / Regional / Hybrid fidelity audit. Unlike `ident_` variables, they are expected to exhibit **signal decay** depending on region and sampling frame.

---

### Summary: Triple-Tier Schema

| Prefix | Tier | Functional Role | Data Type |
|--------|------|-----------------|-----------|
| `ident_` | Identity | World Graph Coordinates | Categorical / String / ID |
| `ggis_` | Operational | Internal Logic & Quality Gates | Boolean / Index / Float |
| `[source]_` | Analytical | Source-Provided Observations | Measurement / Sensor Data |

---

### Note on `ht_region`

Per system requirements, the politico-geographic region variable **`ht_region` remains prefix-free**.

It acts as the primary **Anchor Cluster** between the Identity layer and the Analytical layer.


---
---


# Section 2: Logical Path-Dependency

This document preserves the **Path-Dependency rules** that are often lost in raw code comments. These rules define the structural logic required to maintain a coherent world-graph topology.

---

## I. The Structural Layers

The engineering process follows a **strict hierarchy**.  
If this order is violated, *Ghost Nodes* (such as Chile `152` or Sudan `729`) will fail to find their regional coordinates.

---

### Layer 1: Identity Promotion (`load_raw_ident`)

**Goal:**  
Move standard identity variables into the protected `ident_` namespace.

**Rule:**  
This function **must be the entry point**.  
All downstream functions assume the existence of `:ident_year` and `:ident_ccode`.

**Failure Mode:**  
If skipped or delayed, analytical joins will silently misalign identity keys.

---

### Layer 2: Regional Reconciliation (`load_qog`)

**The Native Eviction Rule:**  
The raw Arrow source frequently contains a legacy `ht_region` field.  
This field **must be dropped** before joining the Master Lookup table.  
If not removed, Julia will raise a **duplicate column name** error during joins.

**The Numeric Lock:**  
All joins are performed on `:ident_ccode` cast to `Int64`.  
This prevents failures caused by linguistic drift in country names and guarantees alignment across historical and modern entities.

### ⚠️ Crucial: The Three-Value Logic Rule
Because the dataset contains `missing` values, standard filtering like `df[df.var .== value, :]` will fail with an `ArgumentError`. 

**Always wrap logical filters in `coalesce`:**
`df_clean = df[coalesce.(df.ident_ccode .== 729, false), :]`

---

### Layer 3: Topological Auditing (`audit_prefix_fidelity`)

**Role:** Measures how completely a given data-prefix covers the regional and world graph.

**The Temporal Snapshot Rule:**  
Sensors that have a defined `death_year` (for example, `aid` ending in 2013) must be audited at their terminal year.  
Auditing them at the 2018 baseline would incorrectly classify them as low-fidelity.

**Purpose:**  
Ensures accurate classification of Global / Regional / Hybrid sensor coverage.

---
---

## II. The Structural Workflow (Path-Dependency)

To maintain the integrity of the **Augmented Standard**, the refinery must follow these steps **in strict order**:

---

### 1. Ingestion  
**Promote native variables to the `ident_` namespace immediately.**  
This establishes the protected identity layer required for all downstream operations.

---

### 2. Eviction  
**Drop the native `ht_region` from the Arrow source file.**  
The embedded version is historically incomplete and will cause duplicate-column conflicts during reconstruction.

---

### 3. Regional Reconstruction  
**Join the `country_region_lookup` using numeric `ident_ccode` keys.**  
This step restores regional coordinates for *Ghost Entities* such as Sudan (`729`) and Chile (`152`) that would otherwise fail to resolve.

---

### 4. Temporal Auditing  
**When generating the Fidelity Registry, check the `death_year` of each prefix.**  
A sensor is evaluated based on its operational lifespan, not its presence in the 2018 baseline.

---

## Workflow Invariant

Violating this sequence breaks topological consistency in the Augmented Standard.

# Section 3: Integrity Verification

Once the **Augmented Standard** is loaded, the following diagnostics must be run to confirm structural alignment:

1. **Regional Saturation Check:** Run `list_unmapped_summary(df_std)`.  
   *Acceptance Criteria:* The output should be `nothing`. Any rows appearing here indicate a failure in the numeric join key (Layer 2).

2. **Temporal Decay Check:** Audit a historical sensor (e.g., `aid`).  
   *Acceptance Criteria:* The snapshot year should reflect the death year from the manifest. If the snapshot is 2018 for a dead sensor, Layer 3 logic has regressed.

3. **Namespace Collision Check:** `names(df_std)` should not contain raw `ccode`, `cname`, or `year`. All identity variables must carry the `ident_` prefix.
