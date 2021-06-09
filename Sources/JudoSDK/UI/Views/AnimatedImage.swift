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

import Foundation
import SwiftUI
import Combine

@available(iOS 13.0, *)
struct AnimatedImage: View {
    @State private var frameIndex = 0

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    private let images: [UIImage]

    init(uiImage image: UIImage) {
        self.images = image.images ?? [image]
        self.timer = Timer.publish(every: image.duration / Double(images.count), on: .main, in: .common).autoconnect()
    }

    var body: some View {
        Image(uiImage: images[frameIndex])
            .resizable()
            .onReceive(timer) { _ in
                if frameIndex + 1 < images.count {
                    frameIndex += 1
                } else {
                    frameIndex = 0
                }
            }
    }
}
