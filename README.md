# Caspian SDK for OCaml

The Caspian SDK for OCaml is the official OCaml client library for the public
Caspian API. Caspian provides policy-aware access to market data and related
metadata through authenticated HTTPS endpoints.

This repository contains the OCaml package that will be published as
`asara-caspian`.

## Status

This SDK is in early package setup. The public package shape is being prepared
before endpoint clients are implemented.

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

The completed SDK is expected to expose a typed client for the external Caspian
API:

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
     let* health = Asara_caspian.Client.health client in
     let* samples =
       Asara_caspian.Market_data.enriched_samples
         client
         ~ticker:"AAPL"
         ~limit:100
         ()
     in
     Asara_caspian.Health.pp Format.std_formatter health;
     Format.printf "@.%a@." Asara_caspian.Market_data.pp_enriched_samples samples;
     Lwt.return_unit)
```

The final API may evolve while the package remains pre-1.0.

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
- `Asara_caspian.Market_data` for market sample reads.
- `Asara_caspian.Policy` for customer-visible policy metadata.
- `Asara_caspian.Error` for typed SDK and service errors.

## Development

Common local checks:

```sh
dune fmt
dune build @install
dune runtest
```

The package metadata is defined in `dune-project`, with opam metadata generated
from Dune.

## License

Copyright 2026 Asara LLC.

Licensed under the Apache License, Version 2.0. See `LICENSE`.
