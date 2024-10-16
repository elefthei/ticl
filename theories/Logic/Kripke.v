From Coq Require Import
  Relations
  Program.Basics
  Classes.Morphisms.

From ICTL Require Export
  Logic.World.

From ICTL Require Import
  Utils.Utils
  Events.Core.

Generalizable All Variables.

(*| Polymorphic Kripke model over family M |*)
Class Kripke (M: forall E, Encode E -> Type -> Type) (E: Type) `{HE: Encode E} := {

    (* - [ktrans] the transition relation over [M X * W] *)
    ktrans {X}: M E HE X -> World E -> M E HE X -> World E -> Prop;

    (* - [ktrans] only if [not_done] *)
    ktrans_not_done {X}: forall (t t': M E HE X) (w w': World E),
      ktrans t w t' w' ->
      not_done w;
  }.

Declare Scope ctl_scope.
Local Open Scope ctl_scope.
Delimit Scope ctl_scope with ctl.

(* Transition relation *)
Notation "[ t , w ]  ↦ [ t' , w' ]" :=
  (ktrans t w t' w')
    (at level 78,
      right associativity): ctl_scope.

Definition can_step `{Kripke M W} {X} (m: M W _ X) (w: World W): Prop :=
  exists m' w', [m,w] ↦ [m',w'].

Lemma can_step_not_done `{Kripke M W} {X}: forall (t: M W _ X) w,
    can_step t w ->
    not_done w.
Proof.
  intros.
  destruct H0 as (t' & w' & TR).
  now apply ktrans_not_done in TR.
Qed.
Global Hint Resolve can_step_not_done: ctl.

Ltac world_inv :=
  match goal with
  | [H: @Obs ?E ?HE ?e ?x = ?w |- _] =>
      dependent destruction H
  | [H: @Pure ?E ?HE = ?w |- _] =>
      dependent destruction H
  | [H: @Done ?E ?HE ?X ?x = ?w |- _] =>
      dependent destruction H
  | [H: @Finish ?E ?HE ?X ?e ?v ?x = ?w |- _] =>
      dependent destruction H
  | [H: ?w = @Obs ?E ?HE ?e ?x |- _] =>
      dependent destruction H
  | [H: ?w = @Pure ?E ?HE |- _] =>
      dependent destruction H
  | [H: ?w = @Done ?E ?HE ?X ?x |- _] =>
      dependent destruction H
  | [H: ?w = @Finish ?E ?HE ?X ?e ?v ?x |- _] =>
      dependent destruction H
  end.
Global Hint Extern 2 => world_inv: ctl.

Ltac ktrans_inv :=
  match goal with
  | [H: [?t, ?w] ↦ [?t', ?w'] |- can_step ?t ?w] =>
      exists t', w'; apply H
  | [H: [?t, ?w] ↦ [?t', ?w'] |- not_done ?w] =>
      apply ktrans_not_done with t t' w'; apply H
  end.
Global Hint Extern 2 => ktrans_inv: ctl.
