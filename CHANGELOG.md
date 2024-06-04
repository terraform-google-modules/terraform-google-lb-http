# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [11.1.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v11.0.0...v11.1.0) (2024-05-29)


### Features

* Add support for setting http_keep_alive_timeout_sec ([#425](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/425)) ([804b7b9](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/804b7b9f9cedf234a2973e13c5ab78c8fec6ee12))


### Bug Fixes

* add backend.groups.description variable to serverless_neg ([#427](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/427)) ([3d7943c](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/3d7943ca8f7c5a38b3b7bf57c5de034a9f7eed49))

## [11.0.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v10.2.0...v11.0.0) (2024-05-03)


### ⚠ BREAKING CHANGES

* **TPG>=4.84:** make health_check optional in root module for serverless neg ([#414](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/414))

### Features

* **TPG>=4.84:** make health_check optional in root module for serverless neg ([#414](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/414)) ([fe92b95](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/fe92b95024414d019a4f0125c1bea307be60bc24))


### Bug Fixes

* updates for tflint ([#403](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/403)) ([29e4503](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/29e4503a62a7df8656353d271756da62236b3529))

## [10.2.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v10.1.0...v10.2.0) (2024-03-20)


### Features

* Allow specifying HTTP and HTTPS port. ([#409](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/409)) ([e24a5a5](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/e24a5a5f9594feff49ceec2235e880e17c74098d))

## [10.1.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v10.0.0...v10.1.0) (2024-01-16)


### Features

* Add Server TLS Policy parameter ([#387](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/387)) ([c553947](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/c553947cbaad01ab8e8b1a837be60092bc3c10fa))
* Added support for locality_lb_policy ([#392](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/392)) ([0127723](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/012772310a18c2198cbd96776fd2e218e5f29d2a))

## [10.0.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v9.3.0...v10.0.0) (2023-11-17)


### ⚠ BREAKING CHANGES

* Fix certificate map issue. Allow adding different types of certificates together. ([#382](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/382))

### Features

* add bypass_cache_on_request_headers to cdn_policy ([#385](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/385)) ([e91961b](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/e91961bedb997bf9c47f3a963149267b365490d6))


### Bug Fixes

* Fix certificate map issue. Allow adding different types of certificates together. ([#382](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/382)) ([d1c89b9](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/d1c89b987b3fa12e4a3cc4dcd52f076b792d6471))
* Invalid variable name in outlier_detection block ([#381](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/381)) ([34fbda9](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/34fbda928d4c03a11ffaefeb9c12e1b5019d7a08))

## [9.3.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v9.2.0...v9.3.0) (2023-11-06)


### Features

* Added support for google_compute_backend_service outlier_detection ([#365](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/365)) ([8554cd0](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/8554cd0f0b56b1ee2976f82770d15eefef09c2f5))

## [9.2.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v9.1.0...v9.2.0) (2023-08-24)


### Features

* Add project for backend service and health check for cross project reference ([#345](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/345)) ([e2b77ed](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/e2b77ed4dde5167d7d355399640e55438b7dea12))
* Add support for TCP healthcheck ([#346](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/346)) ([ddddf32](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/ddddf32b4ba8431d2392e16df1c7073600a72d8e))
* Decouple health check protocol ([#349](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/349)) ([f04d9bb](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/f04d9bbae95faf09f87ef1ed6896af957fbdd3b3))

## [9.1.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v9.0.0...v9.1.0) (2023-06-21)


### Features

* Set edge_security_policy optional and add session_affinity in variables ([#333](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/333)) ([853ccba](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/853ccba8c93971cb1eebea4a36de3e0a89eacf8e))

## [9.0.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v8.0.0...v9.0.0) (2023-04-14)


### ⚠ BREAKING CHANGES

* Fix result of var.quic to match the current behaviour on GCP ([#318](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/318))
* **TPG >= 4.50:** Adding edge_security_policy ([#311](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/311))

### Features

* added network for INTERNAL_SELF_MANAGED load balancing schema ([#320](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/320)) ([7226353](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/722635370e77b865cc7daf120facebc98e458e1a))
* added session affinity for serverless neg ([#319](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/319)) ([e9da266](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/e9da266bb8c13445b6df594b5183da07e543ccbe))
* **TPG >= 4.50:** Adding edge_security_policy ([#311](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/311)) ([f769bf7](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/f769bf741aa85db3f842b6649997b5cb4738e478))


### Bug Fixes

* fix description of var load_balancing_scheme ([#314](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/314)) ([5655ad9](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/5655ad9b483fd0f31d17c0eaebbed76a2920e69d))
* Fix result of var.quic to match the current behaviour on GCP ([#318](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/318)) ([00b5d2f](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/00b5d2f538dee08a13efd1902d9385f5fc8d444c))

## [8.0.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v7.0.0...v8.0.0) (2023-03-31)


### ⚠ BREAKING CHANGES

* add cdn_policy configuration block for backend_service ([#301](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/301))

### Features

* add cdn_policy configuration block for backend_service ([#301](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/301)) ([7aaaa39](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/7aaaa39bc36e140d47ca90888d3830f3d622a86f))


### Bug Fixes

* Support https frontends with certificate_map ([#305](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/305)) ([bf7a9a6](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/bf7a9a63e0bf1a8c3361ef37aab0811f4d034846))

## [7.0.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v6.3.0...v7.0.0) (2023-01-26)


### ⚠ BREAKING CHANGES

* add support for https only procotol in NEG backend service ([#287](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/287))
* add support for compression_mode ([#281](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/281))

### Features

* add support for compression_mode ([#281](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/281)) ([7f30d88](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/7f30d88580b289e31090e9529fc6955841892431))
* add support for https only procotol in NEG backend service ([#287](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/287)) ([f62d329](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/f62d329e88ddcf57ba4bf9e129d5911ecb0923f7))
* added certificate manager support ([#294](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/294)) ([319f416](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/319f4165548188dfdf15830c0ddccda339ccf08e))
* Implement Envoy-based load balancing schemes ([#269](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/269)) ([125bf68](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/125bf688fe88f07f1db4b942a13139e0f63ee8ec))


### Bug Fixes

* fixes lint issues and generates metadata ([#289](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/289)) ([1394f25](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/1394f259ced8cf1115bc83d1bb897a0e52f4ff64))
* plumb backend values, upgrade guide ([#296](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/296)) ([228b59c](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/228b59c55cd87774d411e808d638b84ea54bd60f))

## [6.3.0](https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v6.2.0...v6.3.0) (2022-07-29)


### Features

* Adds support for labels ([#250](https://github.com/terraform-google-modules/terraform-google-lb-http/issues/250)) ([b09bef9](https://github.com/terraform-google-modules/terraform-google-lb-http/commit/b09bef91e6a937bf1e026a9864208a610f774530))

## [6.2.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v6.1.1...v6.2.0) (2021-11-24)


### Features

* update TPG version constraints to allow 4.0 ([#218](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/218)) ([cf6a156](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/cf6a1566309b9080be8941194ba2ba7726b8a71f))

### [6.1.1](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v6.1.0...v6.1.1) (2021-10-13)


### Bug Fixes

* Make log_config optional ([#209](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/209)) ([4ed360e](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/4ed360e21d8872e0ba078de035e1ce856fd8ec6e))

## [6.1.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v6.0.1...v6.1.0) (2021-08-23)


### Features

* add url_map as output ([#203](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/203)) ([2ea30e4](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/2ea30e4af957c8154920fc3ab6222993aeda04ea))

### [6.0.1](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v6.0.0...v6.0.1) (2021-07-12)


### Bug Fixes

* Create the `random_id.certificate` resource only when needed. ([#184](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/184)) ([7190e4e](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/7190e4e6d08a004db0345892c2e5951d0c59db0e))

## [6.0.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v5.1.1...v6.0.0) (2021-07-07)


### ⚠ BREAKING CHANGES

* `backends` variable now accepts `custom_response_headers`. Set `custom_response_headers = null` to preserve existing behavior.

### Features

* Add support for appending a random suffix to certificate names by setting `var.random_certificate_suffix` ([#160](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/160)) ([058549a](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/058549aa6db2eba2dfca4018b2708f2b188c0fe6))
* Implement custom response headers ([#154](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/154)) ([e561eae](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/e561eae637ca5a39a9d734aad28f754451af5284))

### [5.1.1](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v5.1.0...v5.1.1) (2021-05-27)


### Bug Fixes

* Mark output derived from possible sensitive attribute as sensitive ([#167](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/167)) ([386bc89](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/386bc8959c85e8cd06d2c3e49ffc8671763ead5e))

## [5.1.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v5.0.0...v5.1.0) (2021-05-11)


### Features

* Add support for dual-stack IP addresses: IPv4 + IPv6. ([#116](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/116)) ([a39aac4](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/a39aac4c0f78ba23a4026b612498cf69a7e77605))


### Bug Fixes

* Expose ipv6_enabled boolean flag as module output  ([#166](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/166)) ([8dd0d26](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/8dd0d263bd9400fe1e3c1144b01c4177677cda20))

## [5.0.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v4.5.0...v5.0.0) (2021-03-30)


### ⚠ BREAKING CHANGES

* add Terraform 0.13 constraint and module attribution (#157)

### Features

* add Terraform 0.13 constraint and module attribution ([#157](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/157)) ([447611b](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/447611bb9b71d886004e8e2d1cfdd1cd8f648367))


### Bug Fixes

* Add centos 7 source image ([#148](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/148)) ([a98025b](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/a98025bfb034eb1424b68764fb0f8434aa841790))

## [4.5.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v4.4.0...v4.5.0) (2020-11-25)


### Features

* Add managed SSL certificates support ([#135](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/135)) ([7b547d9](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/7b547d9decc1ce3747eac872c732f0f04e78d63b))
* Added Serverless NEGs submodule ([#136](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/136)) ([871b575](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/871b5755a21b58ef332895f188e4f1cc5dca9890))
* Update per-backend security_policy fallback to variable ([#132](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/132)) ([d726501](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/d72650160191a24c97e5d09b8ea3cd28057c3f11))


### Bug Fixes

* Add health-check prober port for checked backends to hc-firewall ([#143](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/143)) ([5acae1e](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/5acae1ead46796303711e7cf9f921d496f15ecd0))
* Fix syntax in example code block ([#137](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/137)) ([4e43deb](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/4e43deb0cf5f2071de355c104b2ca04dc97591dd))

## [4.4.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v4.3.0...v4.4.0) (2020-10-26)


### Features

* Allow configuring security policies per backend ([#115](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/115)) ([ad92b2e](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/ad92b2ece0b8ae3a3e832547c5d69b41a54ff45f))


### Bug Fixes

* Clarify explanation for ssl_certificates ([#128](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/128)) ([8536620](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/85366208fa3451d7c060688a61d50bf16188fc76))

## [4.3.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v4.2.0...v4.3.0) (2020-10-05)


### Features

* Add IAP support to load balancer ([#99](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/99)) ([2421fcb](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/2421fcb98a6ddf3a4da10accae0d70316420078e))
* Add support for configuring `custom_request_headers`  ([#122](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/122)) ([0136c65](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/0136c65dfceafcd468bfb907551cbebb016204d9))
* Added HTTPS redirection support ([#111](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/111)) ([ba0bf1f](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/ba0bf1ff86d0e8a13ad1330944550db67f8e725d))

## [4.2.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v4.1.0...v4.2.0) (2020-07-30)


### Features

* Make health checks optional to support global NEG backend services ([#106](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/106)) ([e0ea139](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/e0ea13967ed324bfd19f7ce3c9659bc1509372e0))

## [4.1.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v4.0.0...v4.1.0) (2020-05-05)

### Features

* Add health check logging support ([#98](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/98)) ([f2b8f3c](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/f2b8f3caf49a5ad06522d703d1ba1a101c561bb7))

## [4.0.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v3.2.0...v4.0.0) (2020-04-21)

Please see the [upgrade guide](./docs/upgrading_to_v4.0.md) for details.

### ⚠ BREAKING CHANGES

* `session_affinity` and `affinity_cookie_ttl_sec` must now be set for backends. Use `null` to get the default value.
* You must now specify log_config for each backend service. Use `log_config = {}` to use the default.

### Features

* Add support for log_config in google_compute_backend_service. ([#88](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/88)) ([f5129ef](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/f5129ef91fdcf1ed19200ee6542f251cc701ab67))
* Add support for session affinity on HTTP(S) LB ([#89](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/89)) ([bf1cf66](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/bf1cf66ba989af2d622dead9428b7a2b046fb594))
* Add support for target_service_accounts in default firewall rule. ([#87](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/87)) ([0ea26a2](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/0ea26a2391d89cb906d91918c03a278eb9ed653a))

## [3.2.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v3.1.0...v3.2.0) (2020-02-13)

### Features

* Add submodule which ignores changes to backend group ([#81](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/81)) ([d8d3e33](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/d8d3e33dc3a128c8790476d44ae45f8465f9fa51))

## [3.1.0](https://www.github.com/terraform-google-modules/terraform-google-lb-http/compare/v3.0.0...v3.1.0) (2020-01-28)

### Features

* Allow 3.x google provider ([#77](https://www.github.com/terraform-google-modules/terraform-google-lb-http/issues/77)) ([650d639](https://www.github.com/terraform-google-modules/terraform-google-lb-http/commit/650d639beba895dabbaeb312090d013fde9a68bd))

## [3.0.0] - 2019-12-16

### Added

- QUIC protocol support [#57]
- Container Native Load Balancing support via NEGs [#57]
- Allow existing IP address to be used [#25]
- Allow setting a SSL Policy to restrict TLS/Ciphers
- Add http/https target proxies to output to allow binding multiple IPs

### Changed

- Update minimum terraform version to 0.12.6
- Update google providers to 2.15
- Move to using `for_each` for state management [#57]
- Move backend variables from list into map/object [#54]
- Allow HTTPS/HTTP2 health checks with custom host/timeouts/thresholds [#34] [#31]
- `backend_services` output is now a map of `google_compute_backend_service` resources rather then a list of URIs

## [2.0.0] - 2019-10-21

### Added

- Support for Terraform 0.12. [#51] [#56]

### Removed

- Support for Terraform 0.11. [#51]
- Unused `region` variable. [#61]

## [1.0.10] - 2018-09-26

## [1.0.9] - 2018-09-06

## [1.0.8] - 2018-07-12

## [1.0.7] - 2018-07-09

## [1.0.6] - 2018-06-25

## [1.0.5] - 2018-02-13

## [1.0.4] - 2017-10-16

## [1.0.3] - 2017-09-20

## [1.0.2] - 2017-09-18

## [1.0.1] - 2017-09-12

## [1.0.0] - 2017-08-23

[Unreleased]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.10...v2.0.0
[1.0.10]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.9...1.0.10
[1.0.9]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.8...1.0.9
[1.0.8]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.7...1.0.8
[1.0.7]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.6...1.0.7
[1.0.6]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.5...1.0.6
[1.0.5]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/terraform-google-modules/terraform-google-lb-http/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/terraform-google-modules/terraform-google-lb-http/releases/tag/1.0.0

[#54]: https://github.com/terraform-google-modules/terraform-google-lb-http/pull/54
[#57]: https://github.com/terraform-google-modules/terraform-google-lb-http/pull/57
[#61]: https://github.com/terraform-google-modules/terraform-google-lb-http/pull/61
[#56]: https://github.com/terraform-google-modules/terraform-google-lb-http/pull/56
[#53]: https://github.com/terraform-google-modules/terraform-google-lb-http/issues/53
[#51]: https://github.com/terraform-google-modules/terraform-google-lb-http/issues/51
[#31]: https://github.com/terraform-google-modules/terraform-google-lb-http/issues/31
[#34]: https://github.com/terraform-google-modules/terraform-google-lb-http/issues/34
[#25]: https://github.com/terraform-google-modules/terraform-google-lb-http/issues/25
