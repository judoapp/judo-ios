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

/// Synchronization service.
final class SyncService {

    typealias SynchronizationToken = URL

    private let lockQueue = DispatchQueue(label: "app.judo.SyncService.fetch-update-lock", attributes: .concurrent)

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
                judo_log(.debug, "Judo cache setup changed since last usage of SyncService, recreating URLSession.")
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

    /// Current synchronization token for the given Judo domain.
    ///
    /// Thread safe.
    internal func persistentSyncToken(domain: String) -> SynchronizationToken? {
        if let string = Judo.userDefaults.string(forKey: "\(domain)-SyncToken") {
            return URL(string: string)
        }
        return nil
    }
    
    /// Set a new sync token for the given Judo domain.
    ///
    /// Thread safe.
    private func setPersistentSyncToken(domain: String, token: SynchronizationToken) {
        Judo.userDefaults.setValue(token.absoluteString, forKey: "\(domain)-SyncToken")
    }
    
    static func defaultURLSessionConfiguration(cache: URLCache) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.networkServiceType = .responsiveData
        return configuration
    }

    /// Download and cache Experiences.
    /// - Parameters:
    ///   - completion: Completion handler.
    func sync(completion: @escaping () -> Void) {
        let fetchGroup = DispatchGroup()
    
        func syncForDomain(domainURL: URL) {
            fetchGroup.enter()
            judo_log(.debug, "Beginning sync for domain: %@", domainURL.absoluteString)
            fetchSyncData(domainURL: domainURL, syncToken: persistentSyncToken(domain: domainURL.host ?? "")) { sync, fetchedNewSyncToken  in
                defer {
                    fetchGroup.leave()
                }

                sync.filter(\.removed).forEach {
                    let cache = self.urlSession.configuration.urlCache!
                    cache.removeCachedResponse(for: URLRequest.apiRequest(url: $0.url))
                }

                let dataToFetch = sync.filter({ $0.removed == false })
                for syncData in dataToFetch {
                    fetchGroup.enter()
                    self.fetchExperienceData(url: syncData.url, cachePolicy: .reloadRevalidatingCacheData) { result in
                        defer { fetchGroup.leave() }

                        if case .failure(let error) = result {
                            judo_log(.error, "Error while downloading Experience during sync: %@", error.debugDescription)
                        }

                    }
                }

                if let syncToken = fetchedNewSyncToken {
                    self.setPersistentSyncToken(domain: domainURL.host ?? "", token: syncToken)
                }
            }
        }
        
        // queue up sync for all the domains.
        syncForDomain(domainURL: Judo.sharedInstance.domainURL)

        fetchGroup.notify(queue: .main) {
            judo_log(.debug, "Completed sync run for all Judo domains.")
            completion()
        }
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

    func fetchSyncData(domainURL: URL, syncToken: SynchronizationToken? = nil, completion: @escaping (_ data: [SyncResponse.Data], _ newSyncToken: SynchronizationToken?) -> Void) {
        var accumulatedSyncData: [SyncResponse.Data] = []

        let url = syncToken ?? domainURL.appendingPathComponent("sync")
        var urlRequest = URLRequest.apiRequest(url: url)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.cachePolicy = .reloadRevalidatingCacheData
        fetchSyncDataPage(urlSession, request: urlRequest) { [weak self] result in
            guard let self = self, let syncResult = try? result.get(), !syncResult.isLast else {
                let newSyncToken = try? result.get().syncToken
                completion(accumulatedSyncData, newSyncToken)
                return
            }

            self.lockQueue.sync(flags: .barrier) {
                accumulatedSyncData += syncResult.data
            }
        }
    }

    // Result is paginated. Fetch all pages and append to receive complete list of updates
    private func fetchSyncDataPage(_ session: URLSession, request: URLRequest, update: @escaping (Result<(isLast: Bool, syncToken: SynchronizationToken?, data: [SyncResponse.Data]), Swift.Error>) -> Void) {
        session.dataTask(with: request) { result in
            update(Result {
                do {
                    let data = try result.get()
                    let sync = try JSONDecoder().decode(SyncResponse.self, from: data)
                    if !sync.data.isEmpty {
                        self.fetchSyncDataPage(session, request: URLRequest.apiRequest(url: sync.nextLink), update: update)
                        return (isLast: false, syncToken: sync.nextLink, data: sync.data)
                    }

                    return (isLast: true, syncToken: sync.nextLink, data: [])
                } catch {
                    judo_log(.error, "Failed to decode server response: %@", (error as NSError).debugDescription)
                    throw URLError(.cannotParseResponse)
                }
            })
        }.resume()
    }
}
