# SOC Model Architecture

**Status:** Defined 2026-03-23. Approved.
**Approach:** Derived from Self-Organized Criticality (SOC) first principles. Deterministic — no stochastic components.

---

## 1. Theoretical Foundation

### 1.1 Self-Organized Criticality (SOC): The Sandpile

Imagine dropping grains of sand, one at a time, onto a flat table. This simple experiment — formalized by Bak, Tang, and Wiesenfeld (1987) — reveals how systems organize themselves to the edge of breakdown, because that is where they are most capable.

**The slow build.** Grains arrive one at a time, slowly enough that the pile can react to each. These are the small, constant pressures any system faces — demands, inputs, perturbations.

**The local limit.** Every spot on the pile has a threshold. When a site gets too steep, it topples — spilling its excess onto its nearest neighbors. The stress doesn't vanish; it becomes the neighbors' problem. This is how perturbations propagate through connected systems.

**The escape valve.** Sand only leaves the system when it reaches the edge of the table and falls off. This boundary dissipation is what prevents the pile from growing forever. Without it, energy accumulates without limit.

**The critical state.** Eventually, the pile reaches a specific shape — not too flat, not a vertical spike. It has tuned itself, without any external controller, to a **critical slope**. This is Self-Organized Criticality.

In this state, the pile is **poised**:

- **Sensitive** — a single grain might do nothing, or it might trigger a cascade that reshapes the entire pile. Avalanche sizes follow a power-law distribution: many small, few large, no characteristic scale.
- **Maximally connected** — because every site is near its threshold, a topple anywhere can propagate everywhere. The system "knows" about its whole self. A grain dropped on the left can eventually cause a fall on the right.
- **Maximally capable** — the system explores its full configuration space. It can respond to perturbations at any scale, processing information from the smallest local adjustment to the largest system-wide reorganization.

This is not metaphor. The mathematics of SOC — power-law event distributions, diverging correlation lengths, scale invariance — are measurable empirical signatures. This model tests whether governance systems exhibit them.

### 1.2 Mapping to Governance

Now replace the sandpile with a country.

**The lattice.** Instead of a grid of sand sites, the lattice is the institutional and social fabric — courts, ministries, markets, communities, media, civil society. Each is a node. The edges between them are the channels through which stress propagates: legal authority, economic dependency, information flow, cultural ties. When a court ruling changes labor law, the stress transfers to employers, then to workers, then to households. When a commodity price spikes, the shock travels from the export sector through government revenue to public services. Same mechanics as sand toppling onto neighbors — stress doesn't vanish, it moves.

**The grains (Excitation, E).** In the sandpile, grains arrive one at a time. In governance, the "grains" are demands and pressures: economic growth that strains infrastructure, demographic shifts that overwhelm schools, protests that challenge legitimacy, external shocks from trade partners or adversaries. These are the slow driving forces that push the system toward reconfiguration. They accumulate whether or not the system is ready to process them.

**The toppling threshold (Ordering, O).** Each sand site has a slope limit. In governance, the equivalent is institutional capacity to absorb stress without breaking — rule of law that channels disputes into courts instead of streets, regulatory frameworks that process economic demands, social norms that maintain cooperation without enforcement, elections and protests that release pressure incrementally. These are the dissipation mechanisms. They don't eliminate stress — they process it, transmit it, and ultimately shed it at the system's boundaries.

**The edge of the table (Boundary dissipation).** Sand leaves the system by falling off the table edge. In governance, energy leaves the system through resolved disputes, completed policy cycles, emigration, trade that exports pressure, or simply time passing and grievances fading. Without these exits, stress accumulates without limit.

**The balance.** The ratio of Ordering to Excitation (O/E) determines the phase state — just as the slope of the sandpile determines whether it is flat, critical, or collapsing. Too much O relative to E: the system is rigid, brittle, accumulating unprocessed stress. Too much E relative to O: the system cannot maintain structure. At the critical balance: the system processes demands at all scales, from minor policy adjustments to major institutional reorganizations.

### 1.3 Three Theoretical Pillars

Once a system exhibits SOC, the mathematics of physics become available — not as metaphor, but as legitimate analytical tools. This is because SOC systems share the same deep structure as physical systems: they have conserved quantities (energy in, energy out), they obey balance laws (what enters must be processed or stored), and they exhibit phase transitions (qualitative changes in behavior at critical thresholds). The sandpile is not "like" a physical system — it IS a physical system, and so is any system that exhibits the same signatures.

