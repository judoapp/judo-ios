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

import XCTest
import Mocker
@testable import JudoSDK

@available(iOS 13.0, *)
final class JudoServiceTest: XCTestCase {
    
    override func setUp() {
        // this is an unclean approach to global state and dependencies, but it keeps things simple in the SDK code proper.
        Judo.initialize(accessToken: "testsuite", domain: "sdktest.judo.app")
        Judo.userDefaults.removeObject(forKey: "sdktest.judo.app-SyncToken")
    }

    func testFetchSyncDataPaging() {
        Mock(url: URL(string: "https://sdktest.judo.app/sync")!,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"data":[{"url":"https://sdktest.judo.app/testslug","removed":false,"priority":10}],"nextLink":"https://sdktest.judo.app/sync?cursor=2"}"#.data(using: .utf8)!,]
        ).register()

        Mock(url: URL(string: "https://sdktest.judo.app/sync?cursor=2")!,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"data":[{"url":"https://sdktest.judo.app/testslug2","removed":true,"priority":5}],"nextLink":"https://sdktest.judo.app/sync?cursor=3"}"#.data(using: .utf8)!,]
        ).register()

        Mock(url: URL(string: "https://sdktest.judo.app/sync?cursor=3")!,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"data":[],"nextLink":"https://sdktest.judo.app/sync?cursor=3"}"#.data(using: .utf8)!]
        ).register()

        let cache = URLCache(memoryCapacity: 1024 * 1024 * 64, diskCapacity: 0)
        let sessionConfiguration = SyncService.defaultURLSessionConfiguration(cache: cache)
        sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
        let service = SyncService(urlSession: URLSession(configuration: sessionConfiguration))

        let expectation = self.expectation(description: "Data request should succeed")
        service.fetchSyncData(domainURL: URL(string: "https://sdktest.judo.app")!) { data, _ in
            XCTAssertEqual(data.count, 2)

            XCTAssertEqual(data[0].url, URL(string: "https://sdktest.judo.app/testslug")!)
            XCTAssertEqual(data[0].removed, false)
            XCTAssertEqual(data[0].priority, 10)

            XCTAssertEqual(data[1].url, URL(string: "https://sdktest.judo.app/testslug2")!)
            XCTAssertEqual(data[1].removed, true)
            XCTAssertEqual(data[1].priority, 5)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)
    }

    func testSync() {
        Mock(url: URL(string: "https://sdktest.judo.app/sync")!,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"data":[{"url":"https://sdktest.judo.app/testslug","removed":false,"priority":10}],"nextLink":"https://sdktest.judo.app/sync?cursor=2"}"#.data(using: .utf8)!]
        ).register()

        Mock(url: URL(string: "https://sdktest.judo.app/sync?cursor=2")!,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"data":[{"url":"https://sdktest.judo.app/testslug2","removed":true,"priority":5}],"nextLink":"https://sdktest.judo.app/sync?cursor=3"}"#.data(using: .utf8)!]
        ).register()

        Mock(url: URL(string: "https://sdktest.judo.app/sync?cursor=3")!,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"data":[],"nextLink":"https://sdktest.judo.app/sync?cursor=4"}"#.data(using: .utf8)!]
        ).register()

        Mock(url: URL(string: "https://sdktest.judo.app/sync?cursor=4")!,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"data":[{"url":"https://sdktest.judo.app/testslug","removed":true,"priority":5}, {"url":"https://sdktest.judo.app/testslug3","removed":false,"priority":5}],"nextLink":"https://sdktest.judo.app/sync?cursor=5"}"#.data(using: .utf8)!]
        ).register()

        Mock(url: URL(string: "https://sdktest.judo.app/sync?cursor=5")!,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"data":[],"nextLink":"https://sdktest.judo.app/sync?cursor=5"}"#.data(using: .utf8)!]
        ).register()

        var mockTestSlug1 = Mock(url: URL(string: "https://sdktest.judo.app/testslug")!,
             cacheStoragePolicy: .allowed,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"id": "1"}"#.data(using: .utf8)!],
             additionalHeaders: [
                "Date": "Tue, 10 Nov 2020 12:48:14 GMT",
                "Cache-Control": "public, max-age=31557600, immutable"
             ]
        )
        let testSlug1Expectation = expectationForCompletingMock(&mockTestSlug1)
        mockTestSlug1.register()

        var mockTestSlug2 = Mock(url: URL(string: "https://sdktest.judo.app/testslug2")!,
             cacheStoragePolicy: .allowed,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"id": "2"}"#.data(using: .utf8)!],
             additionalHeaders: ["Cache-Control": "public, max-age=31557600, immutable"]
        )
        let testSlug2Expectation = expectationForCompletingMock(&mockTestSlug2)
        testSlug2Expectation.isInverted = true
        mockTestSlug2.register()

        var mockTestSlug3 = Mock(url: URL(string: "https://sdktest.judo.app/testslug3")!,
             cacheStoragePolicy: .allowed,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"id": "3"}"#.data(using: .utf8)!],
             additionalHeaders: ["Cache-Control": "public, max-age=31557600, immutable"]
        )
        let testSlug3Expectation = expectationForCompletingMock(&mockTestSlug3)
        mockTestSlug3.register()

        let cache = URLCache(memoryCapacity: 1024 * 1024 * 64, diskCapacity: 0)
        let sessionConfiguration = SyncService.defaultURLSessionConfiguration(cache: cache)
        sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
        let service = SyncService(urlSession: URLSession(configuration: sessionConfiguration))

        let syncCompleteExpectation = self.expectation(description: "Sync should succeed")

        // First sync. Fetch testslug and ignore testslug2
        service.sync() {
            let newSyncToken = service.persistentSyncToken(domain: "sdktest.judo.app")
            XCTAssertNotNil(newSyncToken)
            XCTAssertEqual(newSyncToken, URL(string: "https://sdktest.judo.app/sync?cursor=4")!)
            XCTAssertNotNil(cache.cachedResponse(for: URLRequest(url: URL(string: "https://sdktest.judo.app/testslug")!)))
            XCTAssertNil(cache.cachedResponse(for: URLRequest(url: URL(string: "https://sdktest.judo.app/testslug2")!)))

            // Subsequent sync. remove previous slugs and add testslug3
            service.sync {
                let newSyncToken = service.persistentSyncToken(domain: "sdktest.judo.app")
                XCTAssertNotNil(newSyncToken)
                XCTAssertEqual(newSyncToken, URL(string: "https://sdktest.judo.app/sync?cursor=5")!)
                XCTAssertNil(cache.cachedResponse(for: URLRequest(url: URL(string: "https://sdktest.judo.app/testslug")!)))
                XCTAssertNil(cache.cachedResponse(for: URLRequest(url: URL(string: "https://sdktest.judo.app/testslug2")!)))
                XCTAssertNotNil(cache.cachedResponse(for: URLRequest(url: URL(string: "https://sdktest.judo.app/testslug3")!)))
                syncCompleteExpectation.fulfill()
            }
        }

        wait(for: [testSlug1Expectation, testSlug2Expectation, testSlug3Expectation, syncCompleteExpectation], timeout: 2)
    }

    func testPriorityOrder() {
        let slug1Data = SyncResponse.Data(url: URL(string: "https://sdktest.judo.app/testslug")!, removed: false, priority: 5)
        let slug2Data = SyncResponse.Data(url: URL(string: "https://sdktest.judo.app/testslug2")!, removed: false, priority: 10)
        let slug3Data = SyncResponse.Data(url: URL(string: "https://sdktest.judo.app/testslug3")!, removed: false, priority: 0)

        XCTAssertEqual([slug1Data, slug2Data, slug3Data].sorted(), [slug2Data, slug1Data, slug3Data])
    }

    func testExperienceFetch() {
        var mockTestSlug = Mock(url: URL(string: "https://sdktest.judo.app/testslug")!,
             cacheStoragePolicy: .allowed,
             dataType: .json,
             statusCode: 200,
             data: [.get: #"{"id": 16,"revisionId": 4,"nodes": [], "screenIDs": [], "initialScreenID": "7BE71C5F-CE5E-4BC0-8AC1-7388B35862EF"}"#.data(using: .utf8)!]
        )
        let testSlugExpectation = expectationForCompletingMock(&mockTestSlug)
        mockTestSlug.register()

        let cache = URLCache(memoryCapacity: 1024 * 1024 * 64, diskCapacity: 0)
        let sessionConfiguration = SyncService.defaultURLSessionConfiguration(cache: cache)
        sessionConfiguration.protocolClasses = [MockingURLProtocol.self]
        let service = SyncService(urlSession: URLSession(configuration: sessionConfiguration))
        
        let url = URL(string: "https://sdktest.judo.app/testslug")!

        XCTAssertNil(cache.cachedResponse(for: URLRequest(url: url)))

        let fetchCompletionExpectation = self.expectation(description: "Fetch should succeed")
        service.fetchExperienceData(url: url, cachePolicy: .returnCacheDataElseLoad) { result in
            do {
                _ = try result.get()

                XCTAssertNotNil(cache.cachedResponse(for: URLRequest(url: URL(string: "https://sdktest.judo.app/testslug")!)))
                XCTAssertNil(cache.cachedResponse(for: URLRequest(url: URL(string: "https://sdktest.judo.app/testslug2")!)))

                fetchCompletionExpectation.fulfill()
            } catch {
                XCTFail("\(error)")
            }
        }

        wait(for: [testSlugExpectation, fetchCompletionExpectation], timeout: 2)
    }
}
