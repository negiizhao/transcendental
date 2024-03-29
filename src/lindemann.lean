/-
Copyright (c) 2022 Yuyang Zhao. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yuyang Zhao
-/
import algebra.big_operators.finsupp
import analysis.complex.basic
import analysis.special_functions.polynomials
import data.complex.exponential
import field_theory.polynomial_galois_group
import measure_theory.integral.interval_integral
import measure_theory.integral.set_integral
import ring_theory.algebraic
import algebra.char_p.algebra
import gal_conj
import symmetric

noncomputable theory

open_locale big_operators classical polynomial
open finset

namespace nat

lemma desc_factorial_eq_prod_range (n : ℕ) :
  ∀ k, n.desc_factorial k = ∏ i in range k, (n - i)
| 0       := rfl
| (k + 1) := by rw [desc_factorial, prod_range_succ, mul_comm, desc_factorial_eq_prod_range k]

end nat

namespace finsupp
variables {α M N : Type*}

lemma indicator_const_eq_sum_single [add_comm_monoid M] (s : finset α) (m : M) :
  indicator s (λ _ _, m) = ∑ x in s, single x m :=
(indicator_eq_sum_single _ _).trans $ @sum_attach _ _ _ _ (λ i, single i m)

@[simp, to_additive]
lemma prod_indicator_const_index [has_zero M] [comm_monoid N]
  {s : finset α} (m : M) {h : α → M → N} (h_zero : ∀ a ∈ s, h a 0 = 1) :
  (indicator s (λ _ _, m)).prod h = ∏ x in s, h x m :=
(prod_indicator_index _ h_zero).trans $ @prod_attach _ _ _ _ (λ i, h i m)

end finsupp

namespace polynomial
/-
section
variables {R : Type*} [comm_semiring R]

theorem aeval_X_left_apply (p : R[X]) : aeval X p = p :=
by rw [aeval_X_left, alg_hom.id_apply]

@[simps] def scale {R : Type*} [comm_semiring R] : R →* R[X] →ₐ[R] R[X] :=
{ to_fun := λ s, aeval (C s * X),
  map_one' := by { rw [C_1, one_mul, aeval_X_left], refl, },
  map_mul' := λ x y, by rw [alg_hom.End_mul, ← aeval_alg_hom, map_mul, map_mul, aeval_C, aeval_X,
    ← C_eq_algebra_map, mul_left_comm, mul_assoc], }

lemma scale_C (s : R) (x : R) : scale s (C x) = C x := aeval_C _ _
lemma scale_X (s : R) : scale s X = C s * X := aeval_X _

variables {A B : Type*} [field A] [field B]

lemma scale_one_apply (p : A[X]) :
  scale 1 p = p :=
by rw [map_one, alg_hom.one_apply]

lemma scale_scale_apply (a b : A) (p : A[X]) :
  scale a (scale b p) = scale (a * b) p :=
by rw [map_mul, alg_hom.mul_apply]

lemma scale_inv_scale_apply {s : A} (s0 : s ≠ 0) (p : A[X]) :
  (scale s⁻¹) (scale s p) = p :=
by rw [scale_scale_apply, inv_mul_cancel s0, scale_one_apply]

lemma scale_scale_inv_apply {s : A} (s0 : s ≠ 0) (p : A[X]) :
  (scale s) (scale s⁻¹ p) = p :=
by rw [scale_scale_apply, mul_inv_cancel s0, scale_one_apply]

def scale_equiv : non_zero_divisors A →* A[X] ≃ₐ[A] A[X] :=
{ to_fun := λ s,
  { to_fun := aeval (C (s : A) * X),
    inv_fun := aeval (C (s : A)⁻¹ * X),
    left_inv := λ p, scale_inv_scale_apply (mem_non_zero_divisors_iff_ne_zero.mp s.2) p,
    right_inv := λ p, scale_scale_inv_apply (mem_non_zero_divisors_iff_ne_zero.mp s.2) p,
    ..scale (s : A), },
  map_one' := by { ext1 p, rw [alg_equiv.coe_mk, submonoid.coe_one, C_1, one_mul,
    aeval_X_left_apply, alg_equiv.one_apply], },
  map_mul' := λ x y, by { ext1 p, rw [alg_equiv.mul_apply, alg_equiv.coe_mk, alg_equiv.coe_mk,
    alg_equiv.coe_mk, submonoid.coe_mul, map_mul, ← aeval_alg_hom_apply, map_mul, aeval_C, aeval_X,
    ← C_eq_algebra_map, mul_left_comm, mul_assoc], }, }

 -- why there is nothing like `aeval_injective(_of_injective)`?
def scale_injective {s : A} (s0 : s ≠ 0) : function.injective (scale s) :=
(scale_equiv ⟨s, mem_non_zero_divisors_of_ne_zero s0⟩).injective

lemma le_root_multiplicity_scale (p : A[X]) {s : A} (s0 : s ≠ 0) (a : A) :
  root_multiplicity (s * a) p ≤ root_multiplicity a (scale s p) :=
begin
  rcases eq_or_ne p 0 with rfl | p0,
  { simp_rw [map_zero, root_multiplicity_zero], },
  rw [root_multiplicity, root_multiplicity, dif_neg p0,
    dif_neg ((map_ne_zero_iff _ (scale_injective s0)).mpr p0)],
  simp only [not_not, nat.lt_find_iff, nat.le_find_iff],
  intros m hm,
  specialize hm m le_rfl,
  refine trans _ (_root_.map_dvd (scale s) hm),
  rw [map_pow, map_sub, scale_C, scale_X],
  refine pow_dvd_pow_of_dvd ⟨C s, _⟩ _,
  rw [mul_comm (_ - _), mul_sub, ← C_mul],
end

lemma root_multiplicity_scale_eq (p : A[X]) {s : A} (s0 : s ≠ 0) (a : A) :
  root_multiplicity a (scale s p) = root_multiplicity (s * a) p :=
begin
  refine antisymm _ (le_root_multiplicity_scale p s0 a),
  have := (le_root_multiplicity_scale (scale s p) (inv_ne_zero s0) (s * a)),
  rwa [inv_mul_cancel_left₀ s0, scale_inv_scale_apply s0] at this,
end

lemma root_multiplicity_div_scale_eq (p : A[X]) {s : A} (s0 : s ≠ 0) (a : A) :
  root_multiplicity (a / s) (scale s p) = root_multiplicity a p :=
