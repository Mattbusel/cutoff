import SwiftUI

/// Drives the real screens for the App Review recording (-demoAutoplay).
@MainActor
final class Autopilot {
    static let shared = Autopilot()
    static var on: Bool { ProcessInfo.processInfo.arguments.contains("-demoAutoplay") }
    private var running = false
    private func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }

    func run(_ store: Store, _ router: Router, _ pro: Pro) {
        guard Autopilot.on, !running else { return }
        running = true
        Task { @MainActor in
            await wait(4)
            // Read the curve across the evening.
            let start = Calendar.current.startOfDay(for: store.now)
            for h in stride(from: 14.0, through: 23.5, by: 0.5) {
                router.scrub = start.addingTimeInterval(h * 3600); await wait(0.25)
            }
            await wait(1.5)
            router.scrub = nil; await wait(1)
            router.sheet = .add; await wait(4)
            router.sheet = nil; await wait(1.2)
            withAnimation { router.tab = .week }; await wait(4)
            withAnimation { router.tab = .you }; await wait(4)
            router.sheet = .sources; await wait(4)
            router.sheet = nil; await wait(1.2)
            router.sheet = .drinks; await wait(3)
            router.sheet = nil; await wait(1.2)
            withAnimation { router.tab = .today }; await wait(1.5)
            pro.paywall = .settings; await wait(5)
            pro.paywall = nil; await wait(1.5)
            try? Data("ok".utf8).write(to: URL.documentsDirectory.appending(path: "demo_done"))
        }
    }
}
