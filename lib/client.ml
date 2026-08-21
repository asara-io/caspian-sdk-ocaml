(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

open Lwt.Syntax

type auth_header =
  [ `Authorization
  | `X_api_key
  ]

type t = {
  base_url : Uri.t;
  api_key : string;
  auth_header : auth_header;
  transport : Transport.t;
}

let create ~base_url ~api_key ?(auth_header = `Authorization)
    ?(transport = Transport.cohttp_lwt_unix) () =
  {
    base_url = Uri.of_string base_url;
    api_key;
    auth_header;
    transport;
  }

let auth_headers client =
  match client.auth_header with
  | `Authorization -> [ ("Authorization", "Bearer " ^ client.api_key) ]
  | `X_api_key -> [ ("X-API-Key", client.api_key) ]

let with_path base_url path =
  let base_path = Uri.path base_url in
  let base_path =
    if String.equal base_path "/" then ""
    else String.trim base_path |> String.trim
  in
  let base_path =
    if String.ends_with ~suffix:"/" base_path then
      String.sub base_path 0 (String.length base_path - 1)
    else base_path
  in
  Uri.with_path base_url (base_path ^ path)

let request_id headers =
  let assoc_ci name =
    List.find_map
      (fun (header_name, value) ->
        if String.equal (String.lowercase_ascii header_name)
             (String.lowercase_ascii name)
        then Some value
        else None)
      headers
  in
  match assoc_ci "X-Request-ID" with
  | Some _ as value -> value
  | None -> assoc_ci "X-Caspian-Request-ID"

let get client path =
  let request =
    {
      Transport.meth = `GET;
      url = with_path client.base_url path;
      headers = auth_headers client;
    }
  in
  let* response = client.transport request in
  match response with
  | Error _ as error -> Lwt.return error
  | Ok { Transport.status; headers; body } when status >= 400 ->
      Lwt.return_error
        (Error.Http_error
           { status; request_id = request_id headers; body })
  | Ok response -> Lwt.return_ok response

let health client =
  let* response = get client "/api/v1/health" in
  match response with
  | Error _ as error -> Lwt.return error
  | Ok { Transport.body; _ } -> Lwt.return (Health.of_json_string body)

let active_policy client =
  let* response = get client "/api/v1/policy/active" in
  match response with
  | Error _ as error -> Lwt.return error
  | Ok { Transport.body; _ } -> Lwt.return (Policy.of_json_string body)
