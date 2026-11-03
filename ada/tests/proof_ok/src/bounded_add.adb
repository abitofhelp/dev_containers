--  Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause

package body Bounded_Add
  with SPARK_Mode => On
is
   function Add (A, B : Natural) return Natural is (A + B);
end Bounded_Add;
