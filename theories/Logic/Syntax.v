From ICTL Require Import
  Events.Core
  Logic.Kripke
  Utils.Utils.

From ICTL Require Import
  Events.WriterE.

From Equations Require Import Equations.
Generalizable All Variables.

Variant ctlq := Q_A | Q_E.

Section CtlSyntax.
  Context {E: Type} {HE: Encode E}.

  Inductive ctll: Type :=
  (* Property [φ] holds right now, while in [not_done] world *)
  | CNow (φ: World E -> Prop): ctll
  (* Path quantifier [q]; property [φ: ctll] holds finitely, until [ψ: ctlr] stops it *)
  | CuL (q: ctlq) (φ ψ: ctll): ctll
  | CxL (q: ctlq) (φ ψ: ctll): ctll
  (* Path quantifier [q]; property [φ] holds always (strong always) *)
  | Cg (q: ctlq) (φ: ctll) : ctll
  (* Boolean combinators *)
  | CAndL (p q: ctll): ctll
  | COrL (p q: ctll): ctll.
  
  Inductive ctlr {X: Type} : Type :=
  (* Model returns with type [X] and [φ] holds at this point *)
  | CDone (φ: X -> World E -> Prop): ctlr
  | CuR (q: ctlq) (φ: ctll) (ψ: ctlr): ctlr
  | CxR (q: ctlq) (φ: ctll) (ψ: ctlr): ctlr
  (* Boolean combinators *)
  | CAndR (p: ctlr) (q: ctlr): ctlr
  | COrR (p: ctlr) (q: ctlr): ctlr
  | CImplR (p: ctll) (q: ctlr): ctlr.

    
  Arguments ctlr: clear implicits.

End CtlSyntax.

Arguments ctll E {HE}.
Arguments ctlr E {HE} X.

Section Contramap.
  Context {E: Type} {HE: Encode E} {X Y: Type}.
  Definition contramap(f: Y -> X): ctlr E X -> ctlr E Y :=
    fix F φ :=
      match φ with
      | CDone p => CDone (fun y w => p (f y) w)
      | CuR q φ ψ => CuR q φ (F ψ)
      | CxR q φ ψ => CxR q φ (F ψ)
      | CAndR φ ψ => CAndR (F φ) (F ψ)
      | COrR φ ψ => COrR (F φ) (F ψ)
      | CImplR φ ψ => CImplR φ (F ψ)
      end.

  (* TODO: Contramap laws, identity and composition *)
  (* contramap f id = id, contramap (f . g) p = contramap g (contramap f p) *)
End Contramap.

Bind Scope ctl_scope with ctll ctlr.

