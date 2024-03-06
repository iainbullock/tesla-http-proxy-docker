FROM alpine:3.19.1

# install dependencies
RUN apk add --no-cache \
  python3 \
  py3-flask \
  py3-requests \
  go \
  gpg-agent \
  pass \
  openssl

# Create various working directories
RUN mkdir -p /app/templates /data /share

# Copy project files into required locations
ADD https://raw.githubusercontent.com/iainbullock/tesla-http-proxy-docker/main/tesla_http_proxy/app/templates/callback.html /app/templates
ADD https://raw.githubusercontent.com/iainbullock/tesla-http-proxy-docker/main/tesla_http_proxy/app/templates/index.html /app/templates
ADD https://raw.githubusercontent.com/iainbullock/tesla-http-proxy-docker/main/tesla_http_proxy/app/run.py /app
ADD https://raw.githubusercontent.com/iainbullock/tesla-http-proxy-docker/main/tesla_http_proxy/app/run.sh /app
ADD https://raw.githubusercontent.com/iainbullock/tesla-http-proxy-docker/main/tesla_http_proxy/app/config.sh /root
RUN chmod go+x /app/run.sh && chmod go+r /app/templates/* && chmod 0700 /root/config.sh

# install Tesla Go packages
ADD https://github.com/teslamotors/vehicle-command/archive/refs/heads/main.zip /tmp
RUN unzip /tmp/main.zip -d /app
WORKDIR /app/vehicle-command-main
RUN go get ./... && \
  go build ./... && \
  go install ./...
# installed to /root/go/bin/tesla-http-proxy

# Set environment variables
ENV PATH="/root/go/bin:${PATH}"
ENV GNUPGHOME="/data/gnugpg"
ENV PASSWORD_STORE_DIR="/data/password-store"

# Tidy up
RUN rm -fr /app/vehicle-command-main /tmp/main.zip

# Python 3 HTTP Server serves the current working dir
WORKDIR /app

