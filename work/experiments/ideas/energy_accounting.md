# Energy Accounting in SOC Models — Beyond Mass Conservation

## Status

Current simulator instrumentation (01.01 BTW, 01.02 Manna) tracks **mass conservation**: grain count in, grain count out, plus the scalar `n_dissipated` per avalanche. This is one dimension of energy accounting and sufficient for validating the power-law / universality-class signatures. It is **not sufficient** for:

- Model C (full overtopping with σ field) — damage is driven by local kinetic energy, not by mass flux
- Percolation experiments — dissipation and accumulation depend on cluster topology, not a fixed perimeter
- Coupled-SOC experiments — one system's outflow becomes the other's inflow; rates and locations matter

This doc specifies the full energy accounting so when we get to those experiments the instrumentation knows what to record and the interpretation is consistent.

## Two reservoirs

The overtopping framework makes explicit that the system stores energy in **two reservoirs** with distinct physics:

| Reservoir | State variable | Physical analogue |
|-----------|---------------|-------------------|
| **Grain reservoir** | `z_i(t)` — height field | Water behind a dam; stress on a fault; accumulated charge |
| **Structural reservoir** | `σ_i(t) ∈ [0,1]` — integrity field | Dam wall integrity; fault asperity strength; synaptic plasticity |

For plain BTW / Manna (01.01, 01.02) the structural reservoir is absent — equivalent to σ ≡ 1 permanently. For Model B (threshold elevation), σ ≡ 1 still but threshold is elevated (no dynamics yet). For Model C (overtopping) and beyond, σ is dynamic and the full accounting matters.

## Potential energy

**Grain PE.** Each grain at stack height `h` within a site carries PE = `h` (unit grain weight, unit spacing, gravitational analogue). Total:

```
PE_grain = Σᵢ h=0 to z_i−1 h = Σᵢ z_i(z_i−1)/2
```

Grain-drop increment at site k: `ΔPE_grain = z_k` (new grain lands at height z_k; proof: Δ[z(z−1)/2] = z when z→z+1).

This is the **quadratic** convention — captures stress concentration. The trivial linear convention `PE = Σ z_i = mass` collapses back to mass accounting and is uninformative.

**Structural PE.** Energy stored in the elevated threshold. Natural choices:

```
PE_struct = T · Σᵢ σ_i             (linear in σ; "how much threshold is available")
PE_struct = T · Σᵢ σ_i² / 2        (quadratic; strain-like)
```

Linear is simpler; quadratic captures the nonlinearity that small-σ sites release energy faster.

**Total PE:** `PE(t) = PE_grain(t) + PE_struct(t)`.

## Kinetic energy

In an overdamped sandpile, KE is transient and zero between avalanches. During an avalanche:

```
KE(t) = n_in_wave(t)        ← grains currently in motion
KE_avalanche = ∫ KE(t) dt ≈ avalanche size
```

Per-site, the analogue is `n_topples_i` during one avalanche — the number of topplings at site `i`. This is the **local KE** that the overtopping damage rule already computes internally (`if n_topples_i > E_crit: damage`).

## Dissipated energy

Two channels:

| Channel | What's lost | Per-event quantity |
|---------|-------------|--------------------|
| **Grain dissipation** | Mass + its PE | DE_grain_event = z_i (height of toppling site when grain went OOB) |
| **Structural dissipation** | Structural PE | DE_struct_event = T · σ_i · α (energy released by σ_i → σ_i·(1−α)) |

Current code tracks the *count* of grain dissipation events (`n_dissipated`) but not the energy per event. Adding per-event `z_i` at dissipation is a small instrumentation addition (one extra accumulator in `run_avalanche!`).

## Balance equation

Over any time window:

```
E_in_grain + E_in_struct = ΔPE_grain + ΔPE_struct + DE_grain + DE_struct
```

Where:
- **E_in_grain:** Σ over grain drops of `z_k` at arrival site
- **E_in_struct:** Σ over timesteps of `Σᵢ (1 − σ_i) · recovery_rate` (slow repair inflow from environment)
- **ΔPE:** difference of stored PE between start and end of window
- **DE:** dissipated energy summed over events

