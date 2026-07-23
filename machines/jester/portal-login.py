"""Log in to a captive portal from the command line.

Built for the ANTlabs gateway at The Urban Office (Summer Point), whose
pre-auth firewall blocks both the DHCP-advertised DNS server and the login
server's own IP; only the default gateway answers DNS and serves the login
page. So: talk HTTP straight to the gateway IP with the portal's Host
header, parse whatever <form> the page serves, fill in the credentials,
and POST it back the same way.

Usage: portal-login [username]   (prompts for anything missing)
Credentials can be stored in ~/.config/portal-login as two lines
(username, then password).
"""
import getpass
import re
import subprocess
import sys
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

IFACE = "wlp0s20f3"
PORTAL_HOST = "ezxcess.antlabs.com"
LOGIN_PATH = "/login/index.ant?url=http%3A%2F%2Fneverssl%2Ecom%2F"


def gateway():
    out = subprocess.run(
        ["ip", "route", "show", "default", "dev", IFACE],
        capture_output=True, text=True, check=True,
    ).stdout
    m = re.search(r"via (\S+)", out)
    if not m:
        sys.exit(f"no default route on {IFACE}; connect to the Wi-Fi first")
    return m.group(1)


class FormParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.forms = []  # (action, method, fields, password_field, text_fields)
        self._cur = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "form":
            self._cur = {"action": a.get("action") or "",
                         "method": (a.get("method") or "get").lower(),
                         "fields": {}, "password": None, "texts": []}
            self.forms.append(self._cur)
        elif tag == "input" and self._cur is not None:
            name = a.get("name")
            if not name:
                return
            typ = (a.get("type") or "text").lower()
            self._cur["fields"][name] = a.get("value") or ""
            if typ == "password":
                self._cur["password"] = name
            elif typ in ("text", "email"):
                self._cur["texts"].append(name)

    def handle_endtag(self, tag):
        if tag == "form":
            self._cur = None


def fetch(gw, url, data=None):
    # DNS for the portal host is firewalled pre-auth, so connect to the
    # gateway IP and present the portal hostname in Host/URL ourselves.
    parsed = urllib.parse.urlsplit(url)
    ip_url = urllib.parse.urlunsplit(
        (parsed.scheme or "http", gw, parsed.path, parsed.query, ""))
    req = urllib.request.Request(
        ip_url, data=data,
        headers={"Host": parsed.hostname or PORTAL_HOST,
                 "User-Agent": "Mozilla/5.0"})
    return urllib.request.urlopen(req, timeout=15)


def main():
    gw = gateway()
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

    login_url = f"http://{PORTAL_HOST}{LOGIN_PATH}"
    try:
        with fetch(gw, login_url) as resp:
            page = resp.read().decode(errors="replace")
            base = resp.geturl()
    except OSError as e:
        sys.exit(f"portal at gateway {gw} did not serve the login page ({e}); "
                 "if you are already authenticated this is expected")

    parser = FormParser()
    parser.feed(page)
    form = next((f for f in parser.forms if f["password"]), None)
    if form is None:
        sys.exit("no login form with a password field found; "
                 "are you already logged in?")

    fields = form["fields"]
    fields[form["password"]] = password
    user_field = next(
        (n for n in form["texts"]
         if re.search(r"user|login|email|name", n, re.I)),
        form["texts"][0] if form["texts"] else None)
    if user_field is None:
        sys.exit(f"no username field found in form (fields: {list(fields)})")
    fields[user_field] = user

    # base came back with the gateway IP as host; restore the portal
    # hostname before resolving the form action against it.
    parts = urllib.parse.urlsplit(base)
    base = urllib.parse.urlunsplit(parts._replace(netloc=PORTAL_HOST))
    action = urllib.parse.urljoin(base, str(form["action"] or login_url))
    print(f"POST {action} ({user_field}={user})")
    with fetch(gw, action, urllib.parse.urlencode(fields).encode()) as resp:
        body = resp.read().decode(errors="replace")

    if re.search(r"invalid|incorrect|failed|error", body, re.I):
        snippet = re.sub(r"<[^>]+>|\s+", " ", body).strip()
        print(f"warning: portal response mentions an error: {snippet[:300]}",
              file=sys.stderr)
    print("asking NetworkManager to re-check connectivity...")
    subprocess.run(["nmcli", "networking", "check"], check=False)
    print(subprocess.run(["nmcli", "networking", "connectivity"],
                         capture_output=True, text=True).stdout.strip())


if __name__ == "__main__":
    main()
