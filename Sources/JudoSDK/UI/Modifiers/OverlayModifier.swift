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
import JudoModel

@available(iOS 13.0, *)
struct OverlayModifier: ViewModifier {
    var node: Node

    @ViewBuilder
    func overlayContents(layer: Layer) -> some View {
        // Workaround: SwiftUI Overlays over UIkit views that use gesture recognizers other than tap (namely, swipe, such as ScrollViews) will block the input. The workaround is to embed the SwiftUI overlay inside UIKit itself, which, presumably, is able to properly marshal the gesture input.
        if node is Carousel || node is ScrollContainer {
            SwiftUIWrapper {
                LayerView(layer: layer)
            }
            .environment(\.isEnabled, false)
            .allowsHitTesting(false)
        } else {
            LayerView(layer: layer)
                .environment(\.isEnabled, false)
                .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let overlay = node.overlay, let layer = overlay.node as? Layer {
            content.overlay(
                overlayContents(layer: layer),
                alignment: overlay.alignment.swiftUIValue
            )
        } else {
            content
        }
    }
}

@available(iOS 13.0, *)
private struct SwiftUIWrapper<T: View>: UIViewControllerRepresentable {
    let content: () -> T
    
    func makeUIViewController(context: Context) -> UIHostingController<T> {
        let hostingController = UIHostingController(rootView: content())
        hostingController.view.backgroundColor = .clear
        return hostingController
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<T>, context: Context) {
        uiViewController.rootView = content()
    }
}
