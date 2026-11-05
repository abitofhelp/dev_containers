# Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
#
# Acceptance fixture: a vcpkg manifest-mode project built by the non-root
# session user against the image's read-only /opt/vcpkg (issue #6).
cmake_minimum_required(VERSION 3.25)
project(vcpkg_manifest_check CXX)
find_package(fmt CONFIG REQUIRED)
add_executable(vcpkg_manifest_check main.cpp)
target_link_libraries(vcpkg_manifest_check PRIVATE fmt::fmt)
