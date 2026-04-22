# Research Pathways: Energy Depletion and Percolation Threshold as Cascade Termination Mechanism in SOC

## Status note

The `overtopping.md` framework (§8.3) concretizes the dual role of p_c through σ dynamics: as σ degrades, the effective connectivity of the suppressed lattice degrades with it, giving an explicit mechanism by which effective p_c can be lost independent of activity level. This research-pathways document remains the literature-search roadmap for grounding the proposition in the published SOC literature — a task still required even though one concrete instantiation now exists.

## Core Proposition

In a Self-Organized Critical system, cascade events self-terminate when the energy consumed during propagation depletes the system's stored potential below the percolation threshold — the minimum connectivity/energy condition for a spanning cascade to be sustained. This document maps the research landscape for investigating whether this proposition is established, implicit, or novel.

---

## 1. Primary Theoretical Frameworks to Investigate

### 1.1 Percolation Theory
The foundational framework. Investigate specifically:
- The percolation threshold p_c as a dynamic condition, not merely a static structural property
- Whether existing literature treats p_c as a **termination condition** for spreading processes, not just an initiation condition
- Finite cluster distribution below p_c and how this relates to cascade arrest

**Key questions:**
- Does any existing formalism treat crossing below p_c as the termination event for a cascade?
- Is there a dual role for p_c (activation threshold AND termination threshold) anywhere in the literature?

### 1.2 Directed Percolation (DP)
The universality class most SOC systems belong to. Investigate:
- Activity spreading and the absorbing state — is the absorbing state equivalent to falling below p_c?
- Whether energy/activity depletion is formally treated as the mechanism driving the system toward the absorbing state
- The DP order parameter and whether it maps onto available energy for cascade propagation

**Key questions:**
- Is depletion of local activity density in DP equivalent to the energy depletion mechanism proposed here?
- Does the DP absorbing state correspond formally to sub-percolation conditions?

### 1.3 Absorbing State Phase Transitions
Vespignani and Zapperi's work connecting SOC to absorbing state transitions is the most likely place this concept exists formally. Investigate:
- Whether the absorbing state is defined in terms of energy/activity depletion
- Whether the transition into the absorbing state during a cascade is treated as a percolation phenomenon
- The role of local density depletion in terminating activity spreading

**Key questions:**
- Is there an explicit mapping between absorbing state entry and crossing below the percolation threshold?
- Is cascade-induced depletion treated as distinct from background-state depletion?

### 1.4 Branching Process Theory
Branching processes are a common mathematical framework for SOC avalanches. Investigate:
- Resource-limited branching processes — where each branching event consumes available substrate
- Whether extinction in branching processes is modeled as substrate depletion below a critical density
- The relationship between branching ratio sigma and available substrate

**Key questions:**
- Do resource-depleting branching processes formally model termination via substrate exhaustion?
- Is there a percolation-theoretic interpretation of branching process extinction?

---

## 2. Specific Models to Examine

### 2.1 Forest Fire Model (Drossel and Schwabl, 1992)
The closest natural analogue. Examine specifically:
- Whether fire termination is formally described as consuming the connected cluster below the percolation threshold
- The relationship between cluster size distribution and the percolation threshold
- Whether the model predicts asymmetric pre- and post-fire connectivity

**What to look for:**
- Explicit statement that fire self-terminates when connected fuel falls below p_c
- Any treatment of the remaining forest post-fire in terms of percolation conditions

### 2.2 Manna Model
A stochastic SOC model with explicit energy (sand grain) redistribution. Examine:
- Whether energy redistribution during avalanches is tracked in terms of local density relative to a critical threshold
- Whether avalanche termination is analyzed in terms of energy depletion

### 2.3 Bak-Tang-Wiesenfeld (BTW) Sandpile
The canonical SOC model. Examine:
- Whether toppling termination is ever described in percolation-theoretic terms
- The relationship between the set of critical sites (at or above threshold) and percolation of toppling activity
- Whether the termination of toppling can be described as the critical site cluster falling below p_c

### 2.4 OFC Earthquake Model (Olami-Feder-Christensen)
A non-conservative SOC model. Examine:
- Whether non-conservation (energy loss during redistribution) creates depletion dynamics
- Whether cascade termination in non-conservative systems has been analyzed in percolation terms
- The role of local stress below threshold in terminating cascades

### 2.5 SIR Epidemic Model
The susceptible-infected-recovered framework is mathematically equivalent in key respects. Examine:
- Whether epidemic termination is described as depletion of susceptibles below the percolation threshold
- The herd immunity threshold as a formal equivalent of p_c
- Whether epidemic size is predicted by the initial distance above p_c (directly relevant to the energy proposition)

**This may be the most formally developed analogue** — epidemic final size theory explicitly connects outbreak termination to percolation threshold crossing.

---

## 3. Key Authors and Research Groups

### Foundational SOC
- **Bak, Tang, Wiesenfeld** — original SOC formulation, sandpile model
- **Drossel and Schwabl** — forest fire model
- **Manna** — stochastic SOC

### Percolation and Phase Transitions
- **Stauffer and Aharony** — percolation theory textbook, comprehensive treatment of p_c
- **Broadbent and Hammersley** — original percolation formulation
- **Grimmett** — formal percolation theory

### SOC and Absorbing States
- **Vespignani and Zapperi** — SOC as absorbing state phase transition, most relevant to the proposition
- **Dickman** — directed percolation, absorbing states, and SOC connection
- **Muñoz** — absorbing state transitions and their universality classes

