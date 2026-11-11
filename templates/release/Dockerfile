# rs-skills multi-stage image: small, non-root, reproducible with --locked.
# Build with labels so cleanup can find (and only remove) what an agent created — rs-cleanup:
#   docker build --label rs-skills.created-by=agent -t APP_NAME:dev .      # run with --rm; remove the image when done
# Keep a .dockerignore next to this file (templates/release/dockerignore): target/ must never enter the build context.
FROM rust:1.85-bookworm AS chef
RUN cargo install cargo-chef --locked
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --locked --recipe-path recipe.json     # dependency layer, cached
COPY . .
RUN cargo build --release --locked --bin APP_NAME

FROM gcr.io/distroless/cc-debian12:nonroot AS runtime
WORKDIR /app
COPY --from=builder /app/target/release/APP_NAME /app/APP_NAME
USER nonroot
ENV RUST_LOG=info
ENTRYPOINT ["/app/APP_NAME"]
