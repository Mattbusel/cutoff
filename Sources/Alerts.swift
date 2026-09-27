import Foundation
import UserNotifications

/// Local notifications only: last call before the cutoff, and when it passes (Pro).
@MainActor
final class Alerts: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Alerts()
    private let center = UNUserNotificationCenter.current()
    var demo = false
    weak var pro: Pro?

    func setUp() { center.delegate = self }

    func ask() async -> Bool {
        if demo { return true }
        let s = await center.notificationSettings()
        switch s.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .denied: return false
        default: return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
    }

    /// Re-plan tonight's reminders and the Lock Screen countdown after anything changes.
    func refresh(_ store: Store) {
        guard !demo else { return }
        let unlocked = pro?.unlocked == true
        if unlocked && store.db.profile.live { LiveCup.start(store) } else { LiveCup.end() }
        center.removePendingNotificationRequests(withIdentifiers: ["lastcall-soon", "lastcall-now"])
        guard unlocked, store.db.profile.notify, let cut = store.cutoff() else { return }
        let u = store.usual
        let bed = store.bed
        Task {
            guard await ask() else { return }
            let soon = cut.addingTimeInterval(-20 * 60)
            if soon > Date() {
                add("lastcall-soon", at: soon, title: "Last call in 20 minutes", body: "Your latest \(u.noun) today is \(Fmt.time(cut)) if you want to sleep at \(Fmt.time(bed)).")
            }
            if cut > Date() {
                add("lastcall-now", at: cut, title: "That's the cutoff", body: "Decaf from here. Anything stronger would still be in you at bedtime.")
            }
        }
    }

    private func add(_ id: String, at date: Date, title: String, body: String) {
        let c = UNMutableNotificationContent()
        c.title = title; c.body = body; c.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        center.add(UNNotificationRequest(identifier: id, content: c, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
