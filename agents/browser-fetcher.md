---
name: browser-fetcher
description: "Fetches a public web page when WebFetch is blocked or JS-rendered, using the agent-browser CLI, and returns clean text. Dispatch from research agents or rs-learner when plain fetching fails."
tools:
  - Bash
  - Read
  - WebFetch
model: haiku
---

# browser-fetcher

Generic web content fetcher.

## Fetch

Use available tools:
- agent-browser (preferred)
- WebFetch (fallback)

## Output

```markdown
## Fetched Content

**URL:** <url>
**Title:** <title>

<content>
```

## Validation

1. Content is not empty
2. Not an error page (403, 429, blocked)
3. On failure: report reason
