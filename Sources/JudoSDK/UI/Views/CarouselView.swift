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
struct CarouselView: UIViewControllerRepresentable {
    var carousel: Carousel
    var pages = [UIViewController]()
    
    @EnvironmentObject private var carouselState: CarouselState
    
    init(carousel: Carousel) {
        self.carousel = carousel
        
        pages = carousel.children
            .compactMap { $0 as? Layer }
            .map {
                let vc = UIHostingController(rootView: LayerView(layer: $0) )
                vc.view.backgroundColor = .clear
                vc.view.clipsToBounds = true
                return vc
            }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            pages: pages,
            currentPage: Binding {
                carouselState.currentPageForCarousel[carousel.id] ?? 0
            } set: { pageIndex in
                carouselState.currentPageForCarousel[carousel.id] = pageIndex
            },
            isLoopEnabled: carousel.isLoopEnabled
        )
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal)
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        let currentPageIndex = carouselState.currentPageForCarousel[carousel.id] ?? 0
        
        guard pages.indices.contains(currentPageIndex) else {
            assertionFailure("Out-of-range currentPageIndex for carousel: \(currentPageIndex)")
            return
        }
        
        let currentPage = pages[currentPageIndex]

        var direction: UIPageViewController.NavigationDirection = .forward
        if let currentViewController = pageViewController.viewControllers?.first,
           let fromIndex = pages.firstIndex(of: currentViewController),
           let toIndex = pages.firstIndex(of: currentPage)
        {
            if fromIndex > toIndex {
                direction = .reverse
            }
        }

        pageViewController.setViewControllers([currentPage], direction: direction, animated: true)
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var pages: [UIViewController]
        @Binding var currentPage: Int
        var isLoopEnabled: Bool
        
        init(pages: [UIViewController], currentPage: Binding<Int>, isLoopEnabled: Bool) {
            self.pages = pages
            self._currentPage = currentPage
            self.isLoopEnabled = isLoopEnabled
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = pages.firstIndex(of: viewController) else {
                return nil
            }
            
            if index > 0 {
                return pages[index - 1]
            } else if isLoopEnabled {
                return pages.last
            } else {
                return nil
            }
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = pages.firstIndex(of: viewController) else {
                return nil
            }
            
            if index + 1 < pages.count {
                return pages[index + 1]
            } else if isLoopEnabled {
                return pages.first
            } else {
                return nil
            }
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed, let visibleViewController = pageViewController.viewControllers?.first, let index = pages.firstIndex(of: visibleViewController) {
                currentPage = index
            }
        }
    }
}