(*| Coq notation for CTL formulas |*)
Module CtlNotations.
  Local Open Scope ctl_scope.

  (* left CTL syntax (no termination) *)
  Declare Custom Entry ctll.
  
  Notation "<( e )>" := e (at level 0, e custom ctll at level 95) : ctl_scope.
  Notation "( x )" := x (in custom ctll, x at level 99) : ctl_scope.
  Notation "{ x }" := x (in custom ctll at level 0, x constr): ctl_scope.
  Notation "x" := x (in custom ctll at level 0, x constr at level 0) : ctl_scope.

  (* Right CTL syntax (with termination) *)
  Declare Custom Entry ctlr.

  Notation "<[ e ]>" := e (at level 0, e custom ctlr at level 95) : ctl_scope.
  Notation "( x )" := x (in custom ctlr, x at level 99) : ctl_scope.
  Notation "{ x }" := x (in custom ctlr at level 0, x constr): ctl_scope.
  Notation "x" := x (in custom ctlr at level 0, x constr at level 0) : ctl_scope.

  (* Temporal syntax: base predicates *)
  Notation "'now' p" :=
    (CNow p)
      (in custom ctll at level 74): ctl_scope.

  Notation "'pure'" :=
    (CNow (fun w => w = Pure))
      (in custom ctll at level 74): ctl_scope.

  Notation "'vis' R" :=
    (CNow (vis_with R))
      (in custom ctll at level 74): ctl_scope.

  Notation "'visW' R" :=
    (CNow (vis_with (fun pat : writerE _ =>
                       let 'Log v as x := pat return (encode x -> Prop) in
                       fun 'tt => R v)))
      (in custom ctll at level 75): ctl_scope.
  
  Notation "'done' R" :=
    (CDone R)
      (in custom ctlr at level 74): ctl_scope.

  Notation "'done=' r w" :=
    (CDone (fun r' w' => r = r' /\ w = w'))
      (in custom ctlr at level 74): ctl_scope.

  Notation "'finish' R" :=
    (CDone (finish_with R))
      (in custom ctlr at level 74): ctl_scope.
  
  Notation "'finishW' R" :=
    (CDone (finish_with (fun '(x, s) (pat : writerE _) =>
                           let 'Log w as u := pat return (encode u -> Prop) in
                           fun 'tt => R x s w)))
      (in custom ctlr at level 75): ctl_scope.

  Notation "⊤" := (CNow (fun _ => True))
                    (in custom ctll at level 76): ctl_scope.
  
  Notation "⊥" := (CNow (fun _ => False))
                     (in custom ctll at level 76): ctl_scope.
  Notation "⊤" := (CNow (fun _ => True))
                    (in custom ctlr at level 76): ctl_scope.
  
  Notation "⊥" := (CNow (fun _ => False))
                    (in custom ctlr at level 76): ctl_scope.
  
  Notation "⫪" := (CDone (fun _ _ => True))
                    (in custom ctlr at level 76): ctl_scope.
  
  Notation "⫫" := (CDone (fun _ _ => False))
                    (in custom ctlr at level 76): ctl_scope.
  
  (* Temporal syntax *)
  Notation "p 'EN' q" := (CxL Q_E p q) (in custom ctll at level 75): ctl_scope.
  Notation "p 'AN' q" := (CxL Q_A p q) (in custom ctll at level 75): ctl_scope.

  Notation "p 'EN' q" := (CxR Q_E p q) (in custom ctlr at level 75): ctl_scope.
  Notation "p 'AN' q" := (CxR Q_A p q) (in custom ctlr at level 75): ctl_scope.

  Notation "p 'EU' q" := (CuL Q_E p q) (in custom ctll at level 75): ctl_scope.
  Notation "p 'AU' q" := (CuL Q_A p q) (in custom ctll at level 75): ctl_scope.

  Notation "p 'EU' q" := (CuR Q_E p q) (in custom ctlr at level 75): ctl_scope.
  Notation "p 'AU' q" := (CuR Q_A p q) (in custom ctlr at level 75): ctl_scope.

  Notation "'EG' p" := (Cg Q_E p) (in custom ctll at level 75): ctl_scope.
  Notation "'AG' p" := (Cg Q_A p) (in custom ctll at level 75): ctl_scope.

  Notation "'EG' p" := (Cg Q_E p) (in custom ctll at level 75): ctl_scope.
  Notation "'AG' p" := (Cg Q_A p) (in custom ctll at level 75): ctl_scope.

  (* Syntactic sugar [AF, EF] is finally *)
  Notation "'EF' p" := <( ⊤ EU p )> (in custom ctll at level 74): ctl_scope.
  Notation "'AF' p" := <( ⊤ AU p )> (in custom ctll at level 74): ctl_scope.

  Notation "'EF' p" := <[ ⊤ EU p ]> (in custom ctlr at level 74): ctl_scope.
  Notation "'AF' p" := <[ ⊤ AU p ]> (in custom ctlr at level 74): ctl_scope.

  Notation "'EX' p" := <( ⊤ EN p )> (in custom ctll at level 74): ctl_scope.
  Notation "'AX' p" := <( ⊤ AN p )> (in custom ctll at level 74): ctl_scope.

  Notation "'EX' p" := <[ ⊤ EN p ]> (in custom ctlr at level 74): ctl_scope.
  Notation "'AX' p" := <[ ⊤ AN p ]> (in custom ctlr at level 74): ctl_scope.
  
  (* Propositional syntax *)
  Notation "p '/\' q" := (CAndL p q)
                           (in custom ctll at level 77, left associativity): ctl_scope.
  Notation "p '\/' q" := (COrL p q)
                           (in custom ctll at level 77, left associativity): ctl_scope.

  Notation "p '/\' q" := (CAndR p q)
                           (in custom ctlr at level 77, left associativity): ctl_scope.  
  Notation "p '\/' q" := (COrR p q)
                           (in custom ctlr at level 77, left associativity): ctl_scope.
  Notation "p '->' q" := (CImplR p q)
                           (in custom ctlr at level 78, right associativity): ctl_scope.
End CtlNotations.
