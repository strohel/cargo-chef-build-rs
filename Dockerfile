FROM rust as planner
WORKDIR app
# We only pay the installation cost once, 
# it will be cached from the second build onwards
RUN cargo install --git https://github.com/strohel/cargo-chef.git --branch build-rs-support
COPY . .
RUN cargo chef prepare  --recipe-path recipe.json

FROM rust as cacher
WORKDIR app
RUN cargo install --git https://github.com/strohel/cargo-chef.git --branch build-rs-support
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

FROM rust as builder
WORKDIR app
COPY . .
# Copy over the cached dependencies
COPY --from=cacher /app/target target
COPY --from=cacher $CARGO_HOME $CARGO_HOME
RUN cargo build --release --bin cargo-chef-build-rs

FROM rust as runtime
WORKDIR app
COPY --from=builder /app/target/release/cargo-chef-build-rs /usr/local/bin
ENTRYPOINT ["./usr/local/bin/cargo-chef-build-rs"]
