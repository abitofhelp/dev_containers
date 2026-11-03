--  Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  Acceptance fixture A10: uses a crate from the Alire index, so the build
--  only succeeds offline if the dependency was prefetched.

with libhello;

procedure Offline_Deps is
begin
   libhello.Hello_World;
end Offline_Deps;
