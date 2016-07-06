FROM postgres:9.5
MAINTAINER Peter Mount <peter@retep.org>

RUN mkdir -p /docker-entrypoint-initdb.d
COPY *.sh /docker-entrypoint-initdb.d/

