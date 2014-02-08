Apt-Cacher-NG Docker Image
==========================

[extellisys/apt-cacher-ng](https://index.docker.io/u/extellisys/apt-cacher-ng/)
is a [Docker](http://www.docker.io/) image that runs a simple configuration of
[Apt-Cacher-NG](http://www.unix-ag.uni-kl.de/~bloch/acng/), a caching proxy
for software packages which are downloaded by Unix/Linux system distribution
mechanisms from mirror servers accessible via HTTP.

This simple configuration does not use any access control or save any logs.
It is intended to be used in a trusted environment, such as within a LAN
behind a firewall.

Installation
------------

The image is available from the [Index](https://index.docker.io/) using the
following `pull` command:

    $ sudo docker pull extellisys/apt-cacher-ng:latest

Build instructions are provided below for those who are security-concious and
would like to build the image themselves.

One-Time Usage
--------------

If you need a caching proxy for a one-time event, such as a hackathon, then
you can run the service as follows:

    $ sudo docker run -d -p 3142:3142 extellisys/apt-cacher-ng:latest

This command maps port `3142` of the host machine to the container, binding
all available interfaces.  To bind to other interfaces or ports, see the
Docker documentation on
[port redirection](http://docs.docker.io/en/latest/use/port_redirection/).

If the address of the host machine on the LAN is `192.168.0.1`, then
Debian/Ubuntu systems within the LAN can use the proxy by adding the following
configuration:

    $ echo 'Acquire::http { Proxy "http://192.168.0.1:3142"; };' | \
      sudo tee /etc/apt/apt.conf.d/02proxy

Users can later remove the setting by removing the added configuration:

    $ sudo rm /etc/apt/apt.conf.d/02proxy

When the event is over, the container can be shut down and removed using
[docker stop](http://docs.docker.io/en/latest/reference/commandline/cli/#stop)
and [docker rm](http://docs.docker.io/en/latest/reference/commandline/cli/#rm)
commands.  For example, the following should work when this is the only
container being run:

    $ sudo docker stop $(docker ps -l -q)
    $ sudo docker rm $(docker ps -l -q)

Long-Term Usage
---------------

If you need a caching proxy as a long-term service in your LAN, then it is a
good idea to store the cache files on the host machine.  First, create a
directory for them; for example:

    $ sudo mkdir /var/cache/DockerAptCacher

Run the service with a command like the following:

    $ sudo docker run -d -p 3142:3142 \
      -v /var/cache/DockerAptCacher:/var/cache/apt-cacher-ng \
      extellisys/apt-cacher-ng:latest

This command maps port `3142` of the host machine to the container, binding
all available interfaces.  To bind to other interfaces or ports, see the
Docker documentation on
[port redirection](http://docs.docker.io/en/latest/use/port_redirection/).

This command also bind-mounts the host directory `/var/cache/DockerAptCacher`
so that the cache files are stored there.  The service can therefore be
stopped, removed, and rebuilt without losing the cache.

If the address of the host machine on the LAN is `192.168.0.1`, then
Debian/Ubuntu systems within the LAN can use the proxy by adding the following
configuration:

    $ echo 'Acquire::http { Proxy "http://192.168.0.1:3142"; };' | \
      sudo tee /etc/apt/apt.conf.d/02proxy

Build Instructions
------------------

This image is based on
[extellisys/debian-wheezy](https://index.docker.io/u/extellisys/debian-wheezy/).
If you would like to build the base image yourself as well, follow the
[extellisys/debian-wheezy build instructions](https://github.com/extellisys/docker-update-tagged-bases/blob/master/debian-wheezy.md).

Switch to the `/tmp` directory:

    $ cd /tmp

Clone this repository to get the Dockerfile:

    $ git clone https://github.com/extellisys/docker-image-apt-cacher-ng.git
    $ cd docker-image-apt-cacher-ng

Build the image:

    $ sudo docker build --rm -t extellisys/apt-cacher-ng:latest .

Explanation of parameters:

* `--rm` tells Docker to remove intermediate containers.
* `-t extellisys/apt-cacher-ng:latest` specifies the repository name and tag.
  Change this to your own when building your own image.
* `.` tells Docker to look for the file `Dockerfile` in the current directory.

Clean up:

    $ cd
    $ rm -rf /tmp/apt-cacher-ng

This image is usable at this point, but I also perform the following hack in
order to squash the multiple layers created by the Dockerfile.

Switch to root:

    $ sudo su -

Create a directory to work in:

    # mkdir /tmp/apt-cacher-ng-hack
    # cd /tmp/apt-cacher-ng-hack

Find the image IDs for all layers of the `apt-cacher-ng` repository:

    # docker images -tree | less

Example:

    +-bfae89f72c95 Virtual Size: 117.8 MB Tags: ...debian-wheezy...
      +-78054acc5fe0 Virtual Size: 117.8 MB
        +-4a790d9602b4 Virtual Size: 152.8 MB
          +-845baea42731 Virtual Size: 152.8 MB
            +-7c762a3c427a Virtual Size: 152.8 MB Tags: ...apt-cacher-ng...

The images, from top to bottom, are:

1. `bfae` is the debian-wheezy base image.
2. `7805` adds the `MAINTAINER` metadata.
3. `4a79` adds the filesystem changes made by the `RUN` command.
4. `845b` adds the `EXPOSE` metadata.
5. `7c76` adds the `CMD` metadata.

Export these images to the current directory:

    # docker save extellisys/apt-cacher-ng:latest | tar -x

Our goal is to squash layers 2 through 5 into a single image.  The parent of
the squashed image (keeping ID `7c76`) should be the debian-wheezy base image
(ID `bfae`).  Full IDs are required in the metadata, so we make this change
first, while the full IDs are easily available as exported directory names.

Put the full IDs into a file called `reparent` as follows:

    # ls > reparent

Now edit the file according to the following template, but using the full
IDs instead of the short versions:

    sed -i 's/845b/bfae/g' 7c76/json

This script changes the metadata of the 5th layer, changing the parent from
the 4th layer to the 1st layer.  Execute the script to make the change:

    # sh reparent

Remove the script:

    # rm reparent

We do not need the 2nd and 4th layers at all, as the metadata of the 5th layer
overwrites/persists those changes anyway, so delete them:

    # rm -rf 7805* 845b*

We will not modify the 1st layer or remove it from Docker, so delete the
export:

    # rm -rf bfae*

We do not need the filesystem of the 5th layer, as it is empty, so delete it:

    # rm 7c76*/layer.tar

We need the filesystem of the 3rd layer, so move it into the 5th layer:

    # mv 4a79*/layer.tar 7c76*

We do not need the metadata of the 3rd layer, so delete it:

    # rm -rf 4a79*

Replace  the `container_config` `Cmd` value in the metadata for the 5th layer
with a link to this documentation, so that it is shown in `docker history`:

    # sed -i 's!"#(nop)[^"]*"!"#(nop) https://github.com/extellisys/docker-image-apt-cacher-ng"!' 7c76*/json

Note the use of `!` characters as delimiters in `sed` so that the slashes in
the URL do not cause problems.

At this point, we have the data for a single, squashed image.

Remove the old images from Docker:

    # docker rmi extellisys/apt-cacher-ng:latest

Load the squashed image:

    # tar -c . | docker load

Tag the squashed image:

    # docker tag 7c76 extellisys/apt-cacher-ng:latest

Clean up:

    # cd
    # rm -rf /tmp/apt-cacher-ng-hack

Contact
-------

Please submit any issues to:

<https://github.com/extellisys/docker-image-apt-cacher-ng/issues>

If you do not have a [GitHub](https://github.com) account, feel free to submit
issues via email to <bugs@extellisys.com>.
