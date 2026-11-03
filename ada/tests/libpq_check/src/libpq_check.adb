--  Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  Acceptance fixture A8: proves that the libpq headers' library links and
--  resolves at run time. It prints the libpq version (for example, 180006)
--  and exits with a failure status if libpq is older than 17.

with Ada.Command_Line;
with Ada.Text_IO;
with Interfaces.C;

procedure Libpq_Check is
   function PQlibVersion return Interfaces.C.int
     with Import, Convention => C, External_Name => "PQlibVersion";

   Version : constant Integer := Integer (PQlibVersion);
begin
   Ada.Text_IO.Put_Line ("libpq version:" & Integer'Image (Version));
   if Version < 170_000 then
      Ada.Text_IO.Put_Line ("libpq 17 or later is required.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Libpq_Check;
