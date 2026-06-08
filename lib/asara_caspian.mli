(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

(** Official OCaml SDK for the public Caspian API. *)

val version : string
(** SDK package version. *)

module Error = Error
module Health = Health
module Transport = Transport
module Client = Client
