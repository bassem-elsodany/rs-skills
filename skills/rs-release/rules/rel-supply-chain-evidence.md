# rel-supply-chain-evidence

> Measure dependency risk; report unassessable as unassessable, never as clean
> **rs-release · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Claims about other people's crates ("well maintained", "no advisories") are easily wrong when collected by memory or a web search. A report that treats missing data as a clean bill of health is worse than no report.

## Do

- Run `skills/rs-release/scripts/dep-risk.py .` (online) or `--offline` (local census) before adding or upgrading a dependency, at release, and on a schedule.
- Quote its numbers; don't re-derive or round them. State the **coverage** (what was measured, what was unassessable and why).
- Act on: yanked, advisories (RustSec/OSV), git/path sources, wildcard requirements, build-time code in new or rarely used crates. Judge: stale, single owner, major-behind.
- Pair with `cargo deny check` (licences, bans, sources) and `cargo audit`/`cargo vet` — the report does not replace them.
- A dependency with no flags is *measured against these criteria only*.

## Bad

"I checked, the crate looks maintained." (no data) · deleting the "unassessable" rows because they look untidy.

## See Also

- [rs-security-review sec-supply-chain-build-time-code](../../rs-security-review/rules/sec-supply-chain-build-time-code.md)
