(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

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

let equal = ( = )

let pp formatter policy =
  Format.fprintf formatter
    "{ customer_id = %S; policy_profile_id = %S; policy_version_id = %S; \
     policy_hash = %S }"
    policy.customer_id policy.policy_profile_id policy.policy_version_id
    policy.policy_hash

let decode_error path expected =
  Error
    (Error.Decode_error
       (Printf.sprintf "Caspian response field %S must be %s." path expected))

let object_fields path = function
  | `Assoc fields -> Ok fields
  | _ -> decode_error path "an object"

let required_string path name fields =
  match List.assoc_opt name fields with
  | Some (`String value) -> Ok value
  | Some _ | None -> decode_error (path ^ "." ^ name) "a string"

let optional_string path name fields =
  match List.assoc_opt name fields with
  | None | Some `Null -> Ok None
  | Some (`String value) -> Ok (Some value)
  | Some _ -> decode_error (path ^ "." ^ name) "a string or null"

let string_list path name fields =
  match List.assoc_opt name fields with
  | None -> Ok []
  | Some (`List values) ->
      let rec decode index acc = function
        | [] -> Ok (List.rev acc)
        | `String value :: rest -> decode (index + 1) (value :: acc) rest
        | _ :: _ ->
            decode_error
              (Printf.sprintf "%s.%s[%d]" path name index)
              "a string"
      in
      decode 0 [] values
  | Some _ -> decode_error (path ^ "." ^ name) "an array of strings"

let object_list path name decode fields =
  match List.assoc_opt name fields with
  | None -> Ok []
  | Some (`List values) ->
      let rec loop index acc = function
        | [] -> Ok (List.rev acc)
        | value :: rest -> (
            match decode (Printf.sprintf "%s.%s[%d]" path name index) value with
            | Ok decoded -> loop (index + 1) (decoded :: acc) rest
            | Error _ as error -> error)
      in
      loop 0 [] values
  | Some _ -> decode_error (path ^ "." ^ name) "an array of objects"

let metadata_json path fields =
  match List.assoc_opt "metadata_json" fields with
  | None -> Ok (`Assoc [])
  | Some (`Assoc _ as value) -> Ok value
  | Some _ -> decode_error (path ^ ".metadata_json") "an object"

let approved_data_source path json =
  match object_fields path json with
  | Error _ as error -> error
  | Ok fields -> (
      match
        ( required_string path "source_name" fields,
          string_list path "allowed_uses" fields,
          optional_string path "notes" fields )
      with
      | Ok source_name, Ok allowed_uses, Ok notes ->
          Ok { source_name; allowed_uses; notes }
      | Error error, _, _ | _, Error error, _ | _, _, Error error -> Error error)

let blackout_window path json =
  match object_fields path json with
  | Error _ as error -> error
  | Ok fields -> (
      match
        ( required_string path "window_id" fields,
          required_string path "starts_at_utc" fields,
          required_string path "ends_at_utc" fields,
          required_string path "reason" fields,
          string_list path "applies_to_roles" fields )
      with
      | ( Ok window_id,
          Ok starts_at_utc,
          Ok ends_at_utc,
          Ok reason,
          Ok applies_to_roles ) ->
          Ok
            {
              window_id;
              starts_at_utc;
              ends_at_utc;
              reason;
              applies_to_roles;
            }
      | Error error, _, _, _, _
      | _, Error error, _, _, _
      | _, _, Error error, _, _
      | _, _, _, Error error, _
      | _, _, _, _, Error error ->
          Error error)

let restricted_entity path json =
  match object_fields path json with
  | Error _ as error -> error
  | Ok fields -> (
      match
        ( required_string path "entity_id" fields,
          required_string path "entity_type" fields,
          required_string path "restriction" fields,
          required_string path "reason" fields )
      with
      | Ok entity_id, Ok entity_type, Ok restriction, Ok reason ->
          Ok { entity_id; entity_type; restriction; reason }
      | Error error, _, _, _
      | _, Error error, _, _
      | _, _, Error error, _
      | _, _, _, Error error ->
          Error error)

let restricted_topic path json =
  match object_fields path json with
  | Error _ as error -> error
  | Ok fields -> (
      match
        ( required_string path "topic_id" fields,
          required_string path "restriction" fields,
          required_string path "reason" fields,
          string_list path "applies_to_contract_ids" fields )
      with
      | Ok topic_id, Ok restriction, Ok reason, Ok applies_to_contract_ids ->
          Ok { topic_id; restriction; reason; applies_to_contract_ids }
      | Error error, _, _, _
      | _, Error error, _, _
      | _, _, Error error, _
      | _, _, _, Error error ->
          Error error)

let decode json =
  let path = "active_policy" in
  match object_fields path json with
  | Error _ as error -> error
  | Ok fields -> (
      match
        ( required_string path "customer_id" fields,
          required_string path "policy_profile_id" fields,
          required_string path "policy_version_id" fields,
          required_string path "policy_hash" fields,
          object_list path "approved_data_sources" approved_data_source fields,
          object_list path "blackout_windows" blackout_window fields,
          object_list path "restricted_entities" restricted_entity fields,
          object_list path "restricted_topics" restricted_topic fields,
          metadata_json path fields )
      with
      | ( Ok customer_id,
          Ok policy_profile_id,
          Ok policy_version_id,
          Ok policy_hash,
          Ok approved_data_sources,
          Ok blackout_windows,
          Ok restricted_entities,
          Ok restricted_topics,
          Ok metadata_json ) ->
          Ok
            {
              customer_id;
              policy_profile_id;
              policy_version_id;
              policy_hash;
              approved_data_sources;
              blackout_windows;
              restricted_entities;
              restricted_topics;
              metadata_json;
            }
      | Error error, _, _, _, _, _, _, _, _
      | _, Error error, _, _, _, _, _, _, _
      | _, _, Error error, _, _, _, _, _, _
      | _, _, _, Error error, _, _, _, _, _
      | _, _, _, _, Error error, _, _, _, _
      | _, _, _, _, _, Error error, _, _, _
      | _, _, _, _, _, _, Error error, _, _
      | _, _, _, _, _, _, _, Error error, _
      | _, _, _, _, _, _, _, _, Error error ->
          Error error)

let of_json_string body =
  match Yojson.Safe.from_string body with
  | exception Yojson.Json_error message -> Error (Error.Decode_error message)
  | json -> decode json
