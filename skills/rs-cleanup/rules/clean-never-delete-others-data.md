# clean-never-delete-others-data

> Remove what you created; ask before removing what the user may care about
> **rs-cleanup · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

A cleanup that deletes a hand-built image or a database volume turns a disk problem into a data-loss incident. Regenerable things (build cache, dangling images, `target/` artefacts, containers you labelled) are safe; everything else needs ownership evidence.

## Decision

| Item | Created by you this session / labelled? | Action |
|---|---|---|
| container with label `rs-skills.created-by=agent` | yes | remove |
| dangling image, build cache, `target/` artefacts | regenerable | remove (safe tier) |
| image tagged by the user, base images they pulled | no | keep; list in the report; remove only on request |
| **volumes** | unknown | never remove; list; ask |
| running containers | — | never stop/remove; mention |
| files outside `target/` and your scratchpad | — | never |

When unsure: `cleanup.sh plan`, show the plan, ask.

## See Also

- [clean-docker-hygiene](clean-docker-hygiene.md)
