# Anvil Product Requirements Document

**Status:** Draft
**Version:** 0.1
**Date:** 2026-07-18
**Project:** Anvil
**License target:** MIT
**Runtime target:** Roblox Luau
**Distribution target:** Wally

## 1. Product Summary

Anvil is a Rust-inspired foundation package for reliable Roblox Luau systems. It removes repeated gameplay plumbing while preserving explicit domain logic.

Anvil focuses on five Roblox-specific problems:

1. unsafe client-to-server boundaries;
2. unstructured expected failures;
3. leaked connections, tasks, and Instances;
4. inconsistent action lifecycle;
5. difficult deterministic testing.

Anvil is not a new programming language and does not claim Rust-level compile-time ownership. It applies Rust principles through Luau strict typing, runtime schemas, explicit scopes, server authority, typed results, and predictable runtime cost.

## 2. Problem

Roblox projects repeatedly implement the same infrastructure:

- RemoteEvent and RemoteFunction plumbing;
- payload validation;
- cooldown and rate limiting;
- authorization checks;
- player and character cleanup;
- expected success/failure results;
- action lifecycle;
- test doubles for Player, clock, transport, and persistence.

Existing packages solve individual parts. Knit provides a service/controller model but is archived. Nevermore provides a large reusable ecosystem. Trove/Janitor solve cleanup. Promise solves async control flow. ByteNet/Remo/RbxNet solve networking. Scribe solves typed persistence and replication.

Anvil must not duplicate those packages by default. It must provide a cohesive contract layer that can work alone or through adapters.

## 3. Vision

Make reliable Roblox gameplay code feel as deliberate as Rust code:

- explicit success and failure;
- explicit ownership and cleanup;
- explicit server authority;
- typed contracts at boundaries;
- deterministic tests;
- useful diagnostics;
- no hidden background work.

## 4. Goals

### G1. Safe action boundaries

A developer can define one server-authoritative action with input schema, cooldown, rate limit, authorization, execution, and structured result.

### G2. Explicit resource ownership

Connections, tasks, Instances, and child scopes can be attached to a scope and cleaned up deterministically.

### G3. Typed and runtime-safe contracts

Static Luau types help development. Runtime schemas protect untrusted boundaries.

### G4. Predictable failure handling

Expected gameplay failures use typed `Result` values. Programmer faults remain visible errors.

### G5. Minimal overhead

Disabled diagnostics and optional features must not create permanent loops, hidden polling, or avoidable allocations on hot paths.

### G6. Testable gameplay

Core actions can be tested without live DataStore, real RemoteEvents, or uncontrolled wall-clock timing.

### G7. Adapter-friendly ecosystem

Anvil can use existing packages such as ByteNet, Remo, Replica, ProfileStore, Scribe, Fusion, and Trove without making any of them mandatory.

## 5. Non-goals

Anvil will not:

- implement a borrow checker;
- replace Luau or Roblox Studio;
- replace Wally, Rojo, or Luau LSP;
- replace ProfileStore, Scribe, Replica, Fusion, Promise, Trove, or ByteNet;
- own a cloud backend in the initial product;
- provide automatic gameplay design;
- perform arbitrary transaction rollback for physics or external side effects;
- hide all Roblox networking behind uninspectable magic;
- create a mandatory global singleton;
- scan the entire Workspace every frame.

## 6. Target Users

### Primary

- Luau developers using Rojo and Wally;
- small and medium Roblox teams;
- developers building server-authoritative gameplay;
- developers migrating from ad-hoc RemoteEvent handlers;
- developers who want strict Luau without adopting TypeScript.

### Secondary

- teams using ProfileStore/Scribe with custom gameplay actions;
- framework authors needing action, scope, or Result primitives;
- educators teaching safe Roblox architecture.

## 7. Product Principles

1. **Server owns truth.** Client sends intent, never authority.
2. **Explicit beats magical.** Generated convenience must remain inspectable.
3. **Boring beats clever.** Prefer small data structures and direct control flow.
4. **No hidden work.** No permanent heartbeat, polling, or implicit replication.
5. **Adapters over forks.** Integrate existing libraries instead of copying them.
6. **Static plus runtime safety.** `--!strict` cannot replace boundary validation.
7. **Fail closed at trust boundaries.** Invalid input must not reach domain execution.
8. **Measured performance.** Claims require benchmarks.
9. **Stable contracts.** API changes require migration notes.
10. **Small core.** Optional features remain separately loadable.

## 8. Initial Scope

### Required modules

