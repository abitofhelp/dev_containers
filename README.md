# dev_containers

[![Build](https://github.com/abitofhelp/dev_containers/actions/workflows/docker-build.yml/badge.svg)](https://github.com/abitofhelp/dev_containers/actions/workflows/docker-build.yml) [![Publish](https://github.com/abitofhelp/dev_containers/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/abitofhelp/dev_containers/actions/workflows/docker-publish.yml) [![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)

Professional development containers for Ada, C++, Go, and Rust — with
embedded (ARM Cortex-M/A) support for Ada, C++, and Rust, including
Teensy 4.1 bare-metal Rust support.

## Available Images

| Image | Language | Base | Architectures | Embedded |
|-------|----------|------|---------------|----------|
| `dev-container-ada` | Ada (Alire: GNAT 16.1, GNATprove 16.1, GPRbuild 26.0.1; libpq 18) | Ubuntu 26.04 | amd64, arm64 | ARM GCC cross tools¹ |
| `dev-container-cpp` | C++ (Clang 20, CMake, vcpkg) | Ubuntu 24.04 | amd64, arm64 | Cortex-M/A |
| `dev-container-cpp-system` | C++ (GCC 13, Clang 18, apt) | Ubuntu 24.04 | amd64, arm64 | Cortex-M/A |
| `dev-container-go` | Go 1.26.1, protobuf, Bazelisk | Ubuntu 24.04 | amd64, arm64 | — |
| `dev-container-rust` | Rust 1.95.0 (rustup) | Ubuntu 24.04 | amd64, arm64 | Cortex-M/A, Teensy 4.1 |

¹ The Ada image includes the ARM GCC cross-compilers (`arm-none-eabi`,
`arm-linux-gnueabihf`), OpenOCD, ST-Link tools, and `gdb-multiarch`. An
Ada cross-compiler (for example, Alire's `gnat_arm_elf`) is not
preinstalled.

`dev-container-ada-system` is **deprecated** (see
[Deprecated Images](#deprecated-images)).

All images are published to GitHub Container Registry:

```text
ghcr.io/abitofhelp/<image-name>:latest
ghcr.io/abitofhelp/<image-name>:v<X.Y.Z>
```

### Versioning

All current images share a single repository version. A `vX.Y.Z` tag on this
repo produces the matching `ghcr.io/abitofhelp/<image>:vX.Y.Z` for every
image in the same release. The `:latest` tag always points to the most
recent non-pre-release version. See [CHANGELOG.md](CHANGELOG.md) for the
current release and history.

## Quick Start

### 1. Pull an image

```bash
# From your project directory:
make -f ~/containers/dev_containers/ada/Makefile pull
```

### 2. Launch a container

```bash
cd ~/Ada/github.com/abitofhelp/my_project
make -f ~/containers/dev_containers/ada/Makefile run
```

The Makefile auto-detects the container CLI (docker on macOS and WSL2,
nerdctl on Linux), generates a sequential container name
(`dev-container-ada-1`, `-2`, etc.), passes your host identity (required; see
[Runtime Identity](#runtime-identity)), and mounts your current directory at
`/workspace`.

To run an image directly, pass the three identity variables yourself:

```bash
docker run -it --rm \
  -e HOST_USER="$(whoami)" -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -v "$PWD":/workspace -w /workspace \
  ghcr.io/abitofhelp/dev-container-ada:latest
```

### 3. Or use the shell aliases

If your `.zshrc` has the convenience functions configured:

```bash
adat     # Ada image — changes to the source root and launches a container
cppt     # C++ upstream image
got      # Go image
rustt    # Rust image
```

| Command | Image | amd64 (x86_64) | arm64 |
|---------|-------|:---:|:---:|
| `adat` | dev-container-ada (Alire) | yes | yes |
| `cppt` | dev-container-cpp | yes | yes |
| `cppst` | dev-container-cpp-system (APT) | yes | yes |
| `got` | dev-container-go | yes | yes |
| `rustt` | dev-container-rust | yes | yes |

## Platform Support

Every image is a **Linux 64-bit container** on every host, so the tools in it
build and test **Linux binaries**. Binaries for other operating systems are
built elsewhere (for example, natively on GitHub's Windows runners).

| Host | Architecture | Container runtime | Status |
|------|--------------|-------------------|--------|
| Linux (Ubuntu 24.04 or later) | amd64, arm64 | Docker Engine | Supported; tested in CI |
| Linux | amd64, arm64 | Rootless nerdctl | Supported; used by the maintainers; not tested in CI |
| Linux | amd64, arm64 | Rootless Podman | Supported; identity tests run in CI |
| macOS (Apple Silicon) | arm64 | Docker Desktop | Supported; the maintainers' daily environment |
| macOS (Intel) | amd64 | Docker Desktop | Expected to work; not tested |
| Windows 11 | amd64 | Docker Desktop with the WSL2 back end | Supported through WSL2 only; not tested |
| Windows 11, launched from PowerShell or CMD with the source on `C:\` | — | — | Not supported |

**Windows 11:** open a WSL2 shell, keep your source inside the WSL file
system (for example `~/src/my_project`, not `/mnt/c/...`), and launch from the
project directory. WSL2 provides the POSIX user and group IDs the containers
require, file ownership on the mount behaves as on Linux, and builds are much
faster than on a mounted Windows drive. The images run under emulation on
Windows on ARM; there are no native Windows on ARM images.

**Kubernetes (not tested):** the images could serve as hosted workspaces or
CI runners on a cluster. The pod must set `HOST_USER`, `HOST_UID`, and
`HOST_GID` as environment variables and start the container as root
(`runAsUser: 0`), so the entrypoint can create the account and then drop to
it; `fsGroup` should match `HOST_GID` for volume access. This setup has not
been tested.

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

### Rust Embedded / Teensy 4.1 Support

The Rust image supports both generic embedded Rust targets and a concrete
PJRC Teensy 4.1 workflow. Teensy 4.1 uses the NXP i.MX RT1062 Cortex-M7, so
Rust projects target `thumbv7em-none-eabihf` and produce Intel HEX files for
PJRC's loader.

| Target | Typical hardware | Runtime shape | Primary output |
|--------|------------------|---------------|----------------|
| `thumbv6m-none-eabi` | Cortex-M0/M0+ | `no_std` bare metal | ELF / BIN / HEX |
| `thumbv7m-none-eabi` | Cortex-M3 | `no_std` bare metal | ELF / BIN / HEX |
| `thumbv7em-none-eabi` | Cortex-M4/M7, soft-float ABI | `no_std` bare metal | ELF / BIN / HEX |
| `thumbv7em-none-eabihf` | Cortex-M4F/M7F, including Teensy 4.1 | `no_std` bare metal | ELF / Intel HEX |
| `thumbv8m.main-none-eabihf` | Cortex-M33-class MCUs | `no_std` bare metal | ELF / BIN / HEX |
| `armv7-unknown-linux-gnueabihf` | ARMv7 Linux SBCs / MPU targets | Linux userspace | Linux executable |

The Teensy 4.1 path includes:

- `cargo-binutils` / `cargo objcopy` for Intel HEX generation.
- `teensy_loader_cli` for PJRC command-line flashing.
- `cargo-generate` plus shell helpers for the upstream `teensy4-rs-template`.
- A smoke example at `rust/examples/teensy41_blink`.
- Detailed notes in [`rust/EMBEDDED.md`](rust/EMBEDDED.md).

Cargo cache behavior: the Rust image stores the pinned toolchain and
preinstalled cargo tools under `/opt`, while runtime Cargo cache and user cargo
installs use `${HOME}/.cargo`. This keeps the image reproducible and avoids
permission problems when building bind-mounted projects as the adapted host
user.

Inside the Rust container:

```bash
cd rust/examples/teensy41_blink
cargo objcopy --release -- -O ihex teensy41_blink.hex
```

Flash from a Linux host/container with USB access:

```bash
teensy_loader_cli --mcu=TEENSY41 -w -v teensy41_blink.hex
```

The container can always build the `.hex`. Direct flashing also requires host
USB access. On Linux, install PJRC's Teensy udev rules on the host. On macOS
with Docker Desktop, build in the container and flash from the macOS host with
the PJRC graphical Teensy Loader or a host-installed `teensy_loader_cli`.

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
  (`postgresql-client-18`, `clang-20`); Ubuntu's archive rotates exact
  versions, so exact-version apt pinning is discouraged. The Ada image
  instead pins APT to a dated Ubuntu snapshot (`UBUNTU_SNAPSHOT`) and
  records its exact package list in
  `/usr/share/doc/dev-containers/packages-<arch>.txt`.

Avoid `@latest`, `stable`, `HEAD`, `main`, and unverified downloads. If
you add a tool, add a `TOOLNAME_VERSION` (and `TOOLNAME_SHA256` where the
tool ships a binary release) to the `ARG` block at the top of the
Dockerfile.

The Ada image is the current reference for this policy: the Ubuntu base
image, Alire, GNAT, GPRbuild, GNATprove, Typst, and the Alire index are all
pinned, with SHA256 verification where applicable.

## Deprecated Images

| Image | Status | Use instead | Why |
|-------|--------|-------------|-----|
| `dev-container-ada-system` | Deprecated in v1.2.0; its Dockerfile was removed in v2.0.0. No new versions are published. | `dev-container-ada` | It was a workaround: Alire had no arm64 Linux GNAT, so Apple Silicon users needed Ubuntu's `gnat-13`. Alire now ships GNAT for arm64, and `dev-container-ada` supports amd64 and arm64. |

Existing `dev-container-ada-system` tags (including `v1.1.0` and
`system-gnat-13`) remain on GHCR for anyone who needs the old environment.
`ada/Dockerfile.system` and the Ada `*-system` Makefile targets were removed
in v2.0.0.

## Extending the Images

The published images contain only freely redistributable software. To add a
tool, including vendor tools that require accepting a license (for example,
an MCU vendor's programmer or an FPGA vendor's suite), build your own image
on top of a published one:

```dockerfile
FROM ghcr.io/abitofhelp/dev-container-cpp:v2.0.0

# Root-requiring installation belongs here, not in a running container.
RUN apt-get update \
 && apt-get install -y --no-install-recommends <package> \
 && rm -rf /var/lib/apt/lists/*
```

Pin the base image by version (or digest). A derived image inherits the
toolchain, the required runtime identity, the scoped `sudo` rule, and the
entrypoint unchanged.

**Licensing:** whoever builds a derived image is responsible for complying
with the licenses of the tools they add, and must not redistribute the image
unless those licenses allow it. This is a statement of policy, not legal
advice.

## How It Works

### Runtime Identity

The images contain **no built-in human account**. At startup, `entrypoint.sh`
creates exactly one account from three **required** environment variables:

| Variable | Meaning |
|----------|---------|
| `HOST_USER` | User name (lowercase letters, digits, `_`, `-`; not `root`) |
| `HOST_UID` | Numeric UID (not 0) |
| `HOST_GID` | Numeric GID |

The variables *declare* the identity of the person who launched the
container. They are supplied by the launcher (the Makefiles,
`container_run.py`, or your own `docker run`); the container does not
authenticate anyone. Authentication happens on the host.

- If any variable is missing or invalid, the container **refuses to start**
  (exit status 64) and prints how to launch it. There is no fallback account.
- An existing account is reused only if its name, UID, and GID all match, as
  when a stopped container is restarted. Any conflicting account stops the
  container.
- An existing group with `HOST_GID` is reused under its own name (for
  example, macOS's GID 20 is `dialout` in Ubuntu).
- Per-user settings come from `/etc/skel`.

**sudo:** the account may run the package managers with `sudo` and no
password: `apt-get` and `apt` in every image, plus `pip` (`/opt/venv/bin/pip`
in the Ada image; `/usr/bin/pip3` elsewhere). This is a guardrail against
accidental system changes, **not a security boundary**: installing packages
runs code as root, so the container itself is the boundary. Configuration
that needs root belongs in the image, or in a [derived image](#extending-the-images).
For ordinary Python packages, prefer a project virtual environment.

**Opening another shell in a running container:**

| Runtime | Command |
|---------|---------|
| Docker, Docker Desktop, Podman | `docker exec -it -u "$(id -u)" <container> zsh` (or `podman exec`) |
| Rootless nerdctl | `nerdctl exec -it <container> zsh` (UID 0, which is your host user) |

**Maintainer diagnostics:** to inspect an image as root without the
entrypoint, use the runtime directly, for example
`docker run -it --rm --entrypoint bash -u 0 <image>`. Anyone with access to
the container runtime already has this power; it is deliberately not offered
by the everyday launcher or Makefile targets.

### Container CLI Auto-Detection

The Makefile and `container_run.py` launcher script automatically detect
the host platform:

| Host | CLI | Runtime |
|------|-----|---------|
| macOS | docker | Docker Desktop |
| Linux | nerdctl | Rootless containerd |
| Windows 11 (WSL2 shell) | docker | Docker Desktop |

From native Windows (PowerShell or CMD), the launcher stops and asks you to
use a WSL2 shell.

Override with `CONTAINER_CLI=docker` or the `--cli` flag.

### Container Naming

Containers are named sequentially: `dev-container-ada-1`, `-2`, `-3`, etc.
This allows multiple containers from the same image to run simultaneously
with predictable names.

## Deployment Environments

| Runtime | Container UID 0 is... | The session runs as... | Security boundary |
|---------|----------------------|------------------------|-------------------|
| Docker rootful, Docker Desktop | Real root | `HOST_USER` (dropped via gosu) | Container isolation |
| nerdctl rootless | The host user | Container UID 0 (= the host user) | User namespace |
| Podman rootless (`--userns=keep-id --user 0:0`) | A subordinate UID | `HOST_USER` (dropped via gosu) | User namespace |
| Kubernetes (not tested) | Depends on pod policy | `HOST_USER`, if the pod starts as root | Pod security standards |

In every case `HOST_USER`, `HOST_UID`, and `HOST_GID` are required.

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
│   ├── Dockerfile           ← Alire-managed toolchain (Ubuntu 26.04)
│   ├── Dockerfile.system    ← DEPRECATED system toolchain (Ubuntu 24.04)
│   ├── Makefile             ← thin: sets vars, includes Makefile.common
│   ├── dev-doctor.sh        ← prints every tool version (dev-doctor)
│   ├── .zshrc               ← Ada-specific shell config
│   ├── examples/hello_ada/
│   └── tests/               ← acceptance tests and fixtures
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
    ├── Dockerfile           ← Rust 1.95.0 via rustup
    ├── Makefile
    ├── .zshrc
    └── examples/hello_rust/
```

## Makefile Targets

Run `make -f <lang>/Makefile help` for the full list.  Common targets:

```bash
make -f ada/Makefile build          # Build the image
make -f ada/Makefile run            # Launch container (auto-detects CLI)
make -f ada/Makefile test           # Acceptance tests (A1-A9, I1-I4)
make -f ada/Makefile test-offline   # Offline build test (A10)
make -f ada/Makefile doctor         # Print every tool version
make -f ada/Makefile inspect        # Show configured variables
make -f ada/Makefile help           # Full target list
```

For hosts that should explicitly use Docker Desktop, such as macOS, use the
Docker convenience aliases from the repository root:

```bash
make -f rust/Makefile docker-build
make -f rust/Makefile test-docker
make -f rust/Makefile test-teensy41-docker
```

The Docker and Podman aliases stay in the same Makefile invocation as the
language wrapper, so they preserve the `-f <lang>/Makefile` context and the
shared repo-root build context.

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
