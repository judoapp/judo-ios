// Copyright (c) 2020-present, Rover Labs, Inc. All rights reserved.
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Rover.
//
// This copyright notice shall be included in all copies or substantial portions of 
// the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import SwiftUI
import WebKit
import JudoModel

@available(iOS 13.0, *)
struct WebViewView: View {
    @Environment(\.data) private var data
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.urlParameters) private var urlParameters
    @Environment(\.userInfo) private var userInfo
    
    var webView: WebView
    
    @State private var loadErrorMessage: String?

    var body: some View {
        if let source = source {
            if let message = loadErrorMessage {
                webViewUI(source: source).loadError(message: message)
            } else {
                webViewUI(source: source)
            }
        }
    }
    
    private var source: WebView.Source? {
        switch webView.source {
        case .url(let value):
            let maybeValue = value.evaluatingExpressions(
                data: data,
                urlParameters: urlParameters,
                userInfo: userInfo
            )
                
            guard let value = maybeValue else {
                return nil
            }
            
            return .url(value)
        case .html(let value):
            let maybeValue = value.evaluatingExpressions(
                data: data,
                urlParameters: urlParameters,
                userInfo: userInfo
            )
                
            guard let value = maybeValue else {
                return nil
            }
            
            return .html(value)
        }
    }
    
    private func webViewUI(source: WebView.Source) -> WebViewUI {
        WebViewUI(
            source: source,
            isScrollEnabled: webView.isScrollEnabled,
            isUserInteractionEnabled: isEnabled,
            onFinish: { self.loadErrorMessage = nil },
            onFailure: { self.loadErrorMessage = $0.localizedDescription }
        )
    }
}

// MARK: WebViewUI

@available(iOS 13.0, *)
private struct WebViewUI: UIViewRepresentable {
    var source: WebView.Source
    var isScrollEnabled: Bool
    var isUserInteractionEnabled: Bool

    var onStart: (() -> Void)? = nil
    var onFinish: (() -> Void)? = nil
    var onFailure: ((Error) -> Void)? = nil

    private static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_4_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1"

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView  {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        preferences.isFraudulentWebsiteWarningEnabled = false

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.websiteDataStore = .nonPersistent()
        configuration.suppressesIncrementalRendering = false
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.allowsAirPlayForMediaPlayback = false
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.dataDetectorTypes = [.calendarEvent, .address, .phoneNumber]

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = Self.userAgent
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        webView.scrollView.isScrollEnabled = isScrollEnabled

        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = webView.backgroundColor

        webView.isUserInteractionEnabled = isUserInteractionEnabled
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {

        // This method is called multiple times, but we only care
        // about whether URL changed. In that case, trigger loading new URL
        // by WebView

        guard context.coordinator.source != source else {
            return
        }

        switch source {
        case .url(let value):
            let url = URL(string: value) ?? URL(string: "about:blank")!
            webView.load(URLRequest(url: url))
        case .html(let value):
            webView.loadHTMLString(value, baseURL: nil)
        }
        
        context.coordinator.source = source
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
    }

    class Coordinator : NSObject, WKNavigationDelegate {
        var parent: WebViewUI
        var source: WebView.Source?

        init(_ webView: WebViewUI) {
            self.parent = webView
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            parent.onFinish?()
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
            parent.onStart?()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
            parent.onFailure?(error)
        }
    }
}

// MARK: Modifiers

@available(iOS 13.0, *)
private extension WebViewUI {
    func loadError(message: String) -> some View {
        modifier(LoadErrorModifier(message: message))
    }
}

@available(iOS 13.0, *)
private struct LoadErrorModifier: ViewModifier {
    var message: String

    func body(content: Content) -> some View {
        SwiftUI.ZStack {
            content
            SwiftUI.HStack {
                SwiftUI.Image(systemName: "nosign")
                    .foregroundColor(Color(.systemRed))
                SwiftUI.Text(message)
                    .foregroundColor(Color(.secondaryLabel))
            }.padding()
        }
    }
}
