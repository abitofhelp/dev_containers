# dev_containers

[![Build](https://github.com/abitofhelp/dev_containers/actions/workflows/docker-build.yml/badge.svg)](https://github.com/abitofhelp/dev_containers/actions/workflows/docker-build.yml) [![Publish](https://github.com/abitofhelp/dev_containers/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/abitofhelp/dev_containers/actions/workflows/docker-publish.yml) [![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)

Professional development containers for Ada, C++, Go, and Rust — with
embedded (ARM Cortex-M/A) support for Ada, C++, and Rust.

## Available Images

| Image | Language | Base | Architectures | Embedded |
|-------|----------|------|---------------|----------|
| `dev-container-ada` | Ada (Alire-managed GNAT) | Ubuntu 22.04 | amd64 | Cortex-M/A |
| `dev-container-ada-system` | Ada (APT `gnat-13`) | Ubuntu 24.04 | amd64, arm64 | Cortex-M/A |
| `dev-container-cpp` | C++ (Clang 20, CMake, vcpkg) | Ubuntu 24.04 | amd64, arm64 | Cortex-M/A |
| `dev-container-cpp-system` | C++ (GCC 13, Clang 18, apt) | Ubuntu 24.04 | amd64, arm64 | Cortex-M/A |
| `dev-container-go` | Go 1.26.1, protobuf, Bazelisk | Ubuntu 24.04 | amd64, arm64 | — |
| `dev-container-rust` | Rust stable (rustup) | Ubuntu 24.04 | amd64, arm64 | Cortex-M/A |

All images are published to GitHub Container Registry:

```text
ghcr.io/abitofhelp/<image-name>:latest
ghcr.io/abitofhelp/<image-name>:v<X.Y.Z>
```

### Versioning

All six images share a single repository version. A `vX.Y.Z` tag on this
repo produces the matching `ghcr.io/abitofhelp/<image>:vX.Y.Z` for every
image in the same release. The `:latest` tag always points to the most
recent non-pre-release version. See [CHANGELOG.md](CHANGELOG.md) for the
current release and history.

## Quick Start

### 1. Pull an image

```bash
# From your project directory:
make -f ~/containers/dev_containers/ada/Makefile pull-system
```

### 2. Launch a container

```bash
cd ~/Ada/github.com/abitofhelp/my_project
make -f ~/containers/dev_containers/ada/Makefile run-system
```

The Makefile auto-detects the container CLI (docker on macOS/Windows, nerdctl
on Linux), generates a sequential container name (`dev-container-ada-system-1`,
`-2`, etc.), passes host identity for runtime user adaptation, and mounts your
current directory at `/workspace`.

### 3. Or use the shell aliases

If your `.zshrc` has the convenience functions configured:

```bash
adast    # Ada system image — cd's to source root, launches container
cppt     # C++ upstream image
got      # Go image
rustt    # Rust image
```

| Command | Image | amd64 (x86_64) | arm64 |
|---------|-------|:---:|:---:|
| `adat` | dev-container-ada (Alire) | yes | no |
| `adast` | dev-container-ada-system (APT) | yes | yes |
| `cppt` | dev-container-cpp | yes | yes |
| `cppst` | dev-container-cpp-system (APT) | yes | yes |
| `got` | dev-container-go | yes | yes |
| `rustt` | dev-container-rust | yes | yes |

## Why These Containers Are Useful

Each container provides a reproducible development environment that adapts to
the host user at runtime.  Any developer can pull a pre-built image and run it
without rebuilding.

The included `.zshrc` detects when it is running inside a container and
visibly marks the prompt:

```text
mike@container /workspace (main) [ctr:rootless]
❯
```

This prevents common mistakes: editing in the wrong terminal, confusing host
and container environments, or debugging UID/mount issues.

## Pre-installed Tools (All Images)

| Category | Tools |
|----------|-------|
| **Version control** | git, patch, openssh-client |
| **Editors** | vim, neovim, nano |
| **Search** | ripgrep (rg), fd-find (fdfind), fzf |
| **Network** | curl, wget, rsync |
| **Archives** | tar, zip, unzip, xz, gzip, bzip2 |
| **Python** | python3, pip3, python3-venv |
| **Shell** | zsh (default), bash, zsh-autosuggestions, zsh-syntax-highlighting |
| **Container** | gosu, sudo |
| **Debugger** | gdb, strace |
| **Build** | make, pkg-config |
| **Pagers** | less, more, file, jq, lsof |
| **Documentation** | typst (formal document compiler) |

See each image's Dockerfile for the full list of language-specific tools.

## Reproducibility Policy

To keep image builds reproducible, every tool installed in a Dockerfile MUST
be pinned to a specific version. When downloading binaries or tarballs,
also verify a SHA256 checksum.

Pin at the most specific level available:

- **Base images** — pin by SHA256 digest (e.g., `ubuntu:24.04@sha256:…`).
- **Downloadable binaries/tarballs** — pin `*_VERSION` and verify `*_SHA256`.
- **Package managers** — pin tool versions (e.g., `go install …@v1.2.3`,
  `cargo install --version X.Y.Z`, `rustup toolchain install 1.85.1`).
- **Git clones** — check out a tagged release, not a moving branch.
- **APT packages** — use versioned package names where available
  (`gnat-13`, `clang-20`); Ubuntu's archive rotates exact versions, so
  exact-version apt pinning is discouraged.

Avoid `@latest`, `stable`, `HEAD`, `main`, and unverified downloads. If
you add a tool, add a `TOOLNAME_VERSION` (and `TOOLNAME_SHA256` where the
tool ships a binary release) to the `ARG` block at the top of the
Dockerfile.

The Ada images are the current reference for this policy: the Ubuntu base
image, Alire, GNAT, and GPRBuild are all version-pinned with SHA256
verification where applicable.

## How It Works

### Runtime-Adaptive User Identity

The image ships with a fallback user (`dev:1000:1000`) for CI and Kubernetes.
At run time, `entrypoint.sh` reads `HOST_USER`, `HOST_UID`, and `HOST_GID`
from environment variables and adapts the in-container user to match.

### Container CLI Auto-Detection

The Makefile and `container_run.py` launcher script automatically detect
the host platform:

| Host | CLI | Runtime |
|------|-----|---------|
| macOS | docker | Docker Desktop |
| Linux | nerdctl | Rootless containerd |
| Windows | docker | Docker Desktop |

Override with `CONTAINER_CLI=docker` or the `--cli` flag.

### Container Naming

Containers are named sequentially: `dev-container-ada-1`, `-2`, `-3`, etc.
This allows multiple containers from the same image to run simultaneously
with predictable names.

## Deployment Environments

| Runtime | Container UID 0 is... | Bind mount access via... | Security boundary |
|---------|----------------------|--------------------------|-------------------|
| Docker rootful | Real root (dangerous) | gosu drop to HOST_UID | Container isolation |
| nerdctl rootless | Host user (safe) | Stay UID 0 (= host user) | User namespace |
| Podman rootless | Host user (safe) | --userns=keep-id | User namespace |
| Kubernetes | Blocked by policy | fsGroup in pod spec | Pod security standards |

## Linux Host Prerequisites

Before running containers on a headless Ubuntu server (24.04+), complete
these one-time setup steps:

### 1. Allow unprivileged user namespaces (Ubuntu 24.04)

```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
sudo sh -c 'echo "kernel.apparmor_restrict_unprivileged_userns=0" >> /etc/sysctl.d/99-rootless.conf'
```

### 2. Install rootless containerd

```bash
containerd-rootless-setuptool.sh install
```

### 3. Install BuildKit (required for `nerdctl build`)

```bash
containerd-rootless-setuptool.sh install-buildkit
```

### 4. Enable linger for your user

```bash
sudo loginctl enable-linger $(whoami)
```

This keeps your systemd session alive across SSH connections so that a
second terminal can see running containers.

### 5. Verify XDG_RUNTIME_DIR

```bash
echo $XDG_RUNTIME_DIR
# Should show: /run/user/<uid>
```

If empty, add to your shell profile:

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
```

### 6. Verify

```bash
nerdctl ps    # Should return without errors
```

## Repository Layout

```text
dev_containers/
├── .github/workflows/       ← matrix build + publish
├── .dockerignore
├── .gitignore
├── entrypoint.sh            ← shared across all images
├── LICENSE
├── Makefile.common          ← shared Makefile targets
├── README.md
├── USER_GUIDE.md
├── CHANGELOG.md
├── ada/
│   ├── Dockerfile           ← Alire-managed toolchain (Ubuntu 22.04)
│   ├── Dockerfile.system    ← system toolchain (Ubuntu 24.04)
│   ├── Makefile             ← thin: sets vars, includes Makefile.common
│   ├── .zshrc               ← Ada-specific shell config
│   └── examples/hello_ada/
├── cpp/
│   ├── Dockerfile           ← upstream Clang 20, CMake, vcpkg
│   ├── Dockerfile.system    ← system GCC 13, Clang 18
│   ├── Makefile
│   ├── .zshrc
│   └── examples/hello_cpp/
├── go/
│   ├── Dockerfile           ← Go 1.26.1, protobuf, Bazelisk
│   ├── Makefile
│   ├── .zshrc
│   └── examples/hello_go/
└── rust/
    ├── Dockerfile           ← Rust stable via rustup
    ├── Makefile
    ├── .zshrc
    └── examples/hello_rust/
```

## Makefile Targets

Run `make -f <lang>/Makefile help` for the full list.  Common targets:

```bash
make -f ada/Makefile build          # Build the image
make -f ada/Makefile run            # Launch container (auto-detects CLI)
make -f ada/Makefile run-system     # Launch system-toolchain variant
make -f ada/Makefile test           # Smoke test
make -f ada/Makefile inspect        # Show configured variables
make -f ada/Makefile help           # Full target list
```

## Shared Python Launcher

Container launch logic lives in `container_run.py` from the
[hybrid_scripts_python](https://github.com/abitofhelp/hybrid_scripts_python)
repository.  The Makefile auto-detects its location by platform.  For
standalone use or ad-hoc projects, clone the scripts repo directly:

```bash
# macOS
git clone git@github.com:abitofhelp/hybrid_scripts_python.git \
    ~/Ada/github.com/abitofhelp/hybrid_scripts_python

# Linux
git clone git@github.com:abitofhelp/hybrid_scripts_python.git \
    ~/ada/github.com/abitofhelp/hybrid_scripts_python
```

Override the path with the `HYBRID_SCRIPTS_PYTHON` environment variable
if your clone is elsewhere.

## License

BSD-3-Clause — see [LICENSE](LICENSE).

## AI Assistance and Authorship

This project was developed by Michael Gardner with AI assistance from Claude
(Anthropic) and GPT (OpenAI).  AI tools were used for design review,
architecture decisions, and code generation.  All code has been reviewed and
approved by the human author.  The human maintainer holds responsibility for
all code in this repository.
