open Core
open Collections

type case = Examples of Example.t list * (Name.t * Expr.t) list

type t = {
  name : string;
  desc : string;
  case : case;
  blacklist : Name.t list;
      (** Functions to ignore when synthesizing the test case. This is
      useful to disallow implementations which simply call the correct
      function.

      This is simpler than providing a separate function library
      per-testcase. *)
}

val of_json : Json.t -> t Or_error.t

val to_json : t -> Json.t

val from_file : filename:string -> t Or_error.t

val to_file :
  ?format:[ `Pretty | `Compact ] -> filename:string -> t -> unit Or_error.t

val to_file_exn : ?format:[ `Pretty | `Compact ] -> filename:string -> t -> unit

val from_channel : In_channel.t -> t Or_error.t
