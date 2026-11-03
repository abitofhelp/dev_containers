--  Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  Acceptance fixture A5: with no precondition, A + B can overflow, so
--  GNATprove must report an unproved overflow check and, with
--  --checks-as-errors=on, exit with a nonzero status.

package Unbounded_Add
  with SPARK_Mode => On
is
   function Add (A, B : Natural) return Natural;
end Unbounded_Add;
