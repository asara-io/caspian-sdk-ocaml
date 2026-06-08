(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

type t = {
  service : string;
  status : string;
  version : string;
}

let equal left right =
  String.equal left.service right.service
  && String.equal left.status right.status
  && String.equal left.version right.version

let pp formatter health =
  Format.fprintf formatter "{ service = %S; status = %S; version = %S }"
    health.service health.status health.version

let required_string field_name json =
  match Yojson.Safe.Util.member field_name json with
  | `String value -> Ok value
  | `Null | `Bool _ | `Int _ | `Intlit _ | `Float _ | `Assoc _ | `List _ ->
      Error
        (Error.Decode_error
           (Printf.sprintf "Caspian response field %S must be a string."
              field_name))

let of_json_string body =
  match Yojson.Safe.from_string body with
  | exception Yojson.Json_error message -> Error (Error.Decode_error message)
  | json -> (
      match
        ( required_string "service" json,
          required_string "status" json,
          required_string "version" json )
      with
      | Ok service, Ok status, Ok version -> Ok { service; status; version }
      | Error error, _, _ | _, Error error, _ | _, _, Error error -> Error error)
