ARG GO_VERSION="1.19"

FROM golang:${GO_VERSION}-bullseye

ARG TERRAFORM_VERSION="1.3.6"
ARG KIND_VERSION="v0.17.0"
ARG TFLINT_VERSION="v0.44.1"
ARG TERRAFORM_DOCS_VERSION="v0.16.0"
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
    dnsutils \
    docker.io \
    git \
    gnupg2 \
    make \
    python3-pip \
    software-properties-common \
    unzip \
    && apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Add Hashicorp GPG key
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# Add k8s GPG key
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

# Add Helm GPG key
RUN curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor > /usr/share/keyrings/helm.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

# Install core tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    helm \
    kubectl \
    terraform=${TERRAFORM_VERSION} \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Install pre-commit
RUN pip3 install --no-cache-dir --upgrade pip && pip install --no-cache-dir pre-commit

# Install TFLint
RUN curl -fsSL "https://raw.githubusercontent.com/terraform-linters/tflint/${TFLINT_VERSION}/install_linux.sh" | bash

# Install terraform-docs
RUN curl -fsSL -o /tmp/terraform-docs.tar.gz "https://terraform-docs.io/dl/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-Linux-amd64.tar.gz" \
    && mkdir -p /tmp/terraform-docs \
    && tar -xzf /tmp/terraform-docs.tar.gz -C /tmp/terraform-docs/ \
    && mv /tmp/terraform-docs/terraform-docs /usr/local/bin/ \
    && chmod +x /usr/local/bin/terraform-docs \
    && rm -rf /tmp/terraform-docs

# Install golangci-lint
RUN curl -fsSL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "${GOBIN}" "${GOLANGCI_LINT_VERSION}"

# Install kind
RUN curl -fsSL -o /usr/local/bin/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64" \
    && chmod +x /usr/local/bin/kind

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
COPY --chown=worker:worker --chmod=755 ./scripts/docker-entrypoint.sh /usr/local/bin/

# Copy source codes for later sharing & debugging
COPY --chown=worker:worker . .

HEALTHCHECK NONE

ENTRYPOINT ["docker-entrypoint.sh"]

USER worker:worker
