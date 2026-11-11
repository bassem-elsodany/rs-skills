# Example — editing a file that has a contract

Request: *"Add a `--dry-run` flag to the config."*

1. Read the header of `src/config.rs`:
   - **Extend by:** add a field to `ConfigBuilder` with a default; do NOT add boolean flags.
   - **Patterns:** Builder · Newtype ids
2. The request conflicts with **Extend by** (a boolean flag). Options:
   - Fits the design: model it as `enum Mode { Apply, DryRun }` with `Default = Apply`
     — a field with a default, not a bool. Implement; the contract does not change.
   - Needs a design change: if the team really wants a bool, change the
     **Extend by** line deliberately and say so in the commit message.
3. If the change adds an invariant ("dry-run never opens files for writing"), add
   it to **Invariants** in the same edit.

Never: add the field, leave the contract stale, and move on.
