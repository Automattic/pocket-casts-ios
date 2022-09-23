import Foundation
import UIKit

let isRunningTests = NSClassFromString("XCTestCase") != nil
let appDelegateClass = isRunningTests ? "TestingAppDelegate" : NSStringFromClass(AppDelegate.self)

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    appDelegateClass
)
