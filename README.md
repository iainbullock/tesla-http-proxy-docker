# Tesla HTTP Proxy Docker

Now tested and working as expected with Home Assistant custom integration https://github.com/alandtse/tesla

Originally this was a fork of https://github.com/llamafilm/tesla-http-proxy-addon. All credit to llamafilm (https://github.com/llamafilm) for developing most of this. 

This version provides a standalone docker version instead of a Home Assistant Add-on. This means it can work with versions of Home Assistant which don't allow Add-Ons (e.g. docker version).

This docker runs the official Tesla HTTP Proxy to allow Fleet API requests on modern vehicles. Please do not bother Tesla for support on this.

## About
Runs a temporary Flask web server to handle initial Tesla authorization flow and store the refresh token.  Once that is complete, it quits Flask and runs Tesla's HTTP Proxy code in Go.

Setting this up is fairly complex.  Please read [DOCS.md](./tesla_http_proxy/DOCS.md) for details (TODO), or follow the high level summary below:

## Installation and set up

 - Setup your webserver so it can receive ssl connections to your FQDN from the internet. This FQDN should be different to that used to access your instance of Home Assistant. I have provided my Nginx configuration file (nginx_tesla.conf). The default config for this project assumes you are running Nginx in its own docker container, and the webserver document root for the FQDN is at /var/lib/docker/volumes/nginx/_data/tesla_http_proxy on the docker host. This can be changed in docker-compose.yml

 - Create a directory tesla_http_proxy in the /config directory of your Home Assistant (HA) instance. The default config for this project assumes you are running HA in its owner docker container and /config/tesla_http_proxy is at /var/lib/docker/volumes/home-assistant/_data/tesla_http_proxy on the docker host. This can be changed in docker-compose.yml

 - Build the docker image using the Dockerfile. Alternatively you can get the image directly from Dockerhub https://hub.docker.com/r/iainbullock/tesla_http_proxy

 - Make any required changes required to suit your setup in docker-compose.yml, and deploy the stack. On the first run of the container various files will be initialised and the container will exit

 - Enter your configuration parameters in /data/config.sh (/data is mounted as a volume on the docker host). This will override those specified in docker-compose.yml. Note that PROXY_HOST must not be an IP address; it must be a hostname which resolves to the IP address of your docker host in both HA and proxy containers. Change OPTIONS_COMPLETE=0 to OPTIONS_COMPLETE=1 in /data/config.sh when the configuration parameters have been entered 
 
 - Start the container again. Further configuration will occur, and the Flask service will start to handle the creation of the vehicle keypair with Tesla and installing the key into your vehicle

 - Enter the URL of your FQDN into a web browser. A page titled 'Tesla HTTP Proxy setup' will appear. Click the 'Generate OAuth token' button. This will open another web page inviting you to login into to Tesla. You will then be offered to allow the application to access your Tesla account. Click all the check boxes and press the Allow button

 - The callback will then occur which if successful will display a page saying 'Authorization complete'. Click the 'You can now close this browser instance' button

 - Return to the 'Tesla HTTP Proxy setup' page. Click the 'Enroll public key in your vehicle' button. Another Tesla web page will appear inviting you to set up a third party virtual key. There is a QR code which you should scan with your phone (which already has the Tesla App installed and setup for your Tesla account). Approve the key in the Tesla app, which if successful will install it into your vehicle. You can close this webpage

 - Return to the 'Tesla HTTP Proxy setup' page. Click the 'Test public key endpoint' button. This will download the public key (the private key was installed into you car). You don't need it, but you must keep this accessible to the internet or Tesla will reject your commands made through the proxy

 - Return to the 'Tesla HTTP Proxy setup' page. Click 'Shutdown Flask Server'. This will do as it says. From now on the proxy server will continue to run in the docker contianer and listen for requests

 - Optionally test using curl. See [DOCS.md](./tesla_http_proxy/DOCS.md) for details (TODO)

 - Once you are happy it is working, change restart: no to restart: unless-stopped in your docker-compose.yml, and restart the stack

 ## Setup Home Assistant Custom Integration ##
 
 - Install using HACS. Start the config flow. 

 - On the 'Tesla - Configuration dialog, click 'Use Fleet API Proxy'

 - On the 'Tesla - Configuration' dialog, enter the email address associated with your Tesla Developer account. Obtain the refresh token from /data/refresh_token and enter into the 'Refresh Token' field. Note refresh tokens only work once and only last a short time before they expire. See the [DOCS.md](./tesla_http_proxy/DOCS.md) for details of how to get a new one (TODO). Enter the hostname and port for your proxy in URL format (in my case this is https://macmini.home:4430. It cannot be an IP address). Enter /config/tesla_http_proxy/selfsigned.pem into the 'Proxy SSL certificate' field.

 - If the initialisation is successful, you will be presented with a 'Success!' dialog, with your name of your vehicle shown. Click the 'Finish' button and the entities for your vehicle will have been created. If the integration fails to setup, the most likely issues are: your refresh token has expired; or the SSL certificate that HA uses to connect to the proxy is invalid (e.g. you used an IP rather than hostname, the hostname doesn't resolve to the IP address of your docker host in both HA and proxy containers)

 - Test the integration, in particular by issuing a command e.g. to open the boot. If that fails, most likely culprit is that your webserver is not serving your vehicle's public key (com.tesla.3p.public-key.pem) to Tesla which is required for commands to work
   
