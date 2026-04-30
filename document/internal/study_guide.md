---
title: "SOC Study Guide — Tailored Plan for Gary Dalton"
linkTitle: "SOC Study Guide"
description: "Phased reading + math plan tailored to Gary Dalton's background: category-specific math rebuild strategy, per-phase math + theory targets, and a consolidated reading list."
author: "Gary Dalton"
date: 2026-04-23T00:00:00-05:00
lastmod: 2026-04-23T00:00:00-05:00
include_toc: true
show_comments: false
draft: true
weight: 50
keywords: "study guide, math rebuild, SOC theory reading, Sethna, Lübeck, Pruessner, C-DP, reaction-diffusion, percolation theory, EVT, phased plan, doubly-rusty math"
---

# SOC Study Guide — Tailored Plan for Gary Dalton

A phased plan for math rebuild and SOC theory study, tailored to Gary Dalton's background: BSCE 1992, ~20+ years in IT consulting (computational fluency stayed sharp; analytical math went dormant), returned for math grad work 2019, exited 2021 about a year shy of MS. Math falls into three categories — **doubly-rusty** (learned long ago, partially rebuilt 2019–21), **reactivation** (covered 2019–21, out of practice), and **first-pass** (not yet covered). Strategy differs per category. Phases are sequenceable but not all-or-nothing.

---

## Topical fluency targets

What this plan is aimed at building, in order:

1. **Coupled reaction-diffusion + heat continuity in NESS** — the framework underlying overtopping and liquefaction extensions. Canonical SOC literature underweights this regime.
2. **Absorbing-state phase transitions** beyond Christensen — needed to distinguish distorted SOC from subcritical-with-bursts.
3. **Quenched disorder and SOC on networks** — for percolation experiments and any application to heterogeneous real-world data.
4. **Heavy-tail inference under censoring/truncation** — for real-data application.
5. **Math fluency at working level** — measure theory, stochastic processes, dynamical systems, statistical inference.

---

## Strategy for math rebuild

Three categories of material, three different strategies:

