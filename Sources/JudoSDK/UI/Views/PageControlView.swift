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
struct PageControlView: View {
    @Environment(\.collectionIndex) private var collectionIndex
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.data) private var data
    @Environment(\.urlParameters) private var urlParameters
    @Environment(\.userInfo) private var userInfo
    
    @EnvironmentObject private var carouselState: CarouselState
    let pageControl: PageControl
    
    var body: some View {
        RealizeColor(normalColor) { normalColor in
            RealizeColor(currentColor) { currentColor in
                PageControlViewBody(
                    numberOfPages: numberOfPages,
                    currentPage: currentPage,
                    hidesForSinglePage: pageControl.hidesForSinglePage,
                    normalColor: normalColor,
                    currentColor: currentColor,
                    normalImage: normalImage,
                    currentImage: currentImage
                )
            }
        }
    }
    
    private var currentPage: Binding<Int> {
        guard let carousel = pageControl.carousel else {
            return .constant(0)
        }
        
        let viewID = ViewID(nodeID: carousel.id, collectionIndex: collectionIndex)
        return Binding {
            carouselState.currentPageForCarousel[viewID] ?? 0
        } set: { newValue in
            carouselState.currentPageForCarousel[viewID] = newValue
        }
    }
    
    private var numberOfPages: Binding<Int> {
        guard let carousel = pageControl.carousel else {
            return .constant(0)
        }
        
        let viewID = ViewID(nodeID: carousel.id, collectionIndex: collectionIndex)
        return Binding {
            carouselState.currentNumberOfPagesForCarousel[viewID] ?? 0
        } set: { newValue in
            carouselState.currentNumberOfPagesForCarousel[viewID] = newValue
        }
    }

    private var normalImage: JudoModel.Image? {
        guard case .image(let normalImage, _, _, _) = pageControl.style else {
            return nil
        }

        return normalImage
    }

    private var currentImage: JudoModel.Image? {
        guard case .image(_, _, let currentImage, _) = pageControl.style else {
            return nil
        }

        return currentImage
    }

    private var normalColor: ColorVariants {
        switch pageControl.style {
            case .default:
                return ColorVariants(
                    systemName: nil,
                    default: JudoModel.Color(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3),
                    highContrast: nil,
                    darkMode: JudoModel.Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3),
                    darkModeHighContrast: nil
                )
            case .light:
                return ColorVariants(
                    systemName: nil,
                    default: JudoModel.Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3),
                    highContrast: nil,
                    darkMode: nil,
                    darkModeHighContrast: nil
                )
            case .dark:
                return ColorVariants(
                    systemName: nil,
                    default: JudoModel.Color(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3),
                    highContrast: nil,
                    darkMode: nil,
                    darkModeHighContrast: nil
                )
            case .inverted:
                return ColorVariants(
                    systemName: nil,
                    default: JudoModel.Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3),
                    highContrast: nil,
                    darkMode: JudoModel.Color(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3),
                    darkModeHighContrast: nil
                )
            case .custom(let normalColor, _):
                return normalColor
            case .image(_, let normalColor, _, _):
                return normalColor
        }
    }

    private var currentColor: ColorVariants {
        switch pageControl.style {
            case .default:
                return ColorVariants(
                    systemName: nil,
                    default: JudoModel.Color(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
                    highContrast: nil,
                    darkMode: JudoModel.Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                    darkModeHighContrast: nil
                )
            case .light:
                return ColorVariants(
                    systemName: nil,
                    default: JudoModel.Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                    highContrast: nil,
                    darkMode: nil,
                    darkModeHighContrast: nil
                )
            case .dark:
                return ColorVariants(
                    systemName: nil,
                    default: JudoModel.Color(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
                    highContrast: nil,
                    darkMode: nil,
                    darkModeHighContrast: nil
                )
            case .inverted:
                return ColorVariants(
                    systemName: nil,
                    default: JudoModel.Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                    highContrast: nil,
                    darkMode: JudoModel.Color(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
                    darkModeHighContrast: nil
                )
            case .custom(_, let currentColor):
                return currentColor
            case .image(_, _, _, let currentColor):
                return currentColor
        }
    }
}

@available(iOS 13.0, *)
private struct PageControlViewBody: UIViewRepresentable {
    @Environment(\.data) private var data
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.urlParameters) private var urlParameters
    @Environment(\.userInfo) private var userInfo
    @Binding private var numberOfPages: Int
    @Binding private var currentPage: Int
    private var hidesForSinglePage: Bool

    private let normalColor: UIColor
    private let currentColor: UIColor

    @ObservedObject var images: Images

    init(numberOfPages: Binding<Int>, currentPage: Binding<Int>, hidesForSinglePage: Bool, normalColor: UIColor, currentColor: UIColor, normalImage: JudoModel.Image?, currentImage: JudoModel.Image?) {
        self._numberOfPages = numberOfPages
        self._currentPage = currentPage
        self.hidesForSinglePage = hidesForSinglePage
        self.normalColor = normalColor
        self.currentColor = currentColor
        self.images = Images(normalImage: normalImage, currentImage: currentImage)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage, images: images)
    }

    func makeUIView(context: Context) -> UIPageControl {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = numberOfPages
        pageControl.hidesForSinglePage = hidesForSinglePage

        pageControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.updateCurrentPage(sender:)),
            for: .valueChanged
        )
        
        return pageControl
    }

    func updateUIView(_ pageControl: UIPageControl, context: Context) {
        images.fetchImages(data: data, colorScheme: colorScheme, urlParameters: urlParameters, userInfo: userInfo)
        
        //Update page count, before iterating on the number of pages.
        pageControl.numberOfPages = numberOfPages
        
        // Store current value. currentPage is a binding and it's value may change.
        let currentPageValue = currentPage

        if #available(iOS 14.0, *) {
            for page in 0..<pageControl.numberOfPages {
                let image: UIImage?
                if page == currentPageValue {
                    image = images.currentUIImage
                } else {
                    image = images.normalUIImage
                }

                if let image = image {
                    pageControl.setIndicatorImage(image, forPage: page)
                }
            }
        }

        pageControl.currentPage = currentPageValue
        pageControl.pageIndicatorTintColor = normalColor
        pageControl.currentPageIndicatorTintColor = currentColor
    }

    final class Coordinator: NSObject, ObservableObject {
        @Binding var currentPage: Int
        private let images: Images

        init(currentPage: Binding<Int>, images: Images) {
            self.images = images
            _currentPage = currentPage
            super.init()
        }
        
        @objc func updateCurrentPage(sender: UIPageControl) {
            currentPage = sender.currentPage
        }
    }
}

