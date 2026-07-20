# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versioning follows Semantic Versioning.

## [Unreleased]

### Added
- Optional adapters for ByteNet, Remo, Replica, ProfileStore, Scribe, and Trove; caller ownership preserved and core remains dependency-free.

### Changed

### Fixed


## [0.2.0] - 2026-07-18

### Added

- `Anvil.Test.FakeClock` for deterministic, monotonic time in test code.
- `Anvil.Lifecycle.PlayerScope` and `Anvil.Test.FakePlayer`/`FakeSignal` for deterministic native lifecycle tests.
- `Anvil.ErrorCode`, frozen constants for every stable Anvil-emitted Action and Schema error code.
- `Anvil.Test.FakeTransport` plus opt-in Scope lifecycle audit events for deterministic remote binding and development diagnostics.

## [0.1.3] - 2026-07-18

### Changed

- Rewrite public README, security policy, repository metadata, and roadmap status for the released package.

### Security

- Add private vulnerability-reporting policy and production integration checklist.

## [0.1.2] - 2026-07-18

### Fixed

- Correct server-realm Wally package path in the consumer fixture and installation quick start.

## [0.1.1] - 2026-07-18

### Fixed

- Correct Wally installation guidance and consumer fixture to use server dependencies for the server-realm package.

## [0.1.0] - 2026-07-18

### Added

- Server-only `Action` pipeline with schema validation, deterministic cooldowns, token-bucket rate limits, authorization, output validation, and structured `Result` values.
- Caller-owned `RemoteEvent` and `RemoteFunction` transport binding with safe client failure responses and per-request scope cleanup.
- Deterministic Action, cooldown, rate-limit, authorization, output, and transport dispatch behavior tests.
- Roblox datatype schemas for `Vector3`, `CFrame`, `Color3`, and constrained `EnumItem` values.
- Explicit `Schema.instance` class and ancestry policy; finite-number validation now rejects infinity.

### Changed

- Wally package realm is `server`; Action and transport code are no longer mapped to `ReplicatedStorage` in test places.
- Wally package root now uses its standard `default.project.json` source mapping.

### Security

- Raw remote payloads cannot reach action execution before schema validation.
- Transport responses expose only stable error codes for failures.
