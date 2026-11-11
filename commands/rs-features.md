---
description: Get the Rust version changelog and new language/library features for a version or range (uses the rs-changelog agent).
---

# /rs-features

Get Rust version changelog and new features.

## Usage

```
/rs-features [version]
```

## Parameters

- `version` (optional): Rust version number (e.g., `1.83`, `1.82`). If omitted, fetches the latest stable version.

## Examples

```
/rs-features           # Latest Rust features
/rs-features 1.83      # Rust 1.83 features
/rs-features 1.80      # Rust 1.80 features
```

## Workflow

1. Use `search_actions("releases.rs")` to get action ID
2. Use `get_action_by_id()` to get page selectors
3. Use `agent-browser` to open https://releases.rs and navigate to the version
4. Extract changelog content
5. Summarize key features for user
