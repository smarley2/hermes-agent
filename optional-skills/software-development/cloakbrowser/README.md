# CloakBrowser for Hermes

This optional skill routes Hermes' built-in `browser_*` tools through
[CloakBrowser](https://github.com/CloakHQ/CloakBrowser), a patched stealth
Chromium build. Hermes attaches through Chrome DevTools Protocol (CDP) using
`browser.cdp_url`.

## Quick setup on Windows without admin rights

Run from this directory in PowerShell:

```powershell
cd optional-skills\software-development\cloakbrowser\scripts
powershell -ExecutionPolicy Bypass -File .\install-cloakbrowser-windows.ps1
powershell -ExecutionPolicy Bypass -File .\start-cloakbrowser-server-windows.ps1
hermes config set browser.cdp_url http://127.0.0.1:9222
```

Restart Hermes or the gateway after setting `browser.cdp_url`.

This uses only user-writable locations:

- Python user site packages via `pip install --user cloakbrowser`
- `%USERPROFILE%\.cloakbrowser` for the patched Chromium binary and profile
- `127.0.0.1:9222` for the local CDP endpoint

No Administrator rights or Windows Service registration are required.

## Manual Windows commands

Install:

```powershell
python -m pip install --user --upgrade cloakbrowser
python -m cloakbrowser install
python -m cloakbrowser info
```

Start CDP server:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-cloakbrowser-server-windows.ps1
```

Verify:

```powershell
curl http://127.0.0.1:9222/json/version
```

Configure Hermes:

```powershell
hermes config set browser.cdp_url http://127.0.0.1:9222
```

## macOS quick setup

```bash
python3 -m pip install --user --upgrade cloakbrowser
python3 -m cloakbrowser install

SKILL_DIR=~/.hermes/skills/software-development/cloakbrowser
mkdir -p ~/.local/bin ~/Library/LaunchAgents ~/Library/Logs
install -m 0755 "$SKILL_DIR/scripts/cloakserve-hermes.sh" ~/.local/bin/cloakserve-hermes
sed "s#__HOME__#$HOME#g" "$SKILL_DIR/scripts/com.hermes.cloakbrowser.plist" \
  > ~/Library/LaunchAgents/com.hermes.cloakbrowser.plist
launchctl unload ~/Library/LaunchAgents/com.hermes.cloakbrowser.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.hermes.cloakbrowser.plist
launchctl start com.hermes.cloakbrowser
hermes config set browser.cdp_url http://127.0.0.1:9222
```

## Linux quick setup

```bash
python3 -m pip install --user --upgrade cloakbrowser
python3 -m cloakbrowser install

SKILL_DIR=~/.hermes/skills/software-development/cloakbrowser
mkdir -p ~/.local/bin ~/.config/systemd/user
install -m 0755 "$SKILL_DIR/scripts/cloakserve-hermes.sh" ~/.local/bin/cloakserve-hermes
install -m 0644 "$SKILL_DIR/scripts/cloakbrowser.service" ~/.config/systemd/user/cloakbrowser.service
systemctl --user daemon-reload
systemctl --user enable --now cloakbrowser.service
hermes config set browser.cdp_url http://127.0.0.1:9222
```

## Notes

- `BROWSER_CDP_URL` overrides `browser.cdp_url` if set in the environment.
- This affects Hermes' built-in browser toolset, not unrelated external MCP browser servers.
- Corporate Windows environments may still block Python package download, the Chromium binary download, executable launch, or localhost listening through policy.
