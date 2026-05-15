import AppKit
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var webView: WKWebView!

    // ~/Documents/tasklog/
    let saveDir: URL = {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/tasklog")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let w: CGFloat = 1100, h: CGFloat = 700
        let frame = NSRect(x: screen.midX - w/2, y: screen.midY - h/2, width: w, height: h)

        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "tasklog"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(red: 0.055, green: 0.055, blue: 0.055, alpha: 1)
        window.minSize = NSSize(width: 600, height: 400)

        let controller = WKUserContentController()
        controller.add(self, name: "tasklog")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")

        let baseURL = URL(fileURLWithPath: NSHomeDirectory() + "/Applications/")
        webView.loadHTMLString(tasklogHTML, baseURL: baseURL)

        window.contentView!.addSubview(webView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupMenu()
    }

    // ── Called by JS on every save ─────────────────────────────────────────
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "tasklog",
              let jsonString = message.body as? String,
              let jsonData = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { return }

        // Write data.json
        let jsonURL = saveDir.appendingPathComponent("data.json")
        try? jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)

        // Write notes.md
        let md = generateMarkdown(from: obj)
        let mdURL = saveDir.appendingPathComponent("notes.md")
        try? md.write(to: mdURL, atomically: true, encoding: .utf8)
    }

    // ── On page load: inject saved file data so Claude Code edits sync back ─
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let jsonURL = saveDir.appendingPathComponent("data.json")
        guard let jsonString = try? String(contentsOf: jsonURL, encoding: .utf8) else { return }
        // Pass JSON object directly — no string escaping needed
        webView.evaluateJavaScript(
            "if(window.__injectFromFile) window.__injectFromFile(\(jsonString))"
        ) { _, _ in }
    }

    // ── Markdown generator ─────────────────────────────────────────────────
    func generateMarkdown(from data: [String: Any]) -> String {
        let macrotasks = data["macrotasks"] as? [String] ?? []
        let entries    = data["entries"]    as? [[String: Any]] ?? []

        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var lines = ["# tasklog", "", "*Last synced: \(df.string(from: Date()))*", ""]

        for macro in macrotasks {
            let macroEntries = entries.filter { ($0["macrotask"] as? String) == macro }
            guard !macroEntries.isEmpty else { continue }

            lines += ["## \(macro)", ""]

            // Group by date, newest first
            var byDate: [String: [[String: Any]]] = [:]
            for e in macroEntries {
                let d = e["date"] as? String ?? "unknown"
                byDate[d, default: []].append(e)
            }
            for date in byDate.keys.sorted().reversed() {
                lines.append("### \(date)")
                for e in byDate[date]! {
                    let text    = e["text"]    as? String ?? ""
                    let type    = e["type"]    as? String ?? "note"
                    let checked = e["checked"] as? Bool   ?? false
                    lines.append(type == "todo" ? "- [\(checked ? "x" : " ")] \(text)" : "- \(text)")
                }
                lines.append("")
            }
        }
        return lines.joined(separator: "\n")
    }

    func setupMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem(); mainMenu.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Hide tasklog", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit tasklog", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let winItem = NSMenuItem(); mainMenu.addItem(winItem)
        let winMenu = NSMenu(title: "Window"); winItem.submenu = winMenu
        winMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        winMenu.addItem(withTitle: "Zoom",     action: #selector(NSWindow.zoom(_:)),        keyEquivalent: "")
        winMenu.addItem(.separator())
        winMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = winMenu
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
