# Build and run agents in a devcontainer — a sandbox that is also a disk boundary

> **rs-cleanup · guide** — rs-skills original

Two problems have the same fix: (1) dependencies and agents run **arbitrary code** on your machine (`build.rs`, proc-macros, test code, agent tool calls), and (2) builds fill the host disk. A devcontainer (or any container) gives both a boundary: the code sees only the project and the container's filesystem, and the heavy state lives in **named volumes** you can delete in one command.

## When to use

- reviewing or building unfamiliar/untrusted code (a dependency update with new build scripts, an external PR, a fuzzing or mutation-testing campaign);
- running an agent with broad permissions (`--dangerously-skip-permissions`-style modes belong **only** inside a sandbox with no secrets and a limited network);
- machines where `target/` kept eating the disk.

## Shape (`.devcontainer/devcontainer.json`)

```jsonc
{
  "name": "rust-dev",
  "image": "mcr.microsoft.com/devcontainers/rust:1-bookworm",       // pin a digest for reproducibility
  "remoteUser": "vscode",                                            // non-root
  "mounts": [
    // heavy, regenerable state in NAMED VOLUMES, not in the bind-mounted checkout (also much faster on macOS/Windows)
    { "source": "${localWorkspaceFolderBasename}-target", "target": "${containerWorkspaceFolder}/target", "type": "volume" },
    { "source": "${localWorkspaceFolderBasename}-cargo",  "target": "/usr/local/cargo/registry",            "type": "volume" }
  ],
  "containerEnv": { "CARGO_INCREMENTAL": "0" },
  "postCreateCommand": "cargo fetch --locked || true",
  "runArgs": ["--label", "rs-skills.created-by=agent"]               // so cleanup.sh can find the container
}
```
Variants: `--network none` after `cargo fetch`/`cargo vendor` for builds that must not phone home; mount the checkout read-only for review-only work; no host Docker socket, no host `~/.ssh`, no cloud credentials, no `.env`.

## Rules

| Rule | Why |
|---|---|
| **No secrets in the sandbox** (tokens, SSH agent, cloud creds, production `.env`) | the point is that a malicious build script finds nothing to steal |
| **Named volumes for `target/` and the cargo registry** | disk state is outside the checkout and removable: `docker volume rm <project>-target` frees it at once |
| **Label the container** (`rs-skills.created-by=agent`); stop and remove it when the task ends | `cleanup.sh` removes labelled stopped containers |
| **Named volumes are never pruned by `cleanup.sh`** | they look like user data — **ask** before `docker volume rm`, and say what is in it (a build cache, not data) |
| **One sandbox per untrusted task**, thrown away after | no persistence for an attacker |
| **Pin the image by digest** and update deliberately | the image is part of the supply chain (rs-release `guides/ci-hardening.md`) |
| Mind Docker Desktop's single virtual disk | volumes live inside it; check `docker system df -v` for the volume sizes |

## Disk budget inside the container

Same rules as the host: `cargo sweep --time 7` in the volume, slim debuginfo (`templates/release/dev-profile.toml`), shared target. A fuzz/mutation campaign gets its own volume and is removed after.
