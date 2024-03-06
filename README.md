# Tesla HTTP Proxy Docker

Work in progress it doesn't work yet :)

Originally this was a fork of https://github.com/llamafilm/tesla-http-proxy-addon. All credit to llamafilm (https://github.com/llamafilm) for developing most of this. 

Provides a standalone docker version instead of a Home Assistant Add-on. This means it can work with versions of Home Assistant which don't allow Add-Ons (e.g. docker version).

This docker runs the official Tesla HTTP Proxy to allow Fleet API requests on modern vehicles. Please do not bother Tesla for support on this.

## About
Runs a temporary Flask web server to handle initial Tesla authorization flow and store the refresh token.  Once that is complete, it quits Flask and runs Tesla's HTTP Proxy code in Go.

Setting this up is fairly complex.  Please read [DOCS.md](./tesla_http_proxy/DOCS.md) for details (TODO), or follow the high level summary below:

## Installation and set up

 - Clone the repository onto your host machine, or just copy the files you need

 - Setup your webserver so it can receive ssl connections to your FQDN. This FQDN should be different to that used to access your instance of Home Assistant. I have provided my Nginx configuration file (nginx_tesla.conf). Adapt it to suit your setup 

 - Build the docker image using the Dockerfile. Alternatively you can get the image directly from Dockerhub https://hub.docker.com/r/iainbullock/tesla_http_proxy

 - Deploy the docker stack using docker-compose.yml. On the first run of the container various files will be initialised and the container will exit

 - Enter your configuration parameters in /data/config.sh (/data is mounted as a volume on the docker host)
 
 - Start the container again. Further configuration will occur, and the Flask service will start to handle the creation of the vehicle keypair with Tesla and installing the key into your vehicle

 - Enter the URL of your FQDN into a web browser. A page titled 'Tesla HTTP Proxy add-on' will appear. Press the 'Generate OAuth token' button. This will open another web page inviting you to login into to Tesla. You will then be offered to allow the application to access your Tesla account. Click all the check boxes and press the Allow button

 - The callback will then occur which if successful will display a page saying 'Authorization complete'. You can close this page

 - Return to the 'Tesla HTTP Proxy add-on' page. Click 'Enroll public key n your vehicle'. Another Tesla web page will appear inviting you to set up a third party virtual key. There is a QR code which you should scan with your phone (which already has the Tesal App installed and setup for your Tesal account). Approve the key in the Tesal app, which if successful will install it inot your vehicle. You can close this page

 - Return to the 'Tesla HTTP Proxy add-on' page. Click 'Test public key endpoint'. This will download the public key (the private key was installed inot you car). You don't need it, but you must keep this accessible to the internet or Tesal will reject your command made through the proxy

 - Return to the 'Tesla HTTP Proxy add-on' page. Click 'Shutdown Flask Server'. This will do as it says. From now on the proxy server will continue to run in the docker contianer and listen for requests

 - Test using curl. Setup Home Assistant to work with the proxy. Note the API access_token will expire after approx 8 hours if not refreshed. Setup Home Assistant to ensure the token is refreshed automatically. See [DOCS.md](./tesla_http_proxy/DOCS.md) for details (TODO)
   
