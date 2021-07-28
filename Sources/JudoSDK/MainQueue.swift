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

private let mainQueueKey: DispatchSpecificKey<String> = {
    let key = DispatchSpecificKey<String>()
    DispatchQueue.main.setSpecific(key: key, value: "judoMainQueueValue")
    return key
}()

extension DispatchQueue {

    static var isMainQueue: Bool {
        DispatchQueue.getSpecific(key: mainQueueKey) != nil
    }

    static func toMain(_ block: @escaping () -> Void) {

        // Being on the main thread does not guarantee to be on the main queue.
        if DispatchQueue.isMainQueue {
            block()
        } else {
            if Thread.isMainThread {
                DispatchQueue.main.async {
                    block()
                }
            } else {
                // Execution is not on the main queue and thread at this point.
                DispatchQueue.main.sync {
                    block()
                }
            }
        }
    }
}
