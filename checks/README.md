# checks — compile-verify the rule examples

Type-checks the ```` ```rust ```` blocks of every rule listed in `rule-manifest.txt`
(rules under `skills/*/rules/` written in the Bad/Good format) so the Good examples we
tell agents to write actually compile. Not part of the published skill.

```bash
bash checks/check.sh          # rules-check + gen + cargo check (pinned 1.95.0) + baseline gate
```

`gen.py` extracts candidate blocks to `examples/`; `analyze.py` buckets failures
(fragment / artifact / low / SUSPECT) and gates on `baseline.txt`. After
intentionally changing examples: regenerate the baseline on the pinned toolchain
(`python3 analyze.py check.json --emit-baseline > baseline.txt`) and review the diff.
Rules not in the manifest (e.g. `rs-unsafe/rules/*`) use a different format and are
not compile-checked. Licensing of adapted material: see `../NOTICE.md`.
