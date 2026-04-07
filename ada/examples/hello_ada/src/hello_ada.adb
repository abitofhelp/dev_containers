--  ===========================================================================
--  hello_ada.adb
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  See LICENSE file in the project root.
--  ===========================================================================
--
--  Minimal Ada program to verify the development container toolchain.
--
--  ===========================================================================

with Ada.Text_IO; use Ada.Text_IO;

procedure Hello_Ada is
begin
   Put_Line ("Hello from Ada in dev_container_ada!");
   Put_Line ("Toolchain verification: PASSED");
end Hello_Ada;
