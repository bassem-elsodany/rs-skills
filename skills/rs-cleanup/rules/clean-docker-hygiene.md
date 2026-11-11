# clean-docker-hygiene

> `.dockerignore`, labels, `--rm`, one tag per purpose, bounded cache
> **rs-cleanup · rule** — source: rs-skills original (2026-11-11)

## Why It Matters

Every `docker build` adds layers and cache, every retag orphans an image, every `docker run` without `--rm` leaves a stopped container, and a missing `.dockerignore` sends `target/` into the build context. Together they filled the disk.

## Do

```bash
# build: labelled, one reusable tag, context stripped by .dockerignore
docker build --label rs-skills.created-by=agent -t app:dev .
# run: removed on exit, labelled
docker run --rm --label rs-skills.created-by=agent app:dev
# afterwards (safe, regenerable)
docker builder prune -f --filter until=24h
docker image prune -f                      # dangling <none> images
docker image rm app:dev                    # when the task no longer needs it
```

## Don't

```bash
docker system prune -a --volumes -f        # deletes unused images AND volumes (databases!) — needs the user's word
docker volume prune -a                     # same
docker compose down -v                     # drops the compose project's volumes
```

## Docker Desktop

The VM disk may not shrink immediately after pruning; compare `docker system df` before/after rather than `df` alone.

## See Also

- [clean-never-delete-others-data](clean-never-delete-others-data.md)
