(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

(** SDK and service errors returned by the Caspian client. *)

type t =
  | Transport of string
  | Http_error of {
      status : int;
      request_id : string option;
      body : string;
    }
  | Decode_error of string

val to_string : t -> string
(** Render an error for logs or command-line output. *)
