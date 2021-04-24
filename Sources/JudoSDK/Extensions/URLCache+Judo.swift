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
import JudoModel
import os.log

@available(iOS 13.0, *)
extension URLCache {
    func cachedExperience(url: URL) -> Experience? {
        let request = URLRequest(url: url)
        guard let cachedResponse = self.cachedResponse(for: request), let urlResponse = cachedResponse.response as? HTTPURLResponse, urlResponse.statusCode < 400 else {
            return nil
        }
        do {
            return try Experience(decode: cachedResponse.data)
        } catch {
            judo_log(.error, "Invalid cached Experience for URL '%@' due to: %@. Removing it.", url.absoluteString, error.debugDescription)
            self.removeCachedResponse(for: request)
            return nil
        }
    }
}
