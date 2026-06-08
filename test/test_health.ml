(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

let health_response =
  {|{"service":"caspian-customer-api","status":"ok","version":"0.1.0"}|}

let health =
  Alcotest.testable Asara_caspian.Health.pp Asara_caspian.Health.equal

let run_lwt promise = Lwt_main.run promise

let test_health_sends_bearer_token_and_decodes_response () =
  let transport (request : Asara_caspian.Transport.request) =
    Alcotest.(check string)
      "method" "GET"
      (match request.Asara_caspian.Transport.meth with
      | `GET -> "GET");
    Alcotest.(check string) "url"
      "https://api.example.test/api/v1/health"
      (Uri.to_string request.url);
    Alcotest.(check (option string)) "authorization header"
      (Some "Bearer cas_demo_key")
      (List.assoc_opt "Authorization" request.headers);
    Lwt.return_ok
      {
        Asara_caspian.Transport.status = 200;
        headers = [];
        body = health_response;
      }
  in
  let client =
    Asara_caspian.Client.create ~base_url:"https://api.example.test"
      ~api_key:"cas_demo_key" ~transport ()
  in
  let actual = run_lwt (Asara_caspian.Client.health client) in
  Alcotest.(check (result health reject))
    "health response"
    (Ok
       {
         Asara_caspian.Health.service = "caspian-customer-api";
         status = "ok";
         version = "0.1.0";
       })
    actual

let test_health_can_send_x_api_key_header () =
  let transport (request : Asara_caspian.Transport.request) =
    Alcotest.(check (option string)) "authorization header" None
      (List.assoc_opt "Authorization" request.Asara_caspian.Transport.headers);
    Alcotest.(check (option string)) "x-api-key header"
      (Some "cas_demo_key")
      (List.assoc_opt "X-API-Key" request.headers);
    Lwt.return_ok
      {
        Asara_caspian.Transport.status = 200;
        headers = [];
        body = health_response;
      }
  in
  let client =
    Asara_caspian.Client.create ~base_url:"https://api.example.test/"
      ~api_key:"cas_demo_key" ~auth_header:`X_api_key ~transport ()
  in
  match run_lwt (Asara_caspian.Client.health client) with
  | Ok health -> Alcotest.(check string) "status" "ok" health.status
  | Error error -> Alcotest.fail (Asara_caspian.Error.to_string error)

let test_health_returns_http_error_for_error_status () =
  let transport (_request : Asara_caspian.Transport.request) =
    Lwt.return_ok
      {
        Asara_caspian.Transport.status = 401;
        headers = [ ("x-request-id", "req_123") ];
        body = {|{"detail":"Unauthorized"}|};
      }
  in
  let client =
    Asara_caspian.Client.create ~base_url:"https://api.example.test"
      ~api_key:"bad_key" ~transport ()
  in
  match run_lwt (Asara_caspian.Client.health client) with
  | Ok health ->
      Alcotest.failf "expected HTTP error, got %a" Asara_caspian.Health.pp
        health
  | Error (Asara_caspian.Error.Http_error { status; request_id; body }) ->
      Alcotest.(check int) "status" 401 status;
      Alcotest.(check (option string)) "request id" (Some "req_123")
        request_id;
      Alcotest.(check string) "body" {|{"detail":"Unauthorized"}|} body
  | Error error -> Alcotest.fail (Asara_caspian.Error.to_string error)

let () =
  Alcotest.run "asara-caspian"
    [
      ( "health",
        [
          Alcotest.test_case "bearer auth and decode" `Quick
            test_health_sends_bearer_token_and_decodes_response;
          Alcotest.test_case "x-api-key auth" `Quick
            test_health_can_send_x_api_key_header;
          Alcotest.test_case "http error" `Quick
            test_health_returns_http_error_for_error_status;
        ] );
    ]
