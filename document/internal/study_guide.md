---
title: "SOC Study Guide — Criticality Index Project"
linkTitle: "SOC Study Guide"
description: "Personalized reading + math + experiment plan tuned to project position: validation status, energy-accounting framework, and the path through Phases 0–4 with category-specific math rebuild strategy and per-phase deliverables."
author: "Gary Dalton"
date: 2026-04-23T00:00:00-05:00
lastmod: 2026-04-23T00:00:00-05:00
include_toc: true
show_comments: false
draft: true
weight: 50
keywords: "study guide, math rebuild, SOC theory reading, Sethna, Lübeck, Pruessner, C-DP, reaction-diffusion, percolation theory, EVT, phased plan, doubly-rusty math"
---

# SOC Study Guide — Criticality Index Project

A reading + math + experiment plan tuned to your actual position: validation experiments 01.01 (BTW) and 01.02 (Manna) complete with reproduction of published exponents; bracketed-xmin and `n_dissipated` methodology in place; overtopping and liquefaction frameworks drafted; energy-accounting framework (draft) anchored in C-DP reaction-diffusion with three reservoirs (grain, σ, heat); QoG Phase 0/0b/1 done, Phase 1b/2 in progress.

Your math background isn't a single arc. BSCE in 1992, then 20+ years running an IT consulting business (programming, networking — computational fluency stayed sharp, analytical math went dormant), returned for math grad work in 2019, exited 2021 about a year shy of MS with PhD intentions. That puts material in three categories rather than two: **doubly-rusty** (learned in undergrad long ago, only partially rebuilt 2019–21, now rusty again — the integration techniques for probability and ODE work you flagged live here), **reactivation** (covered in 2019–21, just out of practice), and **first-pass** (the program didn't reach it). The strategy is different for each.

---

## Position assessment

**What's already working in your codebase:**

- Five-signature battery validated on a deterministic-multiscaling substrate (BTW) and a stochastic simple-scaling substrate (Manna). Universality-class diagnostics functioning.
- Auto-xmin failure mode for multiscaling substrates discovered and worked around (manual + bracketed reporting).
- Activity-dependent `b(x)` plateau, three-regime PSD with β_high, FSS extrapolation, top-1% fractal-dimension regression, GPD tails, excess kurtosis growth.
- Clean experimental architecture (explore → ensemble → analyze) with resumable per-seed Arrow files.
- QoG preprocessing pipeline through slug clustering complete.

**What this guide is aimed at filling:**

1. Theoretical fluency with **coupled reaction-diffusion + heat continuity in NESS** — the framework underlying your overtopping and liquefaction "complex energy" extensions. Manna conserves grains under a clean RD continuum theory; the overtopping and liquefaction models add coupled fields (σ, H) that follow their own continuity equations. The canonical SOC literature underweights this regime.
2. **Absorbing-state phase transition** machinery beyond Christensen — needed to distinguish "distorted SOC" from "subcritical with bursts" in the rejection matrix and in QoG application.
3. **Quenched disorder and SOC on networks** — Exp 02 → Exp 03, then real QoG which lives on a heterogeneous network, not a clean lattice.
4. **Heavy-tail inference under censoring/truncation** — needed when QoG data hits and you face under-reporting, regime change, autocorrelation.
5. **Math fluency at working level** — measure theory, stochastic processes, dynamical systems, statistical inference. Reactivation for what your program covered; first-pass for what it didn't.

---

## Strategy for math rebuild

Three categories of material, three different strategies:

