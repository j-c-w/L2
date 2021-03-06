open Core
open Collections

exception RuntimeError of Error.t
[@@deriving sexp]
(** Exceptions that can be thrown by the evaluation and type-checking functions. *)

exception HitRecursionLimit

type closure = {
  args : Name.t list;
  body : Expr.t;
  ctx : closure Ast.evalue option ref Ctx.t;
}
[@@deriving sexp]

type ctx = closure Ast.evalue Ctx.t

(** Raise a bad argument error. *)
let arg_error expr =
  let err = Error.create "Bad function arguments." expr [%sexp_of: Expr.t] in
  raise (RuntimeError err)

(** Raise a wrong # of arguments error. *)
let argn_error expr =
  let err = Error.create "Wrong number of arguments." expr [%sexp_of: Expr.t] in
  raise (RuntimeError err)

let divide_by_zero_error () =
  raise (RuntimeError (Error.of_string "Divide by zero."))

let unbound_error id ctx =
  raise
  @@ RuntimeError
       (Error.create "Unbound lookup."
          (id, Map.keys ctx)
          [%sexp_of: Expr.id * Name.t list])

let unbound_rec_error id ctx =
  raise
  @@ RuntimeError
       (Error.create "BUG: Unbound recursive let."
          (id, Map.keys ctx)
          [%sexp_of: Expr.id * Name.t list])

let non_function_error expr =
  raise
  @@ RuntimeError
       (Error.create "Tried to apply a non-function." expr [%sexp_of: Expr.t])

let inf = Name.of_string "inf"

let to_mut_ctx = Map.map ~f:(fun v -> ref (Some v))

let rec eval decr_limit ctx expr : closure Ast.evalue =
  let eval_ctx = eval decr_limit in
  let eval = eval decr_limit ctx in
  let eval_all = List.map ~f:eval in
  decr_limit ();
  match expr with
  | `Num x -> `Num x
  | `Bool x -> `Bool x
  | `List x -> `List (eval_all x)
  | `Tree x -> `Tree (Tree.map x ~f:eval)
  | `Id id -> (
      match Map.find ctx id with
      | Some { contents = Some v } -> v
      | Some { contents = None } -> unbound_rec_error id ctx
      | None -> unbound_error id ctx )
  | `Let (name, bound, body) ->
      let bound_ref = ref None in
      let bound_ctx = Map.set ctx ~key:name ~data:bound_ref in
      let bound_val = eval_ctx bound_ctx bound in
      bound_ref := Some bound_val;
      eval_ctx bound_ctx body
  | `Lambda (args, body) -> `Closure { args; body; ctx }
  | `Apply (func, args) -> (
      match eval func with
      | `Closure { args = arg_names; body; ctx = enclosed_ctx } -> (
          match List.zip arg_names (eval_all args) with
          | Ok bindings ->
              let ctx =
                List.fold bindings ~init:enclosed_ctx
                  ~f:(fun ctx (arg_name, value) ->
                    Map.set ctx ~key:arg_name ~data:(ref (Some value)))
              in
              eval_ctx ctx body
          | Unequal_lengths -> argn_error expr )
      | _ -> non_function_error expr )
  | `Op (op, args) -> (
      let open Expr.Op in
      match op with
      | Not -> (
          match eval_all args with
          | [ `Bool x ] -> `Bool (not x)
          | _ -> arg_error expr )
      | Car -> (
          match eval_all args with [ `List (x :: _) ] -> x | _ -> arg_error expr )
      | Cdr -> (
          match eval_all args with
          | [ `List (_ :: xs) ] -> `List xs
          | _ -> arg_error expr )
      | Plus -> (
          match eval_all args with
          | [ `Num x; `Num y ] -> `Num (x + y)
          | _ -> arg_error expr )
      | Minus -> (
          match eval_all args with
          | [ `Num x; `Num y ] -> `Num (x - y)
          | _ -> arg_error expr )
      | Mul -> (
          match eval_all args with
          | [ `Num x; `Num y ] -> `Num (x * y)
          | _ -> arg_error expr )
      | Div -> (
          match eval_all args with
          | [ `Num x; `Num y ] ->
              if y = 0 then divide_by_zero_error () else `Num (x / y)
          | _ -> arg_error expr )
      | Mod -> (
          match eval_all args with
          | [ `Num x; `Num y ] ->
              if y = 0 then divide_by_zero_error () else `Num (x mod y)
          | _ -> arg_error expr )
      | Eq -> (
          match eval_all args with
          | [ x; y ] -> (
              try `Bool Poly.(x = y) with Invalid_argument _ -> arg_error expr )
          | _ -> arg_error expr )
      | Neq -> (
          match eval_all args with
          | [ x; y ] -> (
              try `Bool Poly.(x <> y) with Invalid_argument _ -> arg_error expr )
          | _ -> arg_error expr )
      | Lt -> (
          match eval_all args with
          | [ `Num x; `Num y ] -> `Bool (x < y)
          | _ -> arg_error expr )
      | Leq -> (
          match eval_all args with
          | [ `Num x; `Num y ] -> `Bool (x <= y)
          | _ -> arg_error expr )
      | Gt -> (
          match eval_all args with
          | [ `Num x; `Num y ] -> `Bool (x > y)
          | _ -> arg_error expr )
      | Geq -> (
          match eval_all args with
          | [ `Num x; `Num y ] -> `Bool (x >= y)
          | _ -> arg_error expr )
      | And -> (
          match eval_all args with
          | [ `Bool x; `Bool y ] -> `Bool (x && y)
          | _ -> arg_error expr )
      | Or -> (
          match eval_all args with
          | [ `Bool x; `Bool y ] -> `Bool (x || y)
          | _ -> arg_error expr )
      | RCons -> (
          match eval_all args with
          | [ `List y; x ] -> `List (x :: y)
          | _ -> arg_error expr )
      | Cons -> (
          match eval_all args with
          | [ x; `List y ] -> `List (x :: y)
          | _ -> arg_error expr )
      | Tree -> (
          match eval_all args with
          | [ x; `List y ] ->
              let y =
                List.map y ~f:(function `Tree t -> t | _ -> arg_error expr)
              in
              `Tree (Tree.Node (x, y))
          | _ -> arg_error expr )
      | Value -> (
          match eval_all args with
          | [ `Tree (Tree.Node (x, _)) ] -> x
          | _ -> arg_error expr )
      | Children -> (
          match eval_all args with
          | [ `Tree Tree.Empty ] -> `List []
          | [ `Tree (Tree.Node (_, x)) ] -> `List (List.map x ~f:(fun e -> `Tree e))
          | _ -> arg_error expr )
      | If -> (
          match args with
          | [ ux; uy; uz ] -> (
              match eval ux with
              | `Bool x -> if x then eval uy else eval uz
              | _ -> arg_error expr )
          | _ -> arg_error expr ) )

let ctx_of_alist l =
  List.fold_left l ~init:Ctx.empty ~f:(fun ctx (name, lambda) ->
      let bound_ref = ref None in
      let bound_ctx = Map.set ctx ~key:name ~data:bound_ref in
      let bound_val = eval (fun _ -> ()) bound_ctx lambda in
      bound_ref := Some bound_val;
      bound_ctx)
  |> Map.map ~f:(fun v ->
         match !v with Some v' -> v' | None -> failwith "Unbound recursive let.")

(** Evaluate an expression in the provided context. *)
let eval ?recursion_limit ctx expr =
  let decr_limit =
    match recursion_limit with
    | Some max ->
        let limit = ref max in
        fun () ->
          decr limit;
          if !limit <= 0 then
            let err =
              Error.create "Exceeded recursion limit." (max, expr)
                [%sexp_of: int * Expr.t]
            in
            raise (RuntimeError err)
    | None -> fun () -> ()
  in
  eval decr_limit (to_mut_ctx ctx) expr

(** Raise a wrong # of arguments error. *)
let argn_error expr =
  let err = Error.create "Wrong number of arguments." expr [%sexp_of: ExprValue.t] in
  raise (RuntimeError err)

let partial_eval ?recursion_limit:(limit = -1) ?(ctx = Mutctx.empty ()) expr =
  let rec ev ctx lim expr =
    let ev_all = List.map ~f:(ev ctx lim) in
    if lim = 0 then raise HitRecursionLimit
    else
      match expr with
      | `Unit | `Closure _ | `Num _ | `Bool _ -> expr
      | `List x -> `List (List.map x ~f:(ev ctx lim))
      | `Tree x -> `Tree (Tree.map x ~f:(ev ctx lim))
      | `Lambda _ as lambda -> `Closure (lambda, ctx)
      | `Id id -> ( match Mutctx.lookup ctx id with Some e -> e | None -> expr )
      | `Let (name, bound, body) ->
          let ctx' = Mutctx.bind ctx name `Unit in
          Mutctx.update ctx' name (ev ctx' lim bound);
          ev ctx' lim body
      | `Apply (func, raw_args) -> (
          let args = ev_all raw_args in
          match ev ctx lim func with
          | `Closure (`Lambda (arg_names, body), enclosed_ctx) -> (
              match List.zip arg_names args with
              | Ok bindings ->
                  let ctx' =
                    List.fold bindings ~init:enclosed_ctx
                      ~f:(fun ctx' (arg_name, value) ->
                        Mutctx.bind ctx' arg_name value)
                  in
                  ev ctx' (lim - 1) body
              | Unequal_lengths -> argn_error expr )
          | e -> `Apply (e, args) )
      | `Op (op, raw_args) -> (
          let args = lazy (List.map ~f:(ev ctx lim) raw_args) in
          try
            let open Expr.Op in
            let open Poly in
            match op with
            | Plus -> (
                match Lazy.force args with
                | [ `Num x; `Num y ] -> `Num (x + y)
                | [ `Num 0; x ] | [ x; `Num 0 ] -> x
                | [ `Op (Minus, [ x; y ]); z ] when y = z -> x
                | [ z; `Op (Minus, [ x; y ]) ] when y = z -> x
                | _ -> `Op (op, Lazy.force args) )
            | Minus -> (
                match Lazy.force args with
                | [ `Num x; `Num y ] -> `Num (x - y)
                | [ x; `Num 0 ] -> x
                | [ `Op (Plus, [ x; y ]); z ] when x = z -> y
                | [ `Op (Plus, [ x; y ]); z ] when y = z -> x
                | [ z; `Op (Plus, [ x; y ]) ] when x = z -> `Op (Minus, [ `Num 0; y ])
                | [ z; `Op (Plus, [ x; y ]) ] when y = z -> `Op (Minus, [ `Num 0; x ])
                | [ x; y ] when x = y -> `Num 0
                | _ -> `Op (op, Lazy.force args) )
            | Mul -> (
                match Lazy.force args with
                | [ `Num x; `Num y ] -> `Num (x * y)
                | [ `Num 0; _ ] | [ _; `Num 0 ] -> `Num 0
                | [ `Num 1; x ] | [ x; `Num 1 ] -> x
                | [ x; `Op (Div, [ y; z ]) ] when x = z -> y
                | [ `Op (Div, [ y; z ]); x ] when x = z -> y
                | _ -> `Op (op, Lazy.force args) )
            | Div -> (
                match Lazy.force args with
                | [ _; `Num 0 ] -> divide_by_zero_error ()
                | [ `Num x; `Num y ] -> `Num (x / y)
                | [ `Num 0; _ ] -> `Num 0
                | [ x; `Num 1 ] -> x
                | [ x; y ] when x = y -> `Num 1
                | _ -> `Op (op, Lazy.force args) )
            | Mod -> (
                match Lazy.force args with
                | [ _; `Num 0 ] -> divide_by_zero_error ()
                | [ `Num x; `Num y ] -> `Num (x mod y)
                | [ `Num 0; _ ] | [ _; `Num 1 ] -> `Num 0
                | [ x; y ] when x = y -> `Num 0
                | _ -> `Op (op, Lazy.force args) )
            | Eq -> (
                match Lazy.force args with
                | [ `Bool true; x ] | [ x; `Bool true ] -> x
                | [ `Bool false; x ] | [ x; `Bool false ] ->
                    ev ctx (lim - 1) (`Op (Not, [ x ]))
                | [ x; `Op (Cdr, [ y ]) ] when x = y -> `Bool false
                | [ `Op (Cdr, [ y ]); x ] when x = y -> `Bool false
                | [ x; y ] -> `Bool (x = y)
                | _ -> `Op (op, Lazy.force args) )
            | Neq -> (
                match Lazy.force args with
                | [ `Bool true; x ] | [ x; `Bool true ] ->
                    ev ctx (lim - 1) (`Op (Not, [ x ]))
                | [ `Bool false; x ] | [ x; `Bool false ] -> x
                | [ x; `Op (Cdr, [ y ]) ] when x = y -> `Bool true
                | [ `Op (Cdr, [ y ]); x ] when x = y -> `Bool true
                | [ x; y ] -> `Bool (x <> y)
                | _ -> `Op (op, Lazy.force args) )
            | Lt -> (
                match Lazy.force args with
                | [ `Num x; `Num y ] -> `Bool (x < y)
                | [ `Id x; _ ] when Name.O.(x = inf) -> `Bool false
                | [ x; y ] when x = y -> `Bool false
                | _ -> `Op (op, Lazy.force args) )
            | Gt -> (
                match Lazy.force args with
                | [ `Num x; `Num y ] -> `Bool (x > y)
                | [ _; `Id x ] when Name.O.(x = inf) -> `Bool false
                | [ x; y ] when x = y -> `Bool false
                | _ -> `Op (op, Lazy.force args) )
            | Leq -> (
                match Lazy.force args with
                | [ `Num x; `Num y ] -> `Bool (x <= y)
                | [ _; `Id x ] when Name.O.(x = inf) -> `Bool true
                | [ x; y ] when x = y -> `Bool true
                | _ -> `Op (op, Lazy.force args) )
            | Geq -> (
                match Lazy.force args with
                | [ `Num x; `Num y ] -> `Bool (x >= y)
                | [ `Id x; _ ] when Name.O.(x = inf) -> `Bool true
                | [ x; y ] when x = y -> `Bool true
                | _ -> `Op (op, Lazy.force args) )
            | And -> (
                match Lazy.force args with
                | [ `Bool x; `Bool y ] -> `Bool (x && y)
                | [ `Bool true; x ] | [ x; `Bool true ] -> x
                | [ `Bool false; _ ] | [ _; `Bool false ] -> `Bool false
                | [ x; `Op (And, [ y; z ]) ] when x = y -> `Op (And, [ x; z ])
                | [ x; `Op (And, [ y; z ]) ] when x = z -> `Op (And, [ x; y ])
                | [ x; `Op (Not, [ y ]) ] when x = y -> `Bool false
                | [ `Op (Not, [ y ]); x ] when x = y -> `Bool false
                (* DeMorgan's law. *)
                | [ `Op (Not, [ x ]); `Op (Not, [ y ]) ] ->
                    `Op (Not, [ `Op (Or, [ x; y ]) ])
                (* Distributivity. *)
                | [ `Op (Or, [ a; b ]); `Op (Or, [ c; d ]) ] when a = c ->
                    `Op (Or, [ a; `Op (And, [ b; d ]) ])
                | [ x; y ] when x = y -> x
                | _ -> `Op (op, Lazy.force args) )
            | Or -> (
                match Lazy.force args with
                | [ `Bool x; `Bool y ] -> `Bool (x || y)
                | [ `Bool false; x ] | [ x; `Bool false ] -> x
                | [ `Bool true; _ ] | [ _; `Bool true ] -> `Bool true
                | [ x; `Op (Or, [ y; z ]) ] when x = y -> `Op (Or, [ x; z ])
                | [ x; `Op (Or, [ y; z ]) ] when x = z -> `Op (Or, [ x; y ])
                | [ x; `Op (Not, [ y ]) ] when x = y -> `Bool true
                | [ `Op (Not, [ y ]); x ] when x = y -> `Bool true
                (* DeMorgan's law. *)
                | [ `Op (Not, [ x ]); `Op (Not, [ y ]) ] ->
                    `Op (Not, [ `Op (And, [ x; y ]) ])
                (* Distributivity. *)
                | [ `Op (And, [ a; b ]); `Op (And, [ c; d ]) ] when a = c ->
                    `Op (And, [ a; `Op (Or, [ b; d ]) ])
                | [ x; y ] when x = y -> x
                | _ -> `Op (op, Lazy.force args) )
            | Not -> (
                match Lazy.force args with
                | [ `Bool x ] -> `Bool (not x)
                | [ `Op (Not, [ x ]) ] -> x
                | [ `Op (Lt, [ x; y ]) ] -> `Op (Geq, [ x; y ])
                | [ `Op (Gt, [ x; y ]) ] -> `Op (Leq, [ x; y ])
                | [ `Op (Leq, [ x; y ]) ] -> `Op (Gt, [ x; y ])
                | [ `Op (Geq, [ x; y ]) ] -> `Op (Lt, [ x; y ])
                | [ `Op (Eq, [ x; y ]) ] -> `Op (Neq, [ x; y ])
                | [ `Op (Neq, [ x; y ]) ] -> `Op (Eq, [ x; y ])
                | _ -> `Op (op, Lazy.force args) )
            | Cons -> (
                match Lazy.force args with
                | [ x; `List y ] -> `List (x :: y)
                | [ `Op (Car, [ x ]); `Op (Cdr, [ y ]) ] when x = y -> x
                | _ -> `Op (op, Lazy.force args) )
            | RCons -> (
                match Lazy.force args with
                | [ `List y; x ] -> `List (x :: y)
                | [ `Op (Cdr, [ y ]); `Op (Car, [ x ]) ] when x = y -> x
                | _ -> `Op (RCons, Lazy.force args) )
            | Car -> (
                match Lazy.force args with
                | [ `List (x :: _) ] -> x
                | [ `List [] ] ->
                    raise (RuntimeError (Error.of_string "Car of empty list."))
                | [ `Op (Cons, [ x; _ ]) ] -> x
                | [ `Op (RCons, [ _; x ]) ] -> x
                | _ -> `Op (op, Lazy.force args) )
            | Cdr -> (
                match Lazy.force args with
                | [ `List (_ :: xs) ] -> `List xs
                | [ `List [] ] ->
                    raise (RuntimeError (Error.of_string "Cdr of empty list."))
                | [ `Op (Cons, [ _; x ]) ] | [ `Op (RCons, [ x; _ ]) ] -> x
                | _ -> `Op (op, Lazy.force args) )
            | If -> (
                match raw_args with
                | [ ux; uy; uz ] -> (
                    match ev ctx lim ux with
                    | `Bool x -> if x then ev ctx lim uy else ev ctx lim uz
                    | `Op (Not, [ x ]) -> `Op (If, [ x; uz; uy ])
                    | x -> `Op (If, [ x; uy; uz ]) )
                | _ -> expr )
            | Value -> (
                match Lazy.force args with
                | [ `Tree Tree.Empty ] ->
                    raise (RuntimeError (Error.of_string "Value of empty tree."))
                | [ `Tree (Tree.Node (x, _)) ] -> x
                | [ `Op (Tree, [ x; _ ]) ] -> x
                | _ -> `Op (op, Lazy.force args) )
            | Children -> (
                match Lazy.force args with
                | [ `Tree Tree.Empty ] -> `List []
                | [ `Tree (Tree.Node (_, x)) ] ->
                    `List (List.map x ~f:(fun e -> `Tree e))
                | [ `Op (Tree, [ _; x ]) ] -> x
                | _ -> `Op (op, Lazy.force args) )
            | Tree -> (
                match Lazy.force args with
                | [ x; `List y ] ->
                    let y' =
                      List.map y ~f:(fun e ->
                          match e with `Tree t -> t | _ -> Tree.Node (e, []))
                    in
                    `Tree (Tree.Node (x, y'))
                | _ -> `Op (op, Lazy.force args) )
            (* Invalid_argument is thrown when comparing functional values (closures). *)
          with Invalid_argument _ -> `Op (op, Lazy.force args) )
  in
  ev ctx limit expr
