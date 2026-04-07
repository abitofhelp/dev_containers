# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
