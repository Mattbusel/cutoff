import ActivityKit
import Foundation

/// Cutoff Pro: the time left for your usual, counting down on the Lock Screen.
@MainActor
enum LiveCup {
    static func start(_ store: Store) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, let cut = store.cutoff(), cut > Date().addingTimeInterval(60) else { end(); return }
        let state = CupAttributes.ContentState(opened: store.dayStart(for: store.bed).addingTimeInterval(4 * 3600), cutoff: cut, bed: store.bed)
        if let a = Activity<CupAttributes>.activities.first {
            Task { await a.update(ActivityContent(state: state, staleDate: cut)) }
            return
        }
        _ = try? Activity<CupAttributes>.request(attributes: CupAttributes(drink: store.usual.name), content: ActivityContent(state: state, staleDate: cut), pushType: nil)
    }

    static func end() {
        for a in Activity<CupAttributes>.activities { Task { await a.end(nil, dismissalPolicy: .immediate) } }
    }
}