This means we can borrow three frameworks from physics and apply them with mathematical precision, provided we can measure the right quantities:

1. **Inertial mechanics (F = ma).** A governance system has mass — resistance to change. Large, old, deeply institutionalized states (think France, China) do not change direction easily. Small, young, lightly institutionalized states (think South Sudan) have little inertia. Forces (O and E) act on this mass, and the system has a trajectory through state space — a velocity (how fast the O/E balance is changing) and an acceleration (is that change speeding up or slowing down). These are computable from time derivatives of the data, not assumed.

2. **Thermodynamics and information.** The system is an open thermodynamic engine — energy flows in (demands, pressures), useful work comes out (governance outcomes, public goods), and waste heat is dissipated (corruption, violence, rent-seeking, unresolved grievances). Entropy measures how many distinct configurations the system can access — how many ways it can be rearranged internally while still functioning. High entropy means a large configuration space (many possible arrangements), low entropy means few. A diverse, pluralistic society has higher entropy than a monolithic one. Temperature measures how much unprocessed social energy exists per available channel. A high-temperature system is volatile; a low-temperature system is frozen. The state itself acts as a Maxwell's Demon — using information (laws, norms, institutions) to locally reduce entropy at the cost of energy expenditure, consistent with Landauer's principle.

3. **Energy and power.** These are the outputs we ultimately care about. Power is the rate at which the system converts inputs into governance outcomes — how fast it delivers. Efficiency is the fraction that becomes useful work versus waste heat. Capability is the maximum throughput the system can sustain, determined by its mass (buffer capacity) and density (transmission speed). The central prediction of the model is that power delivery is maximized at criticality — the system is most productive at the critical balance.

---

## 2. Phase States

| Regime | Physical Analog | Structure | Failure Mode |
|--------|----------------|-----------|--------------|
| **Sub-critical** | Tectonic fault | Rigid, high-slope. Stress accumulates invisibly along internal fault lines for years or decades. The surface appears stable but is dangerous. | **Earthquake** — catastrophic, sudden release once the accumulated stress exceeds the fault's capacity. Unpredictable in timing and magnitude. (Soviet collapse 1991, Arab Spring 2011.) |
| **Critical** | Ductile material at yield point | Processes stress at all scales. Deforms without breaking. Avalanches are power-law distributed. Maximum adaptive capacity. | **Graceful degradation** — no single failure mode dominates. The system bends but does not break. |
| **Super-critical** | Liquefied soil | Lacks cohesion. Cannot maintain structure. Perturbations destroy whatever temporary order forms. | **Liquefaction** — cannot support any stable configuration. (Somalia, sustained state failure.) |

**The sub-critical system is NOT safe.** It accumulates stress that it cannot process because it lacks the mechanisms (avalanches) to release it incrementally. When it finally breaks, it breaks catastrophically. This maps directly to authoritarian rigidity followed by sudden regime collapse.

**The super-critical system is NOT simply chaotic.** It has lost the cohesion required for any structure to persist. Like liquefied soil in an earthquake — the material cannot support weight regardless of how the load is distributed.

---

## 3. Measurable Components

### 3.1 Forces (Determine Phase State)

#### O (Ordering / Dissipation)

Damps perturbations and prevents cascades. The dissipation mechanism that absorbs energy and prevents runaway failure.

| Sub-component | SOC Mechanism | Governance Meaning |
|---------------|--------------|-------------------|
| **Physical security** | Energy dissipation at boundaries | Violence control — prevents lethal cascading. The most basic damping. A society where political disputes escalate to killing has lost its primary energy sink. |
| **Constraint enforcement** | Lattice rigidity (site-to-site coupling rules) | Rule of law, executive constraints — transmits damping signals through the lattice. Without this, ordering is local only and cannot prevent system-wide cascades. |
| **Social and religious constraint** | Local cohesion (inter-grain friction) | Norms, traditions, community bonds, religious order — voluntary compliance that reduces enforcement cost. This is the distributed damping mechanism; it operates at every node without requiring centralized enforcement. |
| **Expression of disagreement** | Controlled avalanche channels (safety valves) | Legitimate dissent outlets: elections, protests, media criticism, strikes. These ARE ordering — they release stress incrementally instead of letting it accumulate to brittle fracture. A system that suppresses all dissent is removing its own safety valves. |
| **Constraint on privilege capture** | Anti-concentration mechanism | Prevents power/wealth concentration that would distort the lattice. Corruption, oligarchy, and regulatory capture create local stress concentrations that eventually fracture the structure. |

