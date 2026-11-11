---
name: rs-cleanup
description: "CRITICAL: Use whenever you build, compile, test, run containers or build Docker images — and always before finishing a task that did. Agents leave build artefacts, images, containers and caches behind until the disk is full (one session ended at 500 GB). Triggers: disk full, out of space, no space left on device, target directory huge, cargo clean, cargo sweep, build cache, docker build, docker image prune, docker system prune, dangling images, unused images, docker volume, container left running, testcontainers, cleanup, clean up, free disk space, storage, incremental, debuginfo, sccache, rustup toolchain, before you finish, end of task"
user-invocable: false
---

# Cleanup — leave the machine as you found it

> **Layer 4: Delivery** · the last step of every build-heavy task, and a budget during it
>
> Tools: `${CLAUDE_SKILL_DIR}/scripts/disk-guard.sh` (status · preflight · over) · `${CLAUDE_SKILL_DIR}/scripts/cleanup.sh` (plan · apply, tiered, dry-run by default) · hooks: disk preflight before builds, disk check before the session ends · `${CLAUDE_PLUGIN_ROOT}/templates/release/{dockerignore,dev-profile.toml}`

## Core Question

**What did my commands leave on this machine, and is any of it still needed?**

Nothing cleans up after an agent by itself. `cargo` never garbage-collects `target/` (every code change leaves new hashed artefacts), Docker keeps every layer, image and build cache, and integration tests leave containers and volumes. On a real project this produced a **204 GB** `target/` (176 GB of stale files in `debug/deps`, 289 000 files) plus 20 GB of build cache and 19 GB of images — on a 1 TB disk that was "plenty".

---

## The loop: measure → budget → build → clean → report

| When | Do |
|---|---|
| **Before a heavy task** | `${CLAUDE_SKILL_DIR}/scripts/disk-guard.sh status` — free space, every `target/`, caches, Docker. Remember the numbers |
| **Before each big build** | `${CLAUDE_SKILL_DIR}/scripts/disk-guard.sh preflight` (the hook does it for you); below `RS_MIN_FREE_GB` (10–15) clean first, don't build |
| **While working** | follow the build rules below — the cheapest cleanup is the artefact you never create |
| **After the task** | `${CLAUDE_SKILL_DIR}/scripts/cleanup.sh plan` → read it → `apply` (safe tier). Remove what *you* created: spike crates, scratch images, containers |
| **In your answer** | a **Cleanup report**: created / removed / reclaimed / left running and why |

```markdown
### Cleanup report
- Before → after free space: 161 → 171 GiB   (target/ 35 → 9 GiB, Docker build cache 20 → 2 GiB)
- Removed: 5 incremental caches, dangling images (3), stopped agent containers (2), spike crate in scratchpad
- Left in place: volume `pgdata` (user data), image `app:dev` (needed for the demo)
```

## Cargo and `target/`

| Rule | Why / how |
|---|---|
| **`cargo check`, not `cargo build`, to see whether it compiles** | no code generation; a fraction of the disk and time (`cargo clippy` shares check artefacts) |
| **`cargo sweep`** — `cargo install cargo-sweep`; `cargo sweep --time 7` | drops artefacts untouched for N days: the only way to shrink a long-lived `target/` *without* a full rebuild. Run it at the end of build-heavy tasks and weekly |
| **Budget per project: ~10–15 GiB** | above it: sweep; still above: `cargo clean` — a rebuild costs minutes, a full disk costs the day |
| **One shared target directory per repo** — `[build] target-dir` in `.cargo/config.toml` or `CARGO_TARGET_DIR` | five crates with their own `target/` each rebuilt the same dependencies (35 GiB here, 6–10 GiB per crate); a workspace shares one |
| **Spikes and throwaway crates live in the scratchpad with their own `CARGO_TARGET_DIR`**, and are deleted afterwards | no stray `target/` in the user's repo |
| **Slim debug info** (`${CLAUDE_PLUGIN_ROOT}/templates/release/dev-profile.toml`) | `debug = "line-tables-only"`, deps `debug = false`: the largest single size win, stack traces still work |
| **Don't multiply configurations** | each distinct `RUSTFLAGS` / feature set / `--target` / profile is a full new set of artefacts. Use them deliberately and delete them (`cargo clean --target-dir <that dir>`) |
| `incremental = false` in CI and in one-shot builds | incremental caches are only valuable when you rebuild the same crate repeatedly |
| coverage, miri, fuzz, `cargo doc`, wasm targets | give each its own `--target-dir` under the scratchpad and remove it when done |
| **tool artefacts**: fuzz corpora/artifacts (`fuzz/`), `mutants.out/` and cargo-mutants' temporary tree copies, sanitizer builds (`-Zsanitizer` needs its **own** `CARGO_TARGET_DIR`), `cargo llvm-cov` (`target/llvm-cov-target`), nightly toolchains | each is a full extra set of artefacts: scratch dirs, delete after the campaign (rs-fuzzing) |
| old toolchains | `rustup toolchain list`; `cargo sweep --installed` removes artefacts of toolchains no longer installed |
| shared compiler cache | `sccache` with `SCCACHE_CACHE_SIZE` set, instead of ever-growing per-project targets |

`cargo clean -p <crate>` and `cargo clean --release` are the surgical forms; plain `cargo clean` is the safe full reset of a target dir.

## Docker

