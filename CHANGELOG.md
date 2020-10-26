# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