**Military as ordering (guidelines, not locked):** Military capacity under civilian control functions as physical security — the state's monopoly on organized violence is the ultimate boundary dissipation mechanism. Candidate slugs include militarization indices (`bicc_gmi`, `wdi_expmil`, `wdi_afp`), public trust in the military (`wvs_confaf`), and military corruption (`wjp_pol_mil`). However, when the military captures the state (`chisols_mil`, `chisols_indmil`), it crosses from ordering to excitation — the damping mechanism becomes a driving force. The lattice failure function Φ(RoL) partially captures this, but regime-type flags provide a more direct signal.

**Lattice failure:** Ordering that cannot transmit is not ordering. If the rule-of-law substrate collapses, nominal safety institutions cease to function as system-wide damping.

$$O_{effective} = O_{raw} \times \Phi(RoL)$$

where $\Phi$ is a sigmoid function:

$$\Phi(x) = \frac{1}{1 + e^{-k(x - x_0)}}$$

$\Phi \approx 1$ when rule-of-law is healthy; $\Phi \to 0$ as rule-of-law collapses. Parameters $k$ (steepness) and $x_0$ (midpoint) are tunable engineering defaults, not physical constants.

#### E (Excitation / Driving)

Adds energy and pushes the system toward reconfiguration. The slow driving that adds grains to the sandpile.

| Sub-component | SOC Mechanism | Governance Meaning |
|---------------|--------------|-------------------|
| **Economic demands** | Grain addition rate (material stress) | Growth pressure, trade competition, resource scarcity, labor market pressure. The baseline driving force — demands that accumulate regardless of political configuration. |
| **Social mobilization** | Agent activation (nodes becoming active) | Civil society activity, protest, demographic pressure, urbanization demands. When previously passive agents become active, the system receives more energy per unit time. |
| **Interstate competition** | External forcing (boundary conditions) | Geopolitical pressure, arms rivalry, economic competition between states. Energy imposed from outside the system boundary — not internally generated. |
| **Religious mobilization** | Correlated activation (synchronized sub-swarms) | Faith-based demands on the state, religious movements as collective action vehicles. Religious mobilization activates many nodes simultaneously, creating correlated perturbations that are harder to damp. |
| **Communication pathways** | Coupling strength (edge conductance) | Media, internet, social networks — amplify and transmit demands across the lattice. These do not generate energy but increase the speed and reach of its propagation. |

**Military as excitation (guidelines, not locked):** Arms trade (`wdi_armexp`, `wdi_armimp`) measures military energy flowing across borders. Alliance obligations (`atop_defensive`, `atop_offensive`) create forced nearest-neighbor coupling — a partner's crisis becomes your crisis. Active conflict (`ucdp_type1`–`ucdp_type4`) is the most extreme excitation — the system is being driven past its dissipation capacity. Non-state armed actors (`chisols_warlord`) inject correlated excitation outside institutional channels.

**Religion as dual-channel:** Religion appears in both O (social/religious constraint) and E (religious mobilization). This is correct, not a contradiction. Religious energy can flow through ordering channels (established churches, community norms, shared behavioral expectations) or excitatory channels (revolutionary movements, sectarian mobilization, faith-based political demands). The net contribution depends on institutional configuration.

**Network diffusion term:** E includes excitation transmitted FROM neighbors through trade and geographic edges, weighted by edge strength. A country surrounded by super-critical neighbors receives additional excitation through the network. This is the nearest-neighbor coupling mechanism from graph theory.

### 3.2 Material Properties (Describe the Substrate)

These describe what the system is made of — independent of the forces acting on it. Steel and glass under the same stress respond differently because they have different material properties.

#### M (Mass / Inertia)

Resistance to state change and buffer capacity. Mass is not good or bad — it is a description.

