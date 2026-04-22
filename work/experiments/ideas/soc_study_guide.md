# Study Guide: Research and Reading for Modified-SOC Mechanism Frameworks

## Preamble

This study guide maps the reading and research needed to develop modified-SOC mechanism frameworks — specifically **overtopping** (suppressed-release SOC with structural fragility), **liquefaction** (amplified-cascade SOC with cyclic external driving), and the **distorted-SOC signature catalog** (mechanism-agnostic detection categories). It is organized by the specific gap each area of study addresses. Priority is indicated for each section — start with the highest priority areas before moving to supporting material.

The guide covers what you need to be able to do:
- Build the formal mathematical models (overtopping and liquefaction on SOC substrates)
- Establish the SOC substrate argument for candidate systems
- Design valid empirical tests (detection of distorted-SOC signatures; falsification of mechanism claims)
- Ground the frameworks in existing literature (precedents for activity-substrate feedback, cyclic-driving-induced instability, SOC in human systems)
- Understand methodological requirements for complex systems research

See `overtopping.md`, `liquefaction.md`, and `distorted_soc_signatures.md` for the primary framework documents this guide supports.

---

## Module 1: SOC Mathematics — Building The Formal Model

**Priority: Highest. This is the prerequisite for everything else.**

### 1.1 Core SOC Theory

These establish the mathematical foundation on which overtopping and liquefaction build.

**Bak, P., Tang, C., and Wiesenfeld, K. (1987)**
*Self-organized criticality: An explanation of 1/f noise*
Physical Review Letters, 59, 381

The foundational paper. Read for the original sandpile model and the mathematical structure of SOC. Pay attention to the slow driving / fast dissipation separation and how it generates power law distributions.

**Bak, P. (1996)**
*How Nature Works: The Science of Self-Organized Criticality*
Copernicus Books

The accessible book-length treatment. Read alongside the papers for conceptual grounding. Particularly useful for the argument that many natural systems are SOC candidates.

**Christensen, K. and Moloney, N.R. (2005)**
*Complexity and Criticality*
Imperial College Press

The most mathematically complete SOC textbook. This is the primary reference for the formal development. Work through the mathematical treatment of avalanche distributions, scaling relations, and the connection to percolation theory. This is where the formal development of overtopping and liquefaction begins.

### 1.2 Branching Processes

The mathematical framework for cascade propagation. Essential for formalizing the branching ratio predictions.

**Harris, T.E. (1963)**
*The Theory of Branching Processes*
Springer

The foundational mathematical treatment. Focus on subcritical, critical, and supercritical regimes and the mathematical conditions for each. The branching ratio sigma = 1 at criticality is formalized here.

**Athreya, K.B. and Ney, P.E. (1972)**
*Branching Processes*
Springer

More complete mathematical treatment. Particularly useful for resource-limited and modified branching processes — the starting point for formalizing suppression and amplification mathematically.

### 1.3 Directed Percolation

The universality class most relevant to SOC. Essential for situating overtopping and liquefaction within established theoretical structure.

**Hinrichsen, H. (2000)**
*Non-equilibrium critical phenomena and phase transitions into absorbing states*
Advances in Physics, 49, 815-958

The comprehensive review of directed percolation and absorbing state transitions. This is long but essential. Focus on the absorbing state concept and how activity depletion drives systems toward it — directly relevant to the percolation threshold termination proposition.

**Dickman, R. et al. (2000)**
*Paths to self-organized criticality*
Brazilian Journal of Physics, 30, 27-41

Connects SOC to absorbing state phase transitions. Shorter and more accessible than Hinrichsen. Read this first as an introduction to the connection.

### 1.4 Modified and Suppressed SOC Models

These are the closest existing mathematical treatments to what overtopping and liquefaction build on.

**Vespignani, A. and Zapperi, S. (1998)**
*How self-organized criticality works: A unified mean-field picture*
Physical Review E, 57, 6345

Develops the mean-field theory of SOC with explicit treatment of driving and dissipation parameters. The framework for how modifying these parameters changes system behavior — the mathematical starting point for the threshold-elevation dimension of overtopping.

**Bonachela, J.A. and Muñoz, M.A. (2009)**
*Self-organization without conservation: True or just apparent scale-invariance?*
Journal of Statistical Mechanics

Examines what happens to SOC when conservation is broken. Relevant to understanding how suppression distorts the natural SOC distribution mathematically.

---

## Module 2: Percolation Theory — Grounding The Threshold Arguments

**Priority: High. Required for the speculative framework components and the substrate argument.**

