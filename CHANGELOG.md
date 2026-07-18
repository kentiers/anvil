# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versioning follows Semantic Versioning.

## [Unreleased]

### Added

- Server-only `Action` pipeline with schema validation, deterministic cooldowns, token-bucket rate limits, authorization, output validation, and structured `Result` values.
- Caller-owned `RemoteEvent` and `RemoteFunction` transport binding with safe client failure responses and per-request scope cleanup.
- Deterministic Action, cooldown, rate-limit, authorization, output, and transport dispatch behavior tests.

### Changed

- Wally package realm is `server`; Action and transport code is no longer mapped to `ReplicatedStorage` in test places.

### Security

- Raw remote payloads cannot reach action execution before schema validation.
- Transport responses expose only stable error codes for failures.