| Sub-component | What it measures | High mass means... |
|---------------|-----------------|-------------------|
| **Human capital** | Education depth, health outcomes, skill base | Population is capable but has entrenched expectations. Hard to retrain, hard to break. |
| **Institutional depth** | Age, complexity, procedural entrenchment of institutions | Deep institutions resist change. Old constitutions have enormous inertial mass. Young post-colonial institutions are lightweight. Military penetration of government (`wgov_minmil`, `wgov_totmil`) adds rigid, hierarchical mass — countries with deep military-state fusion have enormous inertia in a particular direction. |
| **Demographic mass** | Population size, age structure, dependency ratios | More nodes in the lattice means more inertia. Age structure matters — young populations have more kinetic potential, aging populations have more inertial weight. |
| **Natural capital** | Resource endowment, environmental quality, arable land | Stored potential energy in the physical substrate. Can be converted to kinetic energy (economic activity) or wasted (resource curse). |

#### U (Internal Energy)

Total energy in the system — kinetic (active) + potential (stored) + thermal (tension).

| Sub-component | What it measures | Physical role |
|---------------|-----------------|--------------|
| **Economic kinetic energy** | GDP, trade flows, government expenditure | Energy currently being converted into work. The engine is running. |
| **Resource potential** | Resource rents, sovereign wealth, foreign reserves | Stored energy that can be released. Potential energy awaiting conversion. |
| **Human potential** | Labor force participation, underemployment, education-employment mismatch | Latent capacity. Energy stored in people who could contribute more than they currently do. |
| **Social thermal energy** | Unresolved grievances, unprocessed demands, tension indicators | Internal heat — energy that is not doing useful work but is present in the system. High thermal energy means high temperature means more volatile dynamics. |

#### S (Entropy / Information)

Configurational complexity — how many distinct states the system can access.

| Sub-component | What it measures | Physical role |
|---------------|-----------------|--------------|
| **Economic diversity** | Sectoral complexity, export diversification | Number of economic microstates. More sectors means more ways to rearrange production under stress. |
| **Political pluralism** | Party fragmentation, civil liberties, media diversity | Number of political microstates. More actors means more possible governance configurations. |
| **Social heterogeneity** | Ethnic/linguistic diversity, income dispersion, urbanization gradient | Internal differentiation. More diverse means more complex means higher entropy. |
| **Institutional variety** | Federalism, subnational governance layers, independent agencies | Structural complexity. More governance levels means more processing channels but also more coordination cost. |

**S is diagnostic of phase state:** Unlike M and ρ (which are neutral), S has a direct relationship to the regime:
- Sub-critical states suppress variance (enforced conformity) → low S → brittle
- Super-critical states have unconstrained variance (fragmentation) → high S → liquefied
- Critical states maintain S in a productive band

This reflects the physics — in statistical mechanics, temperature (which determines variance of particle velocities) is also what determines the phase of matter.

#### ρ (Density / Coupling)

In graph theory, density is the ratio of actual edges to possible edges in a network. A fully connected graph (every node linked to every other) has density 1. A sparse graph — few connections, many isolated nodes — has density near 0. This is exactly what ρ measures in the governance lattice: of all the possible transmission pathways between institutions, sectors, communities, and levels of government, how many actually exist?

A high-ρ system has overlapping, redundant channels — legal, economic, informational, infrastructural — connecting its nodes. Perturbations have many paths to travel, and the system behaves as a connected whole. A low-ρ system has sparse connections: the capital may be densely linked internally while rural regions are effectively disconnected. Perturbations reach dead ends and stay local.

**Density is neutral.** It is a structural property of the lattice, not a measure of quality. A dense lattice transmits ordering signals and excitatory perturbations equally well — the same edges that carry a reform from parliament to provinces also carry a crisis from a border region to the financial center.

This is a **hybrid component**: within-country coupling (how connected the internal lattice is) from QoG slugs + between-country coupling (how connected the country is to its neighbors and trading partners) from the network layer.

| Sub-component | Source | What it measures |
|---------------|--------|-----------------|
| **Physical infrastructure** | QoG slugs | Transport, electricity grid, ports — speed of moving goods, people, and energy. |
| **Communications** | QoG slugs | Internet penetration, broadband, mobile coverage — speed of information propagation. |
| **Network degree centrality** | Network layer (Phase 0b) | How many and how strong a country's trade + geographic connections are. |
| **Network betweenness centrality** | Network layer (Phase 0b) | Whether the country sits on critical transmission paths. A country with high betweenness is a bottleneck — its failure cascades globally. |
| **Community membership** | Network layer (Phase 0b) | Which trade/geographic bloc the country belongs to. Within-bloc coupling is typically stronger than between-bloc coupling. |
| **Military alliance edges** | Network layer (potential) | ATOP alliance data (`atop_defensive`, `atop_offensive`, `atop_number`) defines a third type of nearest-neighbor relationship. Alliance edges transmit perturbations differently from trade — a NATO Article 5 trigger activates the entire alliance simultaneously (correlated activation), unlike trade shocks which diffuse gradually. |

