"""The verified program's cutoff, lower bound, by exact integer arithmetic (no floating point).

The definitions in Lean (openai/math 7ef5c0cc5ca4, lean/OAI/Algorithms/SubexponentialSAT/SqrtLogSpace/Asymptotics.lean)
    sparsifyLambda n   = Nat.clog 2 n                      (ceiling of log2 n)
    sparsifyNu n       = Nat.clog 2 (sparsifyLambda n)
    sparsifySchedule n = Nat.sqrt (sparsifyLambda n) / sparsifyNu n ^ 2
    le_sparsifySchedule_iff, for 20 <= n, gives  a <= schedule n  <->  a^2 * nu^4 <= lambda
NativeLargeEntry.lean sets cutoff := max 20 (max Nleaf Ns), where Ns is any number with
    2 <= sparsifySchedule n for all n >= Ns          (Filter.eventually_atTop on sparsifySchedule_tendsto)
So every valid cutoff is at least the least such Ns.
"""
import math


def clog2(n: int) -> int:
    """Lean's Nat.clog 2 n, the least k with n <= 2^k, which is 0 for n <= 1."""
    return 0 if n <= 1 else (n - 1).bit_length()


def schedule_from_lambda(lam: int) -> int:
    nu = clog2(lam)
    return math.isqrt(lam) // nu ** 2 if nu else 0


# 1. clog2 against hand-worked values, and against the definition (least k with n <= 2^k)
hand = {0: 0, 1: 0, 2: 1, 3: 2, 4: 2, 5: 3, 8: 3, 9: 4, 20: 5, 1024: 10, 1025: 11}
assert all(clog2(n) == k for n, k in hand.items()), "clog2 disagrees with hand-worked values"
assert all(clog2(n) == next(k for k in range(64) if n <= 2 ** k) for n in range(1, 5000))
# 2. the schedule computed two ways (definition vs the proved lemma) agrees, for every lambda up to 2^22
for lam in range(5, 2 ** 22 + 1):  # n >= 20 gives lambda >= 5
    nu = clog2(lam)
    assert (schedule_from_lambda(lam) >= 2) == (4 * nu ** 4 <= lam), lam
print("checks passed: clog2 matches hand values and its definition; schedule >= 2 iff 4*nu^4 <= lambda (lambda <= 2^22)")

# 3. the largest lambda where the schedule is below 2; above it, it stays >= 2 for good
#    (for nu >= 21, 2^(nu-1) + 1 > 4*nu^4, so every lambda in (2^(nu-1), 2^nu] passes)
assert all(2 ** (nu - 1) + 1 > 4 * nu ** 4 for nu in range(21, 200))
fail = [lam for lam in range(5, 2 ** 21 + 1) if schedule_from_lambda(lam) < 2]
lam_max = max(fail)
first_ok = [lam for lam in range(5, 2 ** 21) if schedule_from_lambda(lam) >= 2][0]
print(f"schedule first reaches 2 at lambda = {first_ok}, drops below 2 again, last below at lambda = {lam_max}")
# n with clog2(n) = lam_max are n in (2^(lam_max-1), 2^lam_max]; so the least valid Ns is 2^lam_max + 1
digits = math.floor(lam_max * math.log10(2)) + 1
print(f"least valid Ns = 2^{lam_max} + 1, a number with {digits:,} decimal digits (about 10^{digits - 1:,})")
print(f"so the verified program's cutoff is at least 2^{lam_max} + 1 variables; Nleaf may push it higher")
print("for scale: about 10^80 atoms in the observable universe")
