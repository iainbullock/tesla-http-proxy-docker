import os
import sys
import uuid
import logging
import argparse
import requests
from flask import Flask, request, render_template, cli, redirect
from werkzeug.exceptions import HTTPException

logging.basicConfig(
    format="[%(asctime)s] %(name)s:%(levelname)s: %(message)s",
    level=logging.INFO,
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("main")

app = Flask(__name__)

SCOPES = "openid offline_access vehicle_device_data vehicle_cmds vehicle_charging_cmds"
AUDIENCES = {
    "North America, Asia-Pacific": "https://fleet-api.prd.na.vn.cloud.tesla.com",
    "Europe, Middle East, Africa": "https://fleet-api.prd.eu.vn.cloud.tesla.com",
    "China": "https://fleet-api.prd.cn.vn.cloud.tesla.cn",
}
BLUE = "\u001b[34m"
RESET = "\x1b[0m"

parser = argparse.ArgumentParser()

parser.add_argument(
    "--client-id",
    help="Client ID. Required if not provided in environment variable CLIENT_ID",
    default=os.environ.get("CLIENT_ID"),
)
parser.add_argument(
    "--client-secret",
    help="Client secret. Required if not provided in environment variable CLIENT_SECRET",
    default=os.environ.get("CLIENT_SECRET"),
)
parser.add_argument(
    "--domain",
    help="Domain. Required if not provided in environment variable DOMAIN",
    default=os.environ.get("DOMAIN"),
)
parser.add_argument(
    "--region",
    choices=AUDIENCES.keys(),
    help="Region. Required if not provided in environment variable REGION",
    default=os.environ.get("REGION"),
)
parser.add_argument(
    "--proxy-host",
    help="Proxy host. Required if not provided in environment variable PROXY_HOST",
    default=os.environ.get("PROXY_HOST"),
)

args = parser.parse_args()

if (
    not args.client_id
    or not args.client_secret
    or not args.domain
    or not args.region
    or not args.proxy_host
):
    parser.print_help()
    sys.exit(1)


@app.errorhandler(Exception)
def handle_exception(e):
    """Exception handler for HTTP requests"""
    logger.error(e)
    # pass through HTTP errors
    if isinstance(e, HTTPException):
        return e

    # now you're handling non-HTTP exceptions only
    return "Unknown Error", 500


@app.route("/")
def index():
    """Web UI"""
    return render_template(
        "index.html",
        domain=args.domain,
        client_id=args.client_id,
        scopes=SCOPES,
        randomstate=uuid.uuid4().hex,
        randomnonce=uuid.uuid4().hex,
    )


@app.route("/callback")
def callback():
    """Handle POST callback from Tesla server to complete OAuth"""

    logger.info("callback args: %s", request.args)
    # sometimes I don't get a valid code, not sure why
    try:
        code = request.args["code"]
    except KeyError:
        logger.error("args: %s", request.args)
        return "Invalid code!", 400

    # Exchange code for refresh_token
    req = requests.post(
        "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={
            "grant_type": "authorization_code",
            "client_id": args.client_id,
            "client_secret": args.client_secret,
            "code": code,
            "audience": AUDIENCES[args.region],
            "redirect_uri": f"https://{args.domain}/callback",
        },
        timeout=30,
    )

    output = (
        "Info to enter into Tesla Custom component:\n"
        f"Refresh token  : {BLUE}{req.json()['refresh_token']}{RESET}\n"
        f"Proxy URL      : {BLUE}https://{args.proxy_host}:4430{RESET}\n"
        f"SSL certificate: {BLUE}/share/home-assistant/selfsigned.pem{RESET}\n"
        f"Client ID      : {BLUE}{args.client_id}{RESET}\n"
    )

    logger.info(output)

    req.raise_for_status()
    with open("/data/refresh_token", "w", encoding="utf-8") as f:
        f.write(req.json()["refresh_token"])
    with open("/data/access_token", "w", encoding="utf-8") as f:
        f.write(req.json()["access_token"])

    return render_template("callback.html")


@app.route("/shutdown")
def shutdown():
    """Shutdown Flask server so the HTTP proxy can start"""
    os._exit(0)


@app.route("/register-partner-account")
def register_partner_account():
    """Register the partner account with Tesla API to enable API access"""

    logger.info("*** Generating Partner Authentication Token ***")

    req = requests.post(
        "https://fleet-auth.prd.vn.cloud.tesla.com/oauth2/v3/token",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={
            "grant_type": "client_credentials",
            "client_id": args.client_id,
            "client_secret": args.client_secret,
            "scope": SCOPES,
            "audience": AUDIENCES[args.region],
        },
        timeout=30,
    )
    if req.status_code >= 400:
        logger.error("HTTP %s: %s", req.status_code, req.reason)
        return redirect(f"/?error={req.status_code}", code=302)

    logger.info(req.text)
    tesla_api_token = req.json()["access_token"]

    # register Tesla account to enable API access
    logger.info("*** Registering Tesla account ***")
    req = requests.post(
        f"{AUDIENCES[args.region]}/api/1/partner_accounts",
        headers={
            "Authorization": "Bearer " + tesla_api_token,
            "Content-Type": "application/json",
        },
        data='{"domain": "%s"}' % args.domain,
        timeout=30,
    )
    if req.status_code >= 400:
        logger.error("Error %s: %s", req.status_code, req.reason)
        return redirect(f"/?error={req.status_code}", code=302)
    logger.info(req.text)

    return redirect("/?success=1", code=302)


if __name__ == "__main__":
    logger.info("*** Starting Flask server... ***")
    cli.show_server_banner = lambda *_: None
    app.run(port=8099, debug=False, host="0.0.0.0")
