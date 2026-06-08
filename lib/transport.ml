(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

open Lwt.Syntax

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

let cohttp_method = function
  | `GET -> `GET

let cohttp_lwt_unix (request : request) =
  Lwt.catch
    (fun () ->
      let* response, body =
        Cohttp_lwt_unix.Client.call
          ~headers:(Cohttp.Header.of_list request.headers)
          (cohttp_method request.meth) request.url
      in
      let* body = Cohttp_lwt.Body.to_string body in
      let headers = Cohttp.Response.headers response |> Cohttp.Header.to_list in
      let status = Cohttp.Response.status response |> Cohttp.Code.code_of_status in
      Lwt.return_ok { status; headers; body })
    (fun exn -> Lwt.return_error (Error.Transport (Printexc.to_string exn)))
