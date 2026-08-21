(lang dune 3.11)

; Copyright 2026 Asara LLC
; SPDX-License-Identifier: Apache-2.0

(name asara-caspian)

(generate_opam_files true)

(source
 (github asara-io/caspian-sdk-ocaml))

(authors "Asara")
(maintainers "Asara")
(license Apache-2.0)

(package
 (name asara-caspian)
 (synopsis "Official OCaml SDK for the public Caspian API")
 (description
  "asara-caspian is the official OCaml SDK for authenticated access to the public Caspian API, including customer-facing health, market data, enriched market data, and policy metadata endpoints.")
 (depends
  (ocaml
   (>= 5.2))
  cohttp-lwt-unix
  lwt
  uri
  yojson
  (alcotest
   :with-test)))