@available(iOS 13.0, *)
private final class Images: ObservableObject {
    private let normalImage: JudoModel.Image?
    private let currentImage: JudoModel.Image?
    
    private var data: Any?
    private var colorScheme: ColorScheme?
    private var urlParameters: [String: String] = [:]
        
    private var userInfo: [String: Any] = [:]

    @Published var normalUIImage: UIImage?
    @Published var currentUIImage: UIImage?

    init(normalImage: JudoModel.Image?, currentImage: JudoModel.Image?) {
        self.normalImage = normalImage
        self.currentImage = currentImage
    }

    func fetchImages(data: Any?, colorScheme: ColorScheme, urlParameters: [String: String], userInfo: [String: Any]) {
        // we need Equatable to do the comparison so re-wrap in JSON.
        let currentUserInfo = try? JSON(self.userInfo)
        let newUserInfo = try? JSON(userInfo)
        
        guard self.colorScheme != colorScheme || self.urlParameters != urlParameters, currentUserInfo != newUserInfo else {
            return
        }

        self.data = data
        self.colorScheme = colorScheme
        self.urlParameters = urlParameters
        self.userInfo = userInfo
                
        if let normalImage = normalImage {
            fetch(image: normalImage) { uiImage in
                self.normalUIImage = uiImage
            }
        }

        if let currentImage = currentImage {
            fetch(image: currentImage) { uiImage in
                self.currentUIImage = uiImage
            }
        }
    }

    private func fetch(image: JudoModel.Image, completion: @escaping (UIImage) -> Void) {
        let scale = self.scale(for: image)
        if let urlString = urlString(for: image)?.evaluatingExpressions(data: data, urlParameters: urlParameters, userInfo: userInfo), let resolvedURL = URL(string: urlString)  {
            fetchImage(url: resolvedURL) { uiImage in
                DispatchQueue.main.async {
                    completion(UIImage.scale(image: uiImage, by: scale))
                }
            }
        } else if let inlineImage = image.inlineImage {
            completion(UIImage.scale(image: inlineImage, by: scale))
        }
    }

    private func fetchImage(url: URL, success: @escaping (UIImage) -> Void) {
        if let cachedImage = Judo.sharedInstance.imageCache.object(forKey: url as NSURL) {
            success(cachedImage)
            return
        }

        Judo.sharedInstance.downloader.enqueue(url: url, priority: .high) { result in
            switch result {
            case let .failure(error):
                judo_log(.error, "Failed to fetch image data: %@", (error as NSError).userInfo.debugDescription)
                return
            case let .success(data):
                Judo.sharedInstance.imageFetchAndDecodeQueue.async {
                    guard let decoded = UIImage(data: data) else {
                        judo_log(.error, "Failed to decode image data.")
                        return
                    }

                    DispatchQueue.main.async {
                        Judo.sharedInstance.imageCache.setObject(decoded, forKey: url as NSURL)
                    }

                    success(decoded)
                }
            }
        }
    }
    
    private func urlString(for image: JudoModel.Image) -> String? {
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

    private func scale(for image: JudoModel.Image) -> CGFloat {
        guard image.resolution > 0 else {
            return 1
        }

        return CGFloat(1) / image.resolution
    }
}

// MARK: - UIImage helper

private extension UIImage {
    private static func resize(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height

        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

    static func scale(image: UIImage, by scale: CGFloat) -> UIImage {
        let size = image.size
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIImage.resize(image: image, targetSize: scaledSize)
    }
}