**Doubly-rusty** (undergrad foundation that wasn't fully restored in 2019–21). Integration techniques for probability — Jacobians for change of variables, MGF/CGF integrals, gamma/beta integrals, integration by parts on tail expectations — fall here. So does the ODE side of diffeq. The recovery path is targeted problem-work in a current-research-relevant context, not abstract calculus refresh. **Drill via Blitzstein chapters 5–8 problems** (continuous and joint distributions; the solutions manual is the right teaching scaffold). For ODE, **Strogatz chapters 2–6 problems** rebuild the qualitative side fast — phase-plane analysis is closer to algorithmic state-evolution reasoning than symbolic manipulation. Budget ~3–4 weeks of focused work.

**Reactivation** (covered in 2019–21, just out of practice). Two-to-four weeks per topic. Do, don't read. Worked solutions are the test that procedural memory is back.

**First-pass** (program didn't reach it). Read first, then problem-work. Budget eight to twelve weeks per topic. New material needs conceptual scaffolding before problem-solving makes sense.

**Aim for downstream leverage.** Don't drill integration in the abstract; drill it on problems whose answers feed the next phase. Don't redo all of Karlin & Taylor; focus on branching processes because that's what activity-dependent `b(x)` measures.

**Two distinct intensity regimes.**
- **Phase 0 — peak**: ~10–12 hr/week for 2–3 weeks (15 hr probability + 10 hr ODE compressed).
- **Phases 1–4 — sustained**: ~2 hr/week math + ~3–4 hr/week theory reading.

Don't confuse them. Phase 0's intensity is unsustainable and unnecessary as ongoing rate; the sustained rate is inadequate as a Phase 0 rate.

**Spaced revisit.** After 4–6 weeks, briefly revisit problems from earlier phases. Prevents re-rusting on freshly-unrusted material; consolidates first-pass.

**Identifying which category a topic falls in.** Open the relevant chapter and skim the first few problems. Recovering a known skill = reactivation. Reaching for half-remembered techniques = doubly-rusty (slower than reactivation; needs the engineering-undergrad layer rebuilt). Genuinely new derivations = first-pass.

**What not to do.** Don't restart from undergraduate texts wholesale. Banner and the Friendly Analysis book sit below the level you'd been working at. Rebuild doubly-rusty material *inside* the grad-level book that needs it — Blitzstein for probability integration, Strogatz for ODE — not by re-reading first-year calculus.

---

## Phase 0 — Foundation refresh (weeks 0–3)

Drill the doubly-rusty foundation directly before Phase 1's measure theory and inference work depends on it.

**Probability integration drill.** Blitzstein & Hwang ch 5–8 problems with the solutions manual open. Targets:
- Density transformations and Jacobians (ch 8)
- MGF derivations for the named distributions (ch 6)
- Gamma and Beta integrals; the Γ(α)Γ(β)/Γ(α+β) identity should feel automatic by the end (ch 8)
- Integration by parts on tail expectations, E[X] = ∫P(X > x) dx for nonnegative X
- Iterated expectation, Adam's law and Eve's law in continuous form (ch 9)
- Time budget: ~15 hr across 2–3 weeks

Feeds into Wasserman's bootstrap and MLE chapters in Phase 1, EVT integrals in Phase 4, and branching-process expected-value calculations in Phase 2.

**ODE drill.** Strogatz ch 2–6 problems. Targets:
- Linear stability of fixed points (ch 2, 5)
- Phase portraits in 1D and 2D (ch 5–6)
- Bifurcation diagrams (ch 3; ch 8 sits in Phase 2)
- Time budget: ~10 hr across 2 weeks

The qualitative phase-plane analysis is closer to algorithmic state-evolution reasoning than symbolic ODE-solving. Strogatz is engineered for problem-driven intuition rather than proof-heavy formalism.

---

## Phase 1 — Measure / inference / mean-field SOC (weeks 1–6)

### Math

**Measure theory (Bartle, ch 1–5).** Work problems, don't re-read text. Specifically:
- σ-algebras, measurable functions, integrability — Bartle ch 2–3 problems
- Dominated convergence and Fubini — ch 4–5 problems
- Lebesgue measure on ℝⁿ from Bartle's *Lebesgue Measure* portion
- Time budget: ~15 hr across 2 weeks if rusty at standard grad-prelim level

**Statistical inference (Wasserman, *All of Statistics*).** Work problems on:
- Hypothesis testing, p-values, multiple-testing corrections (ch 10–11)
- Bootstrap and jackknife (ch 8)
- Maximum likelihood and consistency (ch 9)
- Time budget: ~10 hr

**Power-law inference.** Re-read Clauset-Shalizi-Newman 2009 with a critical eye on KS-minimization. Implement the goodness-of-fit test (KS p-value via parametric bootstrap).

### Theory reading

- **Sethna, *Statistical Mechanics: Entropy, Order Parameters, and Complexity* (2nd ed., 2018)** — crackling-noise chapter is the foundation for shape-collapse work.
- **Christensen & Moloney, *Complexity and Criticality*** — second pass with validation experience under the belt.
- **Goldenfeld, *Lectures on Phase Transitions and the RG*, ch 1–6** — mean-field theory, scaling hypothesis, RG flow, fixed points, relevant/irrelevant operators. Reading, not problem-working — Goldenfeld is one of the few books worth approaching linearly.
- **Pruessner 2012, *Self-Organised Criticality: Theory, Models and Characterisation*** — canonical SOC reference. Chapter 7 (FSS in SOC) is canonical.

**Phase 1 papers** (read alongside the books):
- Clauset, Shalizi, Newman 2009 — power-law fitting, with attention to failure modes.
- Vespignani, Zapperi, Pietronero 2000 — C-DP continuum field theory.
- Bonachela & Muñoz 2009 — self-organized quasi-criticality.
- Kuntz & Sethna 2000 — mean-field parabolic avalanche shape from Langevin saddle-path.
- Papanikolaou et al. 2011 — 2D corrections to parabolic shape.
- Tebaldi, De Menech, Stella 1999 — BTW multiscaling.

---

## Phase 2 — Coupled reaction-diffusion, NESS, driven-dissipative SOC (weeks 6–14)

The hardest theoretical phase. There is no single textbook for the four-field coupled (n, ρ, σ, H) system. Theory comes from absorbing-state phase transitions (Henkel, Marro-Dickman), Langevin/Fokker-Planck mechanics (Van Kampen), and the crackling-noise framework (Sethna).

### Math

**Stochastic processes (Karlin & Taylor).** Work problems on:
- Branching processes (ch 8) — `b(x)` is a Galton-Watson branching observable. Pay attention to subcritical/critical/supercritical branching and extinction probabilities.
- Diffusion approximations (ch 15) — for the σ field's continuum limit. Assumes ODE comfort; if Phase 0 hasn't fully landed, do another pass on Strogatz ch 5–6 first.
- Time budget: ~20 hr across 3 weeks.

**Continuous-time Markov chains (Norris, ch 2–3).** Jump processes, master equations, generators. Useful for σ recovery dynamics. Time budget: ~10 hr.

**Dynamical systems (Strogatz, ch 7–9).**
- Limit cycles (ch 7) — directly relevant to cyclic-driving liquefaction.
- Bifurcations revisited (ch 8) — absorbing-state transitions as bifurcations in a stochastic activity field.
- Time budget: ~10 hr.

**Langevin / Fokker-Planck.** Likely first-pass. K&T ch 15 is the gentlest entry from a probabilistic angle. **Van Kampen, *Stochastic Processes in Physics and Chemistry*** is the physics-flavored standard — master equations, Kramers-Moyal expansion, Fokker-Planck, system-size expansion. Treat as first-pass: read first, then problem-work. Budget 4–6 weeks.

### Theory reading

- **Sethna's crackling-noise chapter** — by Phase 2 you've done the shape-collapse work; here the question becomes how shapes distort under coupled-field corrections.
- **Henkel, Hinrichsen, Lübeck, *Non-Equilibrium Phase Transitions Vol. 1*** — directed percolation, conserved DP, contact process, absorbing-state transitions. Read their treatment of fixed-energy vs driven protocols specifically.
- **Goldenfeld, dynamic critical phenomena chapters (later in the book)** — Langevin equations, Hohenberg-Halperin classification, Model A/B/C dynamics. Vocabulary for σ-field relaxation and heat-field continuity.
- **Marro & Dickman, *Nonequilibrium Phase Transitions in Lattice Models*** — older, more pedagogically organized than Henkel for the lattice-model side. Gentler entry.

**Phase 2 papers:**
- Lübeck 2004 — universal scaling of non-equilibrium phase transitions; the RD framework as derivation source.
- Sethna's crackling-noise review (if separately published) — cross-system shape-discrimination examples.

---

## Phase 3 — Disorder, networks, percolation (weeks 14–22)

### Math

**Multifractal analysis (Falconer, ch 9, 10, 17).** Work the problems:
- Hausdorff and box-counting dimension equivalence on regular sets (ch 2–3 review)
- Self-similar and self-affine sets (ch 9)
- Multifractal spectrum f(α) and Legendre relation to τ(q) (ch 17)
- Time budget: ~20 hr. Bartle reactivation in Phase 1 paid for this.

**Percolation theory:**
- **Stauffer & Aharony, *Introduction to Percolation Theory*** — short, terse, problem-rich. Standard.
- Alternative: **Grimmett, *Percolation*** — more rigorous but heavier.
- Targets: 2D site/bond percolation exponents (β = 5/36, ν = 4/3, D_f = 91/48).
- Time budget: ~10 hr.

**Graph theory (Diestel + Bondy-Murty as reference).** Use as needed for network construction; don't work problems linearly. Random graph ensembles, configuration model, degree sequences.

### Theory reading

- **Newman, *Networks*** — back third: percolation on networks, network resilience, dynamic processes.
- **Dorogovtsev, Goltsev, Mendes 2008** ("Critical phenomena in complex networks", *Rev. Mod. Phys.* 80, 1275) — review article, freely available on arXiv. Heterogeneous mean-field, annealed vs quenched, percolation on network ensembles. **Single most useful document for network-substrate work.** Read once linearly, then keep open as reference.
- **Falconer, ch 9–10, 17** — fractal substrates and multifractal measures, in tandem with the math reactivation above.

---

## Phase 4 — Empirical inference and real-data application (weeks 22+)

### Math

**Heavy-tail inference (Wasserman + papers).** Bootstrap for power-law fits, confidence intervals, comparison-of-distributions methods. Wasserman ch 8 is the right starting place. Implement parametric bootstrap for Clauset fits — gives proper CIs.

**Extreme value theory.** **Coles, *An Introduction to Statistical Modeling of Extreme Values*** is the standard. GEV and GPD distributions, threshold selection (cousin of xmin selection), block maxima vs peaks-over-threshold. Time budget: ~15 hr after the reading.

**Time series basics.** **Shumway & Stoffer, *Time Series Analysis and Its Applications*** ch 1–3 — autocorrelation handling for time-windowed signatures.

### Theory reading

- Recent applied SOC papers on real-world data (financial markets, neuroscience, geological — pick the closest analog to the application target). Methodological tricks for censoring, regime change, and autocorrelation in real systems live in papers, not textbooks.
- **Sornette, *Critical Phenomena in Natural Sciences*** — SOC, financial crashes, earthquakes, and other real-world critical phenomena from a unified inference perspective.

---

## Cross-phase weekly habit

After Phase 0, sustain ~2 hours of math problem-work per week in the area you're currently engaging. Do this until each phase's math is durably back (or, for first-pass topics, durably learned). Without the sustained drill, rust returns within ~2 months of stopping problem-work, and you'll re-pay the cost when the next phase needs it.

A useful rotation: Mondays and Thursdays, 1 hour each, alternating "current-phase math" and "previous-phase math." Costs 2 hr/week, prevents re-rusting.

Theory reading runs separately at ~3–4 hr/week — don't conflate the two.

---

## Reading list — full inventory

Every book and major paper named in this guide, consolidated.

### Books — active use

Status legend: **on shelf** = confirmed already owned; **verify** = on shelf assumed but worth confirming; **acquire** = not on shelf, recommended addition.

| Title | Author(s) | Phase | Status | Priority | Role |
|-------|-----------|-------|--------|----------|------|
| *Introduction to Probability* (+ solutions manual) | Blitzstein & Hwang | 0, 1 | on shelf | core | Probability integration drill (ch 5–8); foundation for Wasserman + EVT |
| *Nonlinear Dynamics and Chaos* | Strogatz | 0, 2 | on shelf | core | Phase-plane intuition (ch 2–6); limit cycles + bifurcations (ch 7–9) |
| *Elements of Real Analysis / of Integration* | Bartle | 1 | on shelf | core | Measure-theory reactivation; Lebesgue integration |
| *All of Statistics* | Wasserman | 1, 4 | on shelf | core | Hypothesis testing, bootstrap, MLE; bootstrap CI for Phase 4 |
| *Statistical Mechanics: Entropy, Order Parameters, and Complexity* (2nd ed., 2018) | Sethna | 1, 2 | acquire (PDF on Sethna's Cornell page; verify current — 1st ed was free, 2nd ed status worth confirming) | **#1 by impact** | Crackling-noise chapter underpins shape-collapse + cross-system universality |
| *Complexity and Criticality* | Christensen & Moloney | 1 | on shelf | core | Re-read with validation experience |
| *Lectures on Phase Transitions and the RG* (ch 1–6, then dynamic critical chapters) | Goldenfeld | 1, 2 | on shelf | core | Mean-field, scaling hypothesis, RG (Phase 1); Hohenberg-Halperin Models A/B/C, Langevin (Phase 2) |
| *Self-Organised Criticality: Theory, Models and Characterisation* | Pruessner 2012 | 1 | verify | high | Canonical SOC reference. Top acquisition priority if absent |
| *A First Course in Stochastic Processes* | Karlin & Taylor | 2 | on shelf | core | Branching processes (ch 8); diffusion approximations (ch 15) |
| *Markov Chains* | Norris | 2 | on shelf | core | Continuous-time Markov chains (ch 2–3); jump processes |
| *Stochastic Processes in Physics and Chemistry* | Van Kampen | 2 | acquire | high | Master equation, Fokker-Planck, system-size expansion. First-pass; budget 4–6 weeks |
| *Non-Equilibrium Phase Transitions Vol. 1* | Henkel, Hinrichsen, Lübeck | 2 | verify | high | Directed percolation, conserved DP, absorbing-state transitions, fixed-energy vs driven protocols |
| *Nonequilibrium Phase Transitions in Lattice Models* | Marro & Dickman | 2 | acquire (only if Henkel feels dense) | optional | Older, more pedagogically organized than Henkel |
| *Fractal Geometry: Mathematical Foundations and Applications* | Falconer | 3 | on shelf (use as targeted reference) | targeted (ch 9, 10, 17) | Hausdorff/box-counting, multifractal spectrum |
| *Introduction to Percolation Theory* | Stauffer & Aharony | 3 | acquire | high | Short, cheap, problem-rich. 2D site/bond percolation exponents |
| *Percolation* | Grimmett | 3 | acquire (alternative to Stauffer-Aharony) | optional | More rigorous; heavier |
| *Networks* | Newman | 3 | on shelf | core | Back third — percolation on networks, network resilience |
| *Graph Theory* | Diestel | 3 | on shelf (reference) | reference | Random graph ensembles, configuration model |
| *Graph Theory* | Bondy & Murty | 3 | on shelf (reference) | reference | Same role as Diestel |
| *An Introduction to Statistical Modeling of Extreme Values* | Coles | 4 | acquire | high | GEV/GPD, threshold selection, peaks-over-threshold |
| *Time Series Analysis and Its Applications* | Shumway & Stoffer | 4 | acquire | conditional (if signatures are time-windowed) | Autocorrelation handling |
| *Critical Phenomena in Natural Sciences* | Sornette | 4 | acquire | optional | SOC + financial + earthquakes from unified inference perspective |

### Books on shelf, deprioritized

References or unrelated work; not part of active study.

| Title | Author | Reason |
|-------|--------|--------|
| *The Calculus Lifesaver* | Banner | Below working level; quick lookup only |
| *Friendly Introduction to Analysis* | Friendly Analysis | Below Bartle/Rudin level; redundant |
| *Topology* | Munkres | Topology not on critical path; reference only |
| *Introduction to Graph Theory* | Wilson | Covered by Diestel/Bondy-Murty |
| *Classical Mechanics* | Goldstein | Only if pursuing Langevin from phase-space angle in Phase 2 |
| *Contemporary Abstract Algebra* | Gallian | Already-known material |
| *Linear Algebra* | Strang | Already-known material |
| *Elements of Information Theory* | Cover & Thomas | Vocabulary only; not load-bearing |
| *Thermodynamics* | Callen | Vocabulary only |
| *Principles of Mathematical Analysis* | Rudin | Reference; Bartle is the active analysis text |

### Papers — by phase

**Phase 1:**
- Clauset, A., Shalizi, C. R., Newman, M. E. J. (2009). "Power-law distributions in empirical data." *SIAM Review* 51, 661.
- Vespignani, A., Zapperi, S., Pietronero, L. (2000). C-DP continuum field theory.
- Bonachela, J. A., Muñoz, M. A. (2009). "Self-organization without conservation: True or just apparent scale-invariance?" *J. Stat. Mech.* P09009.
- Kuntz, M. C., Sethna, J. P. (2000). "Noise in disordered systems: The power spectrum and dynamic exponents in avalanche models." *Phys. Rev. B* 62, 11699.
- Papanikolaou, S., et al. (2011). "Universality beyond power laws and the average avalanche shape." *Nature Physics* 7, 316.
- Tebaldi, C., De Menech, M., Stella, A. L. (1999). "Multifractality, microcanonical distributions and universality of branching processes." *Phys. Rev. Lett.* 83, 3952.

**Phase 2:**
- Lübeck, S. (2004). "Universal scaling behavior of non-equilibrium phase transitions." *Int. J. Mod. Phys. B* 18, 3977.
- Sethna's crackling-noise review (if separately published).

**Phase 3:**
- Dorogovtsev, S. N., Goltsev, A. V., Mendes, J. F. F. (2008). "Critical phenomena in complex networks." *Rev. Mod. Phys.* 80, 1275. Freely on arXiv.

**Phase 4:**
- Recent applied SOC papers on real data (financial markets, neuroscience, geological — pick whichever is closest analog to the application target).

### Online and free resources

- **Sethna's *Statistical Mechanics* PDF** — verify on Sethna's Cornell page (1st edition was free; 2nd ed status worth confirming).
- **arXiv pre-prints** for the papers above where available (especially Dorogovtsev review, Bonachela-Muñoz, Papanikolaou).

### Quick acquisition shopping list

Priority order for filling shelf gaps:

1. **Sethna PDF** — verify on Cornell page; acquire 2nd edition if not free.
2. **Pruessner 2012** — verify on shelf; if absent, top priority.
3. **Stauffer & Aharony, *Percolation*** — Phase 3 prerequisite.
4. **Van Kampen, *Stochastic Processes*** — Phase 2 first-pass.
5. **Coles, *Extreme Values*** — Phase 4.
6. **Henkel et al., *Non-Equilibrium Phase Transitions Vol. 1*** — Phase 2.
7. (Conditional) **Shumway & Stoffer** — Phase 4 if time-windowed.
8. (Conditional) **Sornette, *Critical Phenomena*** — Phase 4 inference vocabulary.
9. (Conditional) **Marro & Dickman** — Phase 2 if Henkel proves too dense.

---

## Summary table

| Phase | Weeks | Math focus | Theory reading |
|-------|-------|------------|----------------|
| 0 | 0–3 | Blitzstein 5–8 problems, Strogatz 2–6 problems | — |
| 1 | 1–6 | Bartle, Wasserman, Clauset re-read | Sethna crackling-noise, C-DP papers, Christensen 2nd pass, Goldenfeld 1–6, Pruessner |
| 2 | 6–14 | Karlin-Taylor, Norris, Strogatz 7–9, Van Kampen | Sethna, Henkel, Goldenfeld dynamic critical, Marro-Dickman |
| 3 | 14–22 | Falconer 9, 10, 17; Stauffer-Aharony | Newman, Dorogovtsev review |
| 4 | 22+ | Wasserman bootstrap, Coles, time series | Real-data SOC papers, Sornette |

Math runs ~5–6 hr/week sustained across all phases (after the Phase 0 peak); theory reading ~3–4 hr/week.
