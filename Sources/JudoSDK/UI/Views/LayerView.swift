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
struct LayerView: View {
    var layer: Layer
    
    var body: some View {
        content
            .modifier(LayerViewModifier(layer: layer))
    }
    
    @ViewBuilder private var content: some View {
        switch layer {
        case let scrollContainer as JudoModel.ScrollContainer:
            ScrollContainerView(scrollContainer: scrollContainer)
        case let stack as JudoModel.HStack:
            HStackView(stack: stack)
        case let image as JudoModel.Image:
            ImageView(image: image)
        case let icon as JudoModel.Icon:
            IconView(icon: icon)
        case let text as JudoModel.Text:
            TextView(text: text)
        case let rectangle as JudoModel.Rectangle:
            RectangleView(rectangle: rectangle)
        case let stack as JudoModel.VStack:
            VStackView(stack: stack)
        case _ as JudoModel.Spacer:
            SwiftUI.Spacer().frame(minWidth: 0, minHeight: 0).layoutPriority(-1)
        case let divider as JudoModel.Divider: 
            DividerView(divider: divider)
        case let webView as JudoModel.WebView:
            WebViewView(webView: webView)
                .environment(\.isEnabled, false)
        case let stack as JudoModel.ZStack:
            ZStackView(stack: stack)
        case let carousel as JudoModel.Carousel:
            CarouselView(carousel: carousel)
        case let pageControl as JudoModel.PageControl:
            PageControlView(pageControl: pageControl)
        case let video as JudoModel.Video:
            VideoView(video: video)
        case let audio as JudoModel.Audio:
            AudioView(audio: audio)
        case let dataSource as JudoModel.DataSource:
            DataSourceView(dataSource: dataSource)
        case let collection as JudoModel.Collection:
            CollectionView(collection: collection)
        default:
            EmptyView()
        }
    }
}

@available(iOS 13.0, *)
struct LayerViewModifier: ViewModifier {
    var layer: Layer
    
    func body(content: Content) -> some View {
        content
            .modifier(
                AspectRatioModifier(node: layer)
            )
            .modifier(
                PaddingModifier(node: layer)
            )
            .modifier(
                FrameModifier(node: layer)
            )
            .modifier(
                LayoutPriorityModifier(node: layer)
            )
            .modifier(
                ShadowModifier(node: layer)
            )
            .modifier(
                OpacityModifier(node: layer)
            )
            .modifier(
                BackgroundModifier(node: layer)
            )
            .modifier(
                OverlayModifier(node: layer)
            )
            .modifier(
                MaskModifier(node: layer)
            )
            .contentShape(
                SwiftUI.Rectangle()
            )
            .modifier(
                AccessibilityModifier(node: layer)
            )
            .modifier(
                ActionModifier(layer: layer)
            )
            .modifier(
                OffsetModifier(node: layer)
            )
            .modifier(
                IgnoresSafeAreaModifier(node: layer)
            )
    }
}
