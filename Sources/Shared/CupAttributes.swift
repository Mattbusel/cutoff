import ActivityKit
import Foundation

/// What the Lock Screen shows while the coffee window is open. Shared by the app and the Live extension.
struct CupAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var opened: Date
        var cutoff: Date
        var bed: Date
    }
    var drink: String
}
