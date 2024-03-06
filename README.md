# Tesla HTTP Proxy Docker

Work in progress it doesn't work yet :)

Originally this was a fork of https://github.com/llamafilm/tesla-http-proxy-addon. All credit to llamafilm (https://github.com/llamafilm) for developing most of this. 

Provides a standalone docker version instead of a Home Assistant Add-on. This means it can work with versions of Home Assistant which don't allow Add-Ons (e.g. docker version).

This docker runs the official Tesla HTTP Proxy to allow Fleet API requests on modern vehicles. Please do not bother Tesla for support on this.

## About
Runs a temporary Flask web server to handle initial Tesla authorization flow and store the refresh token.  Once that is complete, it quits Flask and runs Tesla's HTTP Proxy code in Go.

Setting this up is fairly complex.  Please read [DOCS.md](./tesla_http_proxy/DOCS.md) for details (TODO), or follow the high level summary below:

## Installation and set up

 - Clone the repository onto your host machine

 - Build the docker image using the Dockerfile. Alternatively you can get the image directly from Dockerhub https://hub.docker.com/r/iainbullock/tesla_http_proxy

 - Deploy the docker stack using docker-compose.yml
