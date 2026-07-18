# AGENTS.md

## Mission

Anvil is a Rust-inspired foundation package for reliable Roblox Luau systems.

Core principles:

- server authority;
- explicit contracts;
- typed boundaries;
- explicit resource ownership;
- deterministic tests;
- predictable runtime cost;
- adapter-based integrations;
- boring, maintainable code.

Anvil does not claim Rust-level borrow checking or memory safety. It applies useful Rust principles through Luau types, runtime schemas, `Result`, `Scope`, testing, and diagnostics.

## Instruction Priority

Resolve conflicts in this order:

1. system and developer instructions;
2. this file and more-specific nested `AGENTS.md` files;
3. `docs/PRD.md`;
4. `docs/ARCHITECTURE.md`;
5. `docs/SECURITY.md`;
6. `docs/DECISIONS.md`;
7. `docs/ROADMAP.md`;
8. issue, PR, or task description;
9. existing implementation conventions.

Never silently shrink requested scope. Record unresolved architecture decisions in `docs/DECISIONS.md`.

## Repository Layout

```text
src/
  Anvil.luau
  Core/
  Schema/
  Action/
  Transport/
  Test/
  Adapters/

test/
  unit/
  integration/

examples/
docs/
benchmarks/
tools/
```

Rules:

- runtime code uses Luau;
- public modules use `--!strict`;
- Rust is reserved for future CLI, static analysis, and code generation;
- adapters remain optional;
- server-only code never enters client-visible locations;
- secrets never enter source, fixtures, examples, or logs.

## Rust Philosophy

Preserve these ideas:

- typed `Result<T, E>`;
- explicit `Scope` ownership;
- server authority;
- runtime schemas at trust boundaries;
- deterministic tests;
- structured diagnostics;
- predictable performance;
- explicit adapters;
- no hidden background work.

Do not implement or claim:

- a Luau borrow checker;
- compile-time ownership;
- Rust-level memory safety;
- arbitrary rollback of Roblox physics or external effects;
- automatic exploit prevention.

## Dependency Policy

Anvil core has zero mandatory third-party dependencies.

Allowed:

- Roblox native APIs;
- Luau language features;
- optional adapter dependencies;
- test-only dependencies.

Forbidden:

- copying Trove, Janitor, Promise, ByteNet, ProfileStore, Replica, Fusion, or similar code into core;
- adding a dependency when correct native code is small enough;
- forcing one transport or persistence provider;
- adding a dependency without license, maintenance, size, and runtime review.

Every dependency proposal answers:

```text
Why is it needed?
Why is native code insufficient?
Why is an existing package insufficient?
What runtime cost does it add?
What license and maintenance risks exist?
Can it expose server-only code?
```

## API Rules

Public API must be:

- strict typed;
- minimal;
- explicit;
- deterministic;
- documented;
- backward-compatible within a supported release line.

Required:

- stable error codes;
- path-aware validation errors;
- idempotent cleanup;
- raw client payload never reaching domain execution;
- no Promise allocation for synchronous `Result`;
- no mandatory global singleton;
- no hidden network creation;
- no implicit state mutation.

Avoid:

- excessive builder chains;
- magic auto-discovery;
- reflection on hot paths;
- hidden retries;
- broad catch-and-ignore behavior;
- automatic code mutation;
- abstractions with one caller and no measured value.

## Security Rules

Treat clients, client payloads, and client-visible Instances as untrusted.

Every client-originated action follows:

```text
receive
  -> decode
  -> schema validation
  -> normalization
  -> rate limit
  -> cooldown
  -> authorization
  -> domain execution
  -> safe response
```

Never trust client values for:

- currency;
- inventory;
- ownership;
- entitlement;
- reward;
- cooldown;
- damage;
- admin permission;
- server-selected price;
- final placement result.

Client-facing errors must not expose:

- stack traces;
- DataStore keys;
- secrets;
- full profiles;
- private moderation data.

Anvil is not an anti-cheat system. Domain code remains responsible for game rules.

## Lifecycle Rules

Every owned resource has a visible owner:

- `RBXScriptConnection`;
- scheduled thread;
- Instance;
- subscription;
- callback registration;
- child scope.

Preferred pattern:

```lua
local scope = Scope.new("Player", player)

scope:connect(connection)
scope:own(thread)
scope:own(instance)
scope:destroy()
```

Rules:

- destruction is idempotent;
- children are destroyed before parents complete;
- owned connections disconnect;
- owned cancellable tasks use `task.cancel` where Roblox permits it;
- no unowned recurring task;
- no permanent polling loop;
- no automatic ownership inference;
- development mode may report leaks and use-after-destroy;
- production diagnostics stay bounded or disabled.

## Performance Rules

Do not optimize by guessing.

Non-trivial runtime changes require:

- relevant benchmark;
- manual baseline comparison;
- diagnostics-on and diagnostics-off measurement;
- allocation and complexity notes;
- realistic payload sizes.

For every non-trivial change, review source fit, trust-boundary impact, lifecycle ownership, hot-path allocations, and time complexity before merge. Record a benchmark or rule only for observed recurring risk; do not encode speculative preferences.

