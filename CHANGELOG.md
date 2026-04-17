# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

All container images published from this repository share the repository
version. The legacy per-image version numbers from the archived pre-monorepo
repositories (ada 2.2.3, ada-system 2.2.3, cpp 1.1.2, cpp-system 1.1.2,
go 1.1.0, rust 1.0.2) are retired.

## [Unreleased]

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

For changes prior to the monorepo consolidation, see the archived individual
repositories:

- [dev_container_ada](https://github.com/abitofhelp/dev_container_ada) (archived)
- [dev_container_cpp](https://github.com/abitofhelp/dev_container_cpp) (archived)
- [dev_container_go](https://github.com/abitofhelp/dev_container_go) (archived)
- [dev_container_rust](https://github.com/abitofhelp/dev_container_rust) (archived)
