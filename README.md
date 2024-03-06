# Tesla HTTP Proxy Docker

Fork of https://github.com/llamafilm/tesla-http-proxy-addon

Provides a standalone docker version instead of Home Assistant Add-on. This means it can work with versions of Home Assistant which don't allow Add-Ons (e.g. docker version).

Work in progress it doesn't work yet :)

This will build a Docker image which can be deployed as a standalone Docker container to run the official [Tesla HTTP Proxy](https://github.com/teslamotors/vehicle-command) to allow Fleet API requests on modern vehicles.  Please do not bother Tesla for support on this.

## About
Runs a temporary Flask web server to handle initial Tesla authorization flow and store the refresh token.  Once that is complete, it quits Flask and runs Tesla's HTTP Proxy code in Go.

Setting this up is fairly complex.  Please read [DOCS.md](./tesla_http_proxy/DOCS.md) for details.
