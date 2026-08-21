(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

(** Effective policy metadata returned by the public Caspian API. *)

type approved_data_source = {
  source_name : string;
  allowed_uses : string list;
  notes : string option;
}

type blackout_window = {
  window_id : string;
  starts_at_utc : string;
  ends_at_utc : string;
  reason : string;
  applies_to_roles : string list;
}

type restricted_entity = {
  entity_id : string;
  entity_type : string;
  restriction : string;
  reason : string;
}

type restricted_topic = {
  topic_id : string;
  restriction : string;
  reason : string;
  applies_to_contract_ids : string list;
}

type t = {
  customer_id : string;
  policy_profile_id : string;
  policy_version_id : string;
  policy_hash : string;
  approved_data_sources : approved_data_source list;
  blackout_windows : blackout_window list;
  restricted_entities : restricted_entity list;
  restricted_topics : restricted_topic list;
  metadata_json : Yojson.Safe.t;
}

val equal : t -> t -> bool
val pp : Format.formatter -> t -> unit
val of_json_string : string -> (t, Error.t) result
