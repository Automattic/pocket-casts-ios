import Foundation
import UIKit

let isRunningTests = false /*NSClassFromString("XCTestCase") != nil*/
let appDelegateClass = isRunningTests ? "TestingAppDelegate" : NSStringFromClass(AppDelegate.self)

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    appDelegateClass
)
