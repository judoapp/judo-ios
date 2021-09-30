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
import BackgroundTasks

@available(iOS 13.0, *)
enum AppRefreshTask {

    static func registerBackgroundTask(taskIdentifier: String, timeInterval: TimeInterval) {
        guard let permittedIdentifiers = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String],
              permittedIdentifiers.contains(taskIdentifier)
        else {
            judo_log(.error, "Background task identifier %@ is not permited. Verify Info.plist \"BGTaskSchedulerPermittedIdentifiers\" key values.", taskIdentifier)
            preconditionFailure("Background task identifier \(taskIdentifier) is not permited. Verify Info.plist \"BGTaskSchedulerPermittedIdentifiers\" key values.")
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            handleJudoRefresh(task: task as! BGAppRefreshTask, timeInterval: timeInterval)
        }
    }

    static func handleJudoRefresh(task: BGAppRefreshTask, timeInterval: TimeInterval) {
        scheduleJudoRefresh(taskIdentifier: task.identifier, timeInterval: timeInterval)
        
        DispatchQueue.main.async {
            Judo.sharedInstance.performSync {
                task.setTaskCompleted(success: true)
            }
        }
    }

    static func scheduleJudoRefresh(taskIdentifier: String, timeInterval: TimeInterval) {
        do {
            let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: timeInterval)
            try BGTaskScheduler.shared.submit(request)
        } catch {
            judo_log(.error, "Could not schedule Judo refresh: %@", error.debugDescription)
        }
    }

}