---

## 4. Derived Quantities

Computed deterministically from the 6 measurables and their time derivatives.

### 4.1 Criticality Index

| Quantity | Formula | Interpretation |
|----------|---------|---------------|
| **D_c (distance from criticality)** | $D_c = \ln(O/E)$ | The primary index output. $D_c = 0$ means at criticality. $D_c > 0$ means sub-critical (O dominates). $D_c < 0$ means super-critical (E dominates). Magnitude indicates how far. |
| **d1 (velocity)** | $d_1 = \frac{dD_c}{dt}$ | Rate of movement toward or away from criticality. $d_1 > 0$ means moving toward sub-critical. $d_1 < 0$ means moving toward super-critical. |
| **d2 (acceleration)** | $d_2 = \frac{d^2 D_c}{dt^2}$ | Is the movement speeding up or slowing down? Sustained $d_2$ in one direction indicates a runaway process. |
| **Phase state** | $f(D_c)$ | Classification: sub-critical / at-criticality / super-critical. Boundaries are tunable thresholds. |

### 4.2 Physics Model

| Quantity | Concept | Interpretation |
|----------|---------|---------------|
| **Power (P)** | $P = F \cdot v$ or $P = dW/dt$ | Rate of governance delivery. How fast the system converts inputs into outcomes for its population. |
| **Temperature (T)** | $T = U/S$ | Social heat per degree of freedom. High T means lots of social energy per available channel — heated dynamics. |
| **Free energy (F)** | $F = U - T \cdot S$ | Deployable governance capacity. Total energy minus what is locked up in maintaining complexity/diversity. |
| **Capability (C)** | $C = g(M, \rho)$ | Maximum system throughput. Determined by mass (buffer) and coupling (transmission speed). |
| **Efficiency (η)** | $\eta = W_{useful} / U_{input}$ | Fraction of energy becoming useful governance work vs. dissipated as waste heat (corruption, violence, rent-seeking). |

### 4.3 Central Testable Prediction

**Power delivery is MAXIMIZED at criticality.**

- Sub-critical: the engine is seized up (brittle). It cannot process demands. Power delivery drops because the system lacks the avalanche mechanisms needed to convert input into output at all scales.
- Super-critical: the engine is dissolving (liquefied). No coherent processing happens. Power delivery drops because energy dissipates without doing useful work.
- Critical: the engine runs at maximum throughput. Avalanches at all scales contribute to processing demands into governance outputs.

This is the central claim of the model and must be tested empirically.

---

## 5. Mathematical Toolkit

### 5.1 Core (Required)

- **Linear algebra** — weighted aggregation, normalization, missingness-aware renormalization
- **Information theory** — Shannon entropy (for S component), mutual information (replaces Pearson correlation for grounding Signature 2 — captures nonlinear coupling), transfer entropy (directional causality between O and E)
- **Power-law statistics** — maximum likelihood estimation + goodness-of-fit (Clauset et al. 2009) for grounding Signature 1
- **Extreme value theory** — Generalized Pareto distribution for grounding Signature 5 (fat tails)

### 5.2 Graph Theory (Nearest-Neighbor Systems)

- **Multi-layer network:** geographic layer (CEPII GeoDist) + trade layer (UN COMTRADE / CEPII BACI)
- **Nearest neighbors** defined by proximity in multiple dimensions (spatial, economic) — not strictly geometric distance
- **Key metrics:** degree centrality, clustering coefficient, betweenness centrality, community detection, spectral gap
- **Network entropy** as a direct measure of structural complexity (informs S)
- **Enhances ρ** — actual network topology instead of proxy indicators
- **Enhances grounding signatures** — between-country tests at a different scale than within-country QoG-based tests

### 5.3 Deferred (Insufficient Data)

- **Dynamical systems** (Lyapunov exponents, bifurcation analysis) — requires longer/denser time series than QoG provides
- **Algebraic topology** (persistent homology, Betti numbers) — requires higher-dimensional point clouds

---

## 6. Grounding Layer (Independent Validation)

### 6.1 Non-Circularity Principle

