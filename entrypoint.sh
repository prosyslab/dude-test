#!/bin/bash -l

# opam init --yes
# eval $(opam env)
# opam install dune

# eval $(opam env)

# dune build ocaml_test.exe

opam switch
# dune exec ./ocaml_test.exe $1 $2 