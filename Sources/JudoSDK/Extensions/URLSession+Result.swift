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

extension URLSession {

    typealias FileURL = URL

    enum NetworkError: Swift.Error, LocalizedError, RecoverableError {
        case transportError(Error)
        case serverError(statusCode: Int, message: String)
        case noData

        var canRecover: Bool {
            switch self {
                case .transportError(_):
                    return true
                case .serverError(_, _):
                    return false
                case .noData:
                    return true
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .transportError(let error):
                return "Transport error: \(error.debugDescription)"
            case .serverError(let statusCode, let message):
                return "HTTP server error: \(statusCode), reason: \(message)"
            case .noData:
                return "No data was received."
            }
        }
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Result<Data, NetworkError>) -> Void) -> URLSessionDataTask {
        dataTask(with: request) { data, response, error in
            // the usages of removeCachedResponse() below, while a bit hacky, are present to prevent the use of .returnCacheDataElseLoad in fetchExperienceData from repeatedly returning a cached error response.
            
            if let error = error {
                self.configuration.urlCache?.removeCachedResponse(for: request)
                completionHandler(.failure(.transportError(error)))
                return
            }

            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                self.configuration.urlCache?.removeCachedResponse(for: request)
                completionHandler(.failure(.serverError(statusCode: response.statusCode, message: data.map { String(data: $0, encoding: .utf8) ?? "<none>" } ?? "<none>" )))
                return
            }

            guard let data = data else {
                self.configuration.urlCache?.removeCachedResponse(for: request)
                completionHandler(.failure(.noData))
                return
            }

            completionHandler(.success(data))
        }
    }

    func downloadTask(with request: URLRequest, completionHandler: @escaping (Result<FileURL, NetworkError>) -> Void) -> URLSessionDownloadTask {
        downloadTask(with: request) { (fileURL, response, error) in
            if let error = error {
                self.configuration.urlCache?.removeCachedResponse(for: request)
                completionHandler(.failure(.transportError(error)))
                return
            }

            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                self.configuration.urlCache?.removeCachedResponse(for: request)
                completionHandler(.failure(.serverError(statusCode: response.statusCode, message: "<none>")))
                return
            }

            guard let fileURL = fileURL else {
                self.configuration.urlCache?.removeCachedResponse(for: request)
                completionHandler(.failure(.noData))
                return
            }

            // download tasks don’t automatically store the result in the cache
            if let response = response, let data = try? Data(contentsOf: fileURL) {
                self.configuration.urlCache?.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
            }

            completionHandler(.success(fileURL))
        }
    }
}
