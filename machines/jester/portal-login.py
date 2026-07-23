"""Log in to the ANTlabs captive portal at The Urban Office from the CLI.

The gateway's pre-auth firewall blocks both the DHCP-advertised DNS server
and the login server's IP; only the default gateway answers HTTP. So all
requests go straight to the gateway IP with the portal's Host header.

Protocol (reverse-engineered from the live portal, 2026-07-23):
1. GET /login/index.ant -> meta-refresh to /login.acs/<token>/index.ant
2. GET that (registers the client; session is keyed on MAC/IP, the
   secure-flagged PHPSESSID cookie is never sent back over http)
3. POST p=local&uid=..&pwd=.. to /login/main.ant?c=proc
4. Success = 302 whose Location contains page=success

Post-auth the gateway stops answering port 80 entirely, so a connect
timeout on step 1 means "already logged in".

Usage: portal-login [username]   (prompts for anything missing)
Credentials can be stored in ~/.config/portal-login as two lines
(username, then password); chmod 600 it.
"""
import getpass
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

IFACE = "wlp0s20f3"
PORTAL_HOST = "ezxcess.antlabs.com"


def gateway():
    out = subprocess.run(
        ["ip", "route", "show", "default", "dev", IFACE],
        capture_output=True, text=True, check=True,
    ).stdout
    m = re.search(r"via (\S+)", out)
    if not m:
        sys.exit(f"no default route on {IFACE}; connect to the Wi-Fi first")
    return m.group(1)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def credentials():
    cred_file = Path.home() / ".config" / "portal-login"
    stored = []
    if cred_file.exists():
        if cred_file.stat().st_mode & 0o077:
            print(f"warning: {cred_file} is readable by others; "
                  "run: chmod 600 " + str(cred_file), file=sys.stderr)
        stored = cred_file.read_text().splitlines()
    user = sys.argv[1] if len(sys.argv) > 1 else (
        stored[0] if stored else input("username: "))
    password = stored[1] if len(stored) > 1 else getpass.getpass("password: ")
    return user, password


def main():
    gw = gateway()
    user, password = credentials()

    # Host must be set per-Request: opener.addheaders loses to the
    # auto-generated Host header, and the gateway 404s on a wrong Host.
    headers = {"Host": PORTAL_HOST, "User-Agent": "Mozilla/5.0"}

    def request(path, data=None):
        return urllib.request.Request(
            f"http://{gw}{path}", data=data, headers=headers)

    def get(path):
        return urllib.request.urlopen(request(path), timeout=15)

    try:
        with get("/login/index.ant") as resp:
            m = re.search(r"login\.acs/[0-9a-f]+", resp.read().decode(
                errors="replace"))
    except OSError as e:
        sys.exit(f"gateway {gw} did not serve the portal page ({e}); "
                 "post-auth it drops port 80, so you are likely already "
                 "logged in")
    if not m:
        sys.exit("portal page had no login.acs session token; "
                 "page format changed?")

    # Registers the client and 302s through to the login form.
    with get(f"/{m.group(0)}/index.ant?page=login"):
        pass

    data = urllib.parse.urlencode(
        {"p": "local", "uid": user, "pwd": password,
         "button-label": "Connect"}).encode()
    # Don't follow the resulting redirect: it points at the portal hostname,
    # which needs real DNS; the Location header alone tells us the outcome.
    poster = urllib.request.build_opener(NoRedirect())
    location, body = "", ""
    try:
        with poster.open(request("/login/main.ant?c=proc", data),
                         timeout=15) as resp:
            body = resp.read().decode(errors="replace")
    except urllib.error.HTTPError as e:
        location = e.headers.get("Location", "")

    if "page=success" in location:
        print("login accepted")
    else:
        snippet = re.sub(r"<[^>]+>|\s+", " ", body).strip()[:300]
        sys.exit("login not confirmed; portal answered "
                 f"Location={location!r} body={snippet!r}")
    print("connectivity:", subprocess.run(
        ["nmcli", "networking", "connectivity", "check"],
        capture_output=True, text=True).stdout.strip())


if __name__ == "__main__":
    main()
