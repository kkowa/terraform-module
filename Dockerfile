ARG GO_VERSION="1.19"

FROM golang:${GO_VERSION}-bullseye

ARG TERRAFORM_VERSION="1.3.6"
ARG GOLANGCI_LINT_VERSION="v1.50.1"

# Workspace directory
ARG WORKSPACE="/var/workspace"

# Workspace user (worker) for manual UID and GID set
ARG UID="1000"
ARG GID="1000"

ENV GOBIN="/usr/local/go/bin"
ENV PATH="${GOBIN}:${PATH}"

SHELL ["/bin/bash", "-c"]

# Install tools
RUN apt update && apt install --no-install-recommends -y \
    curl \
    docker.io \
    git \
    gnupg2 \
    make \
    python3-pip \
    software-properties-common \
    && apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Add Hashicorp GPG key
RUN curl -fsSL "https://apt.releases.hashicorp.com/gpg" | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
RUN apt-get update && apt-get install --no-install-recommends -y \
    terraform=${TERRAFORM_VERSION} \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Install pre-commit
RUN pip3 install --no-cache-dir --upgrade pip && pip install --no-cache-dir pre-commit

# Install golangci-lint
RUN curl -fsSL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "${GOBIN}" "${GOLANGCI_LINT_VERSION}"

# Change working directory
WORKDIR "${WORKSPACE}"

# Install Go dependencies
COPY go.mod go.sum ./
RUN go mod download

# Create workspace user and set as workspace owner
RUN groupadd --gid "${GID}" worker \
    && useradd  --system --uid "${UID}" --gid "${GID}" --create-home worker \
    && chown -R worker:worker "${WORKSPACE}" /home/worker

# Copy script files to executable path
COPY --chown=worker:worker --chmod=755 ./scripts/* /usr/local/bin/

HEALTHCHECK NONE

ENTRYPOINT ["docker-entrypoint.sh"]

USER worker:worker
