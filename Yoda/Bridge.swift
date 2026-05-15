import WebKit

final class Bridge: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    weak var webView: WKWebView?

    let saveDir: URL = {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/yoda")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    // JS → Swift on every save
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "yoda",
              let jsonString = message.body as? String,
              let jsonData = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else { return }

        let jsonURL = saveDir.appendingPathComponent("data.json")
        try? jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)

        let md = generateMarkdown(from: obj)
        let mdURL = saveDir.appendingPathComponent("notes.md")
        try? md.write(to: mdURL, atomically: true, encoding: .utf8)
    }

    // Swift → JS on page load: re-inject canonical data so external edits to data.json win
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let jsonURL = saveDir.appendingPathComponent("data.json")
        guard let jsonString = try? String(contentsOf: jsonURL, encoding: .utf8) else { return }
        webView.evaluateJavaScript(
            "if(window.__injectFromFile) window.__injectFromFile(\(jsonString))"
        ) { _, _ in }
    }

    func generateMarkdown(from data: [String: Any]) -> String {
        let macrotasks = data["macrotasks"] as? [String] ?? []
        let entries    = data["entries"]    as? [[String: Any]] ?? []

        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var lines = ["# yoda", "", "*Last synced: \(df.string(from: Date()))*", ""]

        for macro in macrotasks {
            let macroEntries = entries.filter { ($0["macrotask"] as? String) == macro }
            guard !macroEntries.isEmpty else { continue }

            lines += ["## \(macro)", ""]

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
}
