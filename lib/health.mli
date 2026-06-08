(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

(** Health status returned by the public Caspian API. *)

type t = {
  service : string;
  status : string;
  version : string;
}

val equal : t -> t -> bool
val pp : Format.formatter -> t -> unit
val of_json_string : string -> (t, Error.t) result
