# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

All container images published from this repository share the repository
version. The legacy per-image version numbers from the archived pre-monorepo
repositories (ada 2.2.3, ada-system 2.2.3, cpp 1.1.2, cpp-system 1.1.2,
go 1.1.0, rust 1.0.2) are retired.

## [Unreleased]

## [1.1.0] - 2026-06-22

Adds Rust embedded development support for the PJRC Teensy 4.1 board
(NXP i.MX RT1062 ARM Cortex-M7), along with shared infrastructure fixes for
the Docker/Podman Makefile aliases and the Rust runtime Cargo cache. This is a
Rust-only feature addition; the Ada, C++, and Go images are unchanged.

### Added

- Rust image: add Teensy 4.1 / NXP i.MX RT1062 Cortex-M7 bare-metal support
  path with `cargo-binutils` (`cargo objcopy`) and `teensy_loader_cli`.
- Rust image: add `rust/examples/teensy41_blink`, a `no_std` RTIC blink and
  USB-logging example targeting `thumbv7em-none-eabihf` and `board::t41`.
- Rust Makefile: add `test-teensy41`, `test-teensy41-docker`, and
  `test-teensy41-podman` smoke-test targets that build a Teensy 4.1 `.hex`.
- Rust Makefile: add `clean-teensy41` for generated embedded build outputs.
- Rust shell: add `teensy41_template`, `teensy41_hex`, `teensy41_flash`, and
  `teensy41_build_flash` helper functions.
- Rust docs: add `rust/EMBEDDED.md` with the embedded target matrix,
  Teensy 4.1 build/flash split, host USB caveats, troubleshooting, and guidance
  for adding future board-specific workflows.

### Fixed

- Fixed Rust container runtime Cargo cache ownership: the entrypoint now uses `${HOME}/.cargo` for mutable registry/git/user install state while preserving `/opt/cargo/bin` for image-provided tools.
- Fixed Rust image and smoke-test Teensy loader verification to account for
  `teensy_loader_cli --list-mcus` printing supported MCUs and then exiting with
  a non-zero status. The checks now validate `TEENSY41` support without
  treating that documented loader behavior as a build failure, including inside
  `set -e` smoke-test scripts.
- Fixed Docker and Podman convenience aliases in `Makefile.common` so commands
  such as `make -f rust/Makefile docker-build` preserve the selected language
  Makefile context on macOS and other hosts.

### Documentation

- Clarified the canonical repository-root Makefile commands for Docker Desktop
  builds and Rust Teensy 4.1 smoke testing.

## [1.0.1] - 2026-04-17

Cosmetic cleanup following deletion of the archived pre-monorepo
repositories. No runtime behavior changes in any image.

### Changed

- CHANGELOG.md: drop dead hyperlinks to the retired repositories in the
  `Previous History` subsection of 1.0.0; keep the historical names as
  plain-text references for context.
- Dockerfile headers (6 files): `# Repository: dev_container_<lang>`
  updated to `# Repository: dev_containers`.
- Per-language Makefiles (4 files): wrapper comment and `PROJECT_NAME`
  updated to reference `dev_containers`. `PROJECT_NAME` only affects
  `make archive` tarball naming; image names are unchanged.
- Hello-world examples (4 files): stdout string updated from
  `Hello from <Lang> in dev_container_<lang>!` to
  `Hello from <Lang> in dev_containers!`.
- `ada/examples/hello_ada/alire.toml`: `website` URL updated to
  `https://github.com/abitofhelp/dev_containers`.

## [1.0.0] - 2026-04-17

First unified release of the consolidated dev containers monorepo. All six
container images (`dev-container-ada`, `dev-container-ada-system`,
`dev-container-cpp`, `dev-container-cpp-system`, `dev-container-go`,
`dev-container-rust`) ship at version `1.0.0`.

### Added

