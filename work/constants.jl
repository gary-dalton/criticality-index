# ==============================================================================
# PROJECT-WIDE CONSTANTS
# ==============================================================================
#
# Global constants used across all phases. Loaded once by any phase loader.
# Modifying a const requires kernel restart.
#
# Usage:
#   include("constants.jl")
#
# ==============================================================================


# ==============================================================================
# TEMPORAL
# ==============================================================================

"""Earliest year included in analysis. Pre-1950 data has severe reporting bias
across all sources and predates the post-WWII institutional order (UN, Bretton
Woods, decolonization) that defines modern governance measurement."""
const TEMPORAL_FLOOR = 1950

"""Years of lag before a data source is considered inactive (accounts for
publication delay in most governance datasets)."""
const ACTIVE_LAG_YEARS = 3


# ==============================================================================
# COVERAGE THRESHOLDS
# ==============================================================================

"""Minimum population-weighted country coverage for the primary (global) slug tier."""
const GLOBAL_PENETRATION_UPPER_BOUND = 0.95

"""Minimum coverage for regional slug tier."""
const REGIONAL_PENETRATION_UPPER_BOUND = 0.80

"""Below this coverage, a slug is considered region-exclusive."""
const REGIONAL_PENETRATION_LOWER_BOUND = 0.10

"""Maximum regions a slug can exclude and still qualify as 'all but N'."""
const REGIONAL_EXCLUSION_TOLERANCE = 4

"""Total number of QoG regions."""
const TOTAL_REGIONS_COUNT = 10
