(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

(** Client for the public Caspian API. *)

type auth_header =
  [ `Authorization
  | `X_api_key
  ]

type t

val create :
  base_url:string ->
  api_key:string ->
  ?auth_header:auth_header ->
  ?transport:Transport.t ->
  unit ->
  t
(** Create a client.

    The default authentication header is [Authorization: Bearer <api-key>].
    Use [~auth_header:`X_api_key] to send [X-API-Key] instead. *)

val health : t -> (Health.t, Error.t) result Lwt.t
(** Return the service health status for the authenticated API key. *)

val active_policy : t -> (Policy.t, Error.t) result Lwt.t
(** Return the effective policy profile for the authenticated customer. *)