**Doubly-rusty** (undergrad foundation that wasn't fully restored in 2019–21). Integration techniques for probability — Jacobians for change of variables, MGF/CGF integrals, gamma/beta integrals, integration by parts on tail expectations — fall here. So does the ODE side of diffeq. The recovery path is targeted problem-work in a current-research-relevant context, not abstract calculus refresh. **Drill via Blitzstein chapters 5–8 problems** (continuous and joint distributions; you have the solutions manual, which is the right teaching scaffold). For ODE, **Strogatz chapters 2–6 problems** rebuild the qualitative side fast — the programming/algorithmic background helps because phase-plane analysis is more about state-evolution intuition than symbolic manipulation. Budget ~3–4 weeks of focused work before Phase 1 math depends on it.

**Reactivation** (covered in 2019–21, just out of practice). Two-to-four weeks per topic. Do, don't read. Worked solutions are the test that procedural memory is back.

**First-pass** (program didn't reach it). Read first, then problem-work. Budget eight to twelve weeks per topic. New material needs conceptual scaffolding before problem-solving makes sense.

**For all three: aim for current-experiment leverage.** Don't drill integration in the abstract; drill it on probability problems whose answers you'll cite next month. Don't redo all of Karlin & Taylor; focus on branching processes because that's what `b(x)` is.

**Two distinct intensity regimes.** Phase 0 is **peak math intensity**: ~10–12 hr/week for 2–3 weeks (15 hr probability + 10 hr ODE compressed into a short window). Once Phase 0 closes, the sustained rate drops to roughly **2 hr/week math + 3–4 hr/week theory reading** per the cross-phase weekly habit (see end of doc). Don't confuse the two — Phase 0's intensity is unsustainable and unnecessary as ongoing rate; the cross-phase rate is unsustainable and inadequate as a Phase 0 rate. Different jobs.

**Spaced revisit.** Each phase below names math to engage at the start. After 4–6 weeks, briefly revisit problems from earlier phases. Spaced repetition prevents re-rusting on what you just unrusted, and consolidates first-pass material.

**Identifying which category a topic falls in.** Open the relevant chapter and skim the first few problems. Recovering a known skill = reactivation. Reaching for half-remembered techniques from long ago = doubly-rusty (which is reactivation but slower and needs the engineering-undergrad layer rebuilt). Genuinely new derivations = first-pass.

**What not to do:** don't restart from undergraduate texts wholesale. Banner and the Friendly Analysis book are below the level you'd been working at. The targeted way to rebuild doubly-rusty material is to drill it inside the grad-level book that needs it — Blitzstein for probability integration, Strogatz for ODE — not by re-reading first-year calculus.

---

## Phase 0 — Foundation refresh (weeks 0–3, runs concurrent with starting Phase 1 reading)

Before Phase 1's measure theory and inference work depends on it, drill the doubly-rusty foundation directly:

**Probability integration drill.** Blitzstein & Hwang ch 5–8 problems with the solutions manual open. Targets:
- Density transformations and Jacobians (ch 8)
- MGF derivations for the named distributions (ch 6)
- Gamma and Beta integrals; the Γ(α)Γ(β)/Γ(α+β) identity should feel automatic by the end (ch 8)
- Integration by parts on tail expectations, E[X] = ∫P(X > x)dx for nonnegative X
- Iterated expectation, Adam's law and Eve's law in continuous form (ch 9)
- Time budget: ~15 hr across 2–3 weeks

This work feeds directly into Wasserman's bootstrap and MLE chapters in Phase 1, into the EVT integrals in Phase 4, and into branching-process expected-value calculations in Phase 2.

**ODE drill.** Strogatz ch 2–6 problems. Targets:
- Linear stability of fixed points (ch 2, 5)
- Phase portraits in 1D and 2D (ch 5–6)
- Bifurcation diagrams (ch 3, 8 — though ch 8 sits in Phase 2)
- Time budget: ~10 hr across 2 weeks

The qualitative phase-plane analysis is closer to algorithmic state-evolution reasoning than to symbolic ODE-solving, which plays to your programming background. Strogatz is engineered for problem-driven intuition rather than proof-heavy formalism. This work prepares you for the σ-field dynamics in Phase 2.

**Deliverable:** none; this is preparation. But you'll feel the difference when Phase 1's Wasserman work and Phase 2's stochastic processes don't keep tripping over integration mechanics.

---

## Phase 1 — Consolidation + measure/inference work (weeks 1–6)

**Experimental target:** Exp 01.03 (negative controls, rejection matrix).

**Why first:** the rejection matrix is the linchpin of every claim downstream. Until 01.03 is signed, BTW/Manna validation is reproduction, not load-bearing. The signatures that *cannot* discriminate well also need to be known — possibly more important than which can.

### Math to engage

**Measure theory (Bartle, ch 1–5).** Work problems, don't re-read text. Specifically:
- σ-algebras, measurable functions, integrability — Bartle ch 2–3 problems
- Dominated convergence and Fubini — ch 4–5 problems
- Lebesgue measure on ℝⁿ from Bartle's *Lebesgue Measure* portion
- Time budget: ~15 hr across 2 weeks if rusty at standard grad-prelim level

**Statistical inference (Wasserman, *All of Statistics*).** Work problems on:
- Hypothesis testing, p-values, multiple-testing corrections (chs 10–11)
- Bootstrap and jackknife (ch 8)
- Maximum likelihood and consistency (ch 9)
- Time budget: ~10 hr; this is directly used in the rejection-matrix construction

**Power-law inference.** Re-read the Clauset/Shalizi/Newman 2009 paper now that you've discovered its failure mode on BTW. Understanding *why* their KS-minimization fails on multiscaling substrates makes the bracketed-xmin rule feel principled rather than ad-hoc. Implement their goodness-of-fit test (KS p-value via parametric bootstrap) as part of your rejection-matrix tooling — it discriminates power-law from log-normal at known sample sizes.

### Theory reading

- **Sethna, *Statistical Mechanics: Entropy, Order Parameters, and Complexity* (2nd ed., 2018)** — freely available online from Sethna's website. The crackling-noise chapter is now the foundation for your shape-collapse test on existing 01.02 wave_profile data. This is the highest-leverage Phase 1 reading because it directly enables the first concrete result (see milestone 0 below). Read the crackling-noise chapter first; the rest of the book is a reference you'll revisit.
- **Christensen & Moloney, *Complexity and Criticality*** — re-read chapters on BTW, Manna, Oslo, Bak-Sneppen with your validation results in hand. The second pass is dramatically more useful than the first.
- **Goldenfeld, *Lectures on Phase Transitions and the RG*, ch 1–6** — mean-field theory, scaling hypothesis, RG flow, fixed points, relevant/irrelevant operators. Conceptual machinery for *why* simple scaling exists and why BTW's multiscaling violates it. Your xmin drift is the empirical signature of operators not flowing to a single fixed point. **This is reading, not problem-working** — Goldenfeld is one of the few books worth approaching linearly.
- **Pruessner 2012, *Self-Organised Criticality: Theory, Models and Characterisation*** — verify you have this; you cite it heavily in `01_01_btw_sandpile.md`. If not on your shelf, this is a high-priority addition. Chapter 7 (FSS in SOC) is canonical for the extrapolations you're already running.

**Specific papers (read alongside the books):**

- **Vespignani, Zapperi, Pietronero 2000** — the C-DP continuum field theory. Derives the reaction-diffusion form your `energy_accounting.md` framework anchors on.
- **Bonachela & Muñoz 2009**, *J. Stat. Mech.* P09009, "Self-organization without conservation: True or just apparent scale-invariance?" — self-organized quasi-criticality. Background for why C-DP RD applies to driven Manna and what changes when conservation is broken (relevant for overtopping).
- **Kuntz & Sethna 2000**, *Phys. Rev. B* 62, 11699 — derives the mean-field parabolic avalanche shape from the Langevin saddle-path. Companion reading to Sethna's crackling-noise chapter.
- **Papanikolaou et al. 2011**, *Nature Physics* 7, 316 — 2D corrections to the parabolic shape. The asymmetric power-form fit is what you'll regress against. Verify the specific (a, b) values cited in your `energy_accounting.md` against this paper.

### Experimental milestones

0. **Sethna shape-collapse on existing 01.02 wave_profile data (weeks 1–2)** — the highest-leverage near-term result in the entire program. No new ensembles, no new code beyond a shape-collapse analysis script. Bin avalanches by duration T, normalize each as `n(t/T) / n_max`, average within bin, plot bins together. Curves should collapse onto a single shape. Fit `C · u^a · (1−u)^b`; expect 2D asymmetry with peak at u < 0.5. **Outcome either way is diagnostic:** clean collapse validates the C-DP continuum-theory anchor in your `energy_accounting.md` framework; failed collapse means the framework's foundational assumption needs reconsideration before any further instrumentation. Do this before 01.03 work begins; results inform whether the energy-accounting framework can carry weight downstream.

1. Exp 01.03 simulator + signature battery for Poisson, BTW-subcritical, BTW-supercritical, Manna-subcritical, Manna-supercritical.
2. Rejection matrix: 5 signatures × 5 regimes. ROC-style discriminating power at fixed sample size. Add the avalanche-shape parameters (a, b, peak position) as a sixth signature alongside the existing five — the shape-collapse test gives you this for free once milestone 0 is done.
3. Methodology decision: which signatures are individually sufficient, which only work in combination.

**Deliverables:** shape-collapse note in `experiments/validation/` (small, tight) and signed rejection matrix in `01_03_negatives.md`. The first is a 2-week result; the second is the 4–6 week result. Both downstream documents cite them.

---

## Phase 2 — Coupled reaction-diffusion, NESS, driven-dissipative SOC (weeks 6–14)

**Experimental targets:** Exp 01.04 (overtopping, Models B and C) and Exp 01.05 (liquefaction).

**Why this is the hardest theoretical phase:** canonical SOC literature treats the activity wave (n(x,t)) and energy density (ρ(x,t)) as a coupled reaction-diffusion system in the Manna-baseline limit (Vespignani-Zapperi-Pietronero 2000, Lübeck 2004). Your overtopping model adds (a) a structural integrity field σ(x,t) with its own slow dynamics, (b) a heat reservoir H(x,t) with its own continuity equation ∂H/∂t = α_H · n − κH + D_H ∇²H, (c) coupling terms between (n, ρ, σ, H) — flux-driven damage, optionally heat-coupled recovery and heat-modulated thresholds. There is no single textbook for the four-field coupled system. You'll be assembling theory from absorbing-state phase transitions (Henkel, Marro-Dickman), Langevin/Fokker-Planck mechanics (Van Kampen), and the crackling-noise framework (Sethna).

### Math to engage

**Stochastic processes (Karlin & Taylor, *A First Course in Stochastic Processes*).** Work problems on:
- Branching processes (ch 8) — `b(x)` is a Galton-Watson branching observable. Understanding the underlying process makes b(x) deviations interpretable. Pay particular attention to subcritical/critical/supercritical branching and extinction probabilities.
- Diffusion approximations (ch 15) — the σ field's continuum limit if you go after analytical predictions for overtopping. **This chapter assumes ODE comfort.** Phase 0's Strogatz drill should have rebuilt that; if it hasn't fully landed, do another pass on Strogatz ch 5–6 before tackling K&T 15.
- Time budget: ~20 hr across 3 weeks.

**Continuous-time Markov chains (Norris, *Markov Chains*, ch 2–3).** Work problems on jump processes, master equations, generators. Useful for σ recovery dynamics and for any analytical prediction about the recovery timescale.
- Time budget: ~10 hr.

**Dynamical systems (Strogatz, *Nonlinear Dynamics and Chaos*, ch 7–9).** Phase 0 covered ch 2–6. This phase adds:
- Limit cycles (ch 7) — directly relevant to cyclic-driving liquefaction
- Bifurcations revisited (ch 8) — absorbing-state transitions as bifurcations in a stochastic activity field
- Time budget: ~10 hr (Phase 0 already absorbed the early-chapter cost).

**Langevin/Fokker-Planck (likely first-pass for you).** The σ field's relaxation dynamics are a coupled Langevin equation; the corresponding probability density evolves under a Fokker-Planck equation. K&T ch 15 is the gentlest entry from a probabilistic angle. **Van Kampen, *Stochastic Processes in Physics and Chemistry*** is the physics-flavored standard — master equations, Kramers-Moyal expansion, Fokker-Planck, system-size expansion. Worth adding to your shelf for this phase; it's where the σ field analytics actually live. Treat as first-pass: read first, then problem-work. Budget 4–6 weeks.

### Theory reading

- **Sethna, *Statistical Mechanics: Entropy, Order Parameters, and Complexity*, crackling-noise chapter** — by Phase 2 you've done the shape-collapse test from Phase 1 milestone 0, so you know whether C-DP RD anchors hold for natural Manna. In Phase 2 the question becomes: how does the shape distort under overtopping and liquefaction? Sethna's framework predicts mean-field parabolic; 2D corrections give asymmetry; coupled-field corrections (your σ and H) produce further deviations that become a primary discriminator between distortion mechanisms.
- **Henkel, Hinrichsen, Lübeck, *Non-Equilibrium Phase Transitions Vol. 1*** — chapters on directed percolation, conserved DP (your Manna baseline), the contact process, absorbing-state transitions. Overtopping is Manna coupled to a slow damage field that moves the system across an absorbing barrier; this book is where the absorbing-barrier vocabulary lives. Specifically read their treatment of **fixed-energy vs driven protocols** — you discovered the protocol-mismatch issue empirically with your z_∞ = 0.718 vs ρ_c = 0.683; the theoretical treatment makes the offset structure explicit.
- **Goldenfeld, dynamic critical phenomena chapters (later in the book)** — Langevin equations, Hohenberg-Halperin classification, Model A/B/C dynamics. The σ field's relaxation is most naturally a coupled Langevin equation; the heat field continuity equation is a related Model-B-like dynamics with conservation. You need this vocabulary to derive scaling predictions for overtopping.
- **Marro & Dickman, *Nonequilibrium Phase Transitions in Lattice Models*** — older, more pedagogically organized than Henkel for the lattice-model side. If Henkel feels dense, this is the gentler entry. Not currently on your shelf; worth adding for this phase.

**Specific papers:**

- **Lübeck 2004**, *Int. J. Mod. Phys. B* 18, 3977 — universal scaling of non-equilibrium phase transitions. The reference for C-DP exponents your Phase 1 work already validated against; in Phase 2, his RD framework becomes the derivation source for predicted distortions.
- **Sethna's crackling-noise review** if it's separately available — extends the textbook chapter with more shape-discrimination examples across magnetic and fracture systems. The cross-system universality is exactly the framing that makes shape distortion under overtopping/liquefaction interpretable.

### Experimental milestones

1. **Re-instrument 01.02 with Class A measurements** (cumulative per-bond flux, cumulative per-site KE) per `energy_accounting.md` §11. Sanity check: re-run must reproduce existing α∞, β_high, b(x) within ensemble noise. Failure here is an instrumentation bug, not a discovery — fix before proceeding.
2. Exp 01.04 Model B (threshold elevation only, no σ field). Tests prediction in `distorted_soc_signatures.md` II.1: bracket widening under suppressed-release.
3. Exp 01.04 Model C (full overtopping: σ field + flux damage + recovery). Phase-space map in (T, α, recovery_rate). Locate absorbing barrier.
4. **Cumulative-KE → σ-damage cross-experiment falsifiability test** (`energy_accounting.md` §10.4): correlate the cumulative `n_topples_i` map from re-instrumented 01.02 with the σ-damage map from Model C at small α. Strong correlation (r > 0.7) confirms σ-coupling is a small perturbation; weak correlation (r < 0.3) refutes the perturbative framing and forces a strong-coupling treatment.
5. Exp 01.05 (liquefaction with π = H field, cyclic driving). Test whether liquefaction produces shape distortions distinguishable from overtopping. Reverse heat → KE coupling activated for this experiment per framework §6.3. **Note:** 01.05 simulator depends on resolution of `liquefaction.md` open questions (cyclic-driver coupling form, per-site vs global preconditions). If these don't settle in Phase 2, liquefaction work pushes to a later phase and Phase 2 closes on overtopping alone.
6. Shape-distortion comparison: compare avalanche-shape (a, b) parameters across natural Manna (Phase 1 milestone 0), Model B, Model C, and liquefaction (if completed in this phase). Each distortion mechanism predicted to produce a signature shape deviation.

**Deliverables:** signed re-instrumented 01.02 baseline; two signed phase-space maps (overtopping, liquefaction); cumulative-KE-vs-damage correlation result; shape-distortion comparison table. The re-instrumented 01.02 is the foundation that both downstream maps cite. Also: an updated draft of `energy_accounting.md` reflecting empirical results — the developmental draft becomes a settled methods note if 01.04 confirms the framework.

---

## Phase 3 — Disorder, networks, percolation (weeks 14–22)

**Experimental targets:** Exp 02 (percolation validation) and Exp 03 (sandpile-on-percolation). Concurrently: completion of QoG `p02_network_data` (network layer construction).

**Why now:** real QoG data lives on a heterogeneous network with quenched disorder, missing data, time-varying connectivity. Sandpile-on-percolation is the synthetic bridge: stochastic SOC on a disordered substrate with known percolation transition. You need the theory of transport-on-fractals and SOC-on-networks before applying signatures to QoG.

### Math to engage

**Multifractal analysis (Falconer, ch 9, 10, 17).** Work the problems, particularly:
- Hausdorff dimension and box-counting dimension equivalence on regular sets (ch 2–3 review)
- Self-similar and self-affine sets (ch 9)
- Multifractal spectrum f(α) and its Legendre relation to τ(q) (ch 17)
- Time budget: ~20 hr; this is where rust will be most visible if you didn't do measure theory recently. Bartle reactivation in Phase 1 paid for this.

**Percolation theory** (probably need to add to shelf):
- **Stauffer & Aharony, *Introduction to Percolation Theory*** is the standard short text. Cheap, terse, problem-rich.
- Alternative: **Grimmett, *Percolation*** is more rigorous but heavier. Stauffer-Aharony is enough for your needs.
- Targets: 2D site/bond percolation exponents (β = 5/36, ν = 4/3, D_f = 91/48). These are what Exp 02 validates against.
- Time budget: ~10 hr.

**Graph theory for ensembles (Diestel + Bondy-Murty as reference).** Don't work problems linearly; use as reference for QoG network construction. Specifically: random graph ensembles, configuration model, degree sequences. Newman ch 13 covers most of this in the SOC-applicable form.

### Theory reading

- **Newman, *Networks*** — back third of the book: percolation on networks, network resilience, dynamic processes. Already on your shelf.
- **Dorogovtsev, Goltsev, Mendes 2008** ("Critical phenomena in complex networks", *Rev. Mod. Phys.*) — review article, freely available on arXiv. Heterogeneous mean-field, annealed vs quenched approximations, percolation on network ensembles. Single most useful document for your network-substrate work. Read once linearly, then keep open as reference.
- **Falconer, ch 9–10, 17** — fractal substrates and multifractal measures, in tandem with the math reactivation above.

### Experimental milestones

1. Exp 02: p_c measurement and cluster-statistics tools validated on random-bond and random-site percolation. Reproduce 2D exponents.
2. Exp 03: sandpile dynamics on percolation clusters at p > p_c. Compare τ_s, D_s to clean Manna; quantify substrate-dependence of each of the five signatures.
3. QoG `p02_network_data` completed and characterized in the same framework as the synthetic percolation results — your QoG-derived network's structural metrics need to live in the same vocabulary as your validation substrates.

**Deliverable:** signed `02_percolation.md` and `03_activation_threshold.md`. Substrate-dependence table for each of the five signatures. This protects against attributing QoG signature deviations to mechanism when they actually come from network heterogeneity.

---

## Phase 4 — Empirical inference and the QoG application (weeks 22–onward)

**Experimental targets:** QoG Phase 2 (variable mapping completion) → Phase 3 (locked analysis) → Phase 4 (synthesis).

**Why this needs its own phase:** validation has been on data you generated, where the answer is known. Real QoG data has censoring, truncation, missing values, autocorrelation, and slow regime changes. Your signature battery needs a real-data wrapper. Your `experiments/ideas/real_data_considerations.md` already starts on this; this phase is where it gets formalized and validated against synthetic distortions (Model F: artificial under-reporting on existing Manna ensemble).

### Math to engage

**Heavy-tail inference (Wasserman + papers).** Bootstrap for power-law fits, confidence intervals on τ_s, comparison-of-distributions methods. Wasserman ch 8 is the right starting place. Implement parametric bootstrap for your existing Clauset fits — it gives you proper CIs to report alongside the bracketed extrapolation.

**Extreme value theory.** Probably need to add:
- **Coles, *An Introduction to Statistical Modeling of Extreme Values*** — the standard. GEV and GPD distributions, threshold selection (close cousin to your xmin selection problem), block maxima vs peaks-over-threshold. You're already fitting GPD tails in your existing pipeline; Coles formalizes what you're doing and gives you the threshold-selection diagnostics you'll need for QoG.
- Time budget: ~15 hr of problem work after the Coles reading.

**Time series basics.** If your QoG signatures are computed on temporally ordered windows, you'll need basic time-series autocorrelation handling. **Shumway & Stoffer, *Time Series Analysis and Its Applications*** covers what you need (ch 1–3). Possibly worth adding; your current shelf doesn't have time series.

### Theory reading

- Your own `real_data_considerations.md` — formalize it.
- Recent applied SOC papers on real data (financial markets, neuroscience, geological — pick whichever is closest analog to QoG governance dynamics). The methodological tricks for handling censoring, regime change, and autocorrelation in real systems will be in those papers, not in textbooks.
- **Sornette, *Critical Phenomena in Natural Sciences*** — not on your shelf currently. Sornette treats SOC, financial crashes, earthquakes, and other real-world critical phenomena from a unified inference perspective. Worth considering for this phase specifically.

### Experimental milestones

1. Model F (artificial under-reporting on existing Manna ensemble) — cheap follow-up since the Arrow files exist. Validates the distorted-SOC signature battery against censoring artifacts.
2. QoG Phase 2: variable mapping completed. Document which QoG variables map to which slot in the SOC framework (driving rate, activity, dissipation channel, σ analog, π analog).
3. QoG Phase 3: locked analysis on a pre-registered subset of signatures. Pre-registration matters here because you'll know enough by Phase 4 to be tempted to fish.
4. QoG Phase 4: synthesis. Either a falsifiable claim about criticality in QoG data, or a well-documented null with explicit statement of what would have constituted a positive.

**Deliverable:** a paper. Or, if the data refuses to cooperate, a methods paper on the rejection-matrix + signature-battery framework that's of independent value.

---

## Cross-phase weekly habit

Weekly: 2 hours of problem-work in the math area you're currently engaging. Do this until each phase's math is durably back (or, for first-pass topics, durably learned). Without this, rust returns within ~2 months of stopping problem-work and you'll re-pay the cost when the next phase needs it.

A useful rotation: Mondays and Thursdays evenings, 1 hour each, alternating between "current-phase math" and "previous-phase math." Costs 2 hours/week, prevents re-rusting.

---

## Targeted shelf additions

In priority order. None are necessary, all would help.

1. **Sethna, *Statistical Mechanics: Entropy, Order Parameters, and Complexity* (2nd ed., 2018)** — freely available from Sethna's website. Crackling-noise chapter is the foundation for Phase 1's shape-collapse test, the highest-leverage near-term result in the program. This is now #1 by impact.
2. **Pruessner 2012, *Self-Organised Criticality*** — verify you don't already have it. If absent, this is the canonical SOC reference; you cite it heavily.
3. **Van Kampen, *Stochastic Processes in Physics and Chemistry*** — for Phase 2. Master equation, Fokker-Planck, system-size expansion. The natural framework for σ field analytics and for deriving the Sethna parabolic shape from the Langevin saddle-path.
4. **Stauffer & Aharony, *Introduction to Percolation Theory*** — for Phase 3. Short, cheap, problem-rich. Falconer covers the geometry but not the percolation transition itself.
5. **Coles, *An Introduction to Statistical Modeling of Extreme Values*** — for Phase 4. EVT formalization of what you're already doing with GPD tails.
6. **Marro & Dickman, *Nonequilibrium Phase Transitions in Lattice Models*** — for Phase 2 if Henkel feels dense.
7. **Shumway & Stoffer, *Time Series Analysis and Its Applications*** — for Phase 4 if QoG signatures are time-windowed.
8. **Sornette, *Critical Phenomena in Natural Sciences*** — for Phase 4 inference vocabulary.

---

## What to skip on your existing shelf

- **Banner**, **Friendly Analysis** — both below your level. Don't re-do undergrad calculus or analysis. Banner only if you want a quick lookup; Friendly Analysis is redundant given Bartle and Rudin.
- **Munkres** — keep as reference. Don't read linearly. Topology is not on your critical path.
- **Falconer**, **Diestel**, **Bondy-Murty**, **Wilson** — references, not cover-to-cover. Read the chapters Phase 3 names, leave the rest.
- **Goldstein** — only if you decide to pursue Langevin from a phase-space perspective in Phase 2. Otherwise irrelevant.
- **Gallian, Strang** — already-known material; reach for them only when a specific question demands.
- **Cover & Thomas, Callen** — useful for vocabulary (entropy, free energy in your overtopping writeup) but not load-bearing for the experimental progression. Reference, not study.

---

## Pitfalls specific to your work

These are the failure modes most likely to cost you a publication or six months of wasted compute.

1. **Multiscaling masquerading as simple scaling.** You've already discovered this on BTW. The risk in QoG is the reverse: simple scaling masquerading as multiscaling because of finite-data artifacts (small-sample fluctuations across xmin produce drift that looks like multiscaling). The bracket-width-shrinks-with-L test is the discriminator and only works if you have multiple system sizes. For QoG you'll need to construct synthetic "L" via subnational nesting (countries vs regions vs world) or temporal windows. Plan for this in Phase 4.

2. **Auto-xmin drift on real data.** Your bracketed-xmin rule handles this for synthetic. On QoG, the bracket may need to widen further (xmin = 5, 10, 30) because real-data noise floors are higher.

3. **Driven vs fixed-energy protocol confusion in citations.** When citing published exponents in the QoG paper, always state the protocol. ρ_c = 0.683 ≠ z_∞ = 0.718, and the same kind of error in QoG analog mappings would invalidate a comparison.

4. **Censoring artifacts vs overtopping-like distortion.** Both produce bracket-widening, both produce truncated heavy tails, both produce excess kurtosis. The Model F validation in Phase 4 is meant to disambiguate; don't write the QoG paper before it's done.

5. **Substrate-vs-mechanism attribution.** A QoG signature deviation from clean SOC could be (a) the criticality is real but distorted by overtopping-type dynamics, (b) the criticality is real but the network substrate has a different dimension than 2D Manna, or (c) it isn't critical at all. Phase 3's substrate-dependence table is meant to peel (b) from (a)+(c). Don't conflate these in interpretation.

6. **Slow regime change vs quasi-stationarity.** SOC analysis assumes a steady state. QoG governance regimes change on decade timescales — sometimes faster than your driving-to-dissipation timescale ratio assumes. Pre-registering window sizes and stationarity tests in Phase 4 protects against this.

7. **Instrumentation drift masquerading as discovery.** Your `energy_accounting.md` hard constraint #2 is the right discipline: re-instrumented 01.02 must reproduce existing α∞, β_high, b(x) within ensemble noise. The failure mode is convincing yourself that statistics shifted because the framework is "more correct" rather than because you accidentally changed dynamics. Build the reproduction check as a gate before any new claim is reported. If statistics shift and you can't trace it to a clear instrumentation bug, treat it as a bug until proven otherwise — not as a result.

---

## Summary — the path to results

| Phase | Weeks | Math focus | Theory | Result |
|---|---|---|---|---|
| 0 | 0–3 (concurrent) | Blitzstein 5–8 problems, Strogatz 2–6 problems | — | Foundation rebuilt |
| 1 | 1–6 | Bartle, Wasserman, Clauset re-read | Sethna crackling-noise + C-DP papers, Christensen 2nd pass, Goldenfeld 1–6, Pruessner | **Shape-collapse test (week ~2), then rejection matrix** |
| 2 | 6–14 | Karlin-Taylor, Norris, Strogatz 7–9, Van Kampen | Sethna, Henkel, Goldenfeld dynamic critical, Marro-Dickman | Re-instrumented 01.02 + overtopping + liquefaction phase maps + cumulative-KE-vs-damage correlation |
| 3 | 14–22 | Falconer 9-10-17, Stauffer-Aharony | Newman, Dorogovtsev review | Substrate-dependence table |
| 4 | 22+ | Wasserman bootstrap, Coles, time series | Real-data considerations, Sornette | QoG signature analysis (paper) |

The first concrete result is the Phase 1 shape-collapse test on existing 01.02 data — two weeks out, using only an analysis script. It either validates the C-DP RD anchor your `energy_accounting.md` framework rests on or doesn't; either outcome is publishable as a methods note. The Phase 1 rejection matrix follows at week ~6. The first publishable physics result is the Phase 2 phase-space maps + cumulative-KE-vs-damage cross-experiment test if the overtopping framework holds up — somewhere in the four-month range. The QoG application is a Phase 4 outcome, somewhere past the six-month mark.

The math work runs ~5–6 hours/week sustained across all phases. The theory reading runs ~3–4 hours/week. The experimental work takes the rest. Total time commitment is what you make of it; the phases are sequenceable but not all-or-nothing.