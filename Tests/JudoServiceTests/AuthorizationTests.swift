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
@testable import JudoSDK

@available(iOS 13.0, *)
final class AuthorizationTests: XCTestCase {
    var configuration: Configuration {
        Configuration(
            accessToken: "xxx",
            domain: "example.judo.app"
        )
    }
    
    
    // api.example.com
    // api.example.com (✓)
    func testExactMatch() {
        let url = URL(string: "https://api.example.com")!
        var request = URLRequest(url: url)
        
        var configuration = self.configuration
        
        configuration.authorize("api.example.com") { request in
            request.setValue("bar", forHTTPHeaderField: "foo")
        }
        
        Judo.initialize(configuration: configuration)
        Judo.sharedInstance.authorize(&request)
        XCTAssertEqual(request.allHTTPHeaderFields?["foo"], "bar")
    }
    
    // api.example.com
    //   *.example.com (✓)
    func testWildcardMatch() {
        let url = URL(string: "https://api.example.com")!
        var request = URLRequest(url: url)
        
        var configuration = self.configuration
        
        configuration.authorize("*.example.com") { request in
            request.setValue("bar", forHTTPHeaderField: "foo")
        }
        
        Judo.initialize(configuration: configuration)
        Judo.sharedInstance.authorize(&request)
        XCTAssertEqual(request.allHTTPHeaderFields?["foo"], "bar")
    }
    
    // api.example.com
    // www.example.com (x)
    func testDifferentSubdomain() {
        let url = URL(string: "https://api.example.com")!
        var request = URLRequest(url: url)
        
        var configuration = self.configuration
        
        configuration.authorize("www.example.com") { request in
            request.setValue("bar", forHTTPHeaderField: "foo")
        }
        
        Judo.initialize(configuration: configuration)
        Judo.sharedInstance.authorize(&request)
        XCTAssertNil(request.allHTTPHeaderFields?["foo"])
    }
    
    // api.example.com
    //     example.com (x)
    func testNoSubdomain() {
        let url = URL(string: "https://api.example.com")!
        var request = URLRequest(url: url)
        
        var configuration = self.configuration
        
        configuration.authorize("example.com") { request in
            request.setValue("bar", forHTTPHeaderField: "foo")
        }
        
        Judo.initialize(configuration: configuration)
        Judo.sharedInstance.authorize(&request)
        XCTAssertNil(request.allHTTPHeaderFields?["foo"])
    }
    
    // api.example.com
    //             com (x)
    func testOnlyTLD() {
        let url = URL(string: "https://api.example.com")!
        var request = URLRequest(url: url)
        
        var configuration = self.configuration
        
        configuration.authorize("com") { request in
            request.setValue("bar", forHTTPHeaderField: "foo")
        }
        
        Judo.initialize(configuration: configuration)
        Judo.sharedInstance.authorize(&request)
        XCTAssertNil(request.allHTTPHeaderFields?["foo"])
    }
    
    // example.com
    // example.com (✓)
    func testRequestWithoutSubdomainPass() {
        let url = URL(string: "https://example.com")!
        var request = URLRequest(url: url)
        
        var configuration = self.configuration
        
        configuration.authorize("example.com") { request in
            request.setValue("bar", forHTTPHeaderField: "foo")
        }
        
        Judo.initialize(configuration: configuration)
        Judo.sharedInstance.authorize(&request)
        XCTAssertEqual(request.allHTTPHeaderFields?["foo"], "bar")
    }
    
    //   example.com
    // *.example.com (x)
    func testRequestWithoutSubdomainFail() {
        let url = URL(string: "https://example.com")!
        var request = URLRequest(url: url)
        
        var configuration = self.configuration
        
        configuration.authorize("*.example.com") { request in
            request.setValue("bar", forHTTPHeaderField: "foo")
        }
        
        Judo.initialize(configuration: configuration)
        Judo.sharedInstance.authorize(&request)
        XCTAssertEqual(request.allHTTPHeaderFields?["foo"], "bar")
    }
    
    func testDeeplyNestedSubdomainPass() {
        let url = URL(string: "https://elrond.rivendell.middleearth.net")!
        var request = URLRequest(url: url)
        
        var configuration = self.configuration
        
        configuration.authorize("*.middleearth.net") { request in
            request.setValue("bar", forHTTPHeaderField: "foo")
        }
        
        Judo.initialize(configuration: configuration)
        Judo.sharedInstance.authorize(&request)
        XCTAssertEqual(request.allHTTPHeaderFields?["foo"], "bar")
    }
}
