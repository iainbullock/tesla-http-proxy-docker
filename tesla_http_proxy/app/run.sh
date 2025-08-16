#!/bin/ash
set -e

# read options
cp -n /app/config.sh /data
. /data/config.sh

# Exit if options not setup
if [ $OPTIONS_COMPLETE != 1 ]; then
  echo "Configuration options not set in /data/config.sh, exiting"
  echo "Change OPTIONS_COMPLETE=0 to OPTIONS_COMPLETE=1 in /data/config.sh when the configuration parameters have been set"
  exit 0
fi

echo "Configuration Options are:"
echo CLIENT_ID=$CLIENT_ID
echo "CLIENT_SECRET=Not Shown"
echo DOMAIN=$DOMAIN
echo PROXY_HOST=$PROXY_HOST
echo REGION=$REGION

generate_ssl_certs() {
  # generate self signed SSL certificate
  echo "Generating self-signed SSL certificate"
  openssl req -x509 -nodes -newkey ec \
    -pkeyopt ec_paramgen_curve:secp521r1 \
    -pkeyopt ec_param_enc:named_curve \
    -subj "/CN=${PROXY_HOST}" \
    -keyout /data/key.pem -out /data/cert.pem -sha256 -days 3650 \
    -addext "extendedKeyUsage = serverAuth" \
    -addext "keyUsage = digitalSignature, keyCertSign, keyAgreement"
  mkdir -p /share/home-assistant
  cp /data/cert.pem /share/home-assistant/selfsigned.pem
}

generate_tesla_keypair() {
  # Generate keypair
  echo "Generating keypair"
  mkdir -p /share/nginx
  tesla-keygen -f -keyring-type pass -key-name myself create >/share/nginx/com.tesla.3p.public-key.pem
  cat /share/nginx/com.tesla.3p.public-key.pem
}

# run on first launch only
if ! pass >/dev/null 2>&1; then
  echo "Setting up for first launch"
  echo "Setting up GnuPG and password-store"
  mkdir -m 700 -p /data/gnugpg
  gpg --batch --passphrase '' --quick-gen-key myself default default
  gpg --list-keys
  pass init myself
  generate_tesla_keypair

# verify certificate exists
elif [ ! -f /share/nginx/com.tesla.3p.public-key.pem ]; then
  echo "Public key com.tesla.3p.public-key.pem missing from /share"
  generate_tesla_keypair
fi

if [ -f /share/home-assistant/selfsigned.pem ] && [ -f /data/key.pem ]; then
  certPubKey="$(openssl x509 -noout -pubkey -in /share/home-assistant/selfsigned.pem)"
  keyPubKey="$(openssl pkey -pubout -in /data/key.pem)"
  if [ "${certPubKey}" == "${keyPubKey}" ]; then
    echo "Found existing keypair"
  else
    echo "Existing certificate is invalid"
    generate_ssl_certs
  fi
else
  echo "SSL certificate does not exist"
  generate_ssl_certs
fi

if ! [ -f /data/access_token ]; then
  echo "Starting temporary Python app for authentication flow. Delete /data/access_token to force regeneration in the future"
  python3 /app/run.py --client-id "$CLIENT_ID" --client-secret "$CLIENT_SECRET" --domain "$DOMAIN" --region "$REGION" --proxy-host "$PROXY_HOST"
fi

echo "Starting Tesla HTTP Proxy"
tesla-http-proxy -keyring-debug -keyring-type pass -key-name myself -cert /data/cert.pem -tls-key /data/key.pem -port 443 -host 0.0.0.0 -verbose