by rw [root_multiplicity_scale_eq _ s0, mul_div_cancel' _ s0]

lemma count_roots_scale (p : A[X]) {s : A} (s0 : s ≠ 0) (a : A) :
  (scale s p).roots.count a = p.roots.count (s * a) :=
by rw [count_roots, count_roots, root_multiplicity_scale_eq _ s0]

lemma count_roots_scale_div (p : A[X]) {s : A} (s0 : s ≠ 0) (a : A) :
  (scale s p).roots.count (a / s) = p.roots.count a :=
by rw [count_roots, count_roots, root_multiplicity_div_scale_eq _ s0]

lemma roots_scale_map (p : A[X]) {s : A} (s0 : s ≠ 0) :
  (scale s p).roots.map (λ x, s * x) = p.roots :=
begin
  ext1 x, have : x = s * (x / s) := (mul_div_cancel' _ s0).symm, rw [this],
  rw [multiset.count_map_eq_count' _ _ (mul_right_injective₀ s0), count_roots_scale _ s0],
end

lemma roots_scale (p : A[X]) {s : A} (s0 : s ≠ 0) :
  (scale s p).roots = p.roots.map (λ x, x / s) :=
begin
  conv_rhs { rw [← roots_scale_map _ s0, multiset.map_map, function.comp], },
  simp_rw [mul_div_cancel_left _ s0, multiset.map_id'],
end

lemma card_roots_scale (p : A[X]) {s : A} (s0 : s ≠ 0) :
  (scale s p).roots.card = p.roots.card :=
by rw [roots_scale _ s0, multiset.card_map]

end
-/
section
variables {R k : Type*} [semiring R]

lemma mem_roots_map_of_injective {p : R[X]}
  [comm_ring k] [is_domain k] {f : R →+* k} (hf : function.injective f) {x : k} (hp : p ≠ 0) :
  x ∈ (p.map f).roots ↔ p.eval₂ f x = 0 :=
begin
  rw mem_roots ((polynomial.map_ne_zero_iff hf).mpr hp),
  dsimp only [is_root],
  rw polynomial.eval_map,
end

end

section
variables {R k : Type*} [comm_ring R]

lemma mem_root_set_of_injective {p : R[X]}
  [comm_ring k] [is_domain k] [algebra R k]
  (h : function.injective (algebra_map R k)) {x : k} (hp : p ≠ 0) :
  x ∈ p.root_set k ↔ aeval x p = 0 :=
multiset.mem_to_finset.trans (mem_roots_map_of_injective h hp)

end

variables {R : Type*}

section semiring
variables {S : Type*} [semiring R]

lemma sum_ideriv_apply_of_lt' {p : R[X]} {n : ℕ} (hn : p.nat_degree < n) :
  ∑ i in range (p.nat_degree + 1), (derivative^[i] p) =
  ∑ i in range n, (derivative^[i] p) := by
{ obtain ⟨m, hm⟩ := nat.exists_eq_add_of_lt hn, rw [hm, add_right_comm],
  rw [sum_range_add _ _ m], convert (add_zero _).symm, apply sum_eq_zero,
  intros x hx, rw [add_comm, function.iterate_add_apply],
  convert iterate_derivative_zero, rw [iterate_derivative_eq_zero], exact lt_add_one _, }

lemma sum_ideriv_apply_of_le' {p : R[X]} {n : ℕ} (hn : p.nat_degree ≤ n) :
  ∑ i in range (p.nat_degree + 1), (derivative^[i] p) =
  ∑ i in range (n + 1), (derivative^[i] p) :=
sum_ideriv_apply_of_lt' (nat.lt_add_one_iff.mpr hn)

def sum_ideriv : R[X] →ₗ[R] R[X] :=
{ to_fun := λ p, ∑ i in range (p.nat_degree + 1), (derivative^[i] p),
  map_add' := λ p q, by
  { let x := max ((p + q).nat_degree + 1) (max (p.nat_degree + 1) (q.nat_degree + 1)),
    have hpq : ((p + q).nat_degree + 1) ≤ x := le_max_left _ _,
    have hp : (p.nat_degree + 1) ≤ x := (le_max_left _ _).trans (le_max_right _ _),
    have hq : (q.nat_degree + 1) ≤ x := (le_max_right _ _).trans (le_max_right _ _),
    simp_rw [sum_ideriv_apply_of_lt' hpq, sum_ideriv_apply_of_lt' hp,
      sum_ideriv_apply_of_lt' hq, ← sum_add_distrib, iterate_derivative_add], },
  map_smul' := λ a p, by dsimp;
    simp_rw [sum_ideriv_apply_of_le' (nat_degree_smul_le _ _), iterate_derivative_smul, smul_sum] }

lemma sum_ideriv_apply (p : R[X]) :
  p.sum_ideriv = ∑ i in range (p.nat_degree + 1), (derivative^[i] p) := rfl

lemma sum_ideriv_apply_of_lt {p : R[X]} {n : ℕ} (hn : p.nat_degree < n) :
  p.sum_ideriv = ∑ i in range n, (derivative^[i] p) :=
sum_ideriv_apply_of_lt' hn

lemma sum_ideriv_apply_of_le {p : R[X]} {n : ℕ} (hn : p.nat_degree ≤ n) :
  p.sum_ideriv = ∑ i in range (n + 1), (derivative^[i] p) :=
sum_ideriv_apply_of_le' hn

lemma sum_ideriv_C (a : R) : (C a).sum_ideriv = C a :=
by rw [sum_ideriv_apply, nat_degree_C, zero_add, sum_range_one, function.iterate_zero_apply]

@[simp]
theorem sum_ideriv_map {S : Type*} [comm_semiring S] (p : R[X]) (f : R →+* S) :
  (p.map f).sum_ideriv = p.sum_ideriv.map f := by
{ let n := max (p.map f).nat_degree p.nat_degree,
  rw [sum_ideriv_apply_of_le (le_max_left _ _ : _ ≤ n)],
  rw [sum_ideriv_apply_of_le (le_max_right _ _ : _ ≤ n)],
  simp_rw [polynomial.map_sum],
  apply sum_congr rfl, intros x hx,
  rw [iterate_derivative_map p f x], }

lemma sum_ideriv_derivative (p : R[X]) :
  p.derivative.sum_ideriv = p.sum_ideriv.derivative := by
{ rw [sum_ideriv_apply_of_le ((nat_degree_derivative_le p).trans tsub_le_self),
    sum_ideriv_apply, derivative_sum],
  simp_rw [← function.iterate_succ_apply, function.iterate_succ_apply'], }

lemma sum_ideriv_eq_self_add (p : R[X]) :
  p.sum_ideriv = p + p.derivative.sum_ideriv := by
{ rw [sum_ideriv_derivative, sum_ideriv_apply, derivative_sum, sum_range_succ', sum_range_succ,
    add_comm, ← add_zero (finset.sum _ _)],
  simp_rw [← function.iterate_succ_apply' derivative], congr',
  rw [iterate_derivative_eq_zero (nat.lt_succ_self _)], }

def iterate_derivative_linear_map (n : ℕ) : R[X] →ₗ[R] R[X] :=
{ to_fun := λ p, (derivative^[n] p),
  map_add' := λ p q, iterate_derivative_add,
  map_smul' := λ a p, iterate_derivative_smul _ _ _, }

lemma iterate_derivative_linear_map_apply (p : R[X]) (n : ℕ) :
  iterate_derivative_linear_map n p = (derivative^[n] p) := rfl

variables (f p q : R[X]) (n k : ℕ)

lemma coeff_iterate_derivative_as_prod_range' :
  ∀ m : ℕ, (derivative^[k] f).coeff m = (∏ i in range k, (m + k - i)) • f.coeff (m + k) :=
begin
  induction k with k ih,
  { simp },
  intro m,
  calc (derivative^[k.succ] f).coeff m
      = (∏ i in range k, (m + k.succ - i)) • f.coeff (m + k.succ) * (m + 1) :
    by rw [function.iterate_succ_apply', coeff_derivative, ih m.succ, nat.succ_add, nat.add_succ]
  ... = ((∏ i in range k, (m + k.succ - i)) * (m + 1)) • f.coeff (m + k.succ) :
    by rw [← nat.cast_add_one, ← nsmul_eq_mul', smul_smul, mul_comm]
  ... = (∏ i in range k.succ, (m + k.succ - i)) • f.coeff (m + k.succ) :
    by rw [prod_range_succ, add_tsub_assoc_of_le k.le_succ, nat.succ_sub le_rfl, tsub_self],
end

lemma coeff_iterate_derivative_as_desc_factorial (m : ℕ) :
  (derivative^[k] f).coeff m = (m + k).desc_factorial k • f.coeff (m + k) :=
by rw [coeff_iterate_derivative_as_prod_range', ← nat.desc_factorial_eq_prod_range]

end semiring

section ring
variables [ring R]

lemma sum_ideriv_sub (p : R[X]) :
  p.sum_ideriv - p.derivative.sum_ideriv = p :=
by rw [sum_ideriv_eq_self_add, add_sub_cancel]

def sum_ideriv_linear_equiv : R[X] ≃ₗ[R] R[X] :=
{ to_fun := λ p, ∑ i in range (p.nat_degree + 1), (derivative^[i] p),
  inv_fun := λ p, p - p.derivative,
  left_inv := λ p, by simp_rw [← sum_ideriv_apply, ← sum_ideriv_derivative, sum_ideriv_sub],
  right_inv := λ p, by simp_rw [← sum_ideriv_apply, map_sub, sum_ideriv_sub],
  .. sum_ideriv }

lemma sum_ideriv_linear_equiv_apply (p : R[X]) :
  p.sum_ideriv_linear_equiv = ∑ i in range (p.nat_degree + 1), (derivative^[i] p) := rfl

lemma sum_ideriv_linear_equiv_symm_apply (p : R[X]) :
  sum_ideriv_linear_equiv.symm p = p - p.derivative := rfl

lemma sum_ideriv_linear_equiv_eq_sum_ideriv (p : R[X]) :
  p.sum_ideriv_linear_equiv = p.sum_ideriv := rfl

end ring

end polynomial

open polynomial
open_locale nat

variables {R A : Type*} [comm_ring R] [is_domain R]
  [comm_ring A] [is_domain A] [algebra R A]

namespace polynomial

lemma iterate_derivative_X_sub_C_pow (r : R) (k : ℕ) :
  ∀ (n : ℕ), (derivative^[n] ((X - C r) ^ k : R[X])) = k.desc_factorial n • (X - C r) ^ (k - n)
| 0       := by rw [function.iterate_zero_apply, nat.desc_factorial, one_smul, tsub_zero]
| (n + 1) := by rw [function.iterate_succ_apply', iterate_derivative_X_sub_C_pow n,
  derivative_smul, derivative_X_sub_C_pow, nat.desc_factorial, C_eq_nat_cast, ← nsmul_eq_mul,
  smul_smul, mul_comm, tsub_tsub]

lemma nat_degree_iterate_derivative (p : R[X]) (k : ℕ) :
  (derivative^[k] p).nat_degree ≤ p.nat_degree - k :=
begin
  induction k with d hd, { rw [function.iterate_zero_apply, nat.sub_zero], },
  rw [function.iterate_succ_apply', nat.sub_succ'],
  refine (nat_degree_derivative_le _).trans _,
  exact nat.sub_le_sub_right hd 1,
end

lemma iterate_derivative_eq_factorial_mul (p : R[X]) (k : ℕ) :
  ∃ (gp : R[X]) (gp_le : gp.nat_degree ≤ p.nat_degree - k), (derivative^[k] p) = k! • gp :=
begin
  use ∑ (x : ℕ) in (derivative^[k] p).support, (x + k).choose k • C (p.coeff (x + k)) * X ^ x,
  split,
  { refine (nat_degree_sum_le _ _).trans _,
    rw [fold_max_le],
    refine ⟨nat.zero_le _, λ i hi, _⟩, dsimp only [function.comp],
    replace hi := le_nat_degree_of_mem_supp _ hi,
    rw [smul_C], refine (nat_degree_C_mul_le _ _).trans _,
    rw [nat_degree_X_pow], refine hi.trans _,
    exact nat_degree_iterate_derivative _ _, },
  conv_lhs { rw [(derivative^[k] p).as_sum_support_C_mul_X_pow], },
  rw [smul_sum], congr', funext i,
  calc C ((derivative^[k] p).coeff i) * X ^ i
      = C ((i + k).desc_factorial k • p.coeff (i + k)) * X ^ i :
        by rw [coeff_iterate_derivative_as_desc_factorial]
  ... = C ((k! * (i + k).choose k) • p.coeff (i + k)) * X ^ i :
        by rw [nat.desc_factorial_eq_factorial_mul_choose]
  ... = (k! * (i + k).choose k) • C (p.coeff (i + k)) * X ^ i :
        by rw [smul_C]
  ... = k! • (i + k).choose k • C (p.coeff (i + k)) * X ^ i :
        by rw [mul_smul]
  ... = k! • ((i + k).choose k • C (p.coeff (i + k)) * X ^ i) :
        by rw [smul_mul_assoc],
end

lemma iterate_derivative_small (p : R[X]) (q : ℕ) (r : A)
  {p' : A[X]} (hp : p.map (algebra_map R A) = (X - C r) ^ q * p')
  {k : ℕ} (hk : k < q) :
  aeval r (derivative^[k] p) = 0 :=
begin
  have h : ∀ x, (X - C r) ^ (q - (k - x)) = (X - C r) ^ 1 * (X - C r) ^ (q - (k - x) - 1),
  { intros x, rw [← pow_add, add_tsub_cancel_of_le], rw [nat.lt_iff_add_one_le] at hk,
    exact (le_tsub_of_add_le_left hk).trans (tsub_le_tsub_left (tsub_le_self : _ ≤ k) _), },
  rw [aeval_def, eval₂_eq_eval_map, ← iterate_derivative_map],
  simp_rw [hp, iterate_derivative_mul, iterate_derivative_X_sub_C_pow, ← smul_mul_assoc, smul_smul,
    h, ← mul_smul_comm, mul_assoc, ← mul_sum, eval_mul, pow_one, eval_sub, eval_X, eval_C,
    sub_self, zero_mul],
end

lemma iterate_derivative_of_eq (p : R[X]) (q : ℕ) (r : A)
  {p' : A[X]} (hp : p.map (algebra_map R A) = (X - C r) ^ q * p') :
  aeval r (derivative^[q] p) = q! • p'.eval r :=
begin
  have h : ∀ x ≥ 1, x ≤ q →
    (X - C r) ^ (q - (q - x)) = (X - C r) ^ 1 * (X - C r) ^ (q - (q - x) - 1),
  { intros x h h', rw [← pow_add, add_tsub_cancel_of_le], rwa [tsub_tsub_cancel_of_le h'], },
  rw [aeval_def, eval₂_eq_eval_map, ← iterate_derivative_map],
  simp_rw [hp, iterate_derivative_mul, iterate_derivative_X_sub_C_pow, ← smul_mul_assoc,
    smul_smul],
  rw [sum_range_succ', nat.choose_zero_right, one_mul, tsub_zero, nat.desc_factorial_self,
    tsub_self, pow_zero, smul_mul_assoc, one_mul, function.iterate_zero, eval_add, eval_smul],
  convert zero_add _, rw [← coe_eval_ring_hom, map_sum], apply sum_eq_zero, intros x hx,
  rw [coe_eval_ring_hom, h (x + 1) le_add_self (nat.add_one_le_iff.mpr (mem_range.mp hx)),
    pow_one, eval_mul, eval_smul, eval_mul, eval_sub, eval_X, eval_C, sub_self, zero_mul,
    smul_zero, zero_mul],
end

variable (A)

lemma iterate_derivative_large (p : R[X]) (q : ℕ)
  {k : ℕ} (hk : q ≤ k) :
  ∃ (gp : R[X]) (gp_le : gp.nat_degree ≤ p.nat_degree - k),
    ∀ (r : A), aeval r (derivative^[k] p) = q! • aeval r gp :=
begin
  obtain ⟨p', p'_le, hp'⟩ := iterate_derivative_eq_factorial_mul p k,
  refine ⟨(k.desc_factorial (k - q) : ℤ) • p', _, _⟩,
  { rw [zsmul_eq_mul, ← C_eq_int_cast],
    exact (nat_degree_C_mul_le _ _).trans p'_le, },
  intros r,
  rw [hp', aeval_def, eval₂_eq_eval_map, nsmul_eq_mul, polynomial.map_mul,
    polynomial.map_nat_cast],
  rw [eval_mul, eval_nat_cast,
    ← nat.factorial_mul_desc_factorial (tsub_le_self : k - q ≤ k), tsub_tsub_cancel_of_le hk,
    nat.cast_mul, mul_assoc],
  rw [aeval_def, eval₂_eq_eval_map, zsmul_eq_mul, polynomial.map_mul,
    polynomial.map_int_cast, eval_mul, eval_int_cast, int.cast_coe_nat, nsmul_eq_mul],
end

lemma sum_ideriv_sl (p : R[X]) (q : ℕ) :
  ∃ (gp : R[X]) (gp_le : gp.nat_degree ≤ p.nat_degree - q),
    ∀ (r : A) {p' : A[X]} (hp : p.map (algebra_map R A) = (X - C r) ^ q * p'),
      aeval r p.sum_ideriv = q! • aeval r gp :=
begin
  have h : ∀ k,
    ∃ (gp : R[X]) (gp_le : gp.nat_degree ≤ p.nat_degree - q),
      ∀ (r : A) {p' : A[X]} (hp : p.map (algebra_map R A) = (X - C r) ^ q * p'),
    aeval r (derivative^[k] p) = q! • aeval r gp,
  { intros k, cases lt_or_ge k q with hk hk,
    { use 0, rw [nat_degree_zero], use nat.zero_le _,
      intros r p' hp, rw [map_zero, smul_zero, iterate_derivative_small p q r hp hk], },
    { obtain ⟨gp, gp_le, h⟩ := iterate_derivative_large A p q hk,
      exact ⟨gp, gp_le.trans (tsub_le_tsub_left hk _), λ r p' hp, h r⟩, }, },
  let c := λ k, (h k).some,
  have c_le : ∀ k, (c k).nat_degree ≤ p.nat_degree - q := λ k, (h k).some_spec.some,
  have hc : ∀ k, ∀ (r : A) {p' : A[X]} (hp : p.map (algebra_map R A) = (X - C r) ^ q * p'),
    aeval r (derivative^[k] p) = q! • aeval r (c k) := λ k, (h k).some_spec.some_spec,
  refine ⟨(range (p.nat_degree + 1)).sum c, _, _⟩,
  { refine (nat_degree_sum_le _ _).trans _,
    rw [fold_max_le],
    exact ⟨nat.zero_le _, λ i hi, c_le i⟩, },
  intros r p' hp,
  rw [sum_ideriv_apply, map_sum], simp_rw [hc _ r hp, map_sum, smul_sum],
end

lemma sum_ideriv_sl' (p : R[X]) {q : ℕ} (hq : 0 < q) :
  ∃ (gp : R[X]) (gp_le : gp.nat_degree ≤ p.nat_degree - q),
    ∀ (inj_amap : function.injective (algebra_map R A))
      (r : A) {p' : A[X]} (hp : p.map (algebra_map R A) = (X - C r) ^ (q - 1) * p'),
      aeval r p.sum_ideriv = (q - 1)! • p'.eval r + q! • aeval r gp :=
begin
  rcases eq_or_ne p 0 with rfl | p0,
  { use 0, rw [nat_degree_zero], use nat.zero_le _,
    intros inj_amap r p' hp,
    rw [map_zero, map_zero, smul_zero, add_zero], rw [polynomial.map_zero] at hp,
    replace hp := (mul_eq_zero.mp hp.symm).resolve_left _,
    rw [hp, eval_zero, smul_zero],
    exact λ h, X_sub_C_ne_zero r (pow_eq_zero h), },
  let c := λ k, if hk : q ≤ k then (iterate_derivative_large A p q hk).some else 0,
  have c_le : ∀ k, (c k).nat_degree ≤ p.nat_degree - k := λ k,
    by { dsimp only [c], split_ifs, { exact (iterate_derivative_large A p q h).some_spec.some, },
      rw [nat_degree_zero], exact nat.zero_le _, },
  have hc : ∀ k (hk : q ≤ k) (r : A), aeval r (derivative^[k] p) = q! • aeval r (c k) := λ k hk,
    by { simp_rw [c, dif_pos hk], exact (iterate_derivative_large A p q hk).some_spec.some_spec, },
  refine ⟨∑ (x : ℕ) in Ico q (p.nat_degree + 1), c x, _, _⟩,
  { refine (nat_degree_sum_le _ _).trans _,
    rw [fold_max_le],
    exact ⟨nat.zero_le _, λ i hi, (c_le i).trans (tsub_le_tsub_left (mem_Ico.mp hi).1 _)⟩, },
  intros inj_amap r p' hp,
  have : range (p.nat_degree + 1) = range q ∪ Ico q (p.nat_degree + 1),
  { rw [range_eq_Ico, Ico_union_Ico_eq_Ico hq.le],
    have h := nat_degree_map_le (algebra_map R A) p,
    rw [congr_arg nat_degree hp, nat_degree_mul, nat_degree_pow, nat_degree_X_sub_C, mul_one,
      ← nat.sub_add_comm (nat.one_le_of_lt hq), tsub_le_iff_right] at h,
    exact le_of_add_le_left h,
    { exact pow_ne_zero _ (X_sub_C_ne_zero r), },
    { rintros rfl, rw [mul_zero, polynomial.map_eq_zero_iff inj_amap] at hp, exact p0 hp, }, },
  rw [← zero_add ((q - 1)! • p'.eval r)],
  rw [sum_ideriv_apply, map_sum, map_sum, this, sum_union,
    (by rw [tsub_add_cancel_of_le (nat.one_le_of_lt hq)] : range q = range (q - 1 + 1)),
    sum_range_succ], congr' 1, congr' 1,
  { exact sum_eq_zero (λ x hx, iterate_derivative_small p _ r hp (mem_range.mp hx)), },
  { rw [← iterate_derivative_of_eq _ _ _ hp], },
  { rw [smul_sum, sum_congr rfl], intros k hk, exact hc k (mem_Ico.mp hk).1 r, },
  { rw [range_eq_Ico, disjoint_iff_inter_eq_empty, eq_empty_iff_forall_not_mem],
    intros x hx, rw [mem_inter, mem_Ico, mem_Ico] at hx, exact hx.1.2.not_le hx.2.1, },
end

end polynomial

open complex

lemma differentiable_at.real_of_complex {e : ℂ → ℂ} {z : ℝ} (h : differentiable_at ℂ e ↑z) :
  differentiable_at ℝ (λ (x : ℝ), e ↑x) z :=
(h.restrict_scalars ℝ).comp z of_real_clm.differentiable.differentiable_at

lemma differentiable.real_of_complex {e : ℂ → ℂ} (h : differentiable ℂ e) :
  differentiable ℝ (λ (x : ℝ), e ↑x) :=
(h.restrict_scalars ℝ).comp of_real_clm.differentiable

lemma deriv_eq_f (p : ℂ[X]) (s : ℂ) :
  deriv (λ (x : ℝ), -(exp (-(x • exp (s.arg • I))) * p.sum_ideriv.eval (x • exp (s.arg • I))) /
    exp (s.arg • I)) =
  λ (x : ℝ), exp (-(x • exp (s.arg • I))) * p.eval (x • exp (s.arg • I)) :=
begin
  have h : (λ (y : ℝ), p.sum_ideriv.eval (y • exp (s.arg • I))) =
    (λ x, p.sum_ideriv.eval x) ∘ (λ y, y • exp (s.arg • I)) := rfl,
  funext, rw [deriv_div_const, deriv.neg, deriv_mul, deriv_cexp, deriv.neg],
  any_goals { simp_rw [h] }, clear h,
  rw [deriv_smul_const, deriv_id'', deriv.comp, polynomial.deriv, deriv_smul_const, deriv_id''],
  simp_rw [derivative_map, one_smul, mul_assoc, ← mul_add],
  have h : exp (s.arg • I) * p.sum_ideriv.eval (x • exp (s.arg • I)) -
    p.sum_ideriv.derivative.eval (x • exp (s.arg • I)) * exp (s.arg • I) =
    p.eval (x • exp (s.arg • I)) * exp (s.arg • I) := by
  { conv_lhs { congr, rw [sum_ideriv_eq_self_add, sum_ideriv_derivative], },
    rw [mul_comm, eval_add, add_mul, add_sub_cancel], },
  rw [← mul_neg, neg_add', neg_mul, neg_neg, h, ← mul_assoc, mul_div_cancel],
  exact exp_ne_zero _,
  any_goals { apply differentiable.differentiable_at },
  rotate 5, apply @differentiable.real_of_complex (λ c : ℂ, exp (-(c * exp (s.arg • I)))),
  rotate 1, apply differentiable.comp, apply @differentiable.restrict_scalars ℝ _ ℂ,
  any_goals { repeat
  { apply differentiable.neg <|>
    apply differentiable.cexp <|>
    apply differentiable.mul_const <|>
    apply polynomial.differentiable <|>
    apply differentiable.smul_const <|>
    exact differentiable_id }, },
end

lemma integral_f_eq (p : ℂ[X]) (s : ℂ) :
  ∫ x in 0..s.abs, exp (-(x • exp (s.arg • I))) * p.eval (x • exp (s.arg • I)) =
    -(exp (-s) * p.sum_ideriv.eval s ) / exp (s.arg • I) -
    -(p.sum_ideriv.eval 0) / exp (s.arg • I) :=
begin
  convert interval_integral.integral_deriv_eq_sub' (λ (x : ℝ), -(exp (-(x • exp (s.arg • I))) *
    p.sum_ideriv.eval (x • exp (s.arg • I))) / exp (s.arg • I)) (deriv_eq_f p s) _ _,
  any_goals { simp_rw [real_smul, abs_mul_exp_arg_mul_I], },
  { simp_rw [zero_smul, neg_zero, complex.exp_zero, one_mul], },
  { intros x hx, apply ((differentiable.mul _ _).neg.div_const _).differentiable_at,
    apply @differentiable.real_of_complex (λ c : ℂ, exp (-(c * exp (s.arg • I)))),
    refine (differentiable_id.mul_const _).neg.cexp,
    change differentiable ℝ ((λ (y : ℂ), p.sum_ideriv.eval y) ∘
      (λ (x : ℝ), x • exp (s.arg • I))),
    apply differentiable.comp,
    apply @differentiable.restrict_scalars ℝ _ ℂ, exact polynomial.differentiable _,
    exact differentiable_id'.smul_const _, },
  { refine ((continuous_id'.smul continuous_const).neg.cexp.mul _).continuous_on,
    change continuous ((λ (y : ℂ), p.eval y) ∘ (λ (x : ℝ), x • exp (s.arg • I))),
    exact p.continuous_aeval.comp (continuous_id'.smul continuous_const), },
end

def P (p : ℂ[X]) (s : ℂ) := exp s * p.sum_ideriv.eval 0 - p.sum_ideriv.eval s

lemma P_le' (p : ℕ → ℂ[X]) (s : ℂ)
  (h : ∃ c, ∀ (q : ℕ) (x ∈ set.Ioc 0 s.abs), ((p q).eval (x • exp (s.arg • I))).abs ≤ c ^ q) :
  ∃ c ≥ 0, ∀ (q : ℕ), (P (p q) s).abs ≤
  real.exp s.re * (real.exp s.abs * c ^ q * s.abs) :=
begin
  simp_rw [P], cases h with c hc, replace hc := λ q x hx, (hc q x hx).trans (le_abs_self _),
  simp_rw [_root_.abs_pow] at hc, use [|c|, abs_nonneg _], intros q,
  have h := integral_f_eq (p q) s,
  rw [← sub_div, eq_div_iff (exp_ne_zero _), ← @mul_right_inj' _ _ (exp s) _ _ (exp_ne_zero _),
    neg_sub_neg, mul_sub, ← mul_assoc _ (exp _), ← exp_add, add_neg_self, exp_zero, one_mul] at h,
  replace h := congr_arg complex.abs h,
  simp_rw [map_mul, abs_exp, smul_re, I_re, smul_zero, real.exp_zero, mul_one] at h,
  rw [← h, mul_le_mul_left (real.exp_pos _), ← complex.norm_eq_abs,
    interval_integral.integral_of_le (complex.abs.nonneg _)], clear h,
  convert measure_theory.norm_set_integral_le_of_norm_le_const' _ _ _,
  { rw [real.volume_Ioc, sub_zero, ennreal.to_real_of_real (complex.abs.nonneg _)], },
  { rw [real.volume_Ioc, sub_zero], exact ennreal.of_real_lt_top, },
  { exact measurable_set_Ioc, },
  intros x hx, rw [norm_mul], refine mul_le_mul _ (hc q x hx) (norm_nonneg _) (real.exp_pos _).le,
  rw [norm_eq_abs, abs_exp, real.exp_le_exp], apply (re_le_abs _).trans, rw [← norm_eq_abs,
    norm_neg, norm_smul, norm_eq_abs, abs_exp, smul_re, I_re, smul_zero, real.exp_zero, mul_one,
    real.norm_eq_abs, abs_eq_self.mpr hx.1.le], exact hx.2,
end

lemma P_le (p : ℕ → ℂ[X]) (s : ℂ)
  (h : ∃ c, ∀ (q : ℕ) (x ∈ set.Ioc 0 s.abs), ((p q).eval (x • exp (s.arg • I))).abs ≤ c ^ q) :
  ∃ c ≥ 0, ∀ q ≥ 1, (P (p q) s).abs ≤ c ^ q :=
begin
  simp_rw [P], obtain ⟨c', hc', h'⟩ := P_le' p s h, clear h,
  let c₁ := max (real.exp s.re) 1,
  let c₂ := max (real.exp s.abs) 1, have h₂ : 0 ≤ real.exp s.abs := (real.exp_pos _).le,
  let c₃ := max s.abs 1,            have h₃ : 0 ≤ s.abs := complex.abs.nonneg _,
  have hc : ∀ {x : ℝ}, 0 ≤ max x 1 := λ x, zero_le_one.trans (le_max_right _ _),
  use [c₁ * (c₂ * c' * c₃), mul_nonneg hc (mul_nonneg (mul_nonneg hc hc') hc)],
  intros q hq, refine (h' q).trans _, simp_rw [mul_pow],
  have hcq : ∀ {x : ℝ}, 0 ≤ max x 1 ^ q := λ x, pow_nonneg hc q,
  have hcq' := pow_nonneg hc' q,
  have le_max_one_pow : ∀ {x : ℝ}, x ≤ max x 1 ^ q := λ x, (max_cases x 1).elim
    (λ h, h.1.symm ▸ le_self_pow h.2 (zero_lt_one.trans_le hq).ne')
    (λ h, by rw [h.1, one_pow]; exact h.2.le),
  refine mul_le_mul le_max_one_pow _ (mul_nonneg (mul_nonneg h₂ hcq') h₃) hcq,
  refine mul_le_mul _ le_max_one_pow h₃ (mul_nonneg hcq hcq'),
  refine mul_le_mul le_max_one_pow le_rfl hcq' hcq,
end

open polynomial

theorem exp_polynomial_approx (p : ℤ[X]) (p0 : p.eval 0 ≠ 0) :
  ∃ c, ∀ (q > (eval 0 p).nat_abs) (prime_q : nat.prime q),
    ∃ (n : ℤ) (hn : n % q ≠ 0) (gp : ℤ[X]) (gp_le : gp.nat_degree ≤ q * p.nat_degree - 1),
      ∀ {r : ℂ} (hr : r ∈ p.aroots ℂ),
        (n • exp r - q • aeval r gp : ℂ).abs ≤ c ^ q / (q - 1)! :=
begin
  let p' := λ q, (X ^ (q - 1) * p ^ q).map (algebra_map ℤ ℂ),
  have : ∀ s : ℂ, ∃ c, ∀ (q : ℕ) (x ∈ set.Ioc 0 s.abs),
    ((p' q).eval (x • exp (s.arg • I))).abs ≤ c ^ q,
  { intros s, dsimp only [p'],
    simp_rw [polynomial.map_mul, polynomial.map_pow, map_X, eval_mul, eval_pow, eval_X,
      map_mul, complex.abs_pow, real_smul, map_mul, abs_exp_of_real_mul_I,
      abs_of_real, mul_one, ← eval₂_eq_eval_map, ← aeval_def],
    have : metric.bounded
      ((λ x, max (|x|) 1 * ((aeval (↑x * exp (↑s.arg * I)) p)).abs) '' set.Ioc 0 (abs s)),
    { have h :
        ((λ x, max (|x|) 1 * ((aeval (↑x * exp (↑s.arg * I)) p)).abs) '' set.Ioc 0 (abs s)) ⊆
        ((λ x, max (|x|) 1 * ((aeval (↑x * exp (↑s.arg * I)) p)).abs) '' set.Icc 0 (abs s)),
      { exact set.image_subset _ set.Ioc_subset_Icc_self, },
      refine (is_compact.image is_compact_Icc _).bounded.mono h,
      { refine (continuous_id.abs.max continuous_const).mul _,
        refine complex.continuous_abs.comp ((p.continuous_aeval).comp _),
        exact continuous_of_real.mul continuous_const, }, },
    cases this.exists_norm_le with c h,
    use c, intros q x hx,
    specialize h (max (|x|) 1 * (aeval (↑x * exp (↑s.arg * I)) p).abs) (set.mem_image_of_mem _ hx),
    refine le_trans _ (pow_le_pow_of_le_left (norm_nonneg _) h _),
    simp_rw [norm_mul, real.norm_eq_abs, complex.abs_abs, mul_pow],
    refine mul_le_mul_of_nonneg_right _ (pow_nonneg (complex.abs.nonneg _) _),
    rw [max_def], split_ifs with hx1,
    { rw [_root_.abs_one, one_pow],
      exact pow_le_one _ (abs_nonneg _) hx1, },
    { push_neg at hx1,
      rw [_root_.abs_abs], exact pow_le_pow hx1.le (nat.sub_le _ _), }, },
  let c' := λ r, (P_le p' r (this r)).some,
  have c'0 : ∀ r, 0 ≤ c' r := λ r, (P_le p' r (this r)).some_spec.some,
  have Pp'_le : ∀ (r : ℂ) (q ≥ 1), abs (P (p' q) r) ≤ c' r ^ q :=
    λ r, (P_le p' r (this r)).some_spec.some_spec,
  let c := if h : ((p.aroots ℂ).map c').to_finset.nonempty
    then ((p.aroots ℂ).map c').to_finset.max' h else 0,
  have hc : ∀ x ∈ p.aroots ℂ, c' x ≤ c,
  { intros x hx, dsimp only [c],
    split_ifs,
    { apply finset.le_max', rw [multiset.mem_to_finset],
      refine multiset.mem_map_of_mem _ hx, },
    { rw [nonempty_iff_ne_empty, ne.def, multiset.to_finset_eq_empty,
        multiset.eq_zero_iff_forall_not_mem] at h, push_neg at h,
      exact absurd (multiset.mem_map_of_mem _ hx) (h (c' x)), }, },
  use c,
  intros q q_gt prime_q,
  have q0 : 0 < q := nat.prime.pos prime_q,
  obtain ⟨gp', gp'_le, h'⟩ := sum_ideriv_sl' ℤ (X ^ (q - 1) * p ^ q) q0,
  simp_rw [ring_hom.algebra_map_to_algebra, map_id] at h',
  specialize h' (ring_hom.injective_int _) 0 (by rw [C_0, sub_zero]),
  rw [eval_pow] at h',
  use p.eval 0 ^ q + q • aeval 0 gp',
  split,
  { rw [int.add_mod, nsmul_eq_mul, int.mul_mod_right, add_zero, int.mod_mod, ne.def,
      ← int.dvd_iff_mod_eq_zero],
    intros h,
    replace h := int.prime.dvd_pow' prime_q h, rw [int.coe_nat_dvd_left] at h,
    replace h := nat.le_of_dvd (int.nat_abs_pos_of_ne_zero p0) h,
    revert h, rwa [imp_false, not_le], },
  obtain ⟨gp, gp'_le, h⟩ := sum_ideriv_sl ℂ (X ^ (q - 1) * p ^ q) q,
  refine ⟨gp, _, _⟩,
  { refine gp'_le.trans ((tsub_le_tsub_right nat_degree_mul_le q).trans _),
    rw [nat_degree_X_pow, nat_degree_pow, tsub_add_eq_add_tsub (nat.one_le_of_lt q0),
      tsub_right_comm],
    apply tsub_le_tsub_right, rw [add_tsub_cancel_left], },
  intros r hr,
  have : (X ^ (q - 1) * p ^ q).map (algebra_map ℤ ℂ) = (X - C r) ^ q * (X ^ (q - 1) *
    (C (map (algebra_map ℤ ℂ) p).leading_coeff *
      (((p.aroots ℂ).erase r).map (λ (a : ℂ), X - C a)).prod) ^ q),
  { rw [mul_left_comm, ← mul_pow, mul_left_comm (_ - _), multiset.prod_map_erase hr],
    have : (p.aroots ℂ).card = (p.map (algebra_map ℤ ℂ)).nat_degree :=
      splits_iff_card_roots.mp (is_alg_closed.splits _),
    rw [C_leading_coeff_mul_prod_multiset_X_sub_C this, polynomial.map_mul, polynomial.map_pow,
      polynomial.map_pow, map_X], },
  specialize h r this, clear this,
  rw [le_div_iff (nat.cast_pos.mpr (nat.factorial_pos _) : (0 : ℝ) < _), ← abs_of_nat,
    ← map_mul, mul_comm, mul_sub, ← nsmul_eq_mul, ← nsmul_eq_mul, smul_smul,
    mul_comm, nat.mul_factorial_pred q0, ← h],
  rw [nsmul_eq_mul, ← int.cast_coe_nat, ← zsmul_eq_mul, smul_smul, mul_add, ← nsmul_eq_mul,
    ← nsmul_eq_mul, smul_smul, mul_comm, nat.mul_factorial_pred q0, ← h', zsmul_eq_mul,
    aeval_def, eval₂_at_zero, eq_int_cast, int.cast_id, ← int.coe_cast_ring_hom,
    ← algebra_map_int_eq, ← eval₂_at_zero, aeval_def, eval₂_eq_eval_map, eval₂_eq_eval_map,
    mul_comm, ← sum_ideriv_map, ← P],
  exact (Pp'_le r q (nat.one_le_of_lt q0)).trans (pow_le_pow_of_le_left (c'0 r) (hc r hr) _),
end

namespace add_monoid_algebra

@[simps]
def ring_equiv_congr_left {R S G : Type*} [semiring R] [semiring S] [add_monoid G]
  (f : R ≃+* S) :
  add_monoid_algebra R G ≃+* add_monoid_algebra S G :=
{ to_fun := (finsupp.map_range f f.map_zero :
    (add_monoid_algebra R G) → (add_monoid_algebra S G)),
  inv_fun := (finsupp.map_range f.symm f.symm.map_zero :
    (add_monoid_algebra S G) → (add_monoid_algebra R G)),
  map_mul' := λ x y,
  begin
    ext, simp_rw [mul_apply, mul_def,
      finsupp.map_range_apply, finsupp.sum_apply, map_finsupp_sum],
    rw [finsupp.sum_map_range_index], congrm finsupp.sum x (λ g1 r1, _),
    rw [finsupp.sum_map_range_index], congrm finsupp.sum y (λ g2 r2, _),
    { rw [finsupp.single_apply], split_ifs; simp only [map_mul, map_zero], contradiction, },
    all_goals { intro, simp only [mul_zero, zero_mul], simp only [if_t_t, finsupp.sum_zero], },
  end,
  ..finsupp.map_range.add_equiv f.to_add_equiv }

@[simps]
def alg_equiv_congr_left {k R S G : Type*} [comm_semiring k] [semiring R] [algebra k R]
  [semiring S] [algebra k S] [add_monoid G] (f : R ≃ₐ[k] S) :
  add_monoid_algebra R G ≃ₐ[k] add_monoid_algebra S G :=
{ to_fun := (finsupp.map_range f f.map_zero :
    (add_monoid_algebra R G) → (add_monoid_algebra S G)),
  inv_fun := (finsupp.map_range f.symm f.symm.map_zero :
    (add_monoid_algebra S G) → (add_monoid_algebra R G)),
  commutes' := λ r,
  begin
    ext,
    simp_rw [add_monoid_algebra.coe_algebra_map, function.comp_app, finsupp.map_range_single],
    congr' 2,
    change f.to_alg_hom ((algebra_map k R) r) = (algebra_map k S) r,
    rw [alg_hom.map_algebra_map],
  end,
  ..ring_equiv_congr_left f.to_ring_equiv }

@[simps]
def alg_aut_congr_left {k R G : Type*}
  [comm_semiring k] [semiring R] [algebra k R] [add_monoid G] :
  (R ≃ₐ[k] R) →* add_monoid_algebra R G ≃ₐ[k] add_monoid_algebra R G :=
{ to_fun := λ f, alg_equiv_congr_left f,
  map_one' := by { ext, refl, },
  map_mul' := λ x y, by { ext, refl, }, }

@[simps]
def map_domain_ring_equiv (k : Type*) [semiring k]
  {G H : Type*} [add_monoid G] [add_monoid H] (f : G ≃+ H) :
  add_monoid_algebra k G ≃+* add_monoid_algebra k H :=
{ to_fun := finsupp.equiv_map_domain f,
  inv_fun := finsupp.equiv_map_domain f.symm,
  map_mul' := λ x y,
  begin
    simp_rw [← finsupp.dom_congr_apply],
    induction x using finsupp.induction_linear,
    { simp only [map_zero, zero_mul], }, { simp only [add_mul, map_add, *], },
    induction y using finsupp.induction_linear;
    simp only [mul_zero, zero_mul, map_zero, mul_add, map_add, *],
    ext, simp only [finsupp.dom_congr_apply, single_mul_single, finsupp.equiv_map_domain_single,
      add_equiv.coe_to_equiv, map_add],
  end,
  ..finsupp.dom_congr f.to_equiv }

@[simps]
def map_domain_alg_equiv (k A : Type*) [comm_semiring k] [semiring A] [algebra k A]
  {G H : Type*} [add_monoid G] [add_monoid H] (f : G ≃+ H) :
  add_monoid_algebra A G ≃ₐ[k] add_monoid_algebra A H :=
{ to_fun := finsupp.equiv_map_domain f,
  inv_fun := finsupp.equiv_map_domain f.symm,
  commutes' := λ r, by simp only [function.comp_app, finsupp.equiv_map_domain_single,
      add_monoid_algebra.coe_algebra_map, map_zero, add_equiv.coe_to_equiv],
  ..map_domain_ring_equiv A f }

@[simps]
def map_domain_alg_aut (k A : Type*) [comm_semiring k] [semiring A] [algebra k A]
  {G : Type*} [add_monoid G] :
  (add_aut G) →* add_monoid_algebra A G ≃ₐ[k] add_monoid_algebra A G :=
{ to_fun := map_domain_alg_equiv k A,
  map_one' := by { ext, refl, },
  map_mul' := λ x y, by { ext, refl, }, }

end add_monoid_algebra

namespace aux
variables (p : ℚ[X])

abbreviation K' : intermediate_field ℚ ℂ :=
intermediate_field.adjoin ℚ (p.root_set ℂ)

instance K'.is_splitting_field : is_splitting_field ℚ (K' p) p :=
intermediate_field.adjoin_root_set_is_splitting_field (is_alg_closed.splits_codomain p)

abbreviation K : Type* := p.splitting_field

instance : char_zero (K p) := char_zero_of_injective_algebra_map (algebra_map ℚ (K p)).injective

instance : is_galois ℚ (K p) := {}

abbreviation Lift : K' p ≃ₐ[ℚ] K p := is_splitting_field.alg_equiv (K' p) p

instance algebra_K_ℂ : algebra (K p) ℂ :=
((K' p).val.comp (Lift p).symm.to_alg_hom).to_ring_hom.to_algebra

/--
```
example : (intermediate_field.to_algebra _ : algebra (⊥ : intermediate_field ℚ (K p)) (K p)) =
  (splitting_field.algebra' p : algebra (⊥ : intermediate_field ℚ (K p)) (K p)) :=
rfl
```
-/
instance avoid_diamond_cache : algebra (⊥ : intermediate_field ℚ (K p)) (K p) :=
intermediate_field.to_algebra _

/--
example : algebra_int (K p) = (infer_instance : algebra ℤ (K p)) := rfl
-/
instance avoid_diamond_int_cache : algebra ℤ (K p) := algebra_int (K p)

instance : algebra ℚ (K p) := infer_instance
instance : has_smul ℚ (K p) := algebra.to_has_smul

instance cache_ℚ_K_ℂ : is_scalar_tower ℚ (K p) ℂ := infer_instance
instance cache_ℤ_K_ℂ : is_scalar_tower ℤ (K p) ℂ := infer_instance

end aux


namespace quot

attribute [reducible, elab_as_eliminator]
protected def lift_finsupp {α : Type*} {r : α → α → Prop} {β : Type*} [has_zero β]
  (f : α →₀ β) (h : ∀ a b, r a b → f a = f b) : quot r →₀ β := by
{ refine ⟨image (mk r) f.support, quot.lift f h, λ a, ⟨_, a.ind (λ b, _)⟩⟩,
  { rw [mem_image], rintros ⟨b, hb, rfl⟩, exact finsupp.mem_support_iff.mp hb, },
  { rw [lift_mk _ h], refine λ hb, mem_image_of_mem _ (finsupp.mem_support_iff.mpr hb), }, }

lemma lift_finsupp_mk {α : Type*} {r : α → α → Prop} {γ : Type*} [has_zero γ]
  (f : α →₀ γ) (h : ∀ a₁ a₂, r a₁ a₂ → f a₁ = f a₂) (a : α) :
quot.lift_finsupp f h (quot.mk r a) = f a := rfl

end quot

namespace quotient

attribute [reducible, elab_as_eliminator]
protected def lift_finsupp {α : Type*} {β : Type*} [s : setoid α] [has_zero β] (f : α →₀ β) :
  (∀ a b, a ≈ b → f a = f b) → quotient s →₀ β :=
quot.lift_finsupp f

@[simp] lemma lift_finsupp_mk {α : Type*} {β : Type*} [s : setoid α] [has_zero β] (f : α →₀ β)
  (h : ∀ (a b : α), a ≈ b → f a = f b) (x : α) :
quotient.lift_finsupp f h (quotient.mk x) = f x := rfl

end quotient

section
variables (s : finset ℂ)

abbreviation Poly : ℚ[X] := ∏ x in s, minpoly ℚ x

abbreviation K' : intermediate_field ℚ ℂ :=
intermediate_field.adjoin ℚ ((Poly s).root_set ℂ)

abbreviation K : Type* := (Poly s).splitting_field

abbreviation Gal : Type* := (Poly s).gal

abbreviation Lift : K' s ≃ₐ[ℚ] K s := is_splitting_field.alg_equiv (K' s) (Poly s)

lemma algebra_map_K_apply (x) : algebra_map (K s) ℂ x = ((Lift s).symm x : ℂ) :=
rfl

lemma Poly_ne_zero (hs : ∀ x ∈ s, is_integral ℚ x) : Poly s ≠ 0 :=
prod_ne_zero_iff.mpr (λ x hx, minpoly.ne_zero (hs x hx))

noncomputable!
def rat_coeff : subalgebra ℚ (add_monoid_algebra (K s) (K s)) :=
{ carrier := λ x, ∀ i : K s, x i ∈ (⊥ : intermediate_field ℚ (K s)),
  mul_mem' := λ a b ha hb i,
  begin
    rw [add_monoid_algebra.mul_apply],
    refine sum_mem (λ c hc, sum_mem (λ d hd, _)),
    dsimp only, split_ifs, exacts [mul_mem (ha c) (hb d), zero_mem _],
  end,
  add_mem' := λ a b ha hb i, by { rw [finsupp.add_apply], exact add_mem (ha i) (hb i), },
  algebra_map_mem' := λ r hr,
  begin
    rw [add_monoid_algebra.coe_algebra_map, function.comp_app, finsupp.single_apply],
    split_ifs, exacts [intermediate_field.algebra_map_mem _ _, zero_mem _],
  end }

--cache
instance : zero_mem_class (intermediate_field ℚ (K s)) (K s) := infer_instance

def rat_coeff_equiv.aux :
  rat_coeff s ≃ₐ[ℚ] add_monoid_algebra (⊥ : intermediate_field ℚ (K s)) (K s) :=
{ to_fun := λ x,
  { support := (x : add_monoid_algebra (K s) (K s)).support,
    to_fun := λ i, ⟨x i, x.2 i⟩,
    mem_support_to_fun := λ i,
    begin
      rw [finsupp.mem_support_iff],
      have : (0 : (⊥ : intermediate_field ℚ (K s))) = ⟨0, zero_mem_class.zero_mem _⟩ := rfl,
      simp_rw [this, ne.def, subtype.mk.inj_eq], refl,
    end, },
  inv_fun := λ x, ⟨⟨x.support, λ i, x i, λ i, by simp_rw [finsupp.mem_support_iff, ne.def,
    zero_mem_class.coe_eq_zero]⟩, λ i, set_like.coe_mem _⟩,
  left_inv := λ x, by { ext, refl, },
  right_inv := λ x, by { ext, refl, },
  map_mul' := λ x y,
  begin
    ext, change (x * y : add_monoid_algebra (K s) (K s)) a = _,
    simp_rw [add_monoid_algebra.mul_apply, finsupp.sum, add_submonoid_class.coe_finset_sum],
    refine sum_congr rfl (λ i hi, sum_congr rfl (λ j hj, _)),
    split_ifs; refl,
  end,
  map_add' := λ x y, by { ext, change (x + y : add_monoid_algebra (K s) (K s)) a = x a + y a,
    rw [finsupp.add_apply], refl, },
  commutes' := λ x,
  begin
    ext,
    change (algebra_map ℚ (rat_coeff s) x) a =
      ((finsupp.single 0 (algebra_map ℚ (⊥ : intermediate_field ℚ (K s)) x)) a),
    simp_rw [algebra.algebra_map_eq_smul_one],
    change (x • finsupp.single 0 (1 : K s)) a = _,
    simp_rw [finsupp.smul_single, finsupp.single_apply],
    split_ifs; refl,
  end, }

def rat_coeff_equiv :
  rat_coeff s ≃ₐ[ℚ] add_monoid_algebra ℚ (K s) :=
(rat_coeff_equiv.aux s).trans
  (add_monoid_algebra.alg_equiv_congr_left (intermediate_field.bot_equiv ℚ (K s)))

lemma rat_coeff_equiv_apply_apply (x : rat_coeff s) (i : K s) :
  rat_coeff_equiv s x i =
    (intermediate_field.bot_equiv ℚ (K s)) ⟨x i, x.2 i⟩ := rfl

lemma support_rat_coeff_equiv (x : rat_coeff s) :
  (rat_coeff_equiv s x).support = (x : add_monoid_algebra (K s) (K s)).support :=
begin
  dsimp [rat_coeff_equiv, rat_coeff_equiv.aux],
  rw [finsupp.support_map_range_of_injective],
  exact alg_equiv.injective _,
end

section
variables (F : Type*) [field F] [algebra ℚ F]

noncomputable!
def map_domain_fixed : subalgebra F (add_monoid_algebra F (K s)) :=
{ carrier := λ x, ∀ f : Gal s, add_monoid_algebra.map_domain_alg_aut ℚ _ f.to_add_equiv x = x,
  mul_mem' := λ a b ha hb f, by rw [map_mul, ha, hb],
  add_mem' := λ a b ha hb f, by rw [map_add, ha, hb],
  algebra_map_mem' := λ r f,
  begin
    change finsupp.equiv_map_domain f.to_equiv (finsupp.single _ _) = finsupp.single _ _,
    rw [finsupp.equiv_map_domain_single],
    change finsupp.single (f 0) _ = _, rw [alg_equiv.map_zero],
  end }

lemma mem_map_domain_fixed_iff (x : add_monoid_algebra F (K s)) :
  x ∈ map_domain_fixed s F ↔ (∀ i j, i ∈ mul_action.orbit (Gal s) j → x i = x j) :=
begin
  simp_rw [mul_action.mem_orbit_iff],
  change (∀ (f : Gal s), finsupp.equiv_map_domain ↑(alg_equiv.to_add_equiv f) x = x) ↔ _,
  refine ⟨λ h i j hij, _, λ h f, _⟩,
  { obtain ⟨f, rfl⟩ := hij,
    rw [alg_equiv.smul_def, ← finsupp.congr_fun (h f) (f j)],
    change x (f.symm (f j)) = _, rw [alg_equiv.symm_apply_apply], },
  { ext i, change x (f.symm i) = x i,
    refine (h i ((alg_equiv.symm f) i) ⟨f, _⟩).symm,
    rw [alg_equiv.smul_def, alg_equiv.apply_symm_apply], }
end

noncomputable!
def map_domain_fixed_equiv_subtype :
  map_domain_fixed s F ≃
    {f : add_monoid_algebra F (K s) // (mul_action.orbit_rel (Gal s) (K s)) ≤ setoid.ker f} :=
{ to_fun := λ f, ⟨f, (mem_map_domain_fixed_iff s F f).mp f.2⟩,
  inv_fun := λ f, ⟨f, (mem_map_domain_fixed_iff s F f).mpr f.2⟩,
  left_inv := λ f, by simp_rw [← subtype.coe_inj, subtype.coe_mk],
  right_inv := λ f, by simp_rw [← subtype.coe_inj, subtype.coe_mk], }

end

section to_conj_equiv
variables (F : Type*) [field F] [algebra ℚ F]
open gal_conj_classes

def to_conj_equiv : map_domain_fixed s F ≃ (gal_conj_classes ℚ (K s) →₀ F) :=
begin
  refine (map_domain_fixed_equiv_subtype s F).trans _,
  refine
  { to_fun := λ f, @quotient.lift_finsupp _ _ (is_gal_conj.setoid _ _) _
      (f : add_monoid_algebra F (K s)) f.2,
    inv_fun := λ f, ⟨_, _⟩,
    left_inv := _,
    right_inv := _, },
  { refine ⟨f.support.bUnion (λ i, i.orbit.to_finset), λ x, f (mk _ x), λ i, _⟩,
    simp_rw [mem_bUnion, set.mem_to_finset, mem_orbit,
      finsupp.mem_support_iff, exists_prop, exists_eq_right'], },
  { change ∀ i j, i ∈ mul_action.orbit (Gal s) j → f (quotient.mk' i) = f (quotient.mk' j),
    exact λ i j h, congr_arg f (quotient.sound' h), },
  { exact λ _, subtype.eq $ finsupp.ext $ λ x, rfl, },
  { refine λ f, finsupp.ext $ λ x, quotient.induction_on' x $ λ i, rfl, }
end

@[simp]
lemma to_conj_equiv_apply_apply_mk (f : map_domain_fixed s F) (i : K s) :
  to_conj_equiv s F f (mk ℚ i) = f i := rfl

@[simp]
lemma to_conj_equiv_symm_apply_apply (f : gal_conj_classes ℚ (K s) →₀ F) (i : K s) :
  (to_conj_equiv s F).symm f i = f (mk ℚ i) := rfl

@[simp]
lemma to_conj_equiv_apply_apply (f : map_domain_fixed s F) (i : gal_conj_classes ℚ (K s)) :
  to_conj_equiv s F f i = f i.out :=
by rw [← i.out_eq, to_conj_equiv_apply_apply_mk, i.out_eq]

@[simp]
lemma to_conj_equiv_apply_zero_eq (f : map_domain_fixed s F) :
  to_conj_equiv s F f 0 = f 0 :=
by rw [to_conj_equiv_apply_apply, gal_conj_classes.zero_out]

@[simp]
lemma to_conj_equiv_symm_apply_zero_eq (f : gal_conj_classes ℚ (K s) →₀ F) :
  (to_conj_equiv s F).symm f 0 = f 0 :=
by { rw [to_conj_equiv_symm_apply_apply], refl, }

@[simps]
def to_conj_linear_equiv : map_domain_fixed s F ≃ₗ[F] (gal_conj_classes ℚ (K s) →₀ F) :=
{ to_fun := to_conj_equiv s F,
  inv_fun := (to_conj_equiv s F).symm,
  map_add' := λ x y, by { ext i, simp_rw [finsupp.coe_add, pi.add_apply,
    to_conj_equiv_apply_apply], refl, },
  map_smul' := λ r x, by { ext i, simp_rw [finsupp.coe_smul, pi.smul_apply,
    to_conj_equiv_apply_apply], refl, },
  ..to_conj_equiv s F, }

namespace finsupp.gal_conj_classes

instance : comm_ring (gal_conj_classes ℚ (K s) →₀ F) :=
{ zero := 0,
  add := (+),
  one := to_conj_linear_equiv s F 1,
  mul := λ x y, to_conj_linear_equiv s F $
    ((to_conj_linear_equiv s F).symm x) * ((to_conj_linear_equiv s F).symm y),
  mul_assoc := λ a b c, by simp_rw [mul_def, linear_equiv.symm_apply_apply, mul_assoc],
  one_mul := λ a, by simp_rw [linear_equiv.symm_apply_apply, one_mul,
    linear_equiv.apply_symm_apply],
  mul_one := λ a, by simp_rw [linear_equiv.symm_apply_apply, mul_one,
    linear_equiv.apply_symm_apply],
  left_distrib := λ a b c, by simp only [← map_add, ← mul_add],
  right_distrib := λ a b c, by simp only [← map_add, ← add_mul],
  mul_comm := λ a b, by { change to_conj_linear_equiv s F _ = to_conj_linear_equiv s F _,
    exact congr_arg _ (mul_comm _ _), },
  ..(infer_instance : add_comm_group (gal_conj_classes ℚ (K s) →₀ F)) }

lemma one_def : (1 : gal_conj_classes ℚ (K s) →₀ F) = to_conj_linear_equiv s F 1 := rfl

lemma mul_def (x y : gal_conj_classes ℚ (K s) →₀ F) :
  x * y = to_conj_linear_equiv s F
    (((to_conj_linear_equiv s F).symm x) * ((to_conj_linear_equiv s F).symm y)) := rfl

instance cache : is_scalar_tower F (map_domain_fixed s F) (map_domain_fixed s F) :=
is_scalar_tower.right

instance : algebra F (gal_conj_classes ℚ (K s) →₀ F) :=
algebra.of_module'
  (λ r x, by rw [one_def, mul_def, smul_hom_class.map_smul, linear_equiv.symm_apply_apply,
    smul_one_mul, ← smul_hom_class.map_smul, linear_equiv.apply_symm_apply])
  (λ r x, by rw [one_def, mul_def, smul_hom_class.map_smul, linear_equiv.symm_apply_apply,
    mul_smul_one, ← smul_hom_class.map_smul, linear_equiv.apply_symm_apply])

lemma one_eq_single : (1 : gal_conj_classes ℚ (K s) →₀ F) = finsupp.single 0 1 :=
begin
  change to_conj_equiv s F 1 = _,
  ext i, rw [to_conj_equiv_apply_apply],
  change (1 : add_monoid_algebra F (K s)) i.out = finsupp.single 0 1 i,
  simp_rw [add_monoid_algebra.one_def, finsupp.single_apply],
  change (ite (0 = i.out) 1 0 : F) = ite (0 = i) 1 0,
  simp_rw [@eq_comm _ _ i.out, @eq_comm _ _ i, gal_conj_classes.out_eq_zero_iff],
end

lemma algebra_map_eq_single (x : F) :
  algebra_map F (gal_conj_classes ℚ (K s) →₀ F) x = finsupp.single 0 x :=
begin
  change x • (1 : gal_conj_classes ℚ (K s) →₀ F) = finsupp.single 0 x,
  rw [one_eq_single, finsupp.smul_single, smul_eq_mul, mul_one],
end

end finsupp.gal_conj_classes

@[simps]
def to_conj_alg_equiv : map_domain_fixed s F ≃ₐ[F] (gal_conj_classes ℚ (K s) →₀ F) :=
{ to_fun := to_conj_linear_equiv s F,
  inv_fun := (to_conj_linear_equiv s F).symm,
  map_mul' := λ x y, by simp_rw [finsupp.gal_conj_classes.mul_def, linear_equiv.symm_apply_apply],
  commutes' := λ r,
  begin
    simp_rw [finsupp.gal_conj_classes.algebra_map_eq_single],
    change to_conj_equiv s F (algebra_map F (map_domain_fixed s F) r) = _,
    ext i, rw [to_conj_equiv_apply_apply],
    change finsupp.single 0 r i.out = finsupp.single 0 r i,
    simp_rw [finsupp.single_apply],
    change ite (0 = i.out) r 0 = ite (0 = i) r 0,
    simp_rw [@eq_comm _ _ i.out, @eq_comm _ _ i, out_eq_zero_iff],
  end,
  ..to_conj_linear_equiv s F, }

lemma to_conj_equiv_symm_single.aux (x : gal_conj_classes ℚ (K s)) (a : F) :
  finsupp.indicator x.orbit.to_finset (λ _ _, a) ∈ map_domain_fixed s F :=
begin
  rw [mem_map_domain_fixed_iff],
  rintros i j h,
  simp_rw [finsupp.indicator_apply, set.mem_to_finset], dsimp, congr' 1,
  simp_rw [mem_orbit, eq_iff_iff],
  apply eq.congr_left,
  rwa [gal_conj_classes.eq],
end

lemma to_conj_equiv_symm_single (x : gal_conj_classes ℚ (K s)) (a : F) :
  (to_conj_equiv s F).symm (finsupp.single x a) =
    ⟨finsupp.indicator x.orbit.to_finset (λ _ _, a), to_conj_equiv_symm_single.aux s F x a⟩ :=
begin
  rw [equiv.symm_apply_eq],
  ext i, rw [to_conj_equiv_apply_apply],
  change finsupp.single x a i = finsupp.indicator x.orbit.to_finset (λ _ _, a) i.out,
  rw [finsupp.single_apply, finsupp.indicator_apply], dsimp, congr' 1,
  rw [set.mem_to_finset, mem_orbit, out_eq, @eq_comm _ i],
end

lemma single_prod_apply_zero_ne_zero_iff (x : gal_conj_classes ℚ (K s)) {a : F} (ha : a ≠ 0)
  (y : gal_conj_classes ℚ (K s)) {b : F} (hb : b ≠ 0) :
  (finsupp.single x a * finsupp.single y b) 0 ≠ 0 ↔ x = -y :=
begin
  simp_rw [finsupp.gal_conj_classes.mul_def, to_conj_linear_equiv_apply,
    to_conj_linear_equiv_symm_apply, to_conj_equiv_apply_zero_eq],
  simp_rw [to_conj_equiv_symm_single, mul_mem_class.mk_mul_mk],
  change (finsupp.indicator x.orbit.to_finset (λ _ _, a) *
    finsupp.indicator y.orbit.to_finset (λ _ _, b) :
    add_monoid_algebra _ _) 0 ≠ _ ↔ _,
  haveI := nat.no_zero_smul_divisors ℚ F,
  simp_rw [finsupp.indicator_const_eq_sum_single, sum_mul, mul_sum,
    add_monoid_algebra.single_mul_single,
    finsupp.coe_finset_sum, sum_apply, finsupp.single_apply, ← sum_product', sum_ite,
    sum_const_zero, add_zero, sum_const, smul_ne_zero_iff, mul_ne_zero_iff, iff_true_intro ha,
    iff_true_intro hb, and_true, ne.def, card_eq_zero, filter_eq_empty_iff], push_neg,
  simp_rw [prod.exists, mem_product, set.mem_to_finset],
  exact gal_conj_classes.exist_mem_orbit_add_eq_zero x y,
end

lemma single_prod_apply_zero_eq_zero_iff (x : gal_conj_classes ℚ (K s)) {a : F} (ha : a ≠ 0)
  (y : gal_conj_classes ℚ (K s)) {b : F} (hb : b ≠ 0) :
  (finsupp.single x a * finsupp.single y b) 0 = 0 ↔ x ≠ -y :=
by { convert (single_prod_apply_zero_ne_zero_iff s F x ha y hb).not, rw [ne.def, not_not], }

end to_conj_equiv

section Eval

def exp_monoid_hom : multiplicative ℂ →* ℂ :=
{ to_fun := λ x, exp x.to_add,
  map_one' := by rw [to_add_one, exp_zero],
  map_mul' := λ x y, by rw [to_add_mul, exp_add], }

variables (F : Type*) [field F] [algebra F ℂ]

def Eval : add_monoid_algebra F (K s) →ₐ[F] ℂ :=
add_monoid_algebra.lift F (K s) ℂ
  (exp_monoid_hom.comp (add_monoid_hom.to_multiplicative (algebra_map (K s) ℂ).to_add_monoid_hom))

lemma Eval_apply' (x : add_monoid_algebra F (K s)) :
  Eval s F x = x.sum (λ a c, algebra_map F ℂ c * exp (algebra_map (K s) ℂ a)) := rfl

lemma Eval_apply (x : add_monoid_algebra F (K s)) :
  Eval s F x = x.sum (λ a c, c • exp (algebra_map (K s) ℂ a)) :=
by { rw [Eval, add_monoid_algebra.lift_apply], refl, }

lemma Eval_rat_apply (x : add_monoid_algebra ℚ (K s)) :
  Eval s ℚ x = x.sum (λ a c, c • exp (algebra_map (K s) ℂ a)) := rfl

lemma Eval_K_apply (x : add_monoid_algebra (K s) (K s)) :
  Eval s (K s) x = x.sum (λ a c, c • exp (algebra_map (K s) ℂ a)) := rfl

lemma Eval_rat_coeff (x : rat_coeff s) :
  Eval s (K s) x = Eval s ℚ (rat_coeff_equiv s x) :=
begin
  simp_rw [Eval_apply, finsupp.sum, support_rat_coeff_equiv, rat_coeff_equiv_apply_apply],
  refine sum_congr rfl (λ i hi, _),
  simp_rw [algebra.smul_def, is_scalar_tower.algebra_map_eq ℚ (K s) ℂ], congr' 2,
  rw [is_scalar_tower.algebra_map_apply ℚ (⊥ : intermediate_field ℚ (K s)) (K s),
    ← intermediate_field.bot_equiv_symm, alg_equiv.symm_apply_apply], refl,
end

lemma Eval_to_conj_alg_equiv_symm (x : gal_conj_classes ℚ (K s) →₀ ℚ) :
  Eval s ℚ ((to_conj_alg_equiv s ℚ).symm x) = ∑ (c : gal_conj_classes ℚ (K s)) in x.support,
    x c • ∑ (i : K s) in c.orbit.to_finset, exp (algebra_map (K s) ℂ i) :=
begin
  conv_lhs { rw [← x.sum_single, finsupp.sum, map_sum], },
  change Eval s ℚ ↑(finset.sum _ (λ i, (to_conj_equiv s ℚ).symm _)) = _,
  have : ∀ (s' : finset (K s)) (b : ℚ),
    (finsupp.indicator s' (λ _ _, b)).sum (λ a c, c • exp (algebra_map (K s) ℂ a)) =
    ∑ i in s', b • exp (algebra_map (K s) ℂ i) :=
  λ s' b, finsupp.sum_indicator_const_index _ (λ i hi, by rw [zero_smul]),
  simp_rw [to_conj_equiv_symm_single, add_submonoid_class.coe_finset_sum, subtype.coe_mk, map_sum,
    Eval_apply, this, smul_sum],
end

end Eval

instance is_domain1 : is_domain (add_monoid_algebra (K s) (K s)) := sorry
instance is_domain2 : is_domain (add_monoid_algebra ℚ (K s)) := sorry
instance is_domain3 : is_domain (gal_conj_classes ℚ (K s) →₀ ℚ) :=
ring_equiv.is_domain (map_domain_fixed s ℚ) (to_conj_alg_equiv s ℚ).symm

lemma linear_independent_exp_aux2 (s : finset ℂ)
  (x : add_monoid_algebra ℚ (K s)) (x0 : x ≠ 0) (x_ker : x ∈ (Eval s ℚ).to_ring_hom.ker) :
  ∃ (w : ℚ) (w0 : w ≠ 0)
    (q : finset (gal_conj_classes ℚ (K s))) (hq : (0 : gal_conj_classes ℚ (K s)) ∉ q)
    (w' : gal_conj_classes ℚ (K s) → ℚ),
    (w + ∑ c in q, w' c • ∑ x in c.orbit.to_finset,
      exp (algebra_map (K s) ℂ x) : ℂ) = 0 :=
begin
  let V := ∏ f : Gal s, add_monoid_algebra.map_domain_alg_aut ℚ _ f.to_add_equiv x,
  have hV : V ∈ map_domain_fixed s ℚ,
  { intros f, dsimp only [V],
    rw [map_prod], simp_rw [← alg_equiv.trans_apply, ← alg_equiv.aut_mul, ← map_mul],
    exact (group.mul_left_bijective f).prod_comp
      (λ g, add_monoid_algebra.map_domain_alg_aut ℚ _ g.to_add_equiv x), },
  have V0 : V ≠ 0,
  { dsimp only [V], rw [prod_ne_zero_iff], intros f hf,
    rwa [add_equiv_class.map_ne_zero_iff], },
  have V_ker : V ∈ (Eval s ℚ).to_ring_hom.ker,
  { dsimp only [V],
    suffices : (λ f : Gal s, (add_monoid_algebra.map_domain_alg_aut ℚ _ f.to_add_equiv) x) 1 *
      ∏ (f : Gal s) in univ.erase 1,
        add_monoid_algebra.map_domain_alg_aut ℚ _ f.to_add_equiv x ∈ (Eval s ℚ).to_ring_hom.ker,
    { rwa [mul_prod_erase (univ : finset (Gal s)) _ (mem_univ _)] at this, },
    change (finsupp.equiv_map_domain (equiv.refl _) x * _ : add_monoid_algebra ℚ (K s)) ∈ _,
    rw [finsupp.equiv_map_domain_refl], exact ideal.mul_mem_right _ _ x_ker, },
  
  let V' := to_conj_alg_equiv s ℚ ⟨V, hV⟩,
  have V'0 : V' ≠ 0,
  { dsimp only [V'], rw [add_equiv_class.map_ne_zero_iff],
    exact λ h, absurd (subtype.mk.inj h) V0, },
  obtain ⟨i, hi⟩ := finsupp.support_nonempty_iff.mpr V'0,
  
  let V'' := V' * finsupp.single (-i) (1 : ℚ),
  have V''0 : V'' ≠ 0,
  { dsimp only [V''], refine mul_ne_zero V'0 (λ h, _),
    have := fun_like.congr_fun h (-i),
    rw [finsupp.zero_apply, finsupp.single_apply_eq_zero] at this,
    exact one_ne_zero (this rfl), },
  have hV'' : V'' 0 ≠ 0,
  { dsimp only [V''],
    rw [← V'.sum_single, finsupp.sum, ← add_sum_erase _ _ hi, add_mul, sum_mul, finsupp.add_apply],
    convert_to ((finsupp.single i (V' i) * finsupp.single (-i) 1) 0 + 0 : ℚ) ≠ 0,
    { congr' 1,
      rw [finsupp.finset_sum_apply],
      refine sum_eq_zero (λ j hj, _),
      rw [mem_erase, finsupp.mem_support_iff] at hj,
      rw [single_prod_apply_zero_eq_zero_iff _ _ _ hj.2],
      { rw [neg_neg], exact hj.1, }, exact one_ne_zero, },
    rw [add_zero, single_prod_apply_zero_ne_zero_iff],
    { rw [neg_neg], }, { rwa [finsupp.mem_support_iff] at hi, }, exact one_ne_zero, },
  have zero_mem : (0 : gal_conj_classes ℚ (K s)) ∈ V''.support,
  { rwa [finsupp.mem_support_iff], },
  have Eval_V'' : Eval s ℚ ((to_conj_alg_equiv s ℚ).symm V'') = 0,
  { dsimp only [V'', V'],
    rw [map_mul, subalgebra.coe_mul, map_mul, alg_equiv.symm_apply_apply, subtype.coe_mk],
    rw [ring_hom.mem_ker, alg_hom.to_ring_hom_eq_coe, alg_hom.coe_to_ring_hom] at V_ker,
    rw [V_ker, zero_mul], },
  
  use [V'' 0, hV'', V''.support.erase 0, not_mem_erase _ _, V''],
  rw [← Eval_V'', Eval_to_conj_alg_equiv_symm, ← add_sum_erase _ _ zero_mem],
  congr' 1,
  simp_rw [gal_conj_classes.orbit_zero, set.to_finset_singleton, sum_singleton, map_zero, exp_zero,
    rat.smul_one_eq_coe],
end

lemma linear_independent_exp_aux1 (s : finset ℂ)
  (x : add_monoid_algebra (K s) (K s)) (x0 : x ≠ 0) (x_ker : x ∈ (Eval s (K s)).to_ring_hom.ker) :
  ∃ (w : ℚ) (w0 : w ≠ 0)
    (q : finset (gal_conj_classes ℚ (K s))) (hq : (0 : gal_conj_classes ℚ (K s)) ∉ q)
    (w' : gal_conj_classes ℚ (K s) → ℚ),
    (w + ∑ c in q, w' c • ∑ x in c.orbit.to_finset,
      exp (algebra_map (K s) ℂ x) : ℂ) = 0 :=
begin
  let U := ∏ f : Gal s, add_monoid_algebra.alg_aut_congr_left f x,
  have hU : ∀ f : Gal s, add_monoid_algebra.alg_aut_congr_left f U = U,
  { intros f, dsimp only [U],
    simp_rw [map_prod, ← alg_equiv.trans_apply, ← alg_equiv.aut_mul, ← map_mul],
    exact (group.mul_left_bijective f).prod_comp
      (λ g, add_monoid_algebra.alg_aut_congr_left g x), },
  have U0 : U ≠ 0,
  { dsimp only [U], rw [prod_ne_zero_iff], intros f hf,
    rwa [add_equiv_class.map_ne_zero_iff], },
  have U_ker : U ∈ (Eval s (K s)).to_ring_hom.ker,
  { dsimp only [U],
    suffices : (λ f : Gal s, (add_monoid_algebra.alg_aut_congr_left f) x) 1 *
      ∏ (f : Gal s) in univ.erase 1,
        (add_monoid_algebra.alg_aut_congr_left f) x ∈ (Eval s (K s)).to_ring_hom.ker,
    { rwa [mul_prod_erase (univ : finset (Gal s)) _ (mem_univ _)] at this, },
    change finsupp.map_range id rfl _ * _ ∈ _,
    rw [finsupp.map_range_id], exact ideal.mul_mem_right _ _ x_ker, },
  have U_mem : ∀ i : K s, U i ∈ intermediate_field.fixed_field (⊤ : subgroup (K s ≃ₐ[ℚ] K s)),
  { intros i, dsimp [intermediate_field.fixed_field, fixed_points.intermediate_field],
    rintros ⟨f, hf⟩, rw [subgroup.smul_def, subgroup.coe_mk],
    replace hU : (add_monoid_algebra.alg_aut_congr_left f) U i = U i, { rw [hU f], },
    rwa [add_monoid_algebra.alg_aut_congr_left_apply,
      add_monoid_algebra.alg_equiv_congr_left_apply, finsupp.map_range_apply] at hU, },
  replace U_mem : U ∈ rat_coeff s,
  { intros i, specialize U_mem i,
    rwa [((@is_galois.tfae ℚ _ (K s) _ _ _).out 0 1).mp infer_instance] at U_mem, },
  
  let U' := rat_coeff_equiv s ⟨U, U_mem⟩,
  have U'0 : U' ≠ 0,
  { dsimp only [U'],
    rw [add_equiv_class.map_ne_zero_iff, zero_mem_class.zero_def],
    exact λ h, absurd (subtype.mk.inj h) U0, },
  have U'_ker : U' ∈ (Eval s ℚ).to_ring_hom.ker,
  { dsimp only [U'],
    rw [ring_hom.mem_ker, alg_hom.to_ring_hom_eq_coe, alg_hom.coe_to_ring_hom, ← Eval_rat_coeff],
    rwa [ring_hom.mem_ker] at U_ker, },
  exact linear_independent_exp_aux2 s U' U'0 U'_ker,
end

end

variables {ι : Type*} [fintype ι]

abbreviation Range (u : ι → ℂ) (v : ι → ℂ) : finset ℂ := univ.image u ∪ univ.image v

lemma linear_independent_exp_aux_rat
  (u : ι → ℂ) (hu : ∀ i, is_integral ℚ (u i)) (u_inj : function.injective u)
  (v : ι → ℂ) (hv : ∀ i, is_integral ℚ (v i)) (v0 : v ≠ 0)
  (h : ∑ i, v i * exp (u i) = 0) :
  ∃ (w : ℚ) (w0 : w ≠ 0)
    (q : finset (gal_conj_classes ℚ (K (Range u v)))) (hq : (0 : gal_conj_classes _ _) ∉ q)
    (w' : gal_conj_classes ℚ (K (Range u v)) → ℚ),
    (w + ∑ c in q, w' c • ∑ x in c.orbit.to_finset,
      exp (algebra_map (K (Range u v)) ℂ x) : ℂ) = 0 :=
begin
  let s := Range u v,
  have hs : ∀ x ∈ s, is_integral ℚ x,
  { intros x hx,
    cases mem_union.mp hx with hxu hxv,
    { obtain ⟨i, _, rfl⟩ := mem_image.mp hxu,
      exact hu i, },
    { obtain ⟨i, _, rfl⟩ := mem_image.mp hxv,
      exact hv i, }, },
  have u_mem : ∀ i, u i ∈ K' s,
  { intros i,
    apply intermediate_field.subset_adjoin,
    rw [mem_root_set, map_prod, prod_eq_zero_iff],
    exact ⟨Poly_ne_zero s hs, u i, mem_union_left _ (mem_image.mpr ⟨i, mem_univ _, rfl⟩), minpoly.aeval _ _⟩, },
  have v_mem : ∀ i, v i ∈ K' s,
  { intros i,
    apply intermediate_field.subset_adjoin,
    rw [mem_root_set, map_prod, prod_eq_zero_iff],
    exact ⟨Poly_ne_zero s hs, v i, mem_union_right _ (mem_image.mpr ⟨i, mem_univ _, rfl⟩), minpoly.aeval _ _⟩, },
  let u' : ∀ i, K s := λ i : ι, Lift s ⟨u i, u_mem i⟩,
  let v' : ∀ i, K s := λ i : ι, Lift s ⟨v i, v_mem i⟩,
  have u'_inj : function.injective u' :=
    λ i j hij, u_inj (subtype.mk.inj ((Lift s).injective hij)),
  replace h : ∑ i, (algebra_map (K s) ℂ (v' i)) * exp (algebra_map (K s) ℂ (u' i)) = 0,
  { simp_rw [algebra_map_K_apply, alg_equiv.symm_apply_apply, ← h],
    symmetry, apply sum_congr rfl,
    intros x hx, refl, },
  
  let f : add_monoid_algebra (K s) (K s) := finsupp.on_finset (image u' univ)
    (λ x, if hx : x ∈ image u' univ
      then v' (u'_inj.inv_of_mem_range ⟨x, mem_image_univ_iff_mem_range.mp hx⟩) else 0)
    (λ x, by { contrapose!, intros hx, rw [dif_neg hx], }),
  replace hf : Eval s (K s) f = 0,
  { rw [Eval_apply, ← h, finsupp.on_finset_sum _ (λ a, _)], swap, { rw [zero_smul], },
    rw [sum_image, sum_congr rfl], swap, { exact λ i hi j hj hij, u'_inj hij, },
    intros x hx,
    rw [dif_pos, u'_inj.right_inv_of_inv_of_mem_range], { refl },
    exact mem_image_of_mem _ (mem_univ _), },
  have f0 : f ≠ 0,
  { rw [ne.def, function.funext_iff] at v0, push_neg at v0,
    cases v0 with i hi,
    rw [pi.zero_apply] at hi,
    have h : f (u' i) ≠ 0,
    { rwa [finsupp.on_finset_apply, dif_pos, u'_inj.right_inv_of_inv_of_mem_range, ne.def,
        add_equiv_class.map_eq_zero_iff, ← zero_mem_class.coe_eq_zero],
      exact mem_image_of_mem _ (mem_univ _), },
    intros f0,
    rw [f0, finsupp.zero_apply] at h,
    exact absurd rfl h, },
  rw [← alg_hom.coe_to_ring_hom, ← ring_hom.mem_ker] at hf,
  exact linear_independent_exp_aux1 s f f0 hf,
end

lemma linear_independent_exp_aux''
  (u : ι → ℂ) (hu : ∀ i, is_integral ℚ (u i)) (u_inj : function.injective u)
  (v : ι → ℂ) (hv : ∀ i, is_integral ℚ (v i)) (v0 : v ≠ 0)
  (h : ∑ i, v i * exp (u i) = 0) :
  ∃ (w : ℤ) (w0 : w ≠ 0)
    (q : finset (gal_conj_classes ℚ (K (Range u v)))) (hq : (0 : gal_conj_classes _ _) ∉ q)
    (w' : gal_conj_classes ℚ (K (Range u v)) → ℤ),
    (w + ∑ c in q, w' c • ∑ x in c.orbit.to_finset,
      exp (algebra_map (K (Range u v)) ℂ x) : ℂ) = 0 :=
begin
  obtain ⟨w, w0, q, hq, w', h⟩ := linear_independent_exp_aux_rat u hu u_inj v hv v0 h,
  let N := w.denom * ∏ c in q, (w' c).denom,
  have wN0 : (w * N).num ≠ 0,
  { refine rat.num_ne_zero_of_ne_zero (mul_ne_zero w0 _), dsimp only [N],
    rw [nat.cast_ne_zero, mul_ne_zero_iff, prod_ne_zero_iff],
    exact ⟨rat.denom_ne_zero _, λ c hc, rat.denom_ne_zero _⟩, },
  use [(w * N).num, wN0, q, hq, λ c, (w' c * N).num],
  have hw : ((w * N).num : ℚ) = w * N,
  { dsimp only [N],
    rw [← rat.denom_eq_one_iff, nat.cast_mul, ← mul_assoc, rat.mul_denom_eq_num],
    norm_cast, },
  have hw' : ∀ c ∈ q, ((w' c * N).num : ℚ) = w' c * N,
  { intros c hc, dsimp only [N],
    rw [← rat.denom_eq_one_iff, ← mul_prod_erase _ _ hc, mul_left_comm, nat.cast_mul,
      ← mul_assoc, rat.mul_denom_eq_num],
    norm_cast, },
  convert_to (w * N + ∑ c in q, (w' c * N) • ∑ x in c.orbit.to_finset,
    exp (algebra_map (K (Range u v)) ℂ x) : ℂ) = 0,
  { congr' 1, { norm_cast, rw [hw], },
    refine sum_congr rfl (λ i hi, _),
    rw [← hw' i hi, rat.coe_int_num, ← zsmul_eq_smul_cast], },
  simp_rw [mul_comm _ ↑N, ← smul_smul, ← smul_sum, ← nsmul_eq_mul, ← nsmul_eq_smul_cast,
    ← smul_add, h, nsmul_zero],
end

lemma linear_independent_exp_aux'
  (u : ι → ℂ) (hu : ∀ i, is_integral ℚ (u i)) (u_inj : function.injective u)
  (v : ι → ℂ) (hv : ∀ i, is_integral ℚ (v i)) (v0 : v ≠ 0)
  (h : ∑ i, v i * exp (u i) = 0) :
  ∃ (w : ℤ) (w0 : w ≠ 0) (n : ℕ)
    (p : fin n → ℚ[X]) (p0 : ∀ j, (p j).eval 0 ≠ 0) (w' : fin n → ℤ),
    (w + ∑ j, w' j • (((p j).aroots ℂ).map (λ x, exp x)).sum : ℂ) = 0 :=
begin
  let s := Range u v,
  obtain ⟨w, w0, q, hq, w', h⟩ := linear_independent_exp_aux'' u hu u_inj v hv v0 h,
  let c : fin q.card → gal_conj_classes ℚ (K s) := λ j, q.equiv_fin.symm j,
  have hc : ∀ j, c j ∈ q := λ j, finset.coe_mem _,
  refine ⟨w, w0, q.card, λ j, (c j).minpoly, _, λ j, w' (c j), _⟩,
  { intros j, specialize hc j,
    suffices : ((c j).minpoly.map
      (algebra_map ℚ (K s))).eval (algebra_map ℚ (K s) 0) ≠ 0,
    { rwa [eval_map, ← aeval_def, aeval_algebra_map_apply, _root_.map_ne_zero] at this, },
    rw [ring_hom.map_zero, gal_conj_classes.minpoly.map_eq_prod, eval_prod, prod_ne_zero_iff],
    intros a ha,
    rw [eval_sub, eval_X, eval_C, sub_ne_zero],
    rintros rfl,
    rw [set.mem_to_finset, gal_conj_classes.mem_orbit, gal_conj_classes.mk_zero] at ha,
    rw [← ha] at hc, exact hq hc, },
  rw [← h, add_right_inj],
  change ∑ j, (λ i : q, (λ c, w' c •
    ((c.minpoly.aroots ℂ).map (λ x, exp x)).sum) i) (q.equiv_fin.symm j) = _,
  rw [equiv.sum_comp (q.equiv_fin.symm), sum_coe_sort],
  refine sum_congr rfl (λ c hc, _),
  have : c.minpoly.aroots ℂ = (c.minpoly.aroots (K s)).map (algebra_map (K s) ℂ),
  { change roots _ = _,
    rw [← roots_map, polynomial.map_map, is_scalar_tower.algebra_map_eq ℚ (K s) ℂ],
    rw [splits_map_iff, ring_hom.id_comp], exact gal_conj_classes.minpoly.splits c, },
  simp_rw [this, c.aroots_minpoly_eq_orbit_val, sum_map, multiset.map_map], refl,
end

lemma linear_independent_exp_aux
  (u : ι → ℂ) (hu : ∀ i, is_integral ℚ (u i)) (u_inj : function.injective u)
  (v : ι → ℂ) (hv : ∀ i, is_integral ℚ (v i)) (v0 : v ≠ 0)
  (h : ∑ i, v i * exp (u i) = 0) :
  ∃ (w : ℤ) (w0 : w ≠ 0) (n : ℕ)
    (p : fin n → ℤ[X]) (p0 : ∀ j, (p j).eval 0 ≠ 0) (w' : fin n → ℤ),
    (w + ∑ j, w' j • (((p j).aroots ℂ).map (λ x, exp x)).sum : ℂ) = 0 :=
begin
  obtain ⟨w, w0, n, p, hp, w', h⟩ := linear_independent_exp_aux' u hu u_inj v hv v0 h,
  let b := λ j,
    (is_localization.integer_normalization_map_to_map (non_zero_divisors ℤ) (p j)).some,
  have hb : ∀ j, ((is_localization.integer_normalization (non_zero_divisors ℤ) (p j)).map
    (algebra_map ℤ ℚ) = b j • p j) := λ j,
    (is_localization.integer_normalization_map_to_map (non_zero_divisors ℤ) (p j)).some_spec,
  refine ⟨w, w0, n,
    λ i, is_localization.integer_normalization (non_zero_divisors ℤ) (p i), _, w', _⟩,
  { intros j,
    suffices : aeval (algebra_map ℤ ℚ 0)
      (is_localization.integer_normalization (non_zero_divisors ℤ) (p j)) ≠ 0,
    { rwa [aeval_algebra_map_apply, map_ne_zero_iff _ (algebra_map ℤ ℚ).injective_int] at this, },
    rw [map_zero, aeval_def, eval₂_eq_eval_map, hb, eval_smul, submonoid.smul_def, smul_ne_zero_iff],
    exact ⟨non_zero_divisors.coe_ne_zero _, hp j⟩, },
  rw [← h, add_right_inj],
  refine sum_congr rfl (λ j hj, congr_arg _ (congr_arg _ (multiset.map_congr _ (λ _ _, rfl)))),
  change roots _ = roots _,
  simp_rw [is_scalar_tower.algebra_map_eq ℤ ℚ ℂ, ← polynomial.map_map, hb,
    submonoid.smul_def, zsmul_eq_mul, ← C_eq_int_cast, polynomial.map_mul, map_C],
  rw [roots_C_mul], rw [map_ne_zero_iff _ (algebra_map ℚ ℂ).injective, int.cast_ne_zero],
  exact non_zero_divisors.coe_ne_zero _,
end
/-
variable {A}

lemma is_integral.smul_aeval (k : R) (x : A) (hx : is_integral R (k • x)) (p : R[X])
  (n : ℕ) (hn : p.nat_degree ≤ n) :
  is_integral R (k ^ n • aeval x p) :=
begin
  rw [aeval_eq_sum_range' (nat.lt_add_one_iff.mpr hn), smul_sum], simp_rw [smul_comm (k ^ n)],
  refine is_integral.sum _ (λ i hi, is_integral_smul _ _),
  rw [mem_range, nat.lt_add_one_iff] at hi,
  suffices : is_integral R (k ^ (n - i + i) • x ^ i),
  { rwa [nat.sub_add_cancel hi] at this, },
  rw [pow_add, ← smul_smul, ← smul_pow],
  exact is_integral_smul _ (hx.pow _),
end

section

variables (R₁ K₁ R₂ K₂ : Type*)
  [comm_ring R₁] [is_domain R₁] [field K₁] [algebra R₁ K₁] [is_fraction_ring R₁ K₁]
  [comm_ring R₂] [is_domain R₂] [field K₂] [algebra R₂ K₂]
  [algebra R₁ R₂] [algebra K₁ K₂] [algebra R₁ K₂]
  [is_scalar_tower R₁ K₁ K₂] [is_scalar_tower R₁ R₂ K₂]

include R₁ K₁ R₂ K₂

lemma injective_of_is_fraction_ring :
  function.injective (algebra_map R₁ R₂) :=
begin
  suffices : function.injective (algebra_map R₁ K₂),
  { rw [is_scalar_tower.algebra_map_eq R₁ R₂ K₂] at this,
    exact function.injective.of_comp this, },
  rw [is_scalar_tower.algebra_map_eq R₁ K₁ K₂],
  exact (algebra_map K₁ K₂).injective.comp (is_fraction_ring.injective R₁ K₁),
end

end

section

variables (R₁ K₁ R₂ K₂ : Type*)
  [comm_ring R₁] [is_domain R₁] [field K₁] [algebra R₁ K₁] [is_fraction_ring R₁ K₁]
  [comm_ring R₂] [is_domain R₂] [field K₂] [algebra R₂ K₂]
  [algebra R₁ R₂] [algebra K₁ K₂] [algebra R₁ K₂] [finite_dimensional K₁ K₂]
  [is_integral_closure R₂ R₁ K₂] [is_scalar_tower R₁ K₁ K₂] [is_scalar_tower R₁ R₂ K₂]

include R₁ K₁ R₂ K₂

lemma is_localization_of_is_fraction_ring_tower :
  is_localization ((non_zero_divisors R₁).map (algebra_map R₁ R₂)) K₂ :=
{ map_units :=
  begin
    rintros ⟨_, ⟨c, hc, rfl⟩⟩,
    haveI := is_integral_closure.is_fraction_ring_of_finite_extension R₁ K₁ K₂ R₂,
    rw [is_unit_iff_ne_zero, map_ne_zero_iff _ (is_fraction_ring.injective R₂ K₂),
      subtype.coe_mk, map_ne_zero_iff _ (injective_of_is_fraction_ring R₁ K₁ R₂ K₂)],
    exact non_zero_divisors.ne_zero hc,
  end,
  surj := λ z,
  begin
    have hz := is_algebraic_iff_is_integral.mp (algebra.is_algebraic_of_finite K₁ K₂ z),
    obtain ⟨k, hkz⟩ :=
      is_integral.exists_multiple_integral_of_is_localization (non_zero_divisors R₁) z hz,
    refine ⟨⟨is_integral_closure.mk' R₂ _ hkz, ⟨algebra_map R₁ R₂ k, k, k.2, rfl⟩⟩, _⟩,
    rw [subtype.coe_mk, is_integral_closure.algebra_map_mk', mul_comm,
      ← is_scalar_tower.algebra_map_apply, submonoid.smul_def, algebra.smul_def],
  end,
  eq_iff_exists := λ x y,
  begin
    haveI := is_integral_closure.is_fraction_ring_of_finite_extension R₁ K₁ K₂ R₂,
    rw [(is_fraction_ring.injective R₂ K₂).eq_iff],
    refine ⟨by { rintro rfl, use 1, }, _⟩,
    rintro ⟨⟨_, c, hc, rfl⟩, h⟩,
    refine mul_right_cancel₀ _ h,
    rw [subtype.coe_mk, map_ne_zero_iff _ (injective_of_is_fraction_ring R₁ K₁ R₂ K₂)],
    exact non_zero_divisors.ne_zero hc,
  end, }

end

namespace number_field

variables {F : Type*} [field F] [number_field F]

instance : is_localization ((non_zero_divisors ℤ).map (algebra_map ℤ (𝓞 F))) F :=
is_localization_of_is_fraction_ring_tower ℤ ℚ (𝓞 F) F

end number_field
-/
lemma linear_independent_exp_exists_prime_nat'' (c : ℕ) :
  ∃ n > c, c ^ n < (n - 1)! :=
begin
  refine ⟨2 * (c ^ 2 + 1), _, _⟩, { have : c ≤ c * c := nat.le_mul_self _, linarith, },
  rw [pow_mul, two_mul, add_right_comm, add_tsub_cancel_right],
  refine lt_of_lt_of_le _ nat.factorial_mul_pow_le_factorial,
  rw [← one_mul (_ ^ _ : ℕ)],
  refine nat.mul_lt_mul' (nat.one_le_of_lt (nat.factorial_pos _)) _ (nat.factorial_pos _),
  exact nat.pow_lt_pow_of_lt_left (nat.lt_succ_self _) (nat.succ_pos _),
end

lemma linear_independent_exp_exists_prime_nat' (n : ℕ) (c : ℕ) :
  ∃ p > n, p.prime ∧ c ^ p < (p - 1)! :=
begin
  obtain ⟨m, hm, h⟩ := linear_independent_exp_exists_prime_nat'' c,
  let N := max (n + 2) (m + 1),
  obtain ⟨p, hp', prime_p⟩ := nat.exists_infinite_primes N,
  have hnp : n + 1 < p := (nat.add_one_le_iff.mp (le_max_left _ _)).trans_le hp',
  have hnp' : n < p := lt_of_add_lt_of_nonneg_left hnp zero_le_one,
  have hmp : m < p := (nat.add_one_le_iff.mp (le_max_right _ _)).trans_le hp',
  use [p, hnp', prime_p],
  cases lt_or_ge m 2 with m2 m2,
  { have : c = 0 := by linarith,
    rw [this, zero_pow prime_p.pos],
    exact nat.factorial_pos _, },
  rcases nat.eq_zero_or_pos c with rfl | c0,
  { rw [zero_pow prime_p.pos],
    exact nat.factorial_pos _, },
  have m1 : 1 ≤ m := one_le_two.trans m2,
  have one_le_m_sub_one : 1 ≤ m - 1, { rwa [nat.le_sub_iff_right m1], },
  have : m - 1 - 1 < p - 1,
  { rw [tsub_lt_tsub_iff_right one_le_m_sub_one], exact tsub_le_self.trans_lt hmp, },
  refine lt_of_lt_of_le _ (nat.factorial_mul_pow_sub_le_factorial this),
  have : (m - 1 - 1).succ = m - 1, { rwa [nat.succ_eq_add_one, tsub_add_cancel_of_le], },
  rw [this],
  convert_to c ^ m * c ^ (p - m) < _,
  { rw [← pow_add, add_tsub_cancel_of_le], exact hmp.le },
  rw [tsub_tsub_tsub_cancel_right m1],
  exact nat.mul_lt_mul h (pow_le_pow_of_le_left' (nat.le_pred_of_lt hm) _) (pow_pos c0 _),
end

lemma linear_independent_exp_exists_prime_nat (n : ℕ) (a : ℕ) (c : ℕ) :
  ∃ p > n, p.prime ∧ a * c ^ p < (p - 1)! :=
begin
  obtain ⟨p, hp, prime_p, h⟩ := linear_independent_exp_exists_prime_nat' n (a * c),
  use [p, hp, prime_p],
  refine lt_of_le_of_lt _ h,
  rcases nat.eq_zero_or_pos a with rfl | a0, 
  { simp_rw [zero_mul, zero_pow' _ prime_p.ne_zero], },
  rw [mul_pow],
  apply nat.mul_le_mul_right,
  convert_to a ^ 1 ≤ a ^ p, { rw [pow_one], },
  exact nat.pow_le_pow_of_le_right a0 (nat.one_le_of_lt prime_p.pos),
end

lemma linear_independent_exp_exists_prime (n : ℕ) (a : ℝ) (c : ℝ) :
  ∃ p > n, p.prime ∧ a * c ^ p / (p - 1)! < 1 :=
begin
  simp_rw [@div_lt_one ℝ _ _ _ (nat.cast_pos.mpr (nat.factorial_pos _))],
  obtain ⟨p, hp, prime_p, h⟩ :=
    linear_independent_exp_exists_prime_nat n (⌈|a|⌉).nat_abs (⌈|c|⌉).nat_abs,
  use [p, hp, prime_p],
  have : a * c ^ p ≤ ⌈|a|⌉ * ⌈|c|⌉ ^ p,
  { refine (le_abs_self _).trans _,
    rw [_root_.abs_mul, _root_.abs_pow],
    refine mul_le_mul (int.le_ceil _) (pow_le_pow_of_le_left (abs_nonneg _) (int.le_ceil _) _)
      (pow_nonneg (abs_nonneg _) _) (int.cast_nonneg.mpr (int.ceil_nonneg (abs_nonneg _))), },
  refine this.trans_lt _, clear this,
  refine lt_of_eq_of_lt (_ : _ = ((⌈|a|⌉.nat_abs * ⌈|c|⌉.nat_abs ^ p : ℕ) : ℝ)) _,
  { simp_rw [nat.cast_mul, nat.cast_pow, int.cast_nat_abs, ← int.cast_abs,
      abs_eq_self.mpr (int.ceil_nonneg (_root_.abs_nonneg (_ : ℝ)))], },
  rwa [nat.cast_lt],
end

lemma exists_sum_map_aroot_smul_eq {R S : Type*} [comm_ring R] [field S] [algebra R S]
  (p : R[X]) (k : R) (e : ℕ) (q : R[X])
  (hk : p.leading_coeff ∣ k) (he : q.nat_degree ≤ e)
  (inj : function.injective (algebra_map R S))
  (card_aroots : (p.map (algebra_map R S)).roots.card = p.nat_degree) :
  ∃ c, ((p.aroots S).map (λ x, k ^ e • aeval x q)).sum = algebra_map R S c :=
begin
  obtain ⟨k', rfl⟩ := hk, let k := p.leading_coeff * k',
  have : (λ x : S, k ^ e • aeval x q) = ((λ x, aeval x
    (∑ i in range (e + 1), monomial i (k' ^ i * k ^ (e - i) * q.coeff i))) ∘
      (λ x, p.leading_coeff • x)),
  { funext x, rw [function.comp_app],
    simp_rw [map_sum, aeval_eq_sum_range' (nat.lt_add_one_iff.mpr he), aeval_monomial, smul_sum],
    refine sum_congr rfl (λ i hi, _),
    rw [← algebra.smul_def, smul_pow, smul_smul, smul_smul, mul_comm (_ * _) (_ ^ _),
      ← mul_assoc, ← mul_assoc, ← mul_pow, ← pow_add,
      add_tsub_cancel_of_le (nat.lt_add_one_iff.mp (mem_range.mp hi))], },
  rw [this, ← multiset.map_map _ (λ x, p.leading_coeff • x)],
  have : ((p.aroots S).map (λ x, p.leading_coeff • x)).card = fintype.card (fin (p.aroots S).card),
  { rw [multiset.card_map, fintype.card_fin], },
  rw [← mv_polynomial.symmetric_subalgebra.aeval_multiset_sum_polynomial _ _ this,
    ← mv_polynomial.symmetric_subalgebra.scale_aeval_roots_eq_aeval_multiset],
  exact ⟨_, rfl⟩,
  { exact inj, },
  { rw [fintype.card_fin], exact (card_roots' _).trans (nat_degree_map_le _ _), },
  { exact card_aroots, }
end

def exists_sum_map_aroot_smul_eq_some {R S : Type*} [comm_ring R] [field S] [algebra R S]
  (p : R[X]) (k : R) (e : ℕ) (q : R[X])
  (hk : p.leading_coeff ∣ k) (he : q.nat_degree ≤ e)
  (inj : function.injective (algebra_map R S))
  (card_aroots : (p.map (algebra_map R S)).roots.card = p.nat_degree) :
  R :=
(exists_sum_map_aroot_smul_eq p k e q hk he inj card_aroots).some

lemma exists_sum_map_aroot_smul_eq_some_spec {R S : Type*} [comm_ring R] [field S] [algebra R S]
  (p : R[X]) (k : R) (e : ℕ) (q : R[X])
  (hk : p.leading_coeff ∣ k) (he : q.nat_degree ≤ e)
  (inj : function.injective (algebra_map R S))
  (card_aroots : (p.map (algebra_map R S)).roots.card = p.nat_degree) :
  ((p.aroots S).map (λ x, k ^ e • aeval x q)).sum =
    algebra_map R S (exists_sum_map_aroot_smul_eq_some p k e q hk he inj card_aroots) :=
(exists_sum_map_aroot_smul_eq p k e q hk he inj card_aroots).some_spec

theorem linear_independent_exp
  (u : ι → ℂ) (hu : ∀ i, is_integral ℚ (u i)) (u_inj : function.injective u)
  (v : ι → ℂ) (hv : ∀ i, is_integral ℚ (v i))
  (h : ∑ i, v i * exp (u i) = 0) :
  v = 0 :=
begin
  by_contra' v0,
  obtain ⟨w, w0, m, p, p0, w', h⟩ := linear_independent_exp_aux u hu u_inj v hv v0 h,
  have m0 : m ≠ 0,
  { rintros rfl, rw [fin.sum_univ_zero, add_zero, int.cast_eq_zero] at h, exact w0 h, },
  haveI I : nonempty (fin m) := fin.pos_iff_nonempty.mp (nat.pos_of_ne_zero m0),
  let P := ∏ i : fin m, p i,
  let K := splitting_field (P.map (algebra_map ℤ ℚ)),
  have p0' : ∀ j, p j ≠ 0,
  { intros j h, specialize p0 j, rw [h, eval_zero] at p0, exact p0 rfl, },
  have P0 : P.eval 0 ≠ 0,
  { dsimp only [P], rw [eval_prod, prod_ne_zero_iff], exact λ j hj, p0 j, },
  have P0' : P ≠ 0,
  { intro h, rw [h, eval_zero] at P0, exact P0 rfl, },
  have P0'' : P.map (algebra_map ℤ K) ≠ 0,
  { rwa [polynomial.map_ne_zero_iff (algebra_map ℤ K).injective_int], },
  
  have splits_p : ∀ j, ((p j).map (algebra_map ℤ K)).splits (ring_hom.id K),
  { intros j,
    refine splits_of_splits_of_dvd _ P0'' _ _,
    { rw [is_scalar_tower.algebra_map_eq ℤ ℚ K, ← polynomial.map_map, splits_map_iff,
        ring_hom.id_comp], exact is_splitting_field.splits _ _, },
    simp_rw [P, polynomial.map_prod],
    exact dvd_prod_of_mem _ (mem_univ _), },
  
  have sum_aroots_K_eq_sum_aroots_ℂ : ∀ j (f : ℂ → ℂ),
    (((p j).aroots K).map (λ x, f (algebra_map K ℂ x))).sum =
      (((p j).aroots ℂ).map (λ x, f x)).sum,
  { intros j f,
    have : (p j).aroots ℂ = ((p j).aroots K).map (algebra_map K ℂ),
    { simp_rw [aroots_def, is_scalar_tower.algebra_map_eq ℤ K ℂ, ← polynomial.map_map],
      rw [roots_map], exact splits_p j, },
    simp_rw [this, multiset.map_map], },
  
  replace h : (w + ∑ (j : fin m), w' j •
    (((p j).aroots K).map (λ x, exp (algebra_map K ℂ x))).sum : ℂ) = 0 :=
    h ▸ (congr_arg _ $ congr_arg _ $ funext $
      λ j, congr_arg _ $ sum_aroots_K_eq_sum_aroots_ℂ j exp),
  
  let k : ℤ := ∏ j, (p j).leading_coeff,
  have k0 : k ≠ 0 := prod_ne_zero_iff.mpr (λ j hj, leading_coeff_ne_zero.mpr (p0' j)),
  /-
  obtain ⟨⟨_, k, k0, rfl⟩, hka⟩ := is_localization.exist_integer_multiples_of_finset
    ((non_zero_divisors ℤ).map (algebra_map ℤ (𝓞 K))) (P.aroots K).to_finset,
  rw [set_like.mem_coe, mem_non_zero_divisors_iff_ne_zero] at k0,
  simp_rw [is_localization.is_integer, subalgebra.range_algebra_map,
    subalgebra.mem_to_subring, subtype.coe_mk, algebra_map_smul] at hka,
  
  replace hka : ∀ (p : ℤ[X]) (p_le : p.nat_degree ≤ m) (x ∈ P.aroots K), k ^ m • aeval x p ∈ 𝓞 K,
  { intros p p_le x hx, refine is_integral.smul_aeval _ _ _ _ _ p_le,
    apply hka, rwa [set.mem_to_finset], },
  -/
  obtain ⟨c, hc'⟩ := exp_polynomial_approx P P0,
  let N := max (eval 0 P).nat_abs (max k.nat_abs w.nat_abs),
  
  let W := sup' univ univ_nonempty (λ j, ‖w' j‖),
  have W0 : 0 ≤ W := I.elim (λ j, (norm_nonneg (w' j)).trans (le_sup' _ (mem_univ j))),
  
  obtain ⟨q, hqN, prime_q, hq⟩ := linear_independent_exp_exists_prime N
    (W * ↑∑ (i : fin m), ((p i).aroots ℂ).card)
      (‖k‖ ^ P.nat_degree * c),
  
  obtain ⟨n, hn, gp, hgp, hc⟩ := hc' q ((le_max_left _ _).trans_lt hqN) prime_q,
  replace hgp : gp.nat_degree ≤ P.nat_degree * q, { rw [mul_comm], exact hgp.trans tsub_le_self, },
  
  have sz_h₁ : ∀ j, (p j).leading_coeff ∣ k := λ j, dvd_prod_of_mem _ (mem_univ _),
  have sz_h₂ := λ j, (nat_degree_eq_card_roots (splits_p j)).symm,
  simp_rw [map_id, nat_degree_map_eq_of_injective (algebra_map ℤ K).injective_int] at sz_h₂,
  
  let sz : fin m → ℤ := λ j, exists_sum_map_aroot_smul_eq_some (p j) k (P.nat_degree * q) gp
    (sz_h₁ j) hgp (algebra_map ℤ K).injective_int (sz_h₂ j),
  have hsz : ∀ j, (((p j).aroots K).map (λ (x : K), k ^ (P.nat_degree * q) • aeval x gp)).sum =
    algebra_map ℤ K (sz j) :=
    λ j, exists_sum_map_aroot_smul_eq_some_spec (p j) k (P.nat_degree * q) gp
      (sz_h₁ j) hgp (algebra_map ℤ K).injective_int (sz_h₂ j),
  
  let t := P.nat_degree * q,
  
  have H :=
  calc  ‖algebra_map K ℂ ((k ^ t * n * w : ℤ) + q • ∑ j, w' j •
          (((p j).aroots K).map (λ x, k ^ t • aeval x gp)).sum)‖
      = ‖algebra_map K ℂ (k ^ t • n • w + q • ∑ j, w' j •
          (((p j).aroots K).map (λ x, k ^ t • aeval x gp)).sum)‖
      : by { simp_rw [zsmul_eq_mul], norm_cast, rw [mul_assoc], }
  ... = ‖algebra_map K ℂ (k ^ t • n • w + q • ∑ j, w' j •
          (((p j).aroots K).map (λ x, k ^ t • aeval x gp)).sum) -
          (k ^ t • n •
            (w + ∑ j, w' j • (((p j).aroots K).map (λ x, exp (algebra_map K ℂ x))).sum))‖
      : by rw [h, smul_zero, smul_zero, sub_zero]
  ... = ‖algebra_map K ℂ (k ^ t • n • w + k ^ t • ∑ j, w' j •
          (((p j).aroots K).map (λ x, q • aeval x gp)).sum) -
          (k ^ t • n • w +
            k ^ t • ∑ j, w' j • (((p j).aroots K).map (λ x, n • exp (algebra_map K ℂ x))).sum)‖
      : by simp_rw [smul_add, smul_sum, multiset.smul_sum, multiset.map_map, function.comp,
          smul_comm n, smul_comm (k ^ t), smul_comm q]
  ... = ‖(k ^ t • n • w + k ^ t • ∑ j, w' j •
          (((p j).aroots K).map (λ x, q • algebra_map K ℂ (aeval x gp))).sum : ℂ) -
          (k ^ t • n • w +
            k ^ t • ∑ j, w' j • (((p j).aroots K).map (λ x, n • exp (algebra_map K ℂ x))).sum)‖
      : by simp only [map_add, map_nsmul, map_zsmul, _root_.map_int_cast, map_sum,
          map_multiset_sum, multiset.map_map, function.comp]
  ... = ‖k ^ t • ∑ j, w' j • (((p j).aroots K).map
          (λ x, q • algebra_map K ℂ (aeval x gp) - n • exp (algebra_map K ℂ x))).sum‖
      : by simp only [add_sub_add_left_eq_sub, ← smul_sub, ← sum_sub_distrib,
          ← multiset.sum_map_sub]
  ... = ‖k ^ t • ∑ j, w' j • (((p j).aroots K).map
          (λ x, q • aeval (algebra_map K ℂ x) gp - n • exp (algebra_map K ℂ x))).sum‖
      : by simp_rw [aeval_algebra_map_apply]
  ... = ‖k ^ t • ∑ j, w' j • (((p j).aroots K).map
          (λ x, (λ x', (q • aeval x' gp - n • exp x')) (algebra_map K ℂ x))).sum‖
      : rfl
  ... = ‖k ^ t • ∑ j, w' j • (((p j).aroots ℂ).map (λ x, q • aeval x gp - n • exp x)).sum‖
      : by { congr', funext, congr' 1, exact sum_aroots_K_eq_sum_aroots_ℂ _ _, }
  ... ≤ ‖k ^ t‖ * ∑ j, W * (((p j).aroots ℂ).map (λ x, c ^ q / ↑(q - 1)!)).sum
      : begin
          refine (norm_zsmul_le _ _).trans _,
          refine mul_le_mul_of_nonneg_left _ (norm_nonneg _),
          refine (norm_sum_le _ _).trans _,
          refine sum_le_sum (λ j hj, _),
          refine (norm_zsmul_le _ _).trans _,
          refine mul_le_mul (le_sup' _ (mem_univ j)) _ (norm_nonneg _) W0,
          refine (norm_multiset_sum_le _).trans _,
          rw [multiset.map_map],
          refine multiset.sum_map_le_sum_map _ _ (λ x hx, _),
          rw [function.comp_app, norm_sub_rev],
          refine hc _,
          rw [mem_roots_map_of_injective (algebra_map ℤ ℂ).injective_int (p0' j)] at hx,
          rw [mem_roots_map_of_injective (algebra_map ℤ ℂ).injective_int P0', ← aeval_def],
          dsimp only [P], rw [map_prod],
          exact prod_eq_zero (mem_univ j) hx,
        end,
  simp_rw [int.norm_eq_abs, int.cast_pow, _root_.abs_pow, ← int.norm_eq_abs,
    multiset.map_const, multiset.sum_replicate, ← mul_sum, ← sum_smul, nsmul_eq_mul,
    mul_comm (‖k‖ ^ t), mul_assoc, mul_comm (_ / _ : ℝ), t, pow_mul,
    mul_div (_ ^ _ : ℝ), ← mul_pow, ← mul_assoc, mul_div, ← pow_mul] at H,
  replace H := H.trans_lt hq,
  have : ∑ j, w' j • (((p j).aroots K).map (λ (x : K), k ^ (P.nat_degree * q) • aeval x gp)).sum =
    algebra_map ℤ K (∑ j, w' j • sz j),
  { rw [map_sum], congr', funext j, rw [map_zsmul, hsz], },
  rw [this] at H,
  have : ‖algebra_map K ℂ (↑(k ^ (P.nat_degree * q) * n * w) +
    ↑q * algebra_map ℤ K (∑ j, w' j • sz j))‖ =
    ‖algebra_map ℤ ℂ ((k ^ (P.nat_degree * q) * n * w) + q * (∑ j, w' j • sz j))‖,
  { simp_rw [is_scalar_tower.algebra_map_apply ℤ K ℂ, algebra_map_int_eq, int.coe_cast_ring_hom],
    norm_cast, },
  rw [this, algebra_map_int_eq, int.coe_cast_ring_hom, norm_int, ← int.cast_abs, ← int.cast_one,
    int.cast_lt, int.abs_lt_one_iff] at H,
  replace H : (k ^ (P.nat_degree * q) * n * w + q * ∑ (j : fin m), w' j • sz j) % q = 0,
  { rw [H, int.zero_mod], },
  rw [int.add_mul_mod_self_left, ← int.dvd_iff_mod_eq_zero] at H,
  replace H := (int.prime.dvd_mul prime_q H).imp_left
    (int.prime.dvd_mul prime_q ∘ int.coe_nat_dvd_left.mpr),
  revert H, rw [int.nat_abs_pow, imp_false], push_neg,
  exact ⟨⟨λ h, nat.not_dvd_of_pos_of_lt (int.nat_abs_pos_of_ne_zero k0)
      (((le_max_left _ _).trans (le_max_right _ _)).trans_lt hqN)
      (nat.prime.dvd_of_dvd_pow prime_q h),
    λ h, hn ((int.dvd_iff_mod_eq_zero _ _).mp (int.of_nat_dvd_of_dvd_nat_abs h))⟩,
    nat.not_dvd_of_pos_of_lt (int.nat_abs_pos_of_ne_zero w0)
      (((le_max_right _ _).trans (le_max_right _ _)).trans_lt hqN)⟩,
end

/-- `X ^ n + a` is monic. -/
lemma monic_X_pow_add_C {R : Type*} [ring R] (a : R) {n : ℕ} (h : n ≠ 0) : (X ^ n + C a).monic :=
begin
  obtain ⟨k, hk⟩ := nat.exists_eq_succ_of_ne_zero h,
  convert monic_X_pow_add _,
  exact le_trans degree_C_le nat.with_bot.coe_nonneg,
end

lemma complex.is_integral_int_I : is_integral ℤ I := by
{ refine ⟨X^2 + C 1, monic_X_pow_add_C _ two_ne_zero, _⟩,
  rw [eval₂_add, eval₂_X_pow, eval₂_C, I_sq, eq_int_cast, int.cast_one, add_left_neg], }

lemma complex.is_integral_rat_I : is_integral ℚ I :=
is_integral_of_is_scalar_tower complex.is_integral_int_I

theorem transcendental_exp {a : ℂ} (a0 : a ≠ 0) (ha : is_algebraic ℤ a) : transcendental ℤ (exp a) :=
begin
  intro h,
  have is_integral_a : is_integral ℚ a := is_algebraic_iff_is_integral.mp
    (is_algebraic_of_larger_base_of_injective ((algebra_map ℤ ℚ).injective_int) ha),
  have is_integral_expa : is_integral ℚ (exp a) := is_algebraic_iff_is_integral.mp
    (is_algebraic_of_larger_base_of_injective ((algebra_map ℤ ℚ).injective_int) h),
  have := linear_independent_exp
    (λ i : bool, if i = false then a else 0) _ _
    (λ i : bool, if i = false then 1 else -exp a) _ _,
  { simpa [ite_eq_iff] using congr_fun this ff, },
  { intros i, dsimp only, split_ifs,
    exacts [is_integral_a, is_integral_zero], },
  { intros i j, dsimp, split_ifs,
    all_goals { simp only [to_bool_false_eq_ff, eq_tt_eq_not_eq_ff] at h_1 h_2,
      cases h_1, cases h_2, },
    any_goals { simp_rw [eq_self_iff_true, imp_true_iff], },
    all_goals { simp_rw [tt_eq_ff_eq_false, imp_false, ← ne.def], },
    exacts [a0, a0.symm], },
  { intros i, dsimp, split_ifs, exacts [is_integral_one, is_integral_neg is_integral_expa], },
  simp,
end

theorem transcendental_pi : transcendental ℤ real.pi :=
begin
  intro h,
  have is_integral_pi' : is_integral ℚ real.pi := is_algebraic_iff_is_integral.mp
    (is_algebraic_of_larger_base_of_injective ((algebra_map ℤ ℚ).injective_int) h),
  have is_integral_pi : is_integral ℚ (algebra_map ℝ ℂ real.pi) :=
    (is_integral_algebra_map_iff ((algebra_map ℝ ℂ).injective)).mpr is_integral_pi',
  have := linear_independent_exp
    (λ i : bool, if i = false then real.pi * I else 0) _ _
    (λ i : bool, 1) _ _,
  { simpa only [pi.zero_apply, one_ne_zero] using congr_fun this ff, },
  { intros i, dsimp only, split_ifs,
    { exact is_integral_mul is_integral_pi complex.is_integral_rat_I, },
    { exact is_integral_zero, }, },
  { intros i j, dsimp, split_ifs,
    all_goals { simp only [to_bool_false_eq_ff, eq_tt_eq_not_eq_ff] at h_1 h_2,
      cases h_1, cases h_2, },
    any_goals { simp_rw [eq_self_iff_true, imp_true_iff], },
    all_goals { simp_rw [tt_eq_ff_eq_false, imp_false, ← ne.def], },
    any_goals { rw [@ne_comm ℂ 0], },
    all_goals { rw [mul_ne_zero_iff], norm_cast, simp [real.pi_ne_zero, I_ne_zero], }, },
  { intros i, dsimp, exact is_integral_one, },
  simp,
end
