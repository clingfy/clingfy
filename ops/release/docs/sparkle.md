Sparkle’s default behavior is:

* it may only prompt/enable background checks on the **second launch** (unless you set `SUEnableAutomaticChecks`)
* it normally checks **once every 24h** (`SUScheduledCheckInterval` default is 86400, and it has a **minimum of 1 hour**) ([sparkle-project.org][1])
* for quick testing, Sparkle explicitly recommends clearing the “last check time” and relaunching ([sparkle-project.org][1])

Below are the quickest manual ways.

---

## 1) Fastest: trigger a check right now (no code changes)

### A) If you already have a “Check for Updates…” menu item

Open the app → menu bar → **Check for Updates…**
That calls Sparkle’s user-initiated check. ([sparkle-project.org][1])

### B) If you don’t have the menu item: force a background check on next launch

1. **Quit Clingfy** completely.
2. Clear Sparkle’s last-check timestamp for your bundle id.
3. Launch Clingfy again.

**Prod bundle id**:

```bash
defaults delete com.clingfy.clingfy SULastCheckTime || true
open -a "Clingfy"
```

**Dev bundle id**:

```bash
defaults delete com.clingfy.clingfy.dev SULastCheckTime || true
open -a "Clingfy Dev"
```

Sparkle’s own docs call out `defaults delete <bundle-id> SULastCheckTime` as the way to test automatic checks immediately. ([sparkle-project.org][1])

> Tip: watch logs in **Console.app** (filter for “Sparkle”) — Sparkle logs the whole update flow there. ([sparkle-project.org][1])

---

## 2) Verify your installed app is actually pointing at the right feed

Because you’re using `$(SPARKLE_FEED_URL)`, confirm it expanded correctly in the built app:

```bash
plutil -p /Applications/Clingfy.app/Contents/Info.plist | grep SUFeedURL
# or for dev:
plutil -p "/Applications/Clingfy Dev.app/Contents/Info.plist" | grep SUFeedURL
```

And confirm your app version/build is older than what’s in the appcast, because Sparkle compares versions using `CFBundleVersion` (build number). ([sparkle-project.org][1])

```bash
defaults read /Applications/Clingfy.app/Contents/Info CFBundleShortVersionString
defaults read /Applications/Clingfy.app/Contents/Info CFBundleVersion
```
