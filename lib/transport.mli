(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

(** Minimal HTTP boundary used by the SDK.

    Keeping this type small lets future Eio or Async implementations reuse the
    same request construction, response decoding, and error handling code. *)

type meth = [ `GET ]

type request = {
  meth : meth;
  url : Uri.t;
  headers : (string * string) list;
}

type response = {
  status : int;
  headers : (string * string) list;
  body : string;
}

type t = request -> (response, Error.t) result Lwt.t

val cohttp_lwt_unix : t
(** Default transport backed by CoHTTP and Lwt. *)
