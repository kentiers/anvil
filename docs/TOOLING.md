# Anvil Development Tooling

## Required tools

Install pinned binaries with Rokit:

```bash
rokit install
```

Required development tools:

- `rojo` — project tree and sourcemap generation;
- `wally` — package installation and test-only packages;
- `stylua` — deterministic Luau formatting;
- `selene` — Roblox-aware linting;
- `luau-lsp` — strict type analysis and editor intelligence;
- `run-in-roblox` — executes TestEZ inside local Roblox Studio.

Runtime Anvil remains native Luau with zero mandatory third-party dependencies. TestEZ is a Wally development dependency only.

## Local checks

Install development packages once after checkout or dependency changes:

```bash
wally install
```

Run checks:

```bash
stylua --check src/ test/ tools/ benchmarks/
selene src/ test/ tools/ benchmarks/
rojo sourcemap default.project.json --output sourcemap.json
luau-lsp analyze --sourcemap sourcemap.json src/ test/ tools/ benchmarks/
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
```

`scripts/test.ps1` builds a temporary Rojo place, runs TestEZ through local Roblox Studio, and returns zero only when TestEZ reports zero failures.

Measure Action overhead against manual schema validation on local Roblox Studio:

```bash
powershell -ExecutionPolicy Bypass -File scripts/benchmark-action.ps1
```

This benchmark reports one local measurement only. Record manual comparison, payload size, and diagnostics state before making a performance claim.

GitHub-hosted CI runs formatting, linting, and type analysis. It does not run Roblox Studio: Studio's GUI installer and plugin execution require an interactive desktop session. Run `scripts/test.ps1` locally before opening a pull request.

Verify the failure exit contract without committing a failing spec:

```bash
powershell -ExecutionPolicy Bypass -File scripts/verify-test-harness.ps1
```

`sourcemap.json`, `build/`, and `DevPackages/` are generated and ignored. Do not commit them.

## Graphify

Graphify is optional developer tooling for repository exploration. It maps code and documentation into a local knowledge graph. It does not replace Luau type analysis, Selene linting, tests, or server-side security review.

Install or update outside runtime package management:

```bash
uv tool install graphifyy
```

Build a code-only local graph without credentials:

```bash
graphify extract . --code-only
```

To include documentation, configure an approved semantic backend first, then run:

```bash
graphify extract .
```

Generated output belongs in ignored `graphify-out/`. Do not commit graph data, generated HTML, assistant hooks, credentials, or API keys.

Graphify code extraction is local. Documentation extraction requires a configured backend; do not send private source or secrets to external services.

## CI order

1. `stylua --check`;
2. `selene`;
3. Rojo sourcemap generation;
4. `luau-lsp analyze`;
5. deterministic tests;
6. benchmarks where a performance claim changed.