Forbidden:

- global Heartbeat loops without measured need;
- deep copies by default;
- repeated table construction in hot paths;
- string formatting on success paths;
- full Workspace scans every frame;
- telemetry allocation when disabled;
- automatic per-player polling.

## Testing Rules

Tests defend observable behavior, not implementation text.

Public behavior tests cover where relevant:

- valid input;
- malformed input;
- unknown fields;
- boundary values;
- unauthorized requests;
- cooldown;
- rate limits;
- scope destruction;
- task cancellation;
- repeated destruction;
- structured errors;
- deterministic timing;
- adapter failures.

Tests do not use:

- live DataStore;
- live MarketplaceService;
- production remotes;
- uncontrolled `task.wait`;
- unseeded randomness;
- external network services.

Bug fixes require:

1. reproduce the bug;
2. add a failing behavior test;
3. fix the root cause;
4. rerun the regression test.

## Documentation Rules

Update documentation when public behavior changes.

Public features need:

- API documentation;
- quick start;
- security model;
- lifecycle behavior;
- performance limitations;
- migration notes;
- changelog entry;
- `--!strict` examples.

Public package README MUST include current release and verification badges, concise purpose and non-goals, exact Wally installation and Rojo placement, one runnable `--!strict` use case, security and architecture links, roadmap status, verification commands, contribution or support route, credits, and license link.

Security documentation MUST state trust boundary, enforced request order, safe client-response policy, lifecycle ownership, explicit limitations, production checklist, and private vulnerability reporting route. Every claim must trace to code or tests; do not advertise guarantees Anvil does not enforce.

Never document unsupported guarantees.

## Versioning Policy

Use Semantic Versioning 2.0.0:

```text
MAJOR.MINOR.PATCH
```

### Pre-1.0 policy

Before `1.0.0`, Anvil follows a stricter convention than generic SemVer:

- `0.MINOR.PATCH` — minor release; may contain intentional public API changes;
- `0.MINOR.PATCH` — patch release; bug fixes and compatible behavior only;
- breaking changes increment `MINOR`, never hide in `PATCH`;
- patch releases never rename, remove, or change required behavior of public APIs;
- new experimental APIs use explicit `Experimental` naming or a documented unstable namespace.

Examples:

```text
0.1.0  first public core API
0.2.0  breaking Scope API redesign
0.2.1  compatible bug fix
0.3.0  new Action contract with migration required
```

### Post-1.0 policy

After `1.0.0`:

- `MAJOR` — breaking public API, behavior, or compatibility change;
- `MINOR` — backward-compatible feature;
- `PATCH` — backward-compatible bug, security, or performance fix.

### Pre-release identifiers

Use pre-release versions only when release behavior is intentionally unstable:

```text
0.1.0-alpha.1
0.1.0-beta.1
1.0.0-rc.1
```

Do not publish arbitrary labels such as `latest`, `stable-final`, or `new-api` as version substitutes.

### Version source of truth

Version must be declared once in the package metadata used for release. Generated files must not become independent version sources.

Release metadata must stay consistent across:

- Wally package metadata;
- changelog;
- Git tag;
- GitHub release;
- documentation installation example.

### Changelog

Use `CHANGELOG.md` with Keep a Changelog categories:

```markdown
## [Unreleased]

### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security
```

Every public release moves entries from `Unreleased` into a versioned section.

### Deprecation

A public API is not removed silently.

Deprecation requires:

- changelog entry;
- migration path;
- replacement API;
- removal version;
- test coverage for replacement behavior.

Pre-1.0 breaking changes may remove APIs only when the migration is documented in the release notes.

### Wally consumer guidance

Production projects should pin Anvil to an exact version:

```toml
Anvil = "author/anvil@0.1.0"
```

Ranges may be used only when the consuming project has lockfile/CI verification and accepts automatic compatible updates. Examples and templates use exact versions.

## Git Branch Rules

Protected branch:

```text
main
```

Never commit directly to `main`.

Branch format:

```text
feat/<short-name>
fix/<short-name>
perf/<short-name>
refactor/<short-name>
test/<short-name>
docs/<short-name>
build/<short-name>
chore/<short-name>
```

Examples:

```text
feat/action-schema
fix/scope-double-destroy
perf/result-fast-path
docs/security-model
```

Rules:

- one issue or goal per branch;
- branch from current `main`;
- no unrelated formatting;
- no generated noise;
- never rewrite shared branch history;
- never force-push `main`;
- force-push a feature branch only with explicit approval and `--force-with-lease`;
- inspect status before editing.

## Git Safety

Before editing:

```text
git status --short
```

Before committing:

```text
git diff --check
git diff
git status --short
```

Never use these without explicit user approval:

```text
git reset --hard
git clean -fd
git checkout -- .
git restore .
git branch -D
git push --force
git push --force-with-lease
```

Never use `git add .` blindly. Review staged content with `git diff --cached`.

Never delete or overwrite unexpected user changes.

## Atomic Commit Rules

One commit represents one logical change.

An atomic change is smallest change that can be reviewed, verified, reverted, and described independently. It has one user-visible contract, one bug root cause, or one maintenance concern.

