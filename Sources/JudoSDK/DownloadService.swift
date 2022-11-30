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
import os.log

/// Download service.
final class DownloadService {
    internal var persistentFetchedExperienceURLs: Set<URL> {
        get {
            Set((Judo.userDefaults.array(forKey: "persistentFetchedExperienceURLs") as? [String])?.compactMap({ URL(string: $0) }) ?? [])
        }
        set {
            Judo.userDefaults.set(newValue.map(\.absoluteString), forKey: "persistentFetchedExperienceURLs")
        }
    }

    private var lastSeenCache: URLCache?
    private var _urlSession: URLSession
    private var urlSession: URLSession {
        get {
            if let lastSeenCache = lastSeenCache, lastSeenCache !== Judo.sharedInstance.urlCache {
                judo_log(.debug, "Judo cache setup changed since last usage of DownloadService, recreating URLSession.")
                _urlSession = URLSession(configuration: Self.defaultURLSessionConfiguration(cache: Judo.sharedInstance.urlCache))
                self.lastSeenCache = Judo.sharedInstance.urlCache
            }
            return _urlSession
        }
        set {
            _urlSession = newValue
        }
    }

    /// Instantiate instance
    /// - Parameter configuration: Service configuration.
    init(urlSession: URLSession? = nil) {
        self.lastSeenCache = Judo.sharedInstance.urlCache
        self._urlSession = urlSession ?? URLSession(configuration: Self.defaultURLSessionConfiguration(cache: Judo.sharedInstance.urlCache))
    }
    
    static func defaultURLSessionConfiguration(cache: URLCache) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.networkServiceType = .responsiveData
        return configuration
    }

    /// Fetch experience asynchronously.
    /// - Parameter completion: Fetched experience data
    func fetchExperienceData(url: URL, cachePolicy: URLRequest.CachePolicy, completion: @escaping (Result<Data, Swift.Error>) -> Void) {
        var urlRequest = URLRequest.apiRequest(url: url)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.cachePolicy = cachePolicy
        urlSession.dataTask(with: urlRequest) { result in
            completion(Result {
                let data = try result.get()

                // Remember fetched experience urls
                self.persistentFetchedExperienceURLs.insert(url)

                return data
            })
        }.resume()
    }
}