**Stauffer, D. and Aharony, A. (1994)**
*Introduction to Percolation Theory* (2nd edition)
Taylor and Francis

The standard reference. Read chapters on the percolation threshold, cluster size distributions, and finite size scaling. Focus on p_c as both a structural property and a dynamic condition — this is where the dual role argument must be grounded.

**Grimmett, G. (1999)**
*Percolation* (2nd edition)
Springer

The rigorous mathematical treatment. Use as a reference rather than reading cover to cover. Particularly relevant for the formal definition of the percolation threshold and spanning cluster conditions.

**Newman, M.E.J. (2010)**
*Networks: An Introduction*
Oxford University Press

Percolation on complex networks — essential because human systems are networks, not regular lattices. The percolation threshold on heterogeneous networks differs significantly from regular lattice results. Chapter on network robustness and percolation is particularly relevant.

**Dorogovtsev, S.N., Goltsev, A.V., and Mendes, J.F.F. (2008)**
*Critical phenomena in complex networks*
Reviews of Modern Physics, 80, 1275

Reviews percolation and critical phenomena specifically on complex networks. Directly relevant to applying the percolation threshold concept to human system network topologies.

---

## Module 3: Empirical SOC — Learning From Established Cases

**Priority: High. Provides the template for empirical research design.**

### 3.1 The Forest Fire Case

**Drossel, B. and Schwabl, F. (1992)**
*Self-organized critical forest-fire model*
Physical Review Letters, 69, 1629

The foundational forest fire SOC model. Read carefully for the mathematical structure of how fire spread and termination are modeled. The consumed-tree / regrowth cycle is the closest published precedent for overtopping's damage-recovery loop; see Part IX of `overtopping.md` for the detailed comparison.

**Malamud, B.D., Morein, G., and Turcotte, D.L. (1998)**
*Forest fires: An example of self-organized critical behavior*
Science, 281, 1840-1842

Empirical analysis of forest fire size distributions showing power law behavior. The comparison between managed and unmanaged forests is the template for the empirical research design.

**Pyne, S.J. (1982)**
*Fire in America: A Cultural History of Wildland and Rural Fire*
Princeton University Press

The historical documentation of US fire suppression policy. Essential for establishing the intervention mechanism independently of the fire data — the methodological model for documenting intervention independently.

### 3.2 Neuronal Avalanches

**Beggs, J.M. and Plenz, D. (2003)**
*Neuronal avalanches in neocortical circuits*
Journal of Neuroscience, 23, 11167-11177

The paper that established SOC signatures in neural tissue. Read for the methodology of detecting power law distributions and branching ratios in a complex biological system. The methods translate to other systems.

**Shew, W.L. and Plenz, D. (2013)**
*The functional benefits of criticality in the cortex*
Neuroscientist, 19, 88-100

Review of what criticality confers functionally — dynamic range, information transmission, sensitivity. Useful for the argument that SOC is the natural state of certain systems and deviation from it has functional consequences.

### 3.3 Earthquakes and Seismology

**Gutenberg, B. and Richter, C.F. (1944)**
*Frequency of earthquakes in California*
Bulletin of the Seismological Society of America, 34, 185-188

The original Gutenberg-Richter law. The most mature empirical power law in a natural system. Read for how the energy-frequency relationship is formally established — the template for establishing the same relationship in other systems.

**Sornette, D. and Sammis, C.G. (1995)**
*Complex critical exponents from renormalization group theory of earthquakes*
Journal de Physique I, 5, 607-619

Connects earthquake dynamics to critical phenomena mathematically. Useful for the formal argument that seismic systems are SOC candidates.

---

## Module 4: Complex Systems in Human Domains — Establishing The SOC Substrate

**Priority: High. Required to argue that human systems are SOC candidates.**

### 4.1 Financial Systems

**Mantegna, R.N. and Stanley, H.E. (1999)**
*An Introduction to Econophysics: Correlations and Complexity in Finance*
Cambridge University Press

The foundational text for applying statistical physics methods to financial systems. Establishes power law distributions in financial returns and the case for critical-like dynamics. Essential reading for the financial systems application.

**Sornette, D. (2003)**
*Why Stock Markets Crash: Critical Events in Complex Financial Systems*
Princeton University Press

Develops the case that financial markets exhibit critical dynamics and that crashes are analogous to critical phase transitions. Directly relevant to suppressed-release arguments in financial systems (overtopping). Read critically — some claims are contested.

**Bouchaud, J.P. and Potters, M. (2003)**
*Theory of Financial Risk and Derivative Pricing*
Cambridge University Press