| Rule | Why / how |
|---|---|
| **`.dockerignore` that excludes `target/`, `.git`, `node_modules`** (`${CLAUDE_PLUGIN_ROOT}/templates/release/dockerignore`) | otherwise the build context ships the whole `target/` to the daemon on every build |
| **Label everything you create**: `docker build --label rs-skills.created-by=agent …`, `docker run --rm --label …` | `cleanup.sh` can then remove exactly your leftovers and nothing else |
| **`docker run --rm`** for one-off containers; compose: `down` when done | stopped containers and their writable layers accumulate |
| **Don't tag every build**; reuse one tag per purpose (`app:dev`) | each retag orphans the previous image as `<none>` |
| **One image per purpose; delete it when the task is done** unless the user needs it | `docker image rm app:dev` |
| **Multi-stage + cargo-chef** (`${CLAUDE_PLUGIN_ROOT}/templates/release/Dockerfile`) | small final image; the heavy builder stage is cache, not shipped |
| **Bound the build cache** | `docker builder prune --filter until=24h` after builds; or `docker buildx prune --keep-storage 10GB` |
| **Docker Desktop (macOS/Windows)** keeps everything in one virtual disk | pruning frees space *inside* it; the file may not shrink at once — restart Docker Desktop or use its disk-usage "reclaim space" before concluding nothing was freed |
| **Volumes hold data.** Never `docker system prune --volumes`, `docker volume rm/prune -a`, `docker compose down -v` on your own initiative | the hook asks the user before these run; `cleanup.sh` lists volumes and prunes only anonymous dangling ones with `--volumes` |
| **Testcontainers / compose in tests**: ensure containers are removed (Ryuk enabled, `--rm`, `down`), name them with the label | rs-testing `port-contract-tests` |

## The tiers of `cleanup.sh`

| Tier | Removes | Cost to undo |
|---|---|---|
| `safe` (default) | `cargo sweep`/incremental dirs · stopped containers labelled `rs-skills.created-by=agent` · dangling images · build cache > 24 h | none — all regenerable |
| `more` | + `cargo clean` for targets still over budget · images unused by any container and older than N days | rebuild / re-pull |
| `all` | + every image labelled `rs-skills.created-by=agent` | rebuild |
| `--volumes` | anonymous dangling volumes only | **data** — only with the user's word |

Dry-run is the default (`plan`); `apply` executes and prints reclaimed space. Running containers, named volumes and anything not matched above are never touched.

## Hooks that back this up (enabled with the plugin)

| Hook | Does |
|---|---|
| PreToolUse (Bash) | **denies** `cargo build/test/…` and `docker build/compose up` when free space < `RS_MIN_FREE_GB` (10); **asks the user** before `docker system prune --volumes`, `docker volume rm`, `compose down -v`, `prune -a` |
| Stop | refuses to end the session while a budget is exceeded (free < 15 GiB, `target/` > 15 GiB total, Docker reclaimable > 25 GiB — volumes not counted) and tells you to run cleanup and report; fires once, never loops |
| Off switch | `RS_DISK_GUARD=off` |

## Sandbox instead of sprawl

Untrusted builds, fuzz/mutation campaigns and broad-permission agent runs belong in a throw-away container with **named volumes** for `target/` and the registry — one `docker volume rm` returns the disk, and a malicious `build.rs` finds no secrets. See `guides/devcontainer.md`.

## Rationalizations to reject

| Excuse | Reality |
|---|---|
| "I'll clean up later." | Later never comes; the Stop hook and the disk will. Clean at the end of the task, with a report. |
| "It's only a scratch crate." | Scratch crates built in the repo leave a `target/` nobody remembers. Scratchpad + own `CARGO_TARGET_DIR`, delete after. |
| "There is plenty of disk." | There was 1 TB when a single `target/` reached 204 GB. Budgets, not feelings. |
| "`docker system prune -a --volumes` is quicker." | It deletes databases. Plan first; volumes only with the user's word. |
| "I didn't create it, but it's clearly unused." | Not yours, not deleted — ask. |

## Never

- delete anything you did not create without the user's word — a pruned image they built by hand or a volume with a database is not recoverable;
- run a destructive prune "to be safe" — plan first, read it, apply the narrowest tier that solves the problem;
- leave a background container or watcher running at the end without saying so;
- claim "cleaned up" without the numbers.

## Trace

| Direction | Go to |
|---|---|
| ↑ Up | rs-domain-cloud-native (images, Kubernetes) · rs-release (Docker image, CI cache policy) |
| ↓ Down | rs-testing (containers in tests), rs-performance (profile settings, `lto`/`codegen-units` and build size) |
| → Delivery | rs-release gate runs `disk-guard.sh status`; rs-review notes `target/` and image hygiene |

<!-- rules-index:start -->
## Rules (7)

Depth rules under `rules/` — open the one the question needs, not all of them.

**clean-**

- [`clean-docker-hygiene`](rules/clean-docker-hygiene.md) — `.dockerignore`, labels, `--rm`, one tag per purpose, bounded cache
- [`clean-measure-first`](rules/clean-measure-first.md) — Measure disk before a heavy task and after it; a number, not a feeling
- [`clean-never-delete-others-data`](rules/clean-never-delete-others-data.md) — Remove what you created; ask before removing what the user may care about
- [`clean-report`](rules/clean-report.md) — End every build-heavy task with a Cleanup report in the answer
- [`clean-shared-target-dir`](rules/clean-shared-target-dir.md) — One shared target directory per repo; scratch work gets its own and is deleted
- [`clean-slim-debuginfo`](rules/clean-slim-debuginfo.md) — Dev builds keep line tables only; dependencies get no debug info
- [`clean-sweep-targets`](rules/clean-sweep-targets.md) — `target/` never shrinks by itself — sweep it at the end of build-heavy work

<!-- rules-index:end -->

---

## Related Skills

| When | See |
|---|---|
| Container images and CI | rs-release |
| Integration tests with containers | rs-testing, rs-ports-adapters |
| Build profiles | rs-performance |
