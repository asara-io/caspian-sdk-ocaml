(*
 * Copyright 2026 Asara LLC
 * SPDX-License-Identifier: Apache-2.0
 *)

let full_policy_response =
  {|
  {
    "customer_id": "customer-123",
    "policy_profile_id": "profile-456",
    "policy_version_id": "version-789",
    "policy_hash": "sha256:abc123",
    "approved_data_sources": [
      {
        "source_name": "kalshi",
        "allowed_uses": ["research", "trading"],
        "notes": "Delayed data only"
      }
    ],
    "blackout_windows": [
      {
        "window_id": "window-1",
        "starts_at_utc": "2026-08-20T13:00:00Z",
        "ends_at_utc": "2026-08-20T14:00:00Z",
        "reason": "Restricted event window",
        "applies_to_roles": ["trader"]
      }
    ],
    "restricted_entities": [
      {
        "entity_id": "entity-1",
        "entity_type": "issuer",
        "restriction": "deny",
        "reason": "Customer restriction"
      }
    ],
    "restricted_topics": [
      {
        "topic_id": "topic-1",
        "restriction": "review",
        "reason": "Requires approval",
        "applies_to_contract_ids": ["contract-1"]
      }
    ],
    "metadata_json": {"region": "US", "tier": 2}
  }
  |}

let policy =
  Alcotest.testable Asara_caspian.Policy.pp Asara_caspian.Policy.equal

let run_lwt promise = Lwt_main.run promise

let test_active_policy_sends_request_and_decodes_full_response () =
  let transport (request : Asara_caspian.Transport.request) =
    Alcotest.(check string)
      "method" "GET"
      (match request.meth with
      | `GET -> "GET");
    Alcotest.(check string) "url"
      "https://api.example.test/api/v1/policy/active"
      (Uri.to_string request.url);
    Alcotest.(check (option string)) "authorization header"
      (Some "Bearer cas_demo_key")
      (List.assoc_opt "Authorization" request.headers);
    Lwt.return_ok
      {
        Asara_caspian.Transport.status = 200;
        headers = [];
        body = full_policy_response;
      }
  in
  let client =
    Asara_caspian.Client.create ~base_url:"https://api.example.test"
      ~api_key:"cas_demo_key" ~transport ()
  in
  let actual = run_lwt (Asara_caspian.Client.active_policy client) in
  let expected : Asara_caspian.Policy.t =
    {
      customer_id = "customer-123";
      policy_profile_id = "profile-456";
      policy_version_id = "version-789";
      policy_hash = "sha256:abc123";
      approved_data_sources =
        [
          {
            source_name = "kalshi";
            allowed_uses = [ "research"; "trading" ];
            notes = Some "Delayed data only";
          };
        ];
      blackout_windows =
        [
          {
            window_id = "window-1";
            starts_at_utc = "2026-08-20T13:00:00Z";
            ends_at_utc = "2026-08-20T14:00:00Z";
            reason = "Restricted event window";
            applies_to_roles = [ "trader" ];
          };
        ];
      restricted_entities =
        [
          {
            entity_id = "entity-1";
            entity_type = "issuer";
            restriction = "deny";
            reason = "Customer restriction";
          };
        ];
      restricted_topics =
        [
          {
            topic_id = "topic-1";
            restriction = "review";
            reason = "Requires approval";
            applies_to_contract_ids = [ "contract-1" ];
          };
        ];
      metadata_json = `Assoc [ ("region", `String "US"); ("tier", `Int 2) ];
    }
  in
  Alcotest.(check (result policy reject)) "active policy" (Ok expected) actual

let test_active_policy_decodes_required_fields_with_defaults () =
  let transport (_request : Asara_caspian.Transport.request) =
    Lwt.return_ok
      {
        Asara_caspian.Transport.status = 200;
        headers = [];
        body =
          {|{"customer_id":"c","policy_profile_id":"p","policy_version_id":"v","policy_hash":"h"}|};
      }
  in
  let client =
    Asara_caspian.Client.create ~base_url:"https://api.example.test"
      ~api_key:"cas_demo_key" ~transport ()
  in
  match run_lwt (Asara_caspian.Client.active_policy client) with
  | Error error -> Alcotest.fail (Asara_caspian.Error.to_string error)
  | Ok actual ->
      Alcotest.(check int) "approved sources" 0
        (List.length actual.approved_data_sources);
      Alcotest.(check int) "blackout windows" 0
        (List.length actual.blackout_windows);
      Alcotest.(check int) "restricted entities" 0
        (List.length actual.restricted_entities);
      Alcotest.(check int) "restricted topics" 0
        (List.length actual.restricted_topics);
      Alcotest.(check string) "metadata" "{}"
        (Yojson.Safe.to_string actual.metadata_json)

let test_active_policy_returns_http_error () =
  let transport (_request : Asara_caspian.Transport.request) =
    Lwt.return_ok
      {
        Asara_caspian.Transport.status = 422;
        headers = [ ("X-Caspian-Request-ID", "req-policy-1") ];
        body = {|{"detail":"Validation error"}|};
      }
  in
  let client =
    Asara_caspian.Client.create ~base_url:"https://api.example.test"
      ~api_key:"cas_demo_key" ~transport ()
  in
  match run_lwt (Asara_caspian.Client.active_policy client) with
  | Ok value ->
      Alcotest.failf "expected HTTP error, got %a" Asara_caspian.Policy.pp value
  | Error
      (Asara_caspian.Error.Http_error { status; request_id; body }) ->
      Alcotest.(check int) "status" 422 status;
      Alcotest.(check (option string)) "request id"
        (Some "req-policy-1") request_id;
      Alcotest.(check string) "body" {|{"detail":"Validation error"}|} body
  | Error error -> Alcotest.fail (Asara_caspian.Error.to_string error)

let test_active_policy_rejects_invalid_nested_field () =
  let body =
    {|
    {
      "customer_id": "c",
      "policy_profile_id": "p",
      "policy_version_id": "v",
      "policy_hash": "h",
      "approved_data_sources": [{"source_name": 42}]
    }
    |}
  in
  match Asara_caspian.Policy.of_json_string body with
  | Ok value ->
      Alcotest.failf "expected decode error, got %a" Asara_caspian.Policy.pp value
  | Error (Asara_caspian.Error.Decode_error message) ->
      Alcotest.(check string) "decode error"
        "Caspian response field \
         \"active_policy.approved_data_sources[0].source_name\" must be a \
         string."
        message
  | Error error -> Alcotest.fail (Asara_caspian.Error.to_string error)

let () =
  Alcotest.run "asara-caspian"
    [
      ( "active policy",
        [
          Alcotest.test_case "request and full response" `Quick
            test_active_policy_sends_request_and_decodes_full_response;
          Alcotest.test_case "required fields and defaults" `Quick
            test_active_policy_decodes_required_fields_with_defaults;
          Alcotest.test_case "HTTP error" `Quick
            test_active_policy_returns_http_error;
          Alcotest.test_case "invalid nested field" `Quick
            test_active_policy_rejects_invalid_nested_field;
        ] );
    ]
