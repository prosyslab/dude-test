FROM prosyslab/dude
# COPY entrypoint.sh /entrypoint.sh
RUN eval $(opam env); dune build ocaml_test.exe; dune exec ./ocaml_test.exe $1 $2
# ENTRYPOINT ["/entrypoint.sh"]
# RUN dune build ocaml_test.exe
# RUN dune exec ./ocaml_test.exe $1 $2