More technically rigorous treatment of power laws and heavy tails in financial systems. Useful for the formal statistical argument.

### 4.2 Social and Political Systems

**Cederman, L.E. (2003)**
*Modeling the size of wars: From billiard balls to sandpiles*
American Political Science Review, 97, 135-150

Applies SOC to the size distribution of wars. One of the few papers that explicitly argues for a SOC substrate in a political system. Read carefully for both the argument and its limitations.

**Clauset, A., Young, M., and Gleditsch, K.S. (2007)**
*On the frequency of severe terrorist events*
Journal of Conflict Resolution, 51, 58-87

Power law analysis of terrorist event sizes. Methodologically careful treatment of heavy-tailed distributions in a social system. Read for the statistical methodology as much as the substantive findings.

**Turchin, P. (2003)**
*Historical Dynamics: Why States Rise and Fall*
Princeton University Press

Develops mathematical models of political-historical dynamics including cyclical instability patterns. The secular cycles framework has structural similarities to suppressed-release (overtopping-like) dynamics. Read for the argument that political systems have identifiable dynamical structure.

### 4.3 Epidemics

**Anderson, R.M. and May, R.M. (1991)**
*Infectious Diseases of Humans: Dynamics and Control*
Oxford University Press

The foundational mathematical epidemiology text. The SIR framework and the basic reproduction number R0 are formally developed here. R0 > 1 / R0 < 1 maps directly onto supercritical / subcritical and provides the clearest human system analogue to the branching ratio.

**Grassberger, P. (1983)**
*On the critical behavior of the general epidemic process and dynamical percolation*
Mathematical Biosciences, 63, 157-172

Formally connects epidemic spread to directed percolation. The paper that establishes epidemics as a percolation process — directly relevant to the percolation threshold arguments in the framework.

---

## Module 5: Statistical Methodology — Testing Power Laws and Heavy Tails

**Priority: High. Without correct statistical methods the empirical work is invalid.**

**Clauset, A., Shalizi, C.R., and Newman, M.E.J. (2009)**
*Power-law distributions in empirical data*
SIAM Review, 51, 661-703

The essential methodological reference. Establishes the correct statistical procedures for detecting and testing power law distributions. Most earlier work on power laws in human systems used incorrect methods. Read this before designing any empirical test. The finding that many claimed power laws do not survive rigorous statistical testing is directly relevant to the falsifiability requirements.

**Stumpf, M.P.H. and Porter, M.A. (2012)**
*Critical truths about power laws*
Science, 335, 665-666

Short but important. Summarizes the ways power law claims go wrong and the minimum standards for establishing them. Read alongside Clauset et al.

**White, E.P. et al. (2008)**
*On estimating the exponent of power-law frequency distributions*
Ecology, 89, 905-912

Practical treatment of power law estimation methods with comparison of approaches. Useful for the technical implementation of distributional testing.

---

## Module 6: Philosophy of Science and Falsifiability

**Priority: Medium. Essential for framing the theory correctly but can be read in parallel with other modules.**

**Popper, K.R. (1959)**
*The Logic of Scientific Discovery*
Routledge

The foundational text on falsifiability as the demarcation criterion for scientific theory. Read Part I and Chapter 4 specifically. The framework's current weakness is precisely what Popper describes as the problem of theories that can absorb any observation.

**Lakatos, I. (1978)**
*The Methodology of Scientific Research Programmes*
Cambridge University Press

Develops the concept of research programmes — hard core assumptions surrounded by a protective belt of auxiliary hypotheses. Useful for thinking about what in the overtopping/liquefaction frameworks is the unfalsifiable hard core versus the testable auxiliary claims.

**Mayo, D.G. (1996)**
*Error and the Growth of Experimental Knowledge*
University of Chicago Press

Develops severe testing as the standard for scientific inference. A test is severe if it would probably have detected an error if one exists. This is the appropriate standard for modified-SOC empirical tests.

---

## Module 7: Research Design for Complex Systems

**Priority: Medium. Required for designing valid empirical tests in human systems.**

**Angrist, J.D. and Pischke, J.S. (2008)**
*Mostly Harmless Econometrics*
Princeton University Press

The accessible treatment of natural experiments and causal identification in social science. Essential for designing the intervention comparison studies — particularly the instrumental variable and difference-in-differences approaches that may address the entanglement problem.

**Dunning, T. (2012)**
*Natural Experiments in the Social Sciences*
Cambridge University Press

Specifically focused on natural experiments — cases where intervention intensity varies for reasons exogenous to the system. This is the research design template most applicable to the modified-SOC empirical program (overtopping, liquefaction).

