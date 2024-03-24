#!/bin/bash
#TESLA_AUTH_TOKEN=XXXXXX
#VIN=xxxxxxxxxxxxxxxxx

curl --cacert ../cert.pem \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $TESLA_AUTH_TOKEN" \
    --data '{"sound": "1"}' \
    "https://macmini.home:4430/api/1/vehicles/$VIN/command/remote_boombox"
