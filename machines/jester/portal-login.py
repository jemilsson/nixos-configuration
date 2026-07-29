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

Only this ANTlabs login flow is handled. Non-ANTlabs and JS-heavy captive
portals are not recognized or driven by this script; that is an inherent
scope limit, not a bug. The caller (captive-portal-opener in
config/laptop_base.nix) falls back to captive-browser when this script
exits non-zero, so the user finishes login manually in the opened browser
window.

Usage: portal-login   (no args; run by the NM dispatcher, unattended)

Credentials come from `pass` (password-store), looked up by the currently
connected SSID via a mapping in ~/.config/captive-portals.conf
(SSID=pass-entry-name, one per line, '#' comments allowed). The assumed
`pass show <entry>` output format, since we cannot inspect the real store:
    <password>
    login: <username>
i.e. standard pass convention -- password on line 1, a `login:` or
`username:` line anywhere after it holding the username.
"""
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


def active_ssid():
    # -t: terse/colon-separated. Only the currently-active AP has "yes" in
    # the first field; nmcli lists every scanned network otherwise.
    out = subprocess.run(
        ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"],
        capture_output=True, text=True,
    ).stdout
    for line in out.splitlines():
        if line.startswith("yes:"):
            return line[len("yes:"):]
    return None


def portal_map():
    path = Path.home() / ".config" / "captive-portals.conf"
    mapping = {}
    if not path.exists():
        return mapping
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        ssid, _, entry = line.partition("=")
        mapping[ssid.strip()] = entry.strip()
    return mapping


def pass_credentials(entry):
    try:
        out = subprocess.run(
            ["pass", "show", entry], capture_output=True, text=True, check=True,
        ).stdout
    except subprocess.CalledProcessError:
        # pass's own stderr (e.g. "not in the password store") holds no
        # secret, but we don't relay it anyway to keep this path simple.
        sys.exit(f"pass entry {entry!r} not found or unreadable")
    lines = out.splitlines()
    if not lines:
        sys.exit(f"pass entry {entry!r} is empty")
    password = lines[0]
    user = None
    for line in lines[1:]:
        m = re.match(r"\s*(?:login|username)\s*:\s*(.+)", line, re.IGNORECASE)
        if m:
            user = m.group(1).strip()
            break
    if user is None:
        sys.exit(f"pass entry {entry!r} has no login:/username: line")
    return user, password


def credentials():
    ssid = active_ssid()
    if not ssid:
        sys.exit("no active Wi-Fi connection found")
    entry = portal_map().get(ssid)
    if not entry:
        sys.exit(f"no captive-portals.conf mapping for SSID {ssid!r}")
    return pass_credentials(entry)


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