- Monorepo consolidating four dev container projects: Ada, C++, Go, Rust.
- Shared `entrypoint.sh` for runtime-adaptive user identity.
- Shared `Makefile.common` with auto-detected container CLI
  (macOS/Windows -> docker, Linux -> nerdctl).
- Sequential container naming via `container_run.py` shared launcher
  (e.g., `dev-container-ada-1`, `-2`, `-3`).
- Podman rootless support with `--userns=keep-id`.
- Linux host prerequisites: AppArmor userns fix, rootless containerd
  install, loginctl linger, XDG_RUNTIME_DIR detection.
- Unified README.md, USER_GUIDE.md, and CHANGELOG.md.
- Matrix GitHub Actions for build and publish across all images.
- `workflow_dispatch` trigger on `docker-build.yml` for manual reruns.
- Reproducibility Policy section in README.md documenting version-pinning
  requirements for tools installed in Dockerfiles.
- SHA256 verification for Typst, Bazelisk, Buf, golangci-lint, and
  cargo-binstall downloads.
- `TYPST_SHA256_AMD64` / `TYPST_SHA256_ARM64` build args; Typst install is
  now architecture-aware across all arm64-capable images (previously
  downloaded the x86_64 binary unconditionally).
- `release.yml` GitHub Actions workflow that creates a GitHub Release from
  CHANGELOG.md on `v*` tag push.

### Changed

- Pinned `go install` tool versions (gopls v0.21.1, delve v1.26.1,
  staticcheck 2026.1, protoc-gen-go v1.36.11, protoc-gen-go-grpc v1.6.1)
  in `go/Dockerfile`; previously installed from `@latest`.
- Replaced `curl | sh` installer for golangci-lint with a SHA256-verified
  tarball download pinned to v2.11.4.
- Pinned Rust toolchain to 1.95.0 in `rust/Dockerfile`; previously followed
  the `stable` channel.
- Replaced `curl | bash` installer for cargo-binstall with a SHA256-verified
  tarball pinned to v1.18.1.
- Pinned cargo-installed tools: probe-rs-tools 0.31.0, cargo-generate
  0.23.8, cargo-expand 1.0.121, sccache 0.14.0.
- Pinned vcpkg to tagged release 2026.03.18 in `cpp/Dockerfile`; previously
  cloned HEAD of the default branch.
- Pinned pytest to 9.0.3 across all six Dockerfiles; previously installed
  the latest version on the PyPI index at build time.

### Fixed

- Ada smoke test (CI and Makefile `TEST_SCRIPT` / `TEST_SCRIPT_SYSTEM`) now
  uses `alr run` instead of invoking `gprbuild -P` directly. `gprbuild -P`
  fails on a fresh clone because the Alire-generated
  `config/hello_ada_config.gpr` has not yet been created.

### Container Images

| Image | Base | Architectures | Embedded |
|-------|------|---------------|----------|
| dev-container-ada | Ubuntu 22.04 + Alire-managed GNAT 15.2.1 | amd64 | Cortex-M/A |
| dev-container-ada-system | Ubuntu 24.04 + APT gnat-13 | amd64, arm64 | Cortex-M/A |
| dev-container-cpp | Ubuntu 24.04 + Clang 20 + CMake + vcpkg | amd64, arm64 | Cortex-M/A |
| dev-container-cpp-system | Ubuntu 24.04 + GCC 13 + Clang 18 | amd64, arm64 | Cortex-M/A |
| dev-container-go | Ubuntu 24.04 + Go 1.26.1 + Bazelisk + protobuf | amd64, arm64 | — |
| dev-container-rust | Ubuntu 24.04 + Rust 1.95.0 via rustup | amd64, arm64 | Cortex-M/A |

### Previous History

The pre-monorepo per-language repositories (`dev_container_ada`,
`dev_container_cpp`, `dev_container_go`, `dev_container_rust`) have been
retired and deleted. Their histories were consolidated into this
repository's commit stream at the time of the monorepo migration.
