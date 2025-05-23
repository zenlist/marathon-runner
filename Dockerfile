FROM ghcr.io/actions/actions-runner:latest

ARG TARGETOS
ARG TARGETARCH
ARG ZIG_VERSION=0.14.0
ARG CARGO_LAMBDA_VERSION=1.8.1

# Install base packages
RUN sudo apt update -y \
    && sudo apt install -y curl wget tar xz-utils unzip build-essential docker-buildx git cmake libssl-dev protobuf-compiler

# Install GH CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update && sudo apt install -y gh

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y
ENV PATH="/home/runner/.cargo/bin:${PATH}"

RUN rustup target add aarch64-unknown-linux-musl \
    && rustup target add aarch64-unknown-linux-gnu

RUN cargo install --locked cargo-lambda@${CARGO_LAMBDA_VERSION}
RUN cargo install cargo-nextest --locked

# Install Zig
RUN export RUNNER_ARCH=${TARGETARCH} \
    && if [ "$RUNNER_ARCH" = "arm64" ]; then export RUNNER_ARCH=aarch64 ; fi \
    && if [ "$RUNNER_ARCH" = "amd64" ]; then export RUNNER_ARCH=x86_64 ; fi \
    && curl -f -L -o zig.tar.xz https://ziglang.org/download/${ZIG_VERSION}/zig-${TARGETOS}-${RUNNER_ARCH}-${ZIG_VERSION}.tar.xz \
    && tar xf zig.tar.xz \
    && rm zig.tar.xz \
    && mv zig-${TARGETOS}-${RUNNER_ARCH}-${ZIG_VERSION} zig-${ZIG_VERSION}

ENV PATH="/home/runner/zig-${ZIG_VERSION}:${PATH}"

# Install Node v20 and AWS CDK
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - \
    && sudo apt-get install -y nodejs \
    && sudo npm i -g aws-cdk

RUN sudo rm -rf /var/lib/apt/lists/*