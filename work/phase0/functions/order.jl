"""
Checks if a specific slug is failing globally for a given year.
Returns true if > 30% of the Global Top 50 (by GDP) are missing data.
"""
function is_global_failure(df::DataFrame, slug::Symbol, year::Int, top_50_ccodes::Vector{String})
    # Filter for Top 50 countries in the specific year
    top_50_year = filter(row -> row.year == year && row.ccode in top_50_ccodes, df)
    
    if nrow(top_50_year) == 0 return false end
    
    missing_count = count(ismissing, top_50_year[!, slug])
    missing_ratio = missing_count / nrow(top_50_year)
    
    return missing_ratio > 0.30
end

"""
Calculates the Safety score contribution from Homicide rates.
Applies a 'Dark Lattice' penalty if data has been missing for 4+ years.
"""
function sensor_homicide(df_country::DataFrame, current_year::Int, global_fail::Bool)
    # Get the most recent available homicide data
    # We look back up to 4 years
    recent_data = filter(row -> row.year <= current_year && row.year > (current_year - 4), df_country)
    latest_val = findlast(!ismissing, recent_data.wdi_homs)
    
    if latest_val === nothing
        # If globally available but locally missing for 4 years: apply penalty
        # This reduces the 'Integrity' multiplier later in the loop.
        penalty = global_fail ? 1.0 : 0.85
        return (value = missing, multiplier = penalty)
    else
        # Normalize: Assuming 0-100 scale where 100 is 0 homicides
        # and 0 is 50+ homicides per 100k (Upper bound based on historical outliers)
        raw_val = recent_data.wdi_homs[latest_val]
        norm_val = clamp(100 - (raw_val * 2), 0, 100)
        return (value = norm_val, multiplier = 1.0)
    end
end

"""
Normalizes the Political Terror Scale (pts_avg).
PTS is 1 (Best) to 5 (Worst). We map this to 100-0.
"""
function sensor_pts(val)
    if ismissing(val) return missing end
    # Map: 1->100, 2->75, 3->50, 4->25, 5->0
    return 100 - ((val - 1) * 25)
end



"""
Normalizes V-Dem's Freedom from Peaceful Social Conflict.
V-Dem typically uses an interval scale (e.g., -5 to 5).
"""
function sensor_peasfrel(val, min_val, max_val)
    if ismissing(val) return missing end
    # Standard Min-Max normalization to 0-100
    return ((val - min_val) / (max_val - min_val)) * 100
end



"""
Logic Integration Note
In your main loop, you will call these and aggregate them into your Safety Score (\$O_{safety}\$). If sensor_homicide returns a multiplier of 0.85, that value will be passed downstream to the Integrity element of the lattice.
"""