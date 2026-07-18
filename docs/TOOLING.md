# Anvil Development Tooling

## Required tools

Install pinned binaries with Rokit:

```bash
rokit install
```

Required development tools:

- `rojo` — project tree and sourcemap generation;
- `wally` — package installation;
- `stylua` — deterministic Luau formatting;
- `selene` — Roblox-aware linting;
- `luau-lsp` — strict type analysis and editor intelligence.

Runtime Anvil remains native Luau with zero mandatory third-party dependencies. These are development tools, not runtime package dependencies.

## Local checks

```bash
stylua src/ test/ examples/
selene src/ test/ examples/
rojo sourcemap default.project.json --output sourcemap.json
luau-lsp analyze
```

Use `stylua --check` instead of formatting in CI:

```bash
stylua --check src/ test/ examples/
selene src/ test/ examples/
rojo sourcemap default.project.json --output sourcemap.json
luau-lsp analyze
```

`sourcemap.json` is generated and ignored. Do not commit it.

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