In steady state `⟨ΔPE⟩ = 0` and the balance reduces to `⟨E_in⟩ = ⟨DE⟩`, the energy analogue of mass conservation.

## KE as coupling channel

The **only** way the two reservoirs interact is through KE:

```
local KE (n_topples_i) > E_crit   ⇒   σ_i ← σ_i·(1−α)   ⇒   ΔPE_struct
```

Without measuring per-site KE, you cannot explain why σ changed the way it did. This is why the overtopping simulator must expose `n_topples_i` per avalanche — not just globally via `wave_profile`. The instrumentation cost is one extra `L² × Int32` buffer zeroed per avalanche, recording peak per-site topple count during the cascade.

## Percolation extension

On a percolation substrate both reservoirs acquire topology-dependence:

**Grain reservoir:**
- Capacity bounded by reachable cluster mass, not by L²·z_c
- PE_grain distribution has heavy tails near p_c (cluster-size distribution is power-law)
- Dissipation surface is the *perimeter of the occupied cluster*, not the lattice edge

**Structural reservoir:**
- Each **bond** has a `σ_ij` (not just each site)
- Bond damage from flux can disconnect clusters — percolation topology becomes dynamic
- Spanning-cluster dissipation (DE_struct): when a bond fails, the cluster it connected may fragment; the disconnected piece's stored PE becomes inaccessible → a structural dissipation event

**Natural per-bond measurements:**

| Quantity | What it gives |
|----------|---------------|
| Flux through bond `(i,j)` during recording | Kirchhoff-current analogue; reveals conductance distribution |
| Time-integrated flux per bond | Damage driver |
| `σ_ij(t)` trajectory | Dynamic topology evolution |
| Spanning-cluster mass over time | System-level PE stock |
| Bond-failure events with timestamps | DE_struct events; cascading percolation failure |

## Activation-energy connection

The architecture's activation floor (§5.5) is defined in energy terms: below some driving level, accumulated PE cannot cross the threshold required to trigger spanning cascades. On a percolation lattice this reads:

- Below p* — no spanning cluster; PE stock bounded per cluster; cascades cannot reach system scale
- Above p* — spanning cluster exists; PE can accumulate to arbitrary size; SOC becomes possible
- Activation energy = minimum PE required for a spanning cascade on the *current* cluster structure (time-dependent if σ_ij dynamics are active)

This gives a quantitative definition of "activation energy" that reduces to a measurable quantity once the percolation instrumentation is in place.

## What to instrument and when

| When | Addition | Cost |
|------|----------|------|
| Model C build (01.03) | Per-site `n_topples_i` per avalanche | L² Int32 per avalanche, compressible; needed for damage rule anyway |
| Model C build (01.03) | Per-avalanche `DE_grain` via `Σ z_i_at_dissipation` | 1 Int per avalanche, trivial |
| Model C build (01.03) | PE snapshots at burn-in trace intervals | Cheap; two scalars (PE_grain, PE_struct) |
| Percolation (03) | Per-bond flux counter | 2·L² Int32 buffer for 2D square; larger for higher-connectivity graphs |
| Percolation (03) | σ_ij snapshots | Same size as per-bond flux |
| Coupled SOC (04) | Per-site-of-origin dissipation vector | Replaces scalar n_dissipated; sparse representation |

Each stage adds the minimum needed for that experiment's interpretation. Nothing needs to be retrofitted to 01.01/01.02.

## Related documents

- `overtopping.md` — defines σ, damage rule, recovery rule
- `../validation/01_03_manna_overtopping.md` — Model B/C/D experiment design
- `../validation/03_activation_threshold.md` — percolation-substrate experiment
- `../validation/04_absorbing_barrier.md` — where structural collapse becomes absorbing
- `energy_depletion_percolation_research_paths.md` — literature-mapping for the p_c-as-termination proposition
