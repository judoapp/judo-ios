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
import os.log

@available(iOS 13.0, *)
struct ImageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.urlParameters) private var urlParameters
    @Environment(\.userInfo) private var userInfo
    @Environment(\.data) private var data
    
    var image: JudoModel.Image
    
    var body: some View {
        if let inlineImage = inlineImage {
            imageView(uiImage: inlineImage)
        } else if let urlString = urlString?.evaluatingExpressions(data: data, urlParameters: urlParameters, userInfo: userInfo), let resolvedURL = URL(string: urlString) {
            imageFetcher(url: resolvedURL)
        }
    }
    
    private func imageFetcher(url: URL) -> some View {
        ImageFetcher(url: url) { uiImage in
            imageView(uiImage: uiImage)
                .transition(.opacity)
        } placeholder: {
            PlaceholderView(
                blurHash: image.blurHash,
                scale: scale,
                resizingMode: image.resizingMode,
                size: estimatedImageSize
            )
            .transition(.opacity)
        }
    }
    
    @ViewBuilder
    private func imageView(uiImage: UIImage) -> some View {
        if uiImage.isAnimated {
            AnimatedImageView(
                uiImage: uiImage,
                scale: scale,
                resizingMode: image.resizingMode,
                size: estimatedImageSize
            )
        } else {
            StaticImageView(
                uiImage: uiImage,
                scale: scale,
                resizingMode: image.resizingMode,
                size: estimatedImageSize
            )
        }
    }
    
    private var inlineImage: UIImage? {
        switch colorScheme {
        case .dark:
            if let inlineImage = image.darkModeInlineImage {
                return inlineImage
            }
            
            fallthrough
        default:
            return image.inlineImage
        }
    }
    
    private var urlString: String? {
        switch colorScheme {
        case .dark:
            if let url = image.darkModeImageURL {
                return url
            }
            
            fallthrough
        default:
            return image.imageURL
        }
    }

    
    private var estimatedImageSize: CGSize? {
        var result: CGSize
        if colorScheme == .dark, let width = image.darkModeImageWidth, let height = image.darkModeImageHeight {
            result = CGSize(
                width: width == 0 ? 1 : width,
                height: height == 0 ? 1 : height
            )
        } else if let width = image.imageWidth, let height = image.imageHeight {
            result = CGSize(
                width: width == 0 ? 1 : width,
                height: height == 0 ? 1 : height
            )
        } else {
            return nil
        }
        
        result.width *= scale
        result.height *= scale
        return result
    }
    
    private var scale: CGFloat {
        guard image.resolution > 0 else {
            return 1
        }
        
        return CGFloat(1) / image.resolution
    }
}

private extension UIImage {
    var isAnimated: Bool {
        (self.images?.count).map { $0 > 1 } ?? false
    }
}

// MARK: - StaticImageView

@available(iOS 13.0, *)
private struct StaticImageView: View {
    var uiImage: UIImage
    var scale: CGFloat
    var resizingMode: JudoModel.Image.ResizingMode
    var size: CGSize?
    
    var body: some View {
        switch resizingMode {
        case .originalSize:
            SwiftUI.Image(uiImage: uiImage)
                .resizable()
                .frame(
                    width: frameSize.width,
                    height: frameSize.height
                )
        case .scaleToFill:
                SwiftUI.Rectangle().fill(Color.clear)
                    .overlay(
                        SwiftUI.Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
        case .scaleToFit:
            SwiftUI.Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        case .tile:
            TilingImage(uiImage: uiImage, scale: scale)
        case .stretch:
            SwiftUI.Image(uiImage: uiImage).resizable()
        }
    }
    
    private var frameSize: CGSize {
        if let size = size {
            return size
        } else {
            return CGSize(
                width: uiImage.size.width * scale,
                height: uiImage.size.height * scale
            )
        }
    }
}

// MARK: - AnimatedImage

@available(iOS 13.0, *)
private struct AnimatedImageView: View {
    var uiImage: UIImage
    var scale: CGFloat
    var resizingMode: JudoModel.Image.ResizingMode
    var size: CGSize?