Commit boundary rules:

- include production code with direct tests, required docs, and generated metadata for that same change;
- split changes only when each part can be reviewed, reverted, or released without the other;
- do not split implementation from its required behavior test merely to make a smaller diff;
- separate independent features, unrelated cleanup, and unrelated CI/tooling changes;
- do not mix a prerequisite foundation with a feature that consumes it unless neither can work independently.

Before opening a PR, run:

```text
git log --oneline main..HEAD
```

Every commit in that range must serve the PR's one declared goal. If multiple independent scopes appear, split the work into separate branches and PRs before merge.

Good:

```text
add Result constructor
add schema object validator
fix scope double destroy
add action cooldown test
document transport contract
```

Do not combine:

```text
feature + unrelated refactor
bug fix + formatter rewrite
API change + unrelated docs cleanup
multiple independent features
```

Commit title format:

```text
<type>(<scope>): <imperative summary>
```

Types:

```text
feat
fix
perf
refactor
test
docs
build
chore
```

Examples:

```text
feat(action): add server-authoritative action pipeline
fix(scope): make destroy idempotent
test(schema): cover unknown object fields
docs(api): document Result error codes
```

Non-trivial commits require a body:

```text
feat(action): add server-authoritative action pipeline

Problem:
- raw RemoteEvent handlers duplicated validation and cooldown logic

Change:
- validate payload before execution
- enforce server-side cooldown
- normalize failures into Result errors

Safety:
- invalid client payload never reaches the executor

Verification:
- test/action.spec.luau
- benchmarks/action-baseline.luau
```

Forbidden commit messages:

```text
update
fix stuff
changes
work
final
```

## Push Rules

Before push:

```text
git status --short
git diff --check
git log --oneline -n 5
```

Push only the current feature branch:

```text
git push -u origin feat/action-schema
```

Never push:

- secrets;
- credentials;
- `.env` files;
- Studio autosave files;
- temporary generated files;
- unrelated user work;
- known failing changes without explicit user direction.

If push is rejected:

1. inspect remote status;
2. fetch;
3. rebase or merge only on the feature branch;
4. rerun verification;
5. push again.

## Pull Request Rules

PR title follows commit format:

```text
feat(action): add server-authoritative action pipeline
```

PR description:

```markdown
## Problem

## Decision

## Changes

## Non-goals

## Security impact

## Performance impact

## Tests

## Breaking changes

## Screenshots or examples
```

PRs must be focused, reviewable, linked to a task, and backed by evidence.

## Merge Rules

Default merge method: **squash merge**.

Use squash when a PR contains fixups or represents one logical change. Use a merge commit only when preserving meaningful multi-commit history is important or repository policy requires it.

Before selecting squash, inspect:

```text
git log --oneline main..HEAD
```

Squash only when every commit serves one PR goal. Never use squash to compress independent features into one synthetic commit. Split the PR first; use a merge commit only when intentionally preserving a coherent, reviewed sequence of atomic commits.

Before merge:

- CI passes;
- review comments are resolved;
- branch is current;
- conflicts are reviewed;
- acceptance criteria pass;
- no accidental generated files are included.

After merge:

```text
git switch main
git pull --ff-only
git branch -d <merged-branch>
```

Do not delete a branch before confirming the merge.

## Release Rules

Release only from a clean, verified `main`.

Release sequence:

1. confirm `CHANGELOG.md` entries;
2. run focused tests;
3. run the required project checks;
4. run benchmarks for changed performance paths;
5. review `git diff` and `git status`;
6. update version metadata;
7. create atomic release commit;
8. create annotated tag `vX.Y.Z`;
9. push commit and tag;
10. publish GitHub release with changelog notes;
11. verify Wally package metadata and installation;
12. update documentation examples.

Tag format:

```text
v0.1.0
v0.2.0-alpha.1
v1.0.0
```

Never release from an uncommitted tree or a feature branch.

## Agent Workflow

Every agent must:

1. read applicable `AGENTS.md`;
2. inspect repository state;
3. find existing patterns and callers;
4. identify affected files;
5. make the smallest complete change;
6. run focused verification;
7. review the diff;
8. report changed files and evidence.

Agents must not:

- invent architecture when docs already define it;
- create duplicate utilities;
- edit outside assigned scope;
- run destructive Git commands;
- claim tests passed without running them;
- leave stubs, placeholders, or TODO implementations;
- stop at a scaffold;
- silently reduce scope;
- modify generated files without regenerating through the approved command.

## OMP Subagent Rules

Use subagents only for genuinely independent work.

Scout agents are read-only and return paths, symbols, findings, and risks.

Writing agents receive exact file/symbol scope and must not run formatters, linters, or project-wide suites. They report changed files and focused verification.

Parallel work requires:

- non-overlapping files;
- explicit contracts;
- one final integration review;
- no simultaneous edits to the same file.

Use `local://` for large handoff material.

## Completion Report

Every completed task reports:

```markdown
## Done

- concise result

## Files

- `path`: what changed

## Verification

- command or scenario
- observed result

## Risks

- known limitation or `None`

## Git

- branch
- commit hash, if committed
```

Never report a scaffold as complete.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
