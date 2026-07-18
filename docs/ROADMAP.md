# Anvil Roadmap

**Status:** Draft
**Version:** 0.1

## Roadmap Rules

- No phase is complete without tests and evidence.
- No public API is promised before the release gate passes.
- New features require a documented Roblox-specific problem.
- Rust CLI and Studio plugin remain after runtime API stability.
- Performance claims require repeatable benchmarks.

## Phase 0 — Contract and Prototype

### Deliverables

- package name `Anvil` confirmed;
- MIT license;
- `--!strict` conventions;
- Result prototype;
- Schema prototype;
- Scope prototype;
- Action pipeline prototype;
- test harness decision;
- benchmark harness decision.

### Exit gate

- public API review complete;
- trust-boundary ordering documented;
- no mandatory dependency selected;
- unresolved API decisions listed and assigned.

## Phase 1 — Core 0.1.0

### Deliverables

- `Result` and structured `Error`;
- `Schema` primitives, objects, arrays, optionals, unions;
- Roblox datatype schemas;
- `Scope` cleanup;
- default RemoteEvent/RemoteFunction transport;
- `Action` pipeline;
- cooldown;
- rate limiting;
- authorization hook;
- strict public types;
- TestEZ-compatible tests;
- README quick start;
- security model;
- limitations;
- changelog.

### Exit gate

- invalid payload never reaches execute;
- unknown fields rejected by default;
- cooldown and rate limit tested server-side;
- scope cleanup tested;
- all public modules pass strict analysis;
- manual-handler benchmark recorded;
- no critical security findings;
- clean install in a fresh Rojo/Wally sample project.

## Phase 2 — Reliability 0.2.0

### Deliverables

- player scope helper;
- character scope helper;
- Result combinators;
- fake clock;
- fake transport;
- fake player fixture;
- development lifecycle diagnostics;
- audit hooks;
- stable error catalog.

### Exit gate

- respawn lifecycle test passes;
- player removal lifecycle test passes;
- use-after-destroy diagnostics work;
- deterministic cooldown tests pass;
- error codes documented.

## Phase 3 — Integration 0.3.0

### Deliverables

- ByteNet adapter;
- Remo adapter;
- Replica adapter;
- ProfileStore adapter;
- Scribe adapter;
- Trove adapter;
- adapter examples kept outside core package behavior.

### Exit gate

- each adapter has isolated integration tests;
- core remains usable without adapters;
- no adapter changes core action semantics;
- failure behavior documented per adapter.

## Phase 4 — Transactions and Replay 0.4.0

### Deliverables

- Anvil-managed mutation transaction;
- compensation hooks for external effects;
- deterministic replay record;
- stable request IDs;
- action audit record;
- fake RNG and fake clock integration.

### Exit gate

- failed managed mutation rolls back;
- external side effects are never falsely claimed rolled back;
- replay produces same Result for deterministic fixtures;
- transaction tests cover partial failure.

## Phase 5 — Generated Contracts 0.5.0

### Deliverables

- action contract export;
- generated client/server Luau types;
- schema documentation output;
- duplicate action detection;
- generated API diff.

### Exit gate

- generated output passes strict analysis;
- generated files are deterministic;
- source-to-generated mapping is documented;
- stale generated output is detected.

## Phase 6 — `anvil` CLI 0.6.0

Rust tool, separate from runtime package.

### Deliverables

```text
anvil init
anvil check
anvil generate
anvil test
anvil doctor
```

Initial implementation may shell out to existing tools rather than replace them.

### Exit gate

- Windows support;
- CI exit codes;
- readable diagnostics;
- no requirement for CLI in runtime package;
- reproducible install instructions.

## Phase 7 — Studio Plugin 0.7.0

### Deliverables

- action inspector;
- schema error viewer;
- scope leak viewer;
- replay viewer;
- runtime diagnostics panel;
- source navigation;
- export report.

### Exit gate

- plugin is optional;
- plugin never mutates project without explicit action;
- large projects remain responsive;
- plugin consumes stable Anvil diagnostic format.

## Deferred or Rejected

- borrow checker implementation in Luau;
- custom programming language;
- Rust-to-Luau compiler as core path;
- mandatory global service container;
- mandatory Promise dependency;
- automatic arbitrary rollback;
- cloud dashboard before local diagnostics prove value;
- full UI framework;
- full persistence framework;
- automatic exploit detection claims.

## Release Checklist

- [ ] API documented
- [ ] strict types pass
- [ ] behavior tests pass
- [ ] integration tests pass
- [ ] benchmark recorded
- [ ] security review completed
- [ ] examples run in fresh project
- [ ] changelog updated
- [ ] migration notes written
- [ ] license included
- [ ] Wally metadata verified
- [ ] no hidden runtime loops
