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
final public class JudoRepository {

    enum Error: Swift.Error {
        case notAvailable
    }

    /// Data synchronization service
    let syncService = SyncService()
    
    /// Retrieve Experience data.
    /// - Parameter url: Experience URL
    public func retrieveExperience(url: URL, ignoreCache: Bool = false, completion: @escaping (Result<Experience, Swift.Error>) -> Void) {
        guard (NSURLComponents(url: url, resolvingAgainstBaseURL: true)?.host) != nil else {
            judo_log(.error, "Attempt to retrieve an Experience for an unknown host.")
            DispatchQueue.main.async {
                completion(Result.failure(UnsupportedDomainError(domain: "<unknown>")))
            }
            return
        }
        
        
        syncService.fetchExperienceData(url: url, cachePolicy: ignoreCache ? .reloadIgnoringLocalAndRemoteCacheData : .returnCacheDataElseLoad) { result in
            do {
                let experienceData = try result.get()
                let experience = try Experience(decode: experienceData)
                DispatchQueue.main.async {
                    completion(.success(experience))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

struct UnsupportedDomainError: Error, LocalizedError {
    var domain: String
    
    var errorDescription: String? {
        "Unsupported Judo domain: \(domain)"
    }
}
