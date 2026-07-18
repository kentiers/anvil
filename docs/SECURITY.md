# Anvil Security Model

**Status:** Draft
**Version:** 0.1

## Threat Model

Anvil assumes clients, client payloads, and client-visible Instances are untrusted. Server code, server-owned state, and server-side configuration are trusted only within the application's own security boundary.

## Required Guarantees

- raw network payload never reaches an action executor;
- schema validation occurs on the server;
- rate limit and cooldown occur on the server;
- authorization occurs on the server;
- client values do not define price, reward, ownership, or entitlement;
- Instance payloads require explicit class and ancestry policy;
- server-only modules are not required from client-visible locations;
- action failures do not reveal server-only state;
- diagnostics do not serialize secrets or full profiles by default.

## Out of Scope

Anvil is not an anti-cheat system. It cannot detect every exploit, prevent client-side tampering, or make insecure domain logic safe automatically.

Anvil cannot infer whether a domain mutation is economically correct. The application must implement server-side rules.

## Payload Policy

Default network schema behavior:

- reject unknown object fields;
- reject `NaN` and infinite numbers;
- bound strings, arrays, and nested depth;
- reject unsupported Roblox datatypes;
- reject arbitrary Instances unless explicitly configured;
- return stable, non-secret error codes.

`Schema.instance` is opt-in and requires both non-empty `classNames` and an `ancestor` Instance. An accepted Instance must satisfy an allowed class through `IsA` and be that ancestor or its descendant. This validates reference shape only; domain code still validates ownership and game rules.

## Error Policy

Client-facing errors use stable codes and safe messages:

```lua
return Forge.err("INSUFFICIENT_FUNDS")
```

Internal diagnostics may include a source path or rule details, but must not expose:

- DataStore keys;
- server secrets;
- full profile data;
- private moderation notes;
- internal stack traces in production.

## Transaction Policy

Transactions only cover mutations registered with Anvil. External effects require compensation and are never reported as automatically rolled back.

## Review Checklist

- [ ] Every action has a runtime input schema.
- [ ] Every action has server-side authorization where required.
- [ ] Every action has cooldown/rate-limit policy where abuse is possible.
- [ ] Domain handler does not trust client-owned values.
- [ ] Instance schemas constrain class and ancestry.
- [ ] Diagnostics are disabled or sanitized in production.
- [ ] Tests include malformed, oversized, and unauthorized payloads.
