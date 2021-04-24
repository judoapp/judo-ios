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

import UIKit

extension UIControl {

    func addAction(for controlEvents: UIControl.Event, _ action: @escaping (UIControl) -> Void) {

        @objc final class UIControlClosureBox: NSObject {
            private let closure: (UIControl) -> Void

            init(_ closure: @escaping (UIControl) -> Void) {
                self.closure = closure
            }

            @objc func invoke(_ sender: UIControl) {
                closure(sender)
            }
        }

        let box = UIControlClosureBox(action)
        addTarget(box, action: #selector(UIControlClosureBox.invoke(_:)), for: controlEvents)
        objc_setAssociatedObject(self, "\(UUID())", box, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
}
