#!/bin/bash -l

opam init --yes
eval $(opam env)
opam install dune --yes
opam install cohttp-lwt-unix --yes --confirm-level=unsafe-yes

# dune build ocaml_test.exe

dune exec ./ocaml_test.exe $1 $2 $3 # $1: issue_num, $2: issue_contents, $3: repository_url