#!/bin/bash -l

opam init --yes
eval $(opam env)
opam install dune
opam install cohttp-lwt-unix

# dune build ocaml_test.exe

dune exec ./ocaml_test.exe $1 $2 $3 # $1: issue_num, $2: issue_contents, $3: repository_url