**Shalizi, C.R. (2006)**
*Methods and techniques of complex systems science: An overview*
In T. Deisboeck and J. Kresh (eds.), Complex Systems Science in Biomedicine

Overview of methods for studying complex systems empirically. Particularly relevant sections on time series analysis, scaling, and the detection of critical behavior.

---

## Module 8: Intervention and Suppression in Human Systems — Domain Specific

**Priority: Medium. Provides the empirical grounding for the intervention mechanism argument.**

**Minsky, H.P. (1986)**
*Stabilizing an Unstable Economy*
Yale University Press

Develops the financial instability hypothesis — the argument that financial stability itself breeds instability by encouraging risk-taking. Structurally similar to the suppressed-release argument and provides domain-specific grounding for the financial-system application. The Minsky moment is arguably an overtopping-type release event.

**Scott, J.C. (1998)**
*Seeing Like a State: How Certain Schemes to Improve the Human Condition Have Failed*
Yale University Press

Examines how state intervention in complex systems — agricultural, urban, social — produces large-scale failures by suppressing local adaptive variation. The argument is structurally an overtopping/suppressed-release argument without using that language. Read for the historical documentation of intervention mechanisms and their consequences.

**Taleb, N.N. (2007)**
*The Black Swan: The Impact of the Highly Improbable*
Random House

Argues that human systems systematically underestimate tail risk and that interventions designed to suppress volatility increase fragility. The narrative version of the overtopping argument in financial and social systems. Read critically — the argument is suggestive but lacks the formal structure required for falsifiability.

---

## Module 9: Information Theory and Network Analysis Methods

**Priority: Medium. Required for the cross-domain signature testing.**

**Cover, T.M. and Thomas, J.A. (2006)**
*Elements of Information Theory* (2nd edition)
Wiley

The standard reference for information theory. Entropy, mutual information, transfer entropy, and Fisher information are formally developed here. Required for testing the information-theoretic signatures cataloged in `distorted_soc_signatures.md`.

**Lizier, J.T. (2014)**
*JIDT: An information-theoretic toolkit for studying the dynamics of complex systems*
Frontiers in Robotics and AI, 1, 11

Practical software toolkit for computing information-theoretic measures in time series data. The implementation resource for information-theoretic signature testing.

**Barabási, A.L. (2016)**
*Network Science*
Cambridge University Press
(Available free online at networksciencebook.com)

Comprehensive treatment of network analysis methods. Relevant for the graph-theoretic signature testing — degree distributions, clustering, path lengths, modularity. The chapters on robustness and percolation on networks are directly relevant.

---

## Module 10: Mechanism Precedents for Overtopping and Liquefaction

**Priority: High for mechanism development; lower for generic SOC grounding.**

These are models that implement some combination of activity-substrate feedback, cyclic-driving-induced instability, or threshold modulation. None is a complete precedent for overtopping or liquefaction, but each informs a specific component.

### 10.1 Overtopping-side precedents

**Drossel, B. and Schwabl, F. (1992)** — already cited in Module 3.1. The consumed-tree / regrowth cycle is the closest published precedent for overtopping's damage-recovery loop. What's different: DS has no suppressed regime; overtopping combines threshold elevation with fragile suppression.

**Dieterich, J.H. (1979)** — *Modeling of rock friction: 1. Experimental results and constitutive equations.* Journal of Geophysical Research, 84, 2161–2168.
**Ruina, A. (1983)** — *Slip instability and state variable friction laws.* Journal of Geophysical Research, 88, 10359–10370.

Rate-and-state friction: fault surfaces have a state variable that decays with slip (slip weakens) and heals in quiescence. Mapped onto overtopping: state variable is σ-like, slip is toppling, healing is recovery_rate. Similar mathematics; different motivating question.

**Olami, Z., Feder, H.J.S., Christensen, K. (1992)** — *Self-organized criticality in a continuous, nonconservative cellular automaton modeling earthquakes.* Physical Review Letters, 68, 1244.

OFC earthquake model with non-conservative redistribution. Closest SOC precedent for combining driving with dissipation-during-events; can be extended with σ-like state dynamics.

**Levina, A., Herrmann, J.M., Geisel, T. (2007)** — *Dynamical synapses causing self-organized criticality in neural networks.* Nature Physics, 3, 857–860.
**Hernández-Urbina, V. and Herrmann, J.M. (2017)** — *Neuronal avalanches in complex networks.* Cogent Physics, 4, 1331095.

Neural avalanche models with activity-adapting synapses. Richer than overtopping's σ (synapses can increase or decrease, not just damage and recover), but the same conceptual family of activity-driven substrate modification.

