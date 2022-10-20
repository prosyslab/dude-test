FROM prosyslab/dude
COPY entrypoint.sh /entrypoint.sh
RUN eval $(opam env)
ENTRYPOINT ["/entrypoint.sh"]