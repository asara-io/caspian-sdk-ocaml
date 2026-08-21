# Caspian SDK for OCaml

The Caspian SDK for OCaml is the official OCaml client library for the public
Caspian API. Caspian provides policy-aware access to market data and related
metadata through authenticated HTTPS endpoints.

This repository contains the OCaml package that will be published as
`asara-caspian`.

The SDK supports OCaml 5.2 and newer. OCaml 4.x, 5.0, and 5.1 are not
supported by the current package line.

## Status

This SDK is in early development. The Lwt client currently supports the
authenticated public health and active-policy endpoints.

## Installation

Once released through opam:

```sh
opam install asara-caspian
```

For local development from this repository:

```sh
opam install . --deps-only --with-test
dune build @install @runtest
```

## Authentication

Caspian public API requests authenticate with an API key. The SDK will support
the same credentials accepted by the service:

- `Authorization: Bearer <api-key>`
- `X-API-Key: <api-key>`

Applications should load API keys from environment variables, secret stores, or
deployment-specific credential managers. Do not commit API keys to source
control.

## Example

The SDK exposes a typed Lwt client for the external Caspian API. The
synchronous-looking flow below runs through Lwt:

```ocaml
open Lwt.Syntax

let () =
  Lwt_main.run
    (let client =
       Asara_caspian.Client.create
         ~base_url:"https://api.caspian.example.com"
         ~api_key:(Sys.getenv "CASPIAN_API_KEY")
         ()
     in
     let* result = Asara_caspian.Client.health client in
     match result with
     | Ok health ->
         Format.printf "service=%s status=%s version=%s@."
           health.service
           health.status
           health.version;
         Lwt.return_unit
     | Error error ->
         Format.eprintf "%s@." (Asara_caspian.Error.to_string error);
         Lwt.return_unit)
```

Market data resources will follow the same client layout as they are added.
Read the effective policy for the authenticated customer with:

```ocaml
let client =
  Asara_caspian.Client.create
    ~base_url:"https://api.caspian.example.com"
    ~api_key:(Sys.getenv "CASPIAN_API_KEY")
    ()

let result =
  Lwt_main.run (Asara_caspian.Client.active_policy client)
```

The result contains typed approved data sources, blackout windows, restricted
entities, restricted topics, and open-ended policy metadata. The final API may
evolve while the package remains pre-1.0.

## Public API Coverage

The public SDK will focus on customer-facing Caspian APIs:

- Service health checks.
- Policy-filtered market data samples.
- Policy-filtered enriched market data samples.
- Active policy metadata visible to the authenticated customer.

Internal administrative, compliance, and gateway-only APIs are intentionally out
of scope for this public package.

## Package Layout

The OCaml library name is `asara-caspian`, with the top-level module
`Asara_caspian`.

Expected module areas:

- `Asara_caspian.Client` for client construction and common request behavior.
- `Asara_caspian.Health` for service health response types.
- `Asara_caspian.Transport` for the narrow HTTP transport boundary.
- `Asara_caspian.Market_data` for market sample reads.
- `Asara_caspian.Policy` for customer-visible policy response types.
- `Asara_caspian.Client.active_policy` for reading the effective policy.
- `Asara_caspian.Error` for typed SDK and service errors.

The default transport uses Lwt and CoHTTP. The transport boundary is kept small
so future Eio or Async clients can reuse the same request construction,
decoding, and error types without changing customer-facing models.

## Build and Test

Install dependencies for local development:

```sh
opam install . --deps-only --with-test
```

Build the installable library artifacts:

```sh
dune build @install
```

Run the test suite:

```sh
dune build @runtest
```

Run formatting checks when `ocamlformat` is available:

```sh
dune fmt
```

The package metadata is defined in `dune-project`, with opam metadata generated
from Dune.

## License

Copyright 2026 Asara LLC.

Licensed under the Apache License, Version 2.0. See `LICENSE`.