**Bonachela, J.A. and Muñoz, M.A. (2010)** — *Self-organization without conservation: True or just apparent scale-invariance?* already cited in Module 1.4. Self-organized quasi-criticality frames systems where the control parameter is dynamically driven by activity. Overtopping's "recovering suppressed-release" regime fits this family.

**Gross, T. and Blasius, B. (2008)** — *Adaptive coevolutionary networks: a review.* Journal of the Royal Society Interface, 5, 259–271.

Adaptive networks where edges form/break based on node activity. Topology-responds-to-dynamics is the general frame. Overtopping is a node-local (σ per site) rather than edge version of the same concept.

### 10.2 Liquefaction-side precedents

**Seed, H.B. and Lee, K.L. (1966)** — *Liquefaction of saturated sands during cyclic loading.* Journal of the Soil Mechanics and Foundations Division, 92, 105–134.
**Castro, G. (1975)** — *Liquefaction and cyclic mobility of saturated sands.* Journal of the Geotechnical Engineering Division, 101, 551–569.
**Ishihara, K. (1993)** — *Liquefaction and flow failure during earthquakes.* Géotechnique, 43, 351–451.

Foundational soil-liquefaction literature. Formal treatment of pore-pressure buildup under cyclic loading, precondition dependence (relative density, saturation, grain size), and post-liquefaction state. Source for the π and d formalism in `liquefaction.md`.

**Dahmen, K.A., Ben-Zion, Y., Uhl, J.T. (2009)** — *Micromechanical model for deformation in solids with universal predictions for stress-strain curves and slip avalanches.* Physical Review Letters, 102, 175501.

SOC statistics in slowly-sheared granular and solid materials. Relevant for establishing the granular substrate as SOC-compliant before adding liquefaction amplification.

**Pastor-Satorras, R. and Vespignani, A. (2001)** — *Epidemic spreading in scale-free networks.* Physical Review Letters, 86, 3200.

Epidemic amplification on networks. When external events (super-spreaders, holiday gatherings) raise effective R₀ above 1 transiently, the dynamic is structurally similar to liquefaction — external cyclic driving temporarily dismantling local damping.

---

## Reading Sequence

For someone starting from a strong physics or mathematics background:

1. Christensen and Moloney — establish the mathematical foundation
2. Clauset et al. 2009 — establish the statistical methodology
3. Hinrichsen 2000 — directed percolation and absorbing states
4. Vespignani and Zapperi 1998 + Bonachela and Muñoz 2009/2010 — modified SOC mathematics
5. Drossel and Schwabl 1992 + Malamud et al. 1998 — the forest fire template
6. Module 10.1 — overtopping-side mechanism precedents (rate-and-state, synaptic plasticity, adaptive networks)
7. Module 10.2 — liquefaction-side precedents if ISOC-side work is priority
8. Newman 2010 — networks and percolation
9. Popper + Mayo — falsifiability standards
10. Angrist and Pischke — research design
11. Domain specific modules as relevant

For someone starting from a social science background:

1. Bak 1996 — accessible SOC introduction
2. Clauset et al. 2009 — statistical methodology
3. Cederman 2003 + Clauset et al. 2007 — SOC in human systems
4. Scott 1998 + Taleb 2007 — intervention argument in human systems (overtopping-relevant)
5. Module 10.1 — mechanism precedents for structural fragility
6. Angrist and Pischke — research design
7. Popper + Mayo — falsifiability standards
8. Christensen and Moloney — the mathematical foundation
9. Domain specific modules as relevant

---

## Key Open Questions The Reading Should Answer

As you work through this material, these are the questions to keep in focus:

- Does any existing mathematical treatment of modified SOC generate the specific quantitative predictions overtopping and liquefaction require (phase transitions in parameter space, σ-damage correlations, history-dependent susceptibility)?
- Does the forest fire empirical literature provide a clean enough template for the research design in other systems?
- What is the minimum viable human system — which domain has the cleanest events, the most documentable intervention, and the best comparison cases?
- Does the directed percolation / absorbing state literature contain the percolation threshold termination mechanism explicitly or only implicitly?
- What statistical power is required to distinguish suppressed-release (overtopping-like) from genuine subcritical dynamics in real datasets — is this achievable?
- Has anyone attempted pre-registration of power law predictions in complex systems research?

---

*This study guide should be read alongside `overtopping.md`, `liquefaction.md`, `distorted_soc_signatures.md`, `falsifiability_requirements.md`, and `energy_depletion_percolation_research_paths.md`.*
