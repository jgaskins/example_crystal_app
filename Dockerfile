FROM crystallang/crystal:0.30.1

ADD . /src
WORKDIR /src

RUN shards build --production

CMD ["bin/example_crystal_app"]
