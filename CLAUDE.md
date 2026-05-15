# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A minimal native macOS app that wraps a single-page HTML/JS task tracker in a `WKWebView`. There's no package manager, no test suite, no linter — two source files (`main.swift`, `yoda.html`), a pre-built icon, and a build script.

## Build / run

```bash
./build.sh
```

This does everything: embeds HTML, copies the pre-built icon, compiles Swift, packages `Yoda.app`, and installs it to `~/Applications/`. There is no incremental build — every change re-runs the full pipeline. First launch requires a Gatekeeper bypass (right-click → Open).

Run directly without installing: `open build/Yoda.app` after building.

## Architecture — the non-obvious parts

**The HTML is compiled into the binary.** `build.sh` reads `yoda.html`, wraps it in a Swift raw-string literal (`#"""..."""#`), and writes `build/html_resource.swift` which declares a top-level `let yodaHTML: String`. `main.swift` loads it via `webView.loadHTMLString(yodaHTML, baseURL:)`. Consequences:

- Editing `yoda.html` does **nothing** until you re-run `build.sh`.
- `build/html_resource.swift` is generated — never edit it; changes will be overwritten on the next build.
- The build script escapes any literal `#"""` sequence in the HTML to avoid terminating the raw string. Be mindful if you add Swift-style raw-string delimiters to the HTML/CSS/JS.

**Two-way data sync between JS and Swift.** State lives in three places that must stay coherent:

1. `localStorage['yoda_v1']` — the browser's copy, used for instant reads.
2. `~/Documents/yoda/data.json` — the canonical on-disk copy.
3. `~/Documents/yoda/notes.md` — a derived, human-readable view, regenerated on every save (never read back).

The bridge:
- **JS → Swift** on every mutation: `save()` posts the full JSON blob via `window.webkit.messageHandlers.yoda.postMessage(...)`. Swift's `userContentController(_:didReceive:)` writes `data.json` and regenerates `notes.md`.
- **Swift → JS** on page load: `webView(_:didFinish:)` reads `data.json` and calls `window.__injectFromFile(...)` so external edits to `data.json` (e.g. by Claude Code) sync into the app on next launch. **File wins over localStorage on startup** — this is intentional.

If you change the JSON schema, update both sides: the JS shape in `yoda.html` (`data = { macrotasks, entries }`) and the Swift markdown generator in `main.swift` (`generateMarkdown`).

**The message handler is named `yoda`.** It's registered in `applicationDidFinishLaunching` and referenced as `window.webkit.messageHandlers.yoda` in JS. Renaming requires changes in both files.

## File map

- `main.swift` — `NSApplication` + `WKWebView` host, bridge handler, markdown generator, menu setup.
- `yoda.html` — entire UI (HTML/CSS/JS in one file, no external JS deps beyond a Google Fonts stylesheet).
- `Resources/AppIcon.icns` — pre-built app icon, copied verbatim into the bundle by `build.sh`. To replace: produce a new 1024px PNG, pipe it through `sips` + `iconutil` to get a fresh `.icns`, commit it.
- `build.sh` — the only build entry point.
- `build/` — generated artifacts (gitignored; `html_resource.swift` here is throwaway).