
// Stuff I would want from a standard library

function method Absurd<A>(): A
  requires false
{
  Absurd()
}

function method Fst<A,B>(p: (A,B)): A { p.0 }
function method Snd<A,B>(p: (A,B)): B { p.1 }

datatype List<A> = Cons(Head: A, Tail: List<A>) | Nil

function method Length(xs: List): nat {
  match xs
    case Nil          => 0
    case Cons(_, xs') => 1 + Length(xs')
}

lemma {:induction xs} SmallerThanList<A>(x: A, xs: List<A>)
  requires x in Elements(xs)
  ensures x < xs
{
}

lemma AllSmallerThanList<A>(xs: List<A>)
  ensures forall x :: x in Elements(xs) ==> x < xs
{
  forall x | x in Elements(xs) {
    SmallerThanList(x, xs);
  }
}

function method MapList<A,B>(f: A -> B, xs: List<A>): List<B>
  requires forall x :: f.reads(x) == {}
  requires forall x :: x in Elements(xs) ==> f.requires(x)
  ensures Length(xs) == Length(MapList(f, xs))
{
  match xs
    case Nil => Nil
    case Cons(x, xs') => Cons(f(x), MapList(f, xs'))
}

function method MapFromList<A, B>(pairs: List<(A, B)>): map<A,B> {
  Foldr(map[],
    ((ab: (A, B), m: map<A,B>) =>
    var (a, b) := ab;
    m[a := b]),
      pairs)
}

function method Elements<A>(xs: List<A>): set<A>
{
  Foldr({}, ((x, s) => {x} + s), xs)
}

predicate method NoDuplicates<A(==)>(xs: List<A>) {
  |Elements(xs)| == Length(xs)
}

function method {:fuel (Length<A>), 3} {:fuel (Length<B>), 3}
ZipWith<A,B,C>(f: (A, B) -> C, xs: List<A>, ys: List<B>): List<C>
  requires forall x, y :: f.reads(x, y) == {}
  requires forall x, y :: x in Elements(xs) && y in Elements(ys) ==> f.requires(x, y)
  requires Length(xs) == Length(ys)
  ensures  Length(ZipWith(f, xs, ys)) == Length(xs) == Length(ys)
{
  match (xs, ys)
    case (Nil, Nil) => Nil
    case (Cons(x, xs'), Cons(y, ys')) => Cons(f(x, y), ZipWith(f, xs', ys'))
}

function method Zip<A,B>(xs: List<A>, ys: List<B>): List<(A,B)>
  requires Length(xs) == Length(ys)
  ensures  Length(Zip(xs, ys)) == Length(xs) == Length(ys)
{
  ZipWith((x,y) => (x,y), xs, ys)
}

function method Foldr<A, B>(b: B, k: (A, B) -> B, xs: List<A>): B
  requires forall x, y :: k.reads(x, y) == {}
  requires forall x, y :: k.requires(x, y)
  decreases xs
{
  match xs
    case Nil => b
    case Cons(x, xs') => k(x, Foldr(b, k, xs'))
}

predicate method All<A>(p: A -> bool, xs: List<A>)
  requires forall x :: p.reads(x) == {}
  requires forall x :: x in Elements(xs) ==> p.requires(x)
{
  Foldr(true, (x, y) => x && y, MapList(p, xs))
}

predicate method Any<A>(p: A -> bool, xs: List<A>)
  requires forall x :: p.reads(x) == {}
  requires forall x :: x in Elements(xs) ==> p.requires(x)
{
  Foldr(false, (x, y) => x || y, MapList(p, xs))
}

predicate method And(xs: List<bool>) {
  All(x => x, xs)
}

predicate method Or(xs: List<bool>) {
  Any(x => x, xs)
}

function method Union<A>(xs: List<set<A>>): set<A> {
  Foldr({}, ((x, y) => x + y), xs)
}

datatype Maybe<A> = Just(FromJust: A) | Nothing

