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
import JudoModel
import AVKit
import Combine

@available(iOS 13.0, *)
struct AudioView: View {
    @Environment(\.data) private var data
    @Environment(\.urlParameters) private var urlParameters
    @Environment(\.userInfo) private var userInfo
    
    let audio: JudoModel.Audio
    @State private var isVisible = true

    var body: some View {
        if let urlString = audio.sourceURL.evaluatingExpressions(data: data, urlParameters: urlParameters, userInfo: userInfo), let sourceURL = URL(string: urlString) {
            AudioPlayerView(
                sourceURL: sourceURL,
                looping: audio.looping,
                autoPlay: audio.autoPlay,
                isVisible: isVisible
            )
            .onDisappear { isVisible = false }
            .onAppear { isVisible = true }
            .frame(height: 44)
        }
    }
}

@available(iOS 13.0, *)
private struct AudioPlayerView: UIViewControllerRepresentable {
    var sourceURL: URL
    var looping: Bool
    var autoPlay: Bool
    var isVisible: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        AudioPlayerViewController(sourceURL: sourceURL, looping: looping)
    }
    
    func updateUIViewController(_ viewController: AVPlayerViewController, context: Context) {
        if !isVisible {
            viewController.player?.pause()
        } else if autoPlay {
            viewController.player?.play()
        }
    }
}

@available(iOS 13.0, *)
private class AudioPlayerViewController: AVPlayerViewController {
    private var looper: AVPlayerLooper?

    init(sourceURL: URL, looping: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        let playerItem = AVPlayerItem(url: sourceURL)
        
        if looping {
            let player = AVQueuePlayer()
            self.player = player
            self.looper = AVPlayerLooper(player: player, templateItem: playerItem)
        } else {
            player = AVPlayer(playerItem: playerItem)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