- `Result` and structured `Error`;
- runtime `Schema` validation;
- `Scope` ownership and cleanup;
- server-authoritative `Action` pipeline;
- cooldown;
- rate limit;
- authorization hook;
- default Roblox transport;
- deterministic test helpers;
- strict Luau types.

### Initial action pipeline

```text
receive
  -> decode
  -> validate
  -> normalize
  -> rate limit
  -> cooldown
  -> authorization
  -> execute
  -> normalize Result
  -> respond
```

Only validated input reaches `execute`.

## 9. Deferred Scope

### Release 0.2+

- optional Player and Character lifecycle Scope helpers with no game-domain policy;
- audit hooks with no default telemetry;
- fake clock, fake transport, and fake Player fixture;
- Result combinators;
- transaction for explicitly Anvil-managed server mutations.

### Release 0.3+

- adapter contract and isolated integration-test kit;
- optional transport adapters such as ByteNet and Remo;
- optional state and persistence adapters such as Replica, ProfileStore, and Scribe;
- optional cleanup adapter such as Trove;
- generated client/server contracts.

### Separate projects

- Rust-based `anvil` CLI;
- Studio diagnostics plugin;
- static architecture analyzer;
- cloud telemetry.

## 10. Functional Requirements

### FR-001 Result

`Result<T, E>` must narrow correctly under `--!strict` using a discriminant such as `ok: true | false`.

### FR-002 Schema

Schemas must validate primitive values, nested objects, arrays, optional fields, unions, Roblox datatypes, and bounded strings/numbers.

Schemas must return path-aware errors and reject unexpected fields by default for network payloads.

### FR-003 Scope

A scope must support connection cleanup, task cancellation, Instance cleanup, deferred cleanup, child scopes, idempotent destruction, and use-after-destroy diagnostics in development mode.

### FR-004 Action

An action must support input schema, cooldown, rate limit, authorization, server execution, structured result, and transport response.

### FR-005 Server authority

Client-provided values must be treated as untrusted. Anvil must not authorize or mutate state from client payload without explicit server code.

### FR-006 Testability

Test helpers must allow deterministic clock, transport, player, and random source injection.

### FR-007 Optional dependencies

Core must run without ByteNet, Remo, Replica, ProfileStore, Scribe, Fusion, Promise, or Trove.

### FR-008 Runtime cost

With diagnostics disabled, Anvil must not create a global Heartbeat loop or per-frame scanner.

## 11. Acceptance Criteria

Anvil 0.1 is complete only when all are true:

- invalid payload never reaches action execution;
- unexpected fields are rejected by default;
- cooldown is enforced server-side;
- rate limit is enforced server-side;
- authorization runs before mutation;
- a destroyed scope disconnects owned connections;
- a destroyed scope cancels owned scheduled tasks where Roblox permits cancellation;
- repeated `destroy()` is safe;
- Result success/failure narrows under strict Luau;
- errors contain stable code and field/path where applicable;
- actions can run with a fake transport in tests;
- synchronous actions do not require Promise allocation;
- disabled diagnostics do not start background loops;
- benchmark compares manual handler and Anvil handler;
- README contains installation, quick start, security model, lifecycle model, and limitations;
- MIT license and changelog exist before first public release.

## 12. Success Metrics

Technical:

- 100% of public 0.1 APIs covered by behavior tests;
- zero known unbounded loops in core;
- zero mandatory runtime dependencies;
- deterministic benchmark and test commands;
- no critical server-authority bypass in review.

Developer experience:

- first action works with one package and one bootstrap;
- invalid payload error identifies field and reason;
- migration from a manual RemoteEvent action requires only domain handler movement;
- documentation examples use `--!strict`.

## 13. Risks

| Risk | Mitigation |
| --- | --- |
| Framework bloat | Keep 0.1 to Result, Schema, Scope, Action, tests |
| Hidden overhead | Benchmark diagnostics-off path |
| False Rust claims | Document Luau limitations explicitly |
| Adapter incompatibility | Define narrow interfaces and integration tests |
| Unsafe Instance payloads | Require explicit Instance policy in schemas |
| Scope misuse | Idempotent cleanup and development diagnostics |
| API churn | Freeze 0.1 public API before adapters |
| Competitor overlap | Win on cohesive Roblox contracts, not copied utilities |

## 14. Open Decisions

- default transport API shape;
- whether default action calls return Result directly or Promise only for async handlers;
- array schema semantics;
- transaction mutation representation;
- package naming on Wally;
- whether adapters live in the main repository or separate repositories.

These decisions must be resolved before 0.1 implementation freeze.
