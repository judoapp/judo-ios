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

class JSONSerializationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValueForKeyPath() throws {
        let exampleData = [
            "hello": 42
        ]
        
        let value = JSONSerialization.value(forKeyPath: "data.hello", data: exampleData, urlParameters: [:], userInfo: [:])
        XCTAssertEqual(value as! Int, 42)
    }
    
    func testMissingValueForKeyPath() throws {
        let exampleData = [
            "another": 42
        ]
        
        let value = JSONSerialization.value(forKeyPath: "data.missing", data: exampleData, urlParameters: [:], userInfo: [:])
        XCTAssertNil(value)
    }
    
    func testKeyPathTraversal() throws {
        let exampleData = [
            "nested": [
                "hello": 42,
                "attribute_with.period": 69,
                
                // because you know some deranged API out there will do this.
                "attribute_with_trailing_period.": 1337,
                ".attribute_with_leading_period": 7331
            ],
            "flattened.attributes": [
                "hello": 24
            ]
        ]

        let nestedValue = JSONSerialization.value(forKeyPath: "data.nested.hello", data: exampleData, urlParameters: [:], userInfo: [:])
        XCTAssertEqual(nestedValue as! Int, 42)

        let dictValue = JSONSerialization.value(forKeyPath: "data.nested", data: exampleData, urlParameters: [:], userInfo: [:])
        XCTAssert(dictValue is [String: Any])

        let value = JSONSerialization.value(forKeyPath: "data.flattened.attributes.hello", data: exampleData, urlParameters: [:], userInfo: [:])
        XCTAssertEqual(value as! Int, 24)

        let keyWithPeriodValue = JSONSerialization.value(forKeyPath: "data.nested.attribute_with.period", data: exampleData, urlParameters: [:], userInfo: [:])
        XCTAssertEqual(keyWithPeriodValue as! Int, 69)
        
        let derangedLeadingPeriodValue = JSONSerialization.value(forKeyPath: "data.nested..attribute_with_leading_period", data: exampleData, urlParameters: [:], userInfo: [:])
        XCTAssertEqual(derangedLeadingPeriodValue as! Int, 7331)
        
        let derangedTrailingPeriodValue = JSONSerialization.value(forKeyPath: "data.nested.attribute_with_trailing_period.", data: exampleData, urlParameters: [:], userInfo: [:])
        XCTAssertEqual(derangedTrailingPeriodValue as! Int, 1337)
    }
}
