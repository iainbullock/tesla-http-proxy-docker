#!/bin/bash
#export TESLA_AUTH_TOKEN=XXXXXXXX

curl --cacert ../cert.pem \
    --header "Authorization: Bearer $TESLA_AUTH_TOKEN" \
    "https://$PROXY_HOST:4430/api/1/vehicles"
