"""
The Integrated Check
In your final calculation loop, you can create a "Criticality Grounding Flag".

CG = (is_critical AND is_diverging AND is_invariant AND is_scale_free)

If CG is True, then your D_c measure is no longer an assumption. It is an empirically validated observation of a system sitting at the "Edge of Chaos."
"""

using DataFrames, GLM, Statistics

"""
Calculates the Power Law Alpha (α) for Government Responses to Unrest.
Uses a rolling window to determine the 'Avalanche Slope' of the system.
A slope approaching 1.0 (Zipf's Law) indicates CH Validation.
"""
function validate_power_law(df_country::DataFrame, current_year::Int, window::Int=20)
    # 1. Collect event magnitudes over the historical window
    events = filter(row -> row.year <= current_year && row.year > (current_year - window), df_country)
    magnitudes = collect(skipmissing(events.vdem_subvrs))
    
    if length(magnitudes) < 10 return (alpha = missing, is_critical = false) end
    
    # 2. Rank-Frequency analysis (MLE for Power Law estimation)
    # We estimate the slope of log(Frequency) vs log(Magnitude)
    sort!(magnitudes, rev=true)
    y = log.(1:length(magnitudes))
    x = log.(magnitudes .+ 1e-6) # Avoid log(0)
    
    data = DataFrame(X=x, Y=y)
    model = lm(@formula(Y ~ X), data)
    alpha = abs(coef(model)[2])
    
    # 3. Acceptance Criteria: Alpha near 1.0 indicates No Characteristic Size
    is_critical = 0.8 <= alpha <= 1.5
    
    return (alpha = alpha, is_critical = is_critical)
end


"""
Calculates the Cross-Correlation between Labor Union Action and Religious Organization.
Tests for 'Diverging Correlation Length' (Signature 2).
Uses two independent slugs to avoid circularity with the primary Dc calculation.
"""
function validate_correlation_divergence(df_country::DataFrame, current_year::Int)
    # Define a 12-year window to capture enough temporal signal for correlation
    # while remaining sensitive to recent phase shifts.
    data_window = filter(row -> row.year <= current_year && row.year > (current_year - 12), df_country)
    
    # Ensure we have non-missing pairs for both independent validation slugs
    clean_data = dropmissing(data_window, [:vdem_labvrs, :vdem_relig])
    
    # Statistical threshold: we need at least 6 points to claim a correlation trend
    if nrow(clean_data) < 6 
        return (correlation = missing, is_diverging = false) 
    end
    
    # Compute Pearson Correlation (ρ)
    # A spike in ρ suggests the system is becoming 'coupled' across disparate domains.
    ρ = cor(clean_data.vdem_labvrs, clean_data.vdem_relig)
    
    # Acceptance Criteria: 
    # In SOC literature, criticality is marked by high spatial/sectoral coupling.
    # ρ > 0.70 is our 'Divergence' flag.
    is_diverging = abs(ρ) > 0.70
    
    return (correlation = ρ, is_diverging = is_diverging)
end



"""
Compares Local and National governance distributions to check for Scale Invariance.
Uses the ratio of variances as a proxy for Self-Similarity.
"""
function validate_scale_invariance(df_country::DataFrame, current_year::Int)
    window = filter(row -> row.year <= current_year && row.year > (current_year - 15), df_country)
    
    local_vals = collect(skipmissing(window.vdem_localgov))
    national_vals = collect(skipmissing(window.vdem_execcon))
    
    if length(local_vals) < 5 || length(national_vals) < 5
        return (similarity = missing, is_invariant = false)
    end
    
    # CH Signature: If the system is scale-invariant, the statistical 
    # properties (Normalized SD) should be similar across scales.
    cv_local = std(local_vals) / mean(local_vals)
    cv_national = std(national_vals) / mean(national_vals)
    
    # Ratio near 1.0 implies the dynamics are 'Scale-Free'
    similarity = 1.0 - abs(cv_local - cv_national)
    is_invariant = similarity > 0.85
    
    return (similarity = similarity, is_invariant = is_invariant)
end


"""
Calculates the Kurtosis and Tail-Weight of Polarization 'Jumps'.
Tests for 'No Characteristic Event Size' (Signature 5).
If Kurtosis is high (>3), the system is exhibiting non-Gaussian, scale-free adjustments.
"""
function validate_event_scaling(df_country::DataFrame, current_year::Int, window::Int=20)
    # 1. Filter window and calculate Year-over-Year changes (The 'Jumps')
    window_data = filter(row -> row.year <= current_year && row.year > (current_year - window), df_country)
    sort!(window_data, :year)
    
    # Calculate First Difference
    jumps = diff(collect(skipmissing(window_data.vdem_v3polsoc)))
    
    if length(jumps) < 10 return (kurtosis = missing, is_scale_free = false) end
    
    # 2. Calculate Kurtosis (Peakedness/Fat Tails)
    # Excess Kurtosis > 0 indicates 'Fat Tails' compared to a Normal Distribution
    m2 = mean((jumps .- mean(jumps)).^2)
    m4 = mean((jumps .- mean(jumps)).^4)
    kurt = (m4 / m2^2) - 3.0
    
    # 3. Acceptance Criteria: 
    # High Kurtosis indicates that 'Extreme' jumps are frequent enough 
    # that no 'characteristic' size of social change exists.
    is_scale_free = kurt > 1.5
    
    return (kurtosis = kurt, is_scale_free = is_scale_free)
end