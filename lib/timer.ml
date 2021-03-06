open! Core

type timing_info = { time : Time.Span.t; desc : string }

type t = timing_info Mutctx.t

let empty = Mutctx.empty

let add_zero t name desc =
  Mutctx.update t (Name.of_string name) { time = Time.Span.zero; desc }

let add t name time =
  let time' = Mutctx.lookup_exn t name in
  Mutctx.update t name { time' with time = Time.Span.( + ) time time'.time }

let find_exn t name = (Mutctx.lookup_exn t (Name.of_string name)).time

let run_with_time t name (thunk : unit -> 'a) : 'a =
  let start_t = Time.now () in
  let x = thunk () in
  let end_t = Time.now () in
  add t (Name.of_string name) (Time.diff end_t start_t);
  x

let to_strings (t : t) : string list =
  List.map (Mutctx.data t) ~f:(fun { desc = d; time = t } ->
      sprintf "%s: %s" d (Time.Span.to_short_string t))

(** Serialize a timer to JSON. This creates an object of the form \{
      name: time, ...\}. Times are stored in seconds. *)
let to_json (t : t) =
  `Assoc
    ( Mutctx.to_alist t
    |> List.map ~f:(fun (k, v) ->
           ( Name.to_string k,
             `Assoc
               [
                 ("time", `Float (Time.Span.to_sec v.time));
                 ("description", `String v.desc);
               ] )) )
