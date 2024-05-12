# Tesla HTTP Proxy Cloudflare Tunnel Config
A short guide for hosting the Tesla HTTP Proxy through a Cloudflare tunnel.
## Assumptions
This guide assumes the following:
* You have a working Cloudflare tunnel on your Home Assistant instance
* You are using the [Cloudflared add-on](https://github.com/brenner-tobias/addon-cloudflared) for Home Assistant
* You have configured your developer account on [developer.tesla.com](https://developer.tesla.com) and have your Client ID / Secret Key
* You **have not installed the Nginx add-on** (uninstall it if you have)
## Configure Cloudflare Zero Trust
* In the Zero Trust control panel, select your tunnel and add a new public hostname
  * The subdomain should match the one used on the Tesla developer page (Example: tsla.someplace.com)
  * Type: HTTPS
  * URL: IP:Port used for Nginx (Example: 192.168.1.2:10443)
* Click the "Additional application settings" link below the hostname config
  * TLS > Origin Server Name
    * Enter your domain name _without the subdomain_ (Example: someplace.com)
  * TLS > No TLS Verify
    * Enabled (check the box)
* Click "Save hostname"
## Configure the Cloudflared Home Assistant add-on
* Configure the following in the "Additional Hosts" section of the add-on: 
```
- hostname: tsla.someplace.com
  service: https://192.168.1.2:10443
  originRequest:
    noTLSVerify: true
    originServerName: someplace.com
```
## Install and configure the Nginx Home Assistant add-on
* Install the Nginx add-on from the Home Assistant add-on library
* Set your domain (Example: someplace.com)
* Select the "Cloudflare" option so Nginx adds Cloudflare's IPs to its config
* Set your port to the one you configured in the Cloudflare Zero Trust control panel
* Save and start Nginx

## Install and configure the Tesla HTTP Proxy add-on
* Install Tesla HTTP Proxy from the Home Assistant add-on library
* Configure your Client ID, Client Secret, and FQDN (Example: tsla.someplace.com)
* Save and start the add-on

## Reconfigure the Nginx add-on
* In the "Customize" section, configure the following:
```
active: true
default: nginx_proxy_default*.conf
servers: nginx_proxy/*.conf
```
* Save and restart the add-on

## Finishing Up
Watch the Tesla HTTP Proxy logs. If everything was configured correctly, you should see "Starting Tesla HTTP Proxy" at the bottom of your logs. 
```
[18:05:36] webui:INFO: Starting Flask server for Web UI...
[18:05:36] werkzeug:INFO: WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:8099
 * Running on http://172.30.33.12:8099
[18:05:36] werkzeug:INFO: Press CTRL+C to quit
[18:05:37] INFO: Found existing keypair
[18:05:37] INFO: Testing public key...
HTTP/2 200 
.
.
.
-----BEGIN PUBLIC KEY-----
.
.
-----END PUBLIC KEY-----
[18:05:37] INFO: Running auth.py
[18:05:38] auth:INFO: Generating Partner Authentication Token
[18:05:38] auth:INFO: Registering Tesla account...
[18:05:39] INFO: Starting Tesla HTTP Proxy
```
Proceed with the rest of the setup / configuration as per the standard configuration instructions.

## Debugging
If things don't seem to be working as expected, be sure to check the Cloudflared, Nginx, and Tesla HTTP Proxy logs for clues. 