    var body: some View {
        switch resizingMode {
        case .originalSize:
            AnimatedImage(uiImage: uiImage)
                .frame(
                    width: frameSize.width,
                    height: frameSize.height
                )
        case .scaleToFill:
            SwiftUI.Rectangle().fill(Color.clear)
                .overlay(
                    AnimatedImage(uiImage: uiImage)
                        .scaledToFill()
                )
                .clipped()
        case .scaleToFit:
            AnimatedImage(uiImage: uiImage)
                .scaledToFit()
                .clipped()
        case .tile:
            // Tiling animated images is not supported -- fallback to static image.
            TilingImage(uiImage: uiImage, scale: scale)
        case .stretch:
            AnimatedImage(uiImage: uiImage)
        }
    }

    private var frameSize: CGSize {
        if let size = size {
            return size
        } else {
            return CGSize(
                width: uiImage.size.width * scale,
                height: uiImage.size.height * scale
            )
        }
    }
}

// MARK: - TilingImage

@available(iOS 13.0, *)
private struct TilingImage: View {
    var uiImage: UIImage

    var scale: CGFloat

    var body: some View {
        // tiling only uses the UIImage scale, it cannot be applied after .scaleEffect. so, generate a suitably large tiled image at the default 1x scale, and then scale the entire results down afterwards.
        if #available(iOS 14.0, *) {
            GeometryReader { geometry in
                SwiftUI.Image(uiImage: uiImage)
                    .resizable(resizingMode: .tile)
                    // make sure enough tile is generated to accommodate the scaleEffect below.
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
            }
        } else {
            // we cannot reliably use GeometryReader in all contexts on iOS 13, so instead, we'll just generate a default amount of tile that will accomodate most situations rather than the exact amount. this will waste some vram.
            SwiftUI.Rectangle()
                .fill(Color.clear)
                .overlay(
                    SwiftUI.Image(uiImage: uiImage)
                        .resizable(resizingMode: .tile)
                        // make sure enough tile is generated to accommodate the scaleEffect below.
                        .frame(
                            width: 600,
                            height: 1000
                        )
                    ,
                    alignment: .topLeading
                )
                .clipped()
        }
    }
}


// MARK: - PlaceholderView

@available(iOS 13.0, *)
private struct PlaceholderView: View {
    var blurHash: String?
    var scale: CGFloat
    var resizingMode: JudoModel.Image.ResizingMode
    var size: CGSize?
    
    @ViewBuilder
    var body: some View {
        if let uiImage = blurHashImage {
            StaticImageView(
                uiImage: uiImage,
                scale: scale,
                resizingMode: resizingMode,
                size: size
            )
        } else {
            if #available(iOS 14.0, *) {
                dummyView.redacted(reason: .placeholder)
            } else {
                dummyView
            }
        }
    }
    
    private var blurHashImage: UIImage? {
        guard let blurhash = blurHash, let size = blurHashSize else {
            return nil
        }
        
        return UIImage(blurHash: blurhash, size: size)
    }
    
    private var blurHashSize: CGSize? {
        guard let size = size else {
            return nil
        }
        
        // the blurhash algorithm is extremely expensive in unoptimized/debug builds (unoptimized Swift is sometimes hundreds of times slower), so backing off the resolution of rendered blurhashes in debug builds is very helpful.
        #if DEBUG
        // make the image 100x smaller. since it's blurry anyway and then gets scaled back up, there isn't much loss of fidelity.
        return CGSize(width: size.width / 10, height: size.height / 10)
        #else
        return size
        #endif
    }
    
    /// A clear, dummy view that mimics the sizing behaviour of the image.
    @ViewBuilder
    private var dummyView: some View {
        switch resizingMode {
        case .originalSize:
            SwiftUI.Rectangle()
                .fill(Color.clear)
                .frame(width: size?.width, height: size?.height)
        case .scaleToFill:
            SwiftUI.Rectangle().fill(Color.clear)
        case .scaleToFit:
            SwiftUI.Rectangle()
                .fill(Color.clear)
                .aspectRatio(aspectRatio, contentMode: ContentMode.fit)
        case .tile:
            SwiftUI.Rectangle().fill(Color.clear)
        case .stretch:
            SwiftUI.Rectangle().fill(Color.clear)
        }
    }
    
    private var aspectRatio: CGFloat {
        let ratio = CGFloat(size?.width ?? 1) / CGFloat(size?.height ?? 1)
        if ratio.isNaN || ratio.isInfinite {
            return 1
        } else {
            return ratio
        }
    }
}
