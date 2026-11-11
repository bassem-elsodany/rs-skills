# clean-report

> End every build-heavy task with a Cleanup report in the answer
> **rs-cleanup · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A report makes cleanup observable and gives the user a chance to object. The Stop hook asks for it when budgets are exceeded; do it anyway when the task ran builds or containers.

## Template

```markdown
### Cleanup report
- Disk: <before> → <after> free (target/ <a> → <b> GiB; Docker images+cache <c> → <d> GiB)
- Removed: <what you created and deleted>
- Left in place: <what remains and why — user data, needed artefact, running service>
- Follow-up: <e.g. "install cargo-sweep", "add .dockerignore">
```

## See Also

- [clean-measure-first](clean-measure-first.md)