Validation slugs must be independent from index slugs. If a variable helps define the state, using it again to validate the state is circular. The index set and the grounding set must be **disjoint** — no slug can appear in both.

Which specific slugs go into which set is a **slug selection decision** made during Phase 2b, not a pre-committed constraint. Any slug in the global_95 pool is a candidate for either role until assigned.

### 6.2 Five Empirical Signatures of Criticality

| # | Signature | What it tests | Acceptance criterion |
|---|-----------|--------------|---------------------|
| 1 | **Power-law events** | Event magnitudes follow scale-free distribution | $\alpha \in [0.8, 1.5]$ (MLE) |
| 2 | **Diverging correlation length** | Cross-sector coupling strengthens | $|MI| > threshold$ (mutual information) |
| 3 | **Scale invariance** | Local and national dynamics are self-similar | $similarity > 0.85$ |
| 4 | **Fractal structure** | Hierarchical self-similarity (deferred — needs spatial data) | — |
| 5 | **No characteristic event size** | Fat-tailed year-over-year jumps | $kurtosis > 1.5$ or GPD fit |

Acceptance criteria are **tunable engineering defaults**, not physical constants. They must be validated via sensitivity analysis, backtesting, and (ideally) formal goodness-of-fit tests.

### 6.3 Two Domain-Independent Slug Sets

Grounding signatures are tested using two sets from different measurement domains:

- **Set A (political/governance domain):** V-Dem slugs
- **Set B (economic/conflict domain):** Non-V-Dem slugs testing the same signatures

Domain independence means: different measurement domain, different data generation method, different institutional source. Some correlation between sets is EXPECTED at criticality — that IS Signature 2 (diverging correlation length means sectors couple).

### 6.4 Network-Enhanced Signatures

Between-country tests using Phase 0b network data:

- **Sig 1 enhanced:** Track cascade sizes through the network (shock propagating hop by hop). Power-law cascade size distribution = criticality.
- **Sig 2 enhanced:** Measure correlation of governance perturbations BETWEEN network neighbors. Network correlation length (how many hops with significant correlation) should diverge at criticality.
- **Sig 3 enhanced:** Compare dynamics at ego-network scale vs. global network scale. Self-similarity across these scales = scale invariance.

The within-country and between-country grounding tests operate at different scales. Their agreement is itself evidence of scale invariance.

### 6.5 Execution Order

**Grounding runs FIRST and BLIND.** No preconceptions about which countries should be at criticality. The results become ground truth labels that the O/E model is then tuned to predict. This prevents confirmation bias.

---

## 7. Design Decisions

1. **Deterministic model** — no stochastic components. Slug reliability varies too much to layer probabilistic modeling on top. Uncertainty is addressed through sensitivity analysis and threshold variation.
2. **Expression of disagreement is ORDERING** — protests, elections, and criticism look like excitation but function as safety valves. They release stress incrementally, preventing brittle accumulation.
3. **Religion is dual-channel** — ordering (norms, constraint) AND excitatory (mobilization, demands). Net contribution depends on institutional configuration.
4. **Military is dual-channel** — ordering (security, violence monopoly under civilian control) AND excitatory (coups, arms races, interstate conflict). Whether military capacity functions as O or E depends on civilian control and regime type.
5. **Sub-critical is brittle, not flat** — high-slope, rigid, dangerous. Fails via catastrophic fracture.
6. **Super-critical is liquefied, not just steep** — lacks cohesion. Fails via structural dissolution.
7. **Lattice failure is multiplicative** — rule-of-law collapse doesn't reduce O linearly; it eliminates O's ability to transmit through the lattice.
8. **ρ is hybrid** — within-country (QoG infrastructure slugs) + between-country (network graph metrics).
9. **E has a network diffusion term** — neighbor excitation spills over through trade/geographic edges.
10. **Grounding runs first** — ground truth labels from empirical signatures, THEN tune the O/E model.
11. **Power delivery maximized at criticality** — central testable prediction.
12. **No slug is pre-committed** — all slugs in the eligible pool are candidates for either index or grounding roles until assigned during slug selection.

---

## 8. Dependencies

- Requires Phase 0 complete (augmented Arrow with checksum)
- Requires Phase 1 complete (slug classification: penetration, temporal profiles, clusters)
- Requires Phase 0b (network data: CEPII GeoDist + BACI trade)
- Feeds Phase 2b (slug strategy) and all subsequent phases
