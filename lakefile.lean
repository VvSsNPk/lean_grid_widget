import Lake

open System Lake DSL

package Internship where version := v!"0.1.0"

lean_lib Internship

@[default_target] lean_exe internship where root := `Main

require "leanprover-community" / "proofwidgets" @ git "v0.0.114"
