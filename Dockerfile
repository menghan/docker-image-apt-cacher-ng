# TO_BUILD: docker build -rm -t apt-cacher-ng .
# TO_RUN: docker run -d -p 3142:3142 apt-cacher-ng

FROM debian:latest
MAINTAINER Menghan Zheng <menghan412@gmail.com>

RUN apt-get update
RUN apt-get install -y apt-cacher-ng

VOLUME ["/var/cache/apt-cacher-ng"]

EXPOSE 3142

ENTRYPOINT ["/usr/sbin/apt-cacher-ng"]
CMD ["ForeGround=1", "CacheDir=/var/cache/apt-cacher-ng"]
