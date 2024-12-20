# Use the official Rust image
FROM rust:latest as builder

# Set working directory inside the container
WORKDIR /app

RUN apt update && apt dist-upgrade -y && apt install -y protobuf-compiler && apt-get autoremove --yes && rm -rf /var/lib/{apt,dpkg,cache,log}/
RUN cargo install protobuf-codegen


# Copy project files
COPY proto proto
COPY Cargo.lock Cargo.lock
COPY Cargo.toml Cargo.toml
COPY build.rs build.rs
COPY LICENSE LICENSE
COPY README.md README.md
COPY SECURITY.md SECURITY.md
COPY src src

# Build the project
RUN cargo build --release

# Use a smaller base image for the runtime
FROM ubuntu:latest

# Set working directory inside the runtime image
WORKDIR /app

# Copy the compiled binary from the builder image
COPY --from=builder /app/target/release/derec-crypto-core-grpc /app/

# Expose the port
EXPOSE 50051

# Command to run the binary
CMD ["./derec-crypto-core-grpc"]
