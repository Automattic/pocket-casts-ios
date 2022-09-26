import Foundation
import UIKit

let isRunningTests = false
let appDelegateClass = isRunningTests ? "TestingAppDelegate" : NSStringFromClass(AppDelegate.self)

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    appDelegateClass
)