function method MapMaybe<A,B>(x: Maybe<A>, f: A -> B): Maybe<B>
  requires forall x :: f.reads(x) == {}
  requires forall y :: x == Just(y) ==> f.requires(y)
{
  match x
    case Nothing => Nothing
    case Just(x) => Just(f(x))
}

function method BindMaybe<A,B>(x: Maybe<A>, f: A -> Maybe<B>): Maybe<B>
  requires forall x :: f.reads(x) == {}
  requires forall y :: x == Just(y) ==> f.requires(y)
{
  match x
    case Nothing => Nothing
    case Just(x) => f(x)
}

function method IsJust<A>(x: Maybe<A>): bool
  ensures (exists y :: x == Just(y)) <==> IsJust(x)
{
  match x
    case Just(_) => true
    case Nothing => false
}

datatype Either<A,B> = Left(A) | Right(B)

function method Either<A,B,R>(f: A -> R, g: B -> R, e: Either<A,B>): R
  requires forall a :: f.reads(a) == {}
  requires forall b :: g.reads(b) == {}
  requires forall a :: e == Left(a) ==> f.requires(a)
  requires forall b :: e == Right(b) ==> g.requires(b)
{
  match e
    case Left(l)  => f(l)
    case Right(r) => g(r)
}

function method Lefts<A,B>(es: List<Either<A,B>>): List<A> {
  match es
    case Nil                 => Nil
    case Cons(Left(l),  es') => Cons(l, Lefts(es'))
    case Cons(Right(_), es') => Lefts(es')
}

function method Rights<A,B>(es: List<Either<A,B>>): List<B> {
  match es
    case Nil                 => Nil
    case Cons(Left(_),  es') => Rights(es')
    case Cons(Right(r), es') => Cons(r, Rights(es'))
}


// SYNTAX

type Id = int

datatype Type = Unit | Bool | Int

datatype Expr = Unit | False | True | Literal(int) | Id(Id)
              | Not(Expr) | Apply(Expr, Op, Expr)
              | IfThenElse(Expr, Expr, Expr)
              | Call(Id, List<Expr>)

datatype Op = RelOp(RelOp) | BoolOp(BoolOp) | MathOp(MathOp)

datatype RelOp = Eq | NEq | LT | LTE

datatype BoolOp = Or | And

datatype MathOp = Plus | Minus | Times | DividedBy | Mod

type Program = map<Id, Decl>

type Decl = Either<Function, Procedure>

datatype Procedure = Procedure(List<(Id, Type)>, Type, Block)

datatype Function = Function(List<(Id, Type)>, Type, Block)

type Block = List<Statement>

datatype Statement = Var(Id, Type)
                   | Assign(Id, Expr)
                   | IfThenElse(Expr, Block, Block)
                   | While(Expr, Block)
                   | Return(Expr)
                   | Call(Maybe<Id>, Id, List<Expr>)
                   | Read(Maybe<Id>, Type)
                   | Print(FormatString, List<Expr>)

type FormatString = List<Either<Type, string>>

// FREE VARIABLES

