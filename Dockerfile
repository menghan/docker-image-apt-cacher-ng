# extellisys/apt-cacher-ng - a simple apt-cacher-ng service
#
# VERSION 0.1.0
# DOCKER-VERSION 0.8.0
#
# TO_BUILD: docker build -rm -t apt-cacher-ng .
# TO_RUN: docker run -d -p 3142:3142 \
#           -v /tmp/apt-cacher-ng:/var/cache/apt-cacher-ng \
#           apt-cacher-ng

FROM extellisys/debian-wheezy:latest
MAINTAINER: Travis Cardwell <travis.cardwell@extellisys.com>

RUN apt-get install -y apt-cacher-ng

EXPOSE 3142

CMD /usr/sbin/apt-cacher-ng ForeGround=1 CacheDir=/var/cache/apt-cacher-ng
