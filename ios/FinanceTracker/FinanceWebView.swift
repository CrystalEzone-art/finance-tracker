import SwiftUI
import WebKit
import os

struct FinanceWebView: UIViewRepresentable {
    let reloadToken: UUID

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        loadTracker(in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.reloadToken != reloadToken else { return }
        context.coordinator.reloadToken = reloadToken
        loadTracker(in: webView)
    }

    private func loadTracker(in webView: WKWebView) {
        guard let indexURL = Bundle.main.url(
            forResource: "index",
            withExtension: "html",
            subdirectory: "Web"
        ) else {
            webView.loadHTMLString(
                "<h1>Finance Tracker could not load.</h1><p>Please reinstall the app.</p>",
                baseURL: nil
            )
            return
        }

        let webDirectory = indexURL.deletingLastPathComponent()

        do {
            let html = try String(contentsOf: indexURL, encoding: .utf8)
            webView.loadHTMLString(html, baseURL: webDirectory)
        } catch {
            webView.loadHTMLString(
                "<h1>Finance Tracker could not load.</h1><p>Its bundled data is unavailable.</p>",
                baseURL: nil
            )
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let logger = Logger(
            subsystem: "com.tylerphan.financetracker",
            category: "WebView"
        )
        var reloadToken: UUID?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            if url.isFileURL || url.scheme == "about" {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                UIApplication.shared.open(url)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(
                """
                JSON.stringify({
                  title: document.title,
                  location: location.href,
                  bodyTextLength: document.body?.innerText?.length ?? -1,
                  bodyHTMLLength: document.body?.innerHTML?.length ?? -1
                })
                """
            ) { [logger] result, error in
                if let error {
                    logger.error("Page inspection failed: \(error.localizedDescription, privacy: .public)")
                } else {
                    logger.info("Page loaded: \(String(describing: result), privacy: .public)")
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            logger.error("Navigation failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