function method FV_Gamma_Expr(e: Expr): set<Id>
  decreases e
{
  match e
    case Unit                   => {}
    case False                  => {}
    case True                   => {}
    case Literal(_)             => {}
    case Id(id)                 => {id}
    case Not(e1)                => FV_Gamma_Expr(e1)
    case Apply(e1, _, e2)       => FV_Gamma_Expr(e1) + FV_Gamma_Expr(e2)
    case IfThenElse(e1, e2, e3) => FV_Gamma_Expr(e1) + FV_Gamma_Expr(e2) + FV_Gamma_Expr(e3)
    case Call(_, es)            => AllSmallerThanList(es);
                                   Union(MapList(e' requires e' < e => FV_Gamma_Expr(e'), es))
}

function method FV_Gamma_Statement(s: Statement): set<Id>
{
  match s
    case Var(v, _)             => {v}
    case Assign(v, _)          => {v}
    case IfThenElse(e, s1, s2) => FV_Gamma_Expr(e) + FV_Gamma_Block(s1) + FV_Gamma_Block(s2)
    case While(e, s)           => FV_Gamma_Expr(e) + FV_Gamma_Block(s)
    case Return(e)             => FV_Gamma_Expr(e)
    case Call(maybeId, _, es)  =>
      (AllSmallerThanList(es);
      Union(MapList(e' requires e' < es => FV_Gamma_Expr(e'), es))) +
      (match maybeId case Just(v) => {v} case Nothing => {})
    case Read(maybeId, _)      =>
      (match maybeId case Just(v) => {v} case Nothing => {})
    case Print(_, es)          =>
      AllSmallerThanList(es);
      Union(MapList(e' requires e' < es => FV_Gamma_Expr(e'), es))
}

function method FV_Gamma_Block(ss: Block): set<Id>
{
  AllSmallerThanList(ss);
  Union(MapList(e' requires e' < ss => FV_Gamma_Statement(e'), ss))
}

// TYPING

datatype Purity = Pure | Impure

datatype Certainty = Yes | Perhaps

type Delta = map<Id, (List<Type>, Type, Purity)> // env. of declarations

type Gamma = map<Id, Type> // env. of values

predicate method TypeExpr(delta: Delta, gamma: Gamma, e: Expr, t: Type) {
  match e
    // literals
    case Unit                      => t == Type.Unit
    case False                     => t == Bool
    case True                      => t == Bool
    case Literal(_)                => t == Int
    // variables
    case Id(id)                    => id in gamma && gamma[id] == t
    // operations
    case Not(e)                    => t == Bool && TypeExpr(delta, gamma, e,  Bool)
    case Apply(e1, RelOp(op), e2)  => t == Bool && TypeExpr(delta, gamma, e1, Int)
                                                && TypeExpr(delta, gamma, e2, Int)
    case Apply(e1, BoolOp(op), e2) => t == Bool && TypeExpr(delta, gamma, e1, Bool)
                                                && TypeExpr(delta, gamma, e2, Bool)
    case Apply(e1, MathOp(op), e2) => t == Int  && TypeExpr(delta, gamma, e1, Int)
                                                && TypeExpr(delta, gamma, e2, Int)
    // if-expressions
    case IfThenElse(e1, e2, e3) => TypeExpr(delta, gamma, e1, Bool)
                                && TypeExpr(delta, gamma, e2, t)
                                && TypeExpr(delta, gamma, e3, t)
    // calling of pure functions
    case Call(id, arguments) =>
      id in delta &&
      var (argTypes, retType, purity) := delta[id];
        t == retType &&
        purity == Pure &&
        TypeList(delta, gamma, arguments, argTypes)
}

predicate method TypeList(delta: Delta, gamma: Gamma, es: List<Expr>, ts: List<Type>)
{
  Length(es) == Length(ts) &&
  (AllSmallerThanList(es); AllSmallerThanList(ts);
  And(ZipWith((e, t) requires e < es && t < ts =>
    TypeExpr(delta, gamma, e, t), es, ts)))
}

function method CheckStatement(delta: Delta, gamma: Gamma, rho: Type, s: Statement): Maybe<Gamma>
  decreases s
{
  match s
    case Var(id, t) =>
      if id !in gamma
      then Just(gamma[id := t])
      else Nothing
    case Assign(id, e) =>
      if id in gamma && TypeExpr(delta, gamma, e, gamma[id])
      then Just(gamma)
      else Nothing
    case IfThenElse(e, s1, s2) =>
      if !TypeExpr(delta, gamma, e, Bool) then Nothing else
      BindMaybe(CheckBlock(delta, gamma, rho, s1), gamma1 =>
      BindMaybe(CheckBlock(delta, gamma, rho, s2), gamma2 =>
      if gamma1 == gamma2 then Just(gamma1) else Nothing))
    case While(e, s) =>
      if !TypeExpr(delta, gamma, e, Bool)
      then Nothing
      else if CheckBlock(delta, gamma, rho, s) == Just(gamma)
           then Just(gamma)
           else Nothing
    case Call(maybeId, id, arguments) =>
      if id !in delta then Nothing else
      var (argTypes, retType, purity) := delta[id];
      if (match maybeId
           case Just(v) => v in gamma && gamma[v] == retType
           case Nothing => true) &&
         TypeList(delta, gamma, arguments, argTypes)
      then Just(gamma)
      else Nothing
    case Return(e) =>
      if TypeExpr(delta, gamma, e, rho) then Just(gamma) else Nothing
    case Read(maybeId, t) =>
      if (match maybeId
            case Nothing => true
            case Just(v) =>
              v in gamma && gamma[v] == t)
      then Just(gamma)
      else Nothing
    case Print(spec, arguments) =>
      if TypeList(delta, gamma, arguments, Lefts(spec)) then Just(gamma) else Nothing
}

function method CheckBlock(delta: Delta, gamma: Gamma, rho: Type, ss: Block): Maybe<Gamma>
  decreases ss
{
  match ss
    case Nil => Just(gamma)
    case Cons(s, ss') =>
      BindMaybe(CheckStatement(delta, gamma, rho, s), gamma' =>
      CheckBlock(delta, gamma', rho, ss'))
}

predicate method CertainBlock(ss: Block)
{
  AllSmallerThanList(ss); Any(x requires x < ss => CertainStatement(x), ss)
}

predicate method CertainStatement(s: Statement)
{
  match s
    case Return(_)             => true
    case IfThenElse(_, s1, s2) => CertainBlock(s1) && CertainBlock(s2)
    case Var(_, _)             => false
    case Assign(_, _)          => false
    case While(_, _)           => false
    case Call(_, _, _)         => false
    case Read(_, _)            => false
    case Print(_, _)           => false
}

predicate method PureBlock(delta: Delta, ss: Block)
{
  AllSmallerThanList(ss); All(x requires x < ss => PureStatement(delta, x), ss)
}

predicate method PureStatement(delta: Delta, s: Statement)
{
  match s
    case Print(_, _)           => false
    case Read(_, _)            => false
    case IfThenElse(_, s1, s2) => PureBlock(delta, s1) && PureBlock(delta, s2)
    case While(_, s)           => PureBlock(delta, s)
    case Var(_, _)             => true
    case Assign(_, _)          => true
    case Return(_)             => true
    case Call(_, id, _)        =>
      id in delta &&
      (var (_, _, purity) := delta[id];
      purity == Pure)
}

predicate method TypeDecl(delta: Delta, declaration: Decl) {
  Either(
    ((func: Function) =>
      var Function(args, retType, ss) := func;
      PureBlock(delta, ss) &&            //            <--- functions must be pure
      (retType != Type.Unit ==> CertainBlock(ss)) &&
      NoDuplicates(MapList(Fst, args)) &&
      IsJust(CheckBlock(delta, MapFromList(args), retType, ss))),
    ((proc: Procedure) =>
      var Procedure(args, retType, ss) := proc;
      (retType != Type.Unit ==> CertainBlock(ss)) &&
      NoDuplicates(MapList(Fst, args)) &&
      IsJust(CheckBlock(delta, MapFromList(args), retType, ss))),
    declaration)
}

// BIG STEP SEMANTICS

type State = map<Id, Expr>

predicate method TypeState(delta: Delta, gamma: Gamma, s: State) {
  forall id :: id in s ==>
    id in gamma &&
    TypeExpr(delta, gamma, s[id], gamma[id])
}

predicate method ValidState(s: State) {
  forall id :: id in s ==> Value(s[id])
}

type TopLevel = map<Id, (List<Id>, Block)>

predicate method TypeProgram(delta: Delta, d: TopLevel) {
  0 in delta && delta[0] == (Nil, Type.Unit, Impure) &&  // main is procedure 0, with no arguments and unit return
  forall proc :: proc in d ==>
    proc in delta &&
    var (ps, body)      := d[proc];
    var (ts, r, purity) := delta[proc];
    if Length(ps) != Length(ts) then false else
    match purity
      case Pure   => TypeDecl(delta,   Left(Function(Zip(ps, ts), r, body)))
      case Impure => TypeDecl(delta, Right(Procedure(Zip(ps, ts), r, body)))
}

predicate method Value(e: Expr) {
  e.Unit? || e.False? || e.True? || e.Literal?
}

predicate ApplyDenotes(op: Op, e1: Expr, e2: Expr, result: Expr) {
  match op
    case BoolOp(boolOp) =>
      exists b1, b2, r ::
        IsBool(b1, e1) &&
        IsBool(b2, e1) &&
        IsBool(r, result) &&
        BoolOpDenotes(boolOp, b1, b2, r)
    case RelOp(relOp)   =>
      exists v1, v2, r ::
        IsLiteral(v1, e1) &&
        IsLiteral(v2, e2) &&
        IsBool(r, result) &&
        RelOpDenotes(relOp, v1, v2, r)
    case MathOp(mathOp) =>
      exists v1, v2, r ::
        IsLiteral(v1, e1) &&
        IsLiteral(v2, e2) &&
        IsLiteral(r, result) &&
        MathOpDenotes(mathOp, v1, v2, r)
}

predicate method IsBool(b: bool, e: Expr) {
  if e == True then b == true else
  if e == False then b == false else
  false
}

predicate method IsLiteral(i: int, e: Expr) {
  if !e.Literal? then false
  else match e case Literal(l) => l == i
}

predicate method BoolOpDenotes(op: BoolOp, b1: bool, b2: bool, result: bool) {
  match op
    case Or  => result == b1 || b2
    case And => result == b1 && b2
}

predicate method RelOpDenotes(op: RelOp, v1: int, v2: int, result: bool) {
  match op
    case Eq  => result == (v1 == v2)
    case NEq => result == (v1 != v2)
    case LT  => result == (v1 < v2)
    case LTE => result == (v1 <= v2)
}

predicate method MathOpDenotes(op: MathOp, v1: int, v2: int, result: int) {
  match op
    case Plus      =>           result == v1 + v2
    case Times     =>           result == v1 * v2
    case Minus     =>           result == v1 - v2
    case DividedBy => v2 != 0 ==> result == v1 / v2  // division by zero is undefined
    case Mod       => v2 != 0 ==> result == v1 % v2  // division by zero is undefined
}

inductive predicate EvalExpr(d: TopLevel, s: State, e: Expr, r: Expr)
  requires ValidState(s)
{
  if e.Unit? || e.True? || e.False? || e.Literal? then r == e
  else match e
    case Id(id) =>
      id in s && r == s[id]
    case Not(e') =>
      exists b ::
        EvalBool(d, s, e', b) &&
        r == if b then False else True
    case Apply(e1, op, e2) =>
      exists v1, v2 ::
        EvalExpr(d, s, e1, v1) &&
        EvalExpr(d, s, e2, v2) &&
        ApplyDenotes(op, v1, v2, r)
    case IfThenElse(e1, e2, e3) =>
      exists b :: EvalBool(d, s, e1, b) &&
        if b then EvalExpr(d, s, e2, r)
             else EvalExpr(d, s, e3, r)
    case Call(p, es) =>
      exists vs ::
        EvalList(d, s, es, vs) &&
        EvalCall(d, p, vs, r)
}

inductive predicate EvalList(d: TopLevel, s: State, es: List<Expr>, rs: List<Expr>)
  requires ValidState(s)
{
  Length(es) == Length(rs) &&
  forall evaluation ::
    evaluation in Elements(Zip(es, rs)) ==>
      var (e, r) := evaluation; EvalExpr(d, s, e, r)
}

inductive predicate EvalBool(d: TopLevel, s: State, e: Expr, b: bool)
  requires ValidState(s)
{
  exists v :: EvalExpr(d, s, e, v) && IsBool(b, v)
}

inductive predicate EvalCall(d: TopLevel, p: Id, args: List<Expr>, result: Expr) {
  p in d &&
  var (params, body) := d[p];
  Length(params) == Length(args) &&
  (forall a :: a in Elements(args) ==> Value(a)) &&
  var s := NewState(params, args);
  exists s' | ValidState(s') ::
     EvalBlock(d, body, s, s', Just(result)) ||                  // normal return
    (EvalBlock(d, body, s, s', Nothing) && result == Expr.Unit)  // auto-unit return
}

function method NewState(params: List<Id>, vs: List<Expr>): map<Id, Expr>
  requires Length(vs) == Length(params)
  requires forall v :: v in Elements(vs) ==> Value(v)
  ensures ValidState(NewState(params, vs))
{
  NormalFormNewState(params, vs);
  MapFromList(Zip(params, vs))
}

lemma NormalFormNewState(params: List<Id>, vs: List<Expr>)
  requires Length(vs) == Length(params)
  requires forall v :: v in Elements(vs) ==> Value(v)
  ensures ValidState(MapFromList(Zip(params, vs)))
{
  if !vs.Nil? {
    NormalFormNewState(params.Tail, vs.Tail);
  }
}

inductive predicate EvalStatement(d: TopLevel, c: Statement, s: State, s'': State, r: Maybe<Expr>)
  requires ValidState(s)
  requires ValidState(s'')
{
  match c
    case Var(_, _) =>
      r.Nothing? &&
      s == s''
    case Assign(id, e) =>
      r.Nothing? &&
      exists v ::
        EvalExpr(d, s, e, v) &&
        s'' == s[id := v]
    case IfThenElse(e1, c2, c3) =>
      exists b :: EvalIfStatement(d, e1, c2, c3, s, s'', r, b)
    case While(e, c) =>
      exists b :: EvalBool(d, s, e, b) &&
        if !b
          then s == s'' && r == Nothing
          else exists s', broken ::
            EvalWhileLoop(d, e, c, s, s', s'', r, broken)
    case Return(e) =>
      exists v ::
      EvalExpr(d, s, e, v) &&
      r == Just(v) &&
      s == s''
    case Read(maybeId, t) =>
      r.Nothing? &&
      if maybeId.Just? then
        var id := maybeId.FromJust;
        Havoc(id, t, s, s'')
      else s == s''
    case Print(_, es) =>
      r.Nothing? &&
      s == s'' &&
      exists vs :: EvalList(d, s, es, vs)
    case Call(maybeId, p, es) =>
      r.Nothing? &&
      exists vs, r ::
        EvalList(d, s, es, vs) &&
        EvalCall(d, p, vs, r) &&
        if maybeId.Just? then var id := maybeId.FromJust;
           s'' == s[id := r]
           else s == s''
}

inductive predicate EvalIfStatement(d: TopLevel, e: Expr, c1: Block, c2: Block, s: State, s': State, r: Maybe<Expr>, b: bool)
  requires ValidState(s)
  requires ValidState(s')
{
  EvalBool(d, s, e, b) &&
    if b then EvalBlock(d, c1, s, s', r)
         else EvalBlock(d, c2, s, s', r)
}

inductive predicate EvalWhileLoop(d: TopLevel, e: Expr, c: Block, s: State, s': State, s'': State, r: Maybe<Expr>, broken: bool)
  requires ValidState(s)
  requires ValidState(s'')
{
  ValidState(s') &&
    exists r' :: EvalBlock(d, c, s, s', r') &&
    if r'.Just?
      then r == r' && s' == s'' && broken == true
      else EvalStatement(d, While(e, c), s', s'', r) && broken == false
}

inductive predicate Havoc(id: Id, t: Type, s: State, s': State)
  requires ValidState(s)
  requires ValidState(s')
{
  match t
    case Unit => s' == s[id := Expr.Unit]
    case Bool => s' == s[id := True] || s' == s[id := False]
    case Int =>
      id in s' && s'[id].Literal? &&  // in new state, the id is an int literal
      (forall k :: (k in s ==> k in s')) &&  // new state has domain >= old state
      forall k :: (k in s && k != id ==> s[k] == s'[k]) &&  // all keys != id are preserved in new state
      (k !in s && k != id ==> k !in s')  // no new keys (except maybe id) are introduced
}

inductive predicate EvalBlock(d: TopLevel, cs: Block, s: State, s'': State, result: Maybe<Expr>)
  requires ValidState(s)
  requires ValidState(s'')
{
  match cs
    case Nil =>
      result.Nothing? && s == s''
    case Cons(c, cs') =>
      exists r, s' | ValidState(s') && EvalStatement(d, c, s, s', r) ::
        if r.Just?
          then r == result && s' == s''
          else EvalBlock(d, cs', s', s'', result)
}

predicate EvalProgram(d: TopLevel, result: Expr)
{
  EvalCall(d, 0, Nil, Expr.Unit)
}

// NORMAL FORMS

inductive lemma NormalFormBigStepExpr(d: TopLevel, s: State, e: Expr, r: Expr)
  decreases e
  requires ValidState(s)
  requires EvalExpr(d, s, e, r)
  ensures  Value(r)
{
  if e.Call? {
    match e
      case Call(p, es) =>
        var vs :| EvalList(d, s, es, vs) &&
                  EvalCall(d, p, vs, r);
        NormalFormBigStepCall(d, p, vs, r);
  }
}

inductive lemma NormalFormBigStepCall(d: TopLevel, p: Id, vs: List<Expr>, r: Expr)
  requires EvalCall(d, p, vs, r)
  ensures  Value(r)
{
  var (params, body) := d[p];
  var s0 := NewState(params, vs);
  if s' :| ValidState(s') && EvalBlock(d, body, s0, s', Just(r)) {
    NormalFormBigStepBlockReturn(d, body, s0, s', r);
  }
}

inductive lemma NormalFormBigStepBlockReturn(d: TopLevel, cs: Block, s: State, s'': State, r: Expr)
  requires ValidState(s)
  requires ValidState(s'')
  requires EvalBlock(d, cs, s, s'', Just(r))
  ensures  Value(r)
{
  match cs
    case Nil =>
    case Cons(c, cs') =>
      if EvalStatement(d, c, s, s'', Just(r)) {
        NormalFormBigStepStatementReturn(d, c, s, s'', r);
      } else {
        var s' :| ValidState(s') &&
                  EvalStatement(d, c, s, s', Nothing) &&
                  EvalBlock(d, cs', s', s'', Just(r));
        NormalFormBigStepBlockReturn(d, cs', s', s'', r);
      }
}

inductive lemma NormalFormBigStepStatementReturn(d: TopLevel, c: Statement, s: State, s'': State, r: Expr)
  requires ValidState(s)
  requires ValidState(s'')
  requires EvalStatement(d, c, s, s'', Just(r))
  ensures  Value(r)
{
  if c.Return? || c.IfThenElse? || c.While? {
    match c
      case Return(e) =>
        NormalFormBigStepExpr(d, s, e, r);
      case IfThenElse(e, c1, c2) =>
        var b :| EvalIfStatement(d, e, c1, c2, s, s'', Just(r), b);
        if b {
          NormalFormBigStepBlockReturn#[_k - 2](d, c1, s, s'', r);
        } else {
          NormalFormBigStepBlockReturn#[_k - 2](d, c2, s, s'', r);
        }
      case While(e, c) =>
        var s', broken :| EvalWhileLoop(d, e, c, s, s', s'', Just(r), broken);
        if broken {
          NormalFormBigStepBlockReturn#[_k - 2](d, c, s, s', r);
        } else {
          NormalFormBigStepStatementReturn#[_k - 2](d, While(e, c), s', s'', r);
        }
  }
}

// inductive lemma PreservationBigStepExpr(d: TopLevel,  delta: Delta,
//                                         s: State,     gamma: Gamma,
//                                         e: Expr,      t: Type,
//                                         r: Expr)
//   requires TypeTopLevel(delta, d)        // top level is well-typed
//   requires TypeState(delta, gamma, s)    // environment is well-typed
//   requires ValidState(s)            // environment contains only values
//   requires TypeExpr(delta, gamma, e, t)  // e has type t
//   requires EvalExpr(d, s, e, r)          // e evaluates to r
//   ensures  TypeExpr(delta, gamma, r, t)  // ... then r also will have type t
// {
//   if e.Call? {
//     // fill in heree
//   }
// }
