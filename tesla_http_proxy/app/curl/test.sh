#!/bin/bash
TESLA_AUTH_TOKEN=XXXXXXXX
VIN=xxxxxxxxxxxxxxxxx

curl --cacert cert.pem \
    --header "Authorization: Bearer $TESLA_AUTH_TOKEN" \
    "https://macmini.home:4430/api/1/vehicles"
