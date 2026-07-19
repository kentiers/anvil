# Anvil Architecture Decisions

**Status:** Draft

## ADR-001 — Native Luau Runtime

**Decision:** Write Anvil's Roblox runtime package in native Luau.

**Reason:** Wally and Roblox execute Luau ModuleScripts. Rust cannot be a direct runtime dependency inside Roblox.

**Consequence:** Rust may be used later for CLI, static analysis, and code generation. Rust is not required to install or run Anvil in a game.

## ADR-002 — No Borrow Checker Claim

**Decision:** Implement explicit scope ownership and lifecycle diagnostics, not a simulated Rust borrow checker.

**Reason:** Luau is garbage-collected and has no ownership or borrowing language feature. A runtime imitation would create false confidence.

**Consequence:** Anvil documents lifecycle guarantees and limitations explicitly.

## ADR-003 — Result for Expected Failures

**Decision:** Expected gameplay failures return typed discriminated `Result` values. Programmer faults remain thrown errors.

**Reason:** This matches Rust's useful distinction without hiding bugs as ordinary gameplay failures.

## ADR-004 — Schemas at Trust Boundaries

**Decision:** Runtime schemas validate network payloads on the server. Static Luau types remain a development aid.

**Reason:** Luau types do not exist as runtime validation for untrusted client data.

## ADR-005 — Adapters Over Bundled Replacements

**Decision:** Integrate ByteNet, Remo, Replica, ProfileStore, Scribe, Fusion, and Trove through optional adapters.

**Reason:** Replacing mature packages would increase scope and dependency conflict. Anvil's value is its contract/lifecycle layer.

## ADR-006 — No Mandatory Promise

**Decision:** Synchronous action execution returns `Result` without Promise allocation. Promise integration remains optional.

**Reason:** Avoid unnecessary allocation and preserve compatibility with both synchronous and asynchronous code.

## ADR-007 — Explicit Scope Ownership

**Decision:** Resources are cleaned only when explicitly registered with a `Scope`.

**Reason:** Automatic ownership inference is unsafe and would hide cost. Explicit registration is reviewable.

## ADR-008 — Runtime First, Tooling Later

**Decision:** Stabilize the Wally package before building Rust CLI or Studio tooling.

**Reason:** Tooling must consume a stable contract. Building CLI first would freeze assumptions too early.

## ADR-009 — External Development Toolchain

**Decision:** Use Rokit-managed Rojo, Wally, StyLua, Selene, and Luau LSP for development and CI. Use Graphify only as optional local repository exploration tooling.

**Reason:** These tools solve distinct needs: project mapping, package installation, formatting, linting, and strict type analysis. Graphify builds a knowledge graph for exploration; it is not a correctness gate and must not replace type checks, tests, or security review.

**Consequence:** Tool versions are pinned in `rokit.toml`. Generated `sourcemap.json` and `graphify-out/` stay ignored. Anvil runtime keeps zero mandatory third-party dependencies.

## ADR-010 — Domain-Neutral Package

**Decision:** Anvil remains a reusable Roblox foundation package. Game-specific domain names and rules belong in consumer projects and adapters, not Anvil core.

**Reason:** Anvil is distributed publicly through Wally for unrelated Roblox games. Core contracts solve infrastructure problems without encoding consumer gameplay assumptions.

**Consequence:** Tests and documentation use neutral fixtures. Game-specific examples stay in separate consumer examples or integration projects.

## ADR-011 — TestEZ in Real Roblox Studio

**Decision:** Run TestEZ tests through `run-in-roblox` against a Rojo-built place. TestEZ remains a Wally development dependency and never enters Anvil runtime dependencies.

**Reason:** Core modules use Luau syntax and Roblox instance paths. Lemur-based execution does not faithfully execute that environment. Real Studio tests provide correct Luau behavior and actionable failure output.

**Consequence:** Local test commands require Roblox Studio. GitHub-hosted CI runs static checks only because Studio installation and plugin execution require an interactive desktop session. `scripts/test.ps1` translates TestEZ's `failureCount` into a nonzero process exit code.

## ADR-012 — Opt-In Lifecycle Audit

**Decision:** `Scope` accepts an optional lifecycle audit hook. It emits only destruction and use-after-destroy events, and has no configured default reporter.

**Reason:** Development diagnostics need deterministic, inspectable events without starting telemetry, polling, or a global singleton in production.

**Consequence:** Audit event allocation occurs only when a caller supplies a hook. Callers keep reporting server-side and enable it only for development diagnostics.