<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/zksf-mark-color-on-dark-tight.svg">
    <img src="assets/zksf-mark-color-on-light-tight.svg" alt="ZKSF" width="96">
  </picture>
</p>

# The Exponential Time Hypothesis Proof Checks, and Its Algorithm Is Brute Force on Every Formula That Could Exist

[![Proof check: Lean kernel and nanoda accept](https://img.shields.io/badge/proof_check-Lean_%E2%9C%93_%7C_nanoda_%E2%9C%93-2ea44f)](logs/stageB_run3_nanoda_bigstack.log)
[![openai/math at 7ef5c0c](https://img.shields.io/badge/openai%2Fmath-7ef5c0c-555555?logo=github)](https://github.com/openai/math/tree/7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a)
[![Lean 4.34.1](https://img.shields.io/badge/Lean-4.34.1-0055A2)](https://github.com/leanprover/lean4/releases/tag/v4.34.1)
[![zcc-verify on PyPI](https://img.shields.io/pypi/v/zcc-verify.svg?label=zcc-verify)](https://pypi.org/project/zcc-verify/)
[![qsim-sdk on PyPI](https://img.shields.io/pypi/v/qsim-sdk.svg?label=qsim-sdk)](https://pypi.org/project/qsim-sdk/)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Website zksf.org](https://img.shields.io/badge/website-zksf.org-6133BD)](https://zksf.org)
[![Quantum computing mobile app on Google Play](https://img.shields.io/badge/Mobile_app-Google_Play-34A853?logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=com.quantumcomputing.app)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23732240.svg)](https://doi.org/10.5281/zenodo.23732240)

ZKSF re-ran the published Lean check of the claimed subexponential #k-SAT algorithm in openai/math at commit 7ef5c0c,
with two independent proof kernels. We proved the check's inputs untampered and measured where the algorithm's
subexponential construction is actually used. Everything needed to repeat each step is in this repository, and the
write-up is `report.pdf`.

## Results

### The proof checks

| Run | Setup | Lean kernel | nanoda kernel | Result |
|---|---|---|---|---|
| 1 | comparator with OpenAI's configuration, unchanged (nanoda off) | accepts | not run | pass, 1 h 30 min on 18 threads |
| 2 | nanoda switched on, the challenge rebuilt from source | accepts | stopped by a stack overflow after 80 s, before reaching a verdict | exit 1 |
| 3 | as run 2, with nanoda's thread stack raised from 16 MiB to 1 GiB (`Dockerfile.bigstack`, the only change) | accepts | **accepts** | **pass**, "Your solution is okay!" |

The only axioms used are `propext`, `Quot.sound` and `Classical.choice`.

### The inputs are untampered

- Nothing outside the work volume changed during run 1 (`logs/stageB_run1_docker_diff.txt`).
- The challenge file, its configuration, the lakefile, the manifest and the toolchain file have GitHub's git blob hashes
  at the pinned commit (`logs/step2_challenge_hashes.txt`).
- All 8,926 compiled Mathlib and dependency files are byte-identical to a fresh download of the official cache
  (`logs/step3_olean_compare.log`).
- The challenge rebuilt from source in run 2 is byte-identical to the one built in run 1 (`logs/step4_olean_rebuild_compare.txt`).

### The formal statement is faithful

One fixed multi-tape Turing machine per k writes the exact count and the satisfiability bit for every formula of width at
most k, within the stated time and polynomial space, and each step is one action on one tape. For k = 3 this gives 3-SAT
in 2^{o(n)} time, the negation of ETH.

### Where the algorithm is used

The paper's Proposition 6.4 sets s = ⌊√λ/ν²⌋ with λ = ⌈log₂ n⌉ and ν = ⌈log₂ λ⌉, and says "If s < 2, we use exhaustive
search". s < 2 for every n ≤ 2^521,283 (a 156,922-digit number), so on every such formula the algorithm is exhaustive
search. The same holds again for 2^524,288 < n ≤ 2^639,999 (`logs/paper_threshold_windows.txt`). The verified program uses
its construction only above 2^639,999. These facts are checked in Lean against the proof's own definitions, with standard
axioms only (`cutoff_check.lean`, `logs/cutoff_check_compile.log`).

- `sparsifySchedule (2^521283) = 1` and `sparsifySchedule (2^521284) = 2`
- `sparsifySchedule (2^639999) = 1` and `sparsifySchedule (2^640000) = 2`
- `zksf_Ns_gt` proves that every threshold the proof's construction can choose exceeds 2^639,999.

Even with every hidden constant set to 1, the claimed bound is no better than 2^n for any n up to 2^65,536
(`logs/bound_vs_bruteforce.txt`). The theorem refutes ETH as mathematics and changes nothing for any formula that can be
written down.

### The brute-force regime on real engines

We ran one Grover iteration on the formula (x0 ∨ ¬x1)(x1 ∨ ¬x2)(x2 ∨ ¬x0), which has 2 solutions among 8 assignments.
Exact simulation puts 100% of shots on them, and random guessing would put 25%.

| Engine | Shots | On the 2 solutions | Certificate | Hardware fidelity |
|---|---|---|---|---|
| exact.cpu | 1,000 | 100% | 818bfc6914fa4377 (ZCC-v0.1, exact) | exact |
| exact.gpu | 1,000 | 100% | f385b7b3d59f4454 (ZCC-v0.1, exact) | exact |
| exact.tpu | 1,000 | 100% | 7dbcaa36f63c4b9c (ZCC-v0.1, exact) | exact |
| IQM Garnet | 560 | 44.1% | e2b1fe6a617649ec (ZHF-v0.1) | 0.437 |
| AQT IBEX | 100 | 44% | c752e4db92bb418a (ZHF-v0.1) | 0.416 |
| Rigetti Cepheus-1-108Q | 1,000 | 26.2% | 3b7a1267e203441a (ZHF-v0.1) | 0.252 |

Every certificate passes zcc-verify, and the JSON and PDF of each are in `certificates/`. On Rigetti's native gates the
circuit compiles to about 73 to 81 two-qubit gates (`logs/rigetti_compile_estimate.txt`). IonQ Forte and IQM Emerald were
offline at the time.

## How to repeat it

**Check our certificates with no account.** Run `pip install zcc-verify` and then `zcc-verify c752e4db92bb418a`, or any
other id above.

**Repeat the engine runs.** `engine_runs_public.py` needs a ZKSF account and an API key. Run it with `--quote` first to
see each engine's price.

**Repeat the proof check.** Run `bash run_check.sh`. It needs Docker, about 20 GB of disk, 24 GB of memory and about 2
hours. Each step is a command we ran and logged in `logs/`, and the script strings them together without itself having been
run end to end. The steps are as follows.

1. Build the image from `Dockerfile`, with Lean 4.34.1, comparator and lean4export v4.34.0, landrun ec104f6edc1e and
   nanoda 37cb87b7e6cd, all from pinned sources and run as a non-root user.
2. Stage A is the only step with network. It clones openai/math at 7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a and fetches
   the official Mathlib cache with `lake exe cache get`. Never run `lake update`, because several dependencies are pinned
   to `main` and would move.
3. Run 1 uses the published configuration.
4. Run 2 switches nanoda on, using the image from `Dockerfile.bigstack` for nanoda's larger stack, as our run 3 did.
5. Compile `cutoff_check.lean`.
6. Run `cutoff_threshold.py`.

Isolation is a Docker container with no network, as a non-root user. The checker's additional file-level layer (landrun)
needs Linux 7.2+, so on our 5.15 kernel we added the integrity checks above.

## Files

| File | What it holds |
|---|---|
| `report.pdf` | The write-up |
| `.zenodo.json` | The metadata Zenodo archives each release with |
| `Dockerfile`, `Dockerfile.bigstack` | The toolchain image, and nanoda with the larger stack |
| `run_check.sh` | Every step of the proof check |
| `cutoff_check.lean` | The Lean checks of the thresholds |
| `cutoff_threshold.py`, `cutoff_threshold_output.txt` | Where the schedule first stays at 2 or more |
| `engine_runs_public.py` | The engine runs with the public SDK |
| `certificates/` | The six certificates (JSON and PDF) and `engine_runs_summary.json` |
| `logs/` | Every run log and hash listing cited above |
| `assets/` | The ZKSF logo |

## Licence

CC-BY-4.0. Published by ZKSF (zksf.org).
