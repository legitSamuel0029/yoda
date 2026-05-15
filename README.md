# yoda

> Yet anOther toDo App.

A minimal native macOS task and note tracker. One window, a capture bar at the top, projects in the sidebar, notes and todos stacked by date. No accounts, no sync, no telemetry — just a `~/Documents/yoda/` directory you can grep, version, or edit by hand.

## Install

```bash
./build.sh
```

Compiles, generates the icon, packages `Yoda.app`, and installs it to `~/Applications/`. First launch needs a Gatekeeper bypass (right-click → Open, once).

## Hackable data

Two files live at `~/Documents/yoda/`:

- `data.json` — source of truth, edit at your own risk
- `notes.md` — auto-regenerated on every save; never read back

External edits to `data.json` sync into the app on next launch. The reverse does not apply — anything you write into `notes.md` gets overwritten.

## Stack

- `main.swift` — `WKWebView` host plus the Swift↔JS bridge that writes `data.json` and `notes.md` on every mutation.
- `yoda.html` — the entire UI (HTML/CSS/JS in one file, ~500 lines).
- `build.sh` — embeds `yoda.html` into the Swift binary as a raw-string literal, then compiles.

Three source files, no package manager, no test suite, no linter. Read it in an afternoon, fork it in an evening.

## Why "yoda"

`Y`et an`O`ther to`D`o `A`pp. The capital O is doing a lot of work. It's a tradition — see also: YAML, YACC, YASnippet.
