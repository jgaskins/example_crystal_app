FROM crystallang/crystal:0.30.1

ADD . /src
WORKDIR /src

RUN shards build --production

EXPOSE 8080/tcp

CMD ["bin/example_crystal_app"]
