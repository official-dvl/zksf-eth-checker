/-
ZKSF cutoff check for openai/math 7ef5c0cc5ca4 (the "ETH is false" SAT proof).

The verified algorithm sparsifies with `sparsifySchedule n`, and the construction needs that schedule to be at
least 2 (by `le_sparsifySchedule_iff`, 2 ≤ schedule ↔ 4 · ν⁴ ≤ λ, with λ = ⌈log₂ n⌉ and ν = ⌈log₂ λ⌉). This file checks,
against their own definitions, that the schedule is still 1 at n = 2^639999 and first holds at 2 for good from
λ = 640000. Compile it from `lean/` in the checked clone with `lake env lean cutoff_check.lean`.
-/
import OAI.Algorithms.SubexponentialSAT.SqrtLogSpace.Asymptotics

open OAI.Algorithms.SubexponentialSAT.SqrtLogSpace

private theorem two_lt : 1 < (2 : ℕ) := by norm_num

/-- λ(2^k) = k, since the ceiling base-2 logarithm of an exact power of two is its exponent. -/
theorem zksf_lambda_two_pow (k : ℕ) (hk : 0 < k) : sparsifyLambda (2 ^ k) = k := by
  unfold sparsifyLambda
  have h1 : Nat.clog 2 (2 ^ k) ≤ k := (Nat.le_pow_iff_clog_le two_lt).mp le_rfl
  have h2 : k - 1 < Nat.clog 2 (2 ^ k) :=
    (Nat.pow_lt_iff_lt_clog two_lt).mp (Nat.pow_lt_pow_right two_lt (by omega))
  omega

/-- ν = ⌈log₂ λ⌉ = 20 for both λ = 639999 and λ = 640000 (2^19 < λ ≤ 2^20). -/
theorem zksf_clog_639999 : Nat.clog 2 639999 = 20 := by
  have h1 : Nat.clog 2 639999 ≤ 20 := (Nat.le_pow_iff_clog_le two_lt).mp (by norm_num)
  have h2 : 19 < Nat.clog 2 639999 := (Nat.pow_lt_iff_lt_clog two_lt).mp (by norm_num)
  omega

theorem zksf_clog_640000 : Nat.clog 2 640000 = 20 := by
  have h1 : Nat.clog 2 640000 ≤ 20 := (Nat.le_pow_iff_clog_le two_lt).mp (by norm_num)
  have h2 : 19 < Nat.clog 2 640000 := (Nat.pow_lt_iff_lt_clog two_lt).mp (by norm_num)
  omega

theorem zksf_sqrt_639999 : Nat.sqrt 639999 = 799 := by
  have h1 : 799 ≤ Nat.sqrt 639999 := Nat.le_sqrt'.mpr (by norm_num)
  have h2 : Nat.sqrt 639999 < 800 := Nat.sqrt_lt'.mpr (by norm_num)
  omega

theorem zksf_sqrt_640000 : Nat.sqrt 640000 = 800 := by
  have h1 : 800 ≤ Nat.sqrt 640000 := Nat.le_sqrt'.mpr (by norm_num)
  have h2 : Nat.sqrt 640000 < 801 := Nat.sqrt_lt'.mpr (by norm_num)
  omega

/-- At n = 2^639999 the schedule is 1, below the required 2, because √639999 = 799, ν = 20 and 799 / 20² = 1. -/
theorem zksf_schedule_at_2_pow_639999 : sparsifySchedule (2 ^ 639999) = 1 := by
  unfold sparsifySchedule sparsifyNu
  rw [zksf_lambda_two_pow 639999 (by norm_num), zksf_clog_639999, zksf_sqrt_639999]
  norm_num

/-- At n = 2^640000 it is 2, because √640000 = 800, ν = 20 and 800 / 20² = 2. -/
theorem zksf_schedule_at_2_pow_640000 : sparsifySchedule (2 ^ 640000) = 2 := by
  unfold sparsifySchedule sparsifyNu
  rw [zksf_lambda_two_pow 640000 (by norm_num), zksf_clog_640000, zksf_sqrt_640000]
  norm_num

/-- The proof's own cutoff is `max 20 (max Nleaf Ns)` with `Ns` ANY number past which the schedule stays at least 2
(`NativeLargeEntry.lean`, lines 48-50, via `Filter.eventually_atTop`). Every such `Ns` exceeds 2^639999, so the
verified program never runs its subexponential construction on a formula with at most 2^639999 variables. -/
theorem zksf_Ns_gt (Ns : ℕ) (hNs : ∀ n ≥ Ns, 2 ≤ sparsifySchedule n) : 2 ^ 639999 < Ns := by
  by_contra h
  have h2 := hNs (2 ^ 639999) (Nat.le_of_not_lt h)
  rw [zksf_schedule_at_2_pow_639999] at h2
  exact absurd h2 (by norm_num)

/-! The paper (Proposition 6.4, pp. 43-44) defines the same s and says "If s < 2, we use exhaustive search".
s first reaches 2 at λ = 521284 (722² = 521284, ν = 19), so it is 1 at n = 2^521283 and 2 at n = 2^521284. -/

theorem zksf_clog_521283 : Nat.clog 2 521283 = 19 := by
  have h1 : Nat.clog 2 521283 ≤ 19 := (Nat.le_pow_iff_clog_le two_lt).mp (by norm_num)
  have h2 : 18 < Nat.clog 2 521283 := (Nat.pow_lt_iff_lt_clog two_lt).mp (by norm_num)
  omega

theorem zksf_clog_521284 : Nat.clog 2 521284 = 19 := by
  have h1 : Nat.clog 2 521284 ≤ 19 := (Nat.le_pow_iff_clog_le two_lt).mp (by norm_num)
  have h2 : 18 < Nat.clog 2 521284 := (Nat.pow_lt_iff_lt_clog two_lt).mp (by norm_num)
  omega

theorem zksf_sqrt_521283 : Nat.sqrt 521283 = 721 := by
  have h1 : 721 ≤ Nat.sqrt 521283 := Nat.le_sqrt'.mpr (by norm_num)
  have h2 : Nat.sqrt 521283 < 722 := Nat.sqrt_lt'.mpr (by norm_num)
  omega

theorem zksf_sqrt_521284 : Nat.sqrt 521284 = 722 := by
  have h1 : 722 ≤ Nat.sqrt 521284 := Nat.le_sqrt'.mpr (by norm_num)
  have h2 : Nat.sqrt 521284 < 723 := Nat.sqrt_lt'.mpr (by norm_num)
  omega

theorem zksf_schedule_at_2_pow_521283 : sparsifySchedule (2 ^ 521283) = 1 := by
  unfold sparsifySchedule sparsifyNu
  rw [zksf_lambda_two_pow 521283 (by norm_num), zksf_clog_521283, zksf_sqrt_521283]
  norm_num

theorem zksf_schedule_at_2_pow_521284 : sparsifySchedule (2 ^ 521284) = 2 := by
  unfold sparsifySchedule sparsifyNu
  rw [zksf_lambda_two_pow 521284 (by norm_num), zksf_clog_521284, zksf_sqrt_521284]
  norm_num

#print axioms zksf_schedule_at_2_pow_639999
#print axioms zksf_schedule_at_2_pow_640000
#print axioms zksf_Ns_gt
#print axioms zksf_schedule_at_2_pow_521283
#print axioms zksf_schedule_at_2_pow_521284
