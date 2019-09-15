FROM crystallang/crystal:0.30.1

RUN /bin/bash -l -c "shards install"
RUN /bin/bash -l -c "shards build --release"

CMD ["bin/example_crystal_app"]
