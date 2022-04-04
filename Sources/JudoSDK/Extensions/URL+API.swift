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
import UIKit
import JudoModel

extension URLRequest {
    static func assetRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addDefaultHeaders()
        return request
    }
    
    static func apiRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addDefaultHeaders()
        request.addAPIHeaders()
        request.addAPIVersionParameter()
        return request
    }
    
    private mutating func addDefaultHeaders() {
        let deviceID = UIDevice().identifierForVendor?.uuidString ?? ""
        addValue(deviceID, forHTTPHeaderField: "Judo-Device-ID")
        addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        addValue(judoUserAgent, forHTTPHeaderField: "User-Agent")
    }
    
    private mutating func addAPIHeaders() {
        guard let accessToken = Judo.sharedInstance.configuration.accessToken else {
            return
        }
        addValue("application/json", forHTTPHeaderField: "Accept")
        addValue(accessToken, forHTTPHeaderField: "Judo-Access-Token")
    }
    
    private mutating func addAPIVersionParameter() {
        guard let existingURL = url,
              var components = URLComponents(url: existingURL, resolvingAgainstBaseURL: false) else {
            assertionFailure("Invalid URL Request")
            return
        }
        
        let apiVersion = URLQueryItem(
            name: "apiVersion",
            value: Meta.APIVersion.description
        )
        
        components.queryItems = [apiVersion] + (components.queryItems ?? [])
        
        guard let newURL = components.url else {
            assertionFailure("Failed to append API version to URL request")
            return
        }
        
        url = newURL
    }
}

private var judoUserAgent: String {
    // AppName/$version. (a value exists for this by default, but this version is a bit better than the stock version of this value, which has the app build number rather than version)
    let appBundleDict = Bundle.main.infoDictionary
    let appName = appBundleDict?["CFBundleName"] as? String ?? "unknown"
    let appVersion = appBundleDict?["CFBundleShortVersionString"] as? String ?? "unknown"
    let appDescriptor = appName + "/" + appVersion

    // CFNetwork/$version (reproducing it; it exists in the standard iOS user agent, and perhaps some ops tooling will benefit from it being stock)
    let cfNetworkInfo = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary
    let cfNetworkVersion = cfNetworkInfo?["CFBundleShortVersionString"] as? String ?? "unknown"
    let cfNetworkDescriptor = "CFNetwork/\(cfNetworkVersion)"

    // Darwin/$version (reproducing it; it exists in the standard iOS user agent, and perhaps some ops tooling will benefit from it being stock)
    var sysinfo = utsname()
    uname(&sysinfo)
    let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) ?? "unknown"
    let darwinDescriptor = "Darwin/\(dv)"

    // iOS/$ios-version
    let osDescriptor = "iOS/" + UIDevice.current.systemVersion
    return "\(appDescriptor) \(cfNetworkDescriptor) \(darwinDescriptor) \(osDescriptor) JudoSDK/\(Meta.SDKVersion)"
}

