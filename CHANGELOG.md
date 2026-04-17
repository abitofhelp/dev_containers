# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Reproducibility Policy section in README.md documenting version-pinning
  requirements for tools installed in Dockerfiles.
- SHA256 verification for Typst, Bazelisk, Buf, golangci-lint, and
  cargo-binstall downloads.
- `TYPST_SHA256_AMD64` / `TYPST_SHA256_ARM64` build args; Typst install is
  now architecture-aware across all arm64-capable images (previously
  downloaded the x86_64 binary unconditionally).

### Changed

- Pinned `go install` tool versions (gopls v0.21.1, delve v1.26.1,
  staticcheck 2026.1, protoc-gen-go v1.36.11, protoc-gen-go-grpc v1.6.1)
  in `go/Dockerfile` — previously installed from `@latest`.
- Replaced `curl | sh` installer for golangci-lint with a SHA256-verified
  tarball download pinned to v2.11.4.
- Pinned Rust toolchain to 1.95.0 in `rust/Dockerfile` — previously
  followed the `stable` channel.
- Replaced `curl | bash` installer for cargo-binstall with a
  SHA256-verified tarball pinned to v1.18.1.
- Pinned cargo-installed tools: probe-rs-tools 0.31.0, cargo-generate
  0.23.8, cargo-expand 1.0.121, sccache 0.14.0.
- Pinned vcpkg to tagged release 2026.03.18 in `cpp/Dockerfile` — previously
  cloned HEAD of the default branch.
- Pinned pytest to 9.0.3 across all six Dockerfiles — previously installed
  the latest version on the PyPI index at build time.

## [1.0.0] - 2026-04-06

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

### Container Images

| Image | Version | Notes |
|-------|---------|-------|
| dev-container-ada | 2.2.3 | Alire-managed GNAT 15.2.1, amd64 only |
| dev-container-ada-system | 2.2.3 | APT gnat-13, amd64 + arm64 |
| dev-container-cpp | 1.1.2 | Clang 20, CMake, vcpkg, amd64 + arm64 |
| dev-container-cpp-system | 1.1.2 | GCC 13, Clang 18, amd64 + arm64 |
| dev-container-go | 1.1.0 | Go 1.26.1, protobuf, Bazelisk, amd64 + arm64 |
| dev-container-rust | 1.0.2 | Rust stable via rustup, amd64 + arm64 |

### Previous History

For changes prior to the monorepo consolidation, see the archived
individual repositories:

- [dev_container_ada](https://github.com/abitofhelp/dev_container_ada) (archived)
- [dev_container_cpp](https://github.com/abitofhelp/dev_container_cpp) (archived)
- [dev_container_go](https://github.com/abitofhelp/dev_container_go) (archived)
- [dev_container_rust](https://github.com/abitofhelp/dev_container_rust) (archived)
