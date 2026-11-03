--  Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  Acceptance fixture A4: the precondition rules out overflow, so GNATprove
--  must prove every check.

package Bounded_Add
  with SPARK_Mode => On
is
   function Add (A, B : Natural) return Natural
   with Pre  => A <= 1_000 and then B <= 1_000,
        Post => Add'Result = A + B;
end Bounded_Add;
