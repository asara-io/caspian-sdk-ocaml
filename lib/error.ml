(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

type t =
  | Transport of string
  | Http_error of {
      status : int;
      request_id : string option;
      body : string;
    }
  | Decode_error of string

let to_string = function
  | Transport message -> "Transport error: " ^ message
  | Http_error { status; request_id; body } ->
      let request_id =
        match request_id with
        | None -> ""
        | Some value -> " request_id=" ^ value
      in
      Printf.sprintf "HTTP error: status=%d%s body=%s" status request_id body
  | Decode_error message -> "Decode error: " ^ message