### Network and Cascade Theory
- **Watts** — cascade models on networks, threshold dynamics
- **Goh, Kahng, Kim** — cascade and avalanche dynamics on complex networks
- **Dorogovtsev and Mendes** — percolation on complex networks

### Neuroscience and Criticality
- **Beggs and Plenz** — neuronal avalanches, original empirical SOC in neuroscience
- **Chialvo** — brain criticality
- **Haimovici et al.** — brain as critical system with percolation-like dynamics

---

## 4. Search Strategy

### 4.1 Primary Search Terms
Begin with these targeted combinations:

- "percolation threshold" AND "cascade termination"
- "SOC" AND "substrate depletion" AND "termination"
- "avalanche termination" AND "percolation"
- "self-organized criticality" AND "depletion" AND "threshold"
- "forest fire" AND "percolation threshold" AND "termination"
- "directed percolation" AND "energy depletion"
- "absorbing state" AND "depletion" AND "percolation"
- "branching process" AND "resource depletion" AND "extinction"
- "epidemic final size" AND "percolation threshold"
- "cascade arrest" AND "percolation"

### 4.2 Secondary Search Terms
If primary searches are insufficient:

- "activity depletion" AND "critical threshold" AND "spreading"
- "finite cluster" AND "cascade" AND "arrest"
- "connectivity depletion" AND "avalanche"
- "stress depletion" AND "earthquake model" AND "percolation"
- "fuel depletion" AND "fire spread" AND "percolation"

### 4.3 Citation Chain Strategy
- Find the most relevant paper through primary searches
- Follow ALL citations backward (what it cites)
- Follow ALL citations forward (what cites it) using Google Scholar
- This two-directional chain will capture both foundational work and recent developments

---

## 5. Databases and Journals

### Primary Databases
- **arXiv.org** — cond-mat.stat-mech, cond-mat.dis-nn, q-bio.NC sections
- **Google Scholar** — broadest coverage, best for citation chains
- **Web of Science** — formal citation analysis
- **Semantic Scholar** — AI-enhanced relevance, good for finding related concepts

### Primary Journals
- **Physical Review Letters** — high-impact SOC and phase transition work
- **Physical Review E** — detailed statistical physics, most likely to contain formal treatments
- **Journal of Statistical Mechanics** — theoretical statistical physics
- **Physica A** — complexity and SOC applications
- **Nature Physics** — high-profile criticality work
- **PLOS Computational Biology** — if biological applications are relevant

---

## 6. Textbooks for Formal Grounding

These provide the mathematical framework against which the proposition can be checked:

- **Stauffer and Aharony** — Introduction to Percolation Theory (standard reference)
- **Christensen and Moloney** — Complexity and Criticality (best SOC textbook, connects SOC to percolation formally)
- **Hinrichsen** — Non-equilibrium critical phenomena and phase transitions into absorbing states (directed percolation formal treatment)
- **Bollobas and Riordan** — Percolation (rigorous mathematical treatment)
- **Newman** — Networks (percolation on complex networks, cascade models)

---

## 7. What to Look For in Each Source

When examining any source, specifically assess:

**Does it address the dual role of p_c?**
Most literature treats p_c as a condition for cascade initiation. The proposition requires it to also function as a termination condition during a cascade. Look for any acknowledgment of this dual role.

**Is depletion treated as a dynamic process during the cascade?**
Many models treat energy/activity as static background. Look for models where the cascade explicitly depletes the substrate as it propagates, and where this depletion is tracked relative to a critical threshold.

**Is cascade size predicted by initial distance above p_c?**
If the proposition is correct, the total energy released in a cascade should scale with how far above p_c the system was when the cascade initiated. Look for this relationship explicitly stated or derivable.

**Is the post-cascade state analyzed in percolation terms?**
If the cascade terminates by driving the system below p_c, the post-cascade state should be analyzable as a sub-percolation system. Look for any characterization of the post-cascade state in these terms.

---

## 8. Documenting What Is Found

For each source examined, record:

- **Full citation**
- **Does it explicitly state the proposition?** (Yes / Implicitly / No)
- **Does it contain the mathematical components?** (List which components)
- **Does it treat p_c as termination condition?** (Yes / Implicitly / No)
- **Does it model dynamic depletion during cascade?** (Yes / Implicitly / No)
- **Relevant quotes or equations** (with page/equation numbers)
- **Forward citations to follow**

---

## 9. If The Proposition Is Not Found in the Literature

This would be significant. The appropriate response would be:

**Demonstrate mathematical consistency:**
- Show that existing percolation formalism is consistent with the proposition
- Derive the expected cascade size as a function of initial distance above p_c
- Show this is consistent with known SOC scaling relations and exponents

**Demonstrate it is implicit in existing models:**
- Show that the BTW sandpile, forest fire model, or SIR model implicitly satisfy the proposition even if not stated
- Numerical simulation could demonstrate the relationship directly

**Identify the gap:**
- Formally state what has not been stated before
- Situate it within the existing theoretical framework
- This constitutes a genuine contribution to the formalization of SOC termination dynamics

---

## 10. Connection to Modified-SOC Frameworks

Throughout the literature search, also note any sources relevant to the broader framework under development:

- Sources treating **damped or thresholded SOC** — relevant to overtopping's threshold elevation
- Sources treating **deficit accumulation** between events
- Sources treating **quasi-periodicity** in SOC-like systems
- Sources treating **inductive / amplified** criticality
- Sources treating **susceptibility** as the recruitable energy in a cascade

The energy depletion — percolation threshold proposition is one component of a larger framework. Literature that addresses adjacent components should also be tracked.

---

*Document prepared as part of ongoing theoretical development of overtopping, liquefaction, and related modified-SOC frameworks.*
