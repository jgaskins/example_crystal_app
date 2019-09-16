FROM crystallang/crystal:0.30.1

ARG NEO4J_URL
ARG NEO4J_USE_SSL
ARG AMQP_URL

ADD . /src
WORKDIR /src

RUN shards build --production

ENV NEO4J_URL ${NEO4J_URL}
ENV NEO4J_USE_SSL ${NEO4J_USE_SSL}
ENV AMQP_URL ${AMQP_URL}

EXPOSE 8080/tcp

CMD ["bin/example_crystal_app"]
