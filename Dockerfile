FROM prosyslab/dude
# COPY entrypoint.sh /entrypoint.sh
COPY .github/workflows/main.yml /.github/workflows/main.yml
COPY action.yml /action.yml
COPY dune /dune
COPY dune-project /dune-project
COPY ocaml_test.ml /ocaml_test.ml
RUN eval $(opam env); dune build ocaml_test.exe; dune exec ocaml_test.exe $1 $2
# ENTRYPOINT ["/entrypoint.sh"]
# RUN dune build ocaml_test.exe
# RUN dune exec ./ocaml_test.exe $1 $2