import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MainActor.assumeIsolated { Alerts.shared.setUp() }
        return true
    }
}

@main
struct CutoffApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var store: Store
    @State private var router = Router()
    @State private var pro: Pro
    @Environment(\.scenePhase) private var phase

    init() {
        let a = ProcessInfo.processInfo.arguments
        let demo = a.contains("-shot") || a.contains("-demoAutoplay")
        _store = State(initialValue: Store(demo: demo))
        let shot = a.firstIndex(of: "-shot").flatMap { $0 + 1 < a.count ? a[$0 + 1] : nil }
        let p: Pro
        if shot == "paywall" { p = Pro(forced: false); p.paywall = .settings }
        else if demo { p = Pro(forced: true) }
        else { p = Pro() }
        _pro = State(initialValue: p)
        if demo { Alerts.shared.demo = true }
    }

    var body: some Scene {
        WindowGroup {
            RootView().environment(store).environment(router).environment(pro)
                .preferredColorScheme(.dark).tint(Brew.crema)
                .onAppear {
                    Alerts.shared.pro = pro
                    router.applyShotArgs(store)
                    Autopilot.shared.run(store, router, pro)
                }
        }
        .onChange(of: phase) { _, p in
            if p == .active { Alerts.shared.refresh(store) }
        }
    }
}

enum Tab: String, CaseIterable, Identifiable {
    case today, week, you
    var id: String { rawValue }
    var title: String { self == .you ? "Sleep" : rawValue.capitalized }
    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .week: return "chart.bar.fill"
        case .you: return "moon.zzz.fill"
        }
    }
}

enum Sheet: Identifiable {
    case add, sip(Sip), drinks, drink(Drink), sources
    var id: String {
        switch self {
        case .add: return "add"
        case .sip(let s): return "sip-\(s.id)"
        case .drinks: return "drinks"
        case .drink(let d): return "drink-\(d.id)"
        case .sources: return "sources"
        }
    }
}

@MainActor
@Observable
final class Router {
    var tab: Tab = .today
    var sheet: Sheet? = nil
    /// A time the curve is being read at, when a finger is on it.
    var scrub: Date? = nil

    func applyShotArgs(_ s: Store) {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-shot"), i + 1 < a.count else { return }
        switch a[i + 1] {
        case "curve": scrub = Calendar.current.startOfDay(for: s.now).addingTimeInterval(19 * 3600 + 30 * 60)
        case "add": sheet = .add
        case "week": tab = .week
        case "drinks": sheet = .drinks
        case "sleep": tab = .you
        default: break
        }
    }
}

struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro

    var body: some View {
        @Bindable var router = router
        @Bindable var pro = pro
        ZStack(alignment: .bottom) {
            TimelineView(.periodic(from: .now, by: 60)) { _ in Sky(night: nightness) }
            Group {
                switch router.tab {
                case .today: TodayView()
                case .week: WeekView()
                case .you: SleepView()
                }
            }
            .transition(.opacity)
            Saucer(selection: $router.tab) { router.sheet = .add }
        }
        .sheet(item: $router.sheet) { sheet in
            Group {
                switch sheet {
                case .add: AddSheet()
                case .sip(let s): SipEditor(sip: s).presentationDetents([.height(520)])
                case .drinks: DrinksView()
                case .drink(let d): DrinkEditor(drink: d)
                case .sources: SourcesView()
                }
            }
            .presentationBackground(Brew.night2).presentationCornerRadius(34)
            .environment(store).environment(router).environment(pro)
        }
        .overlay {
            Color.clear.allowsHitTesting(false)
                .sheet(item: $pro.paywall) { why in
                    PaywallView(reason: why).environment(pro).presentationBackground(Brew.night2).presentationCornerRadius(34)
                }
        }
        .fullScreenCover(isPresented: Binding(get: { !store.db.profile.setUp && !store.demo }, set: { _ in })) {
            Onboarding().environment(store)
        }
    }

    /// 0 in the morning, 1 at bedtime.
    var nightness: Double {
        let b = store.bed, s = store.dayStart(for: b)
        return max(0, min(1, store.now.timeIntervalSince(s.addingTimeInterval(3 * 3600)) / b.timeIntervalSince(s.addingTimeInterval(3 * 3600))))
    }
}

/// The tab bar is a saucer, and the add button is the cup sitting on it.
struct Saucer: View {
    @Binding var selection: Tab
    var add: () -> Void
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases) { item($0) }
            }
            .padding(5)
            .background {
                Capsule().fill(Brew.cup)
                    .overlay(Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.14), .white.opacity(0.02)], startPoint: .top, endPoint: .bottom)))
                    .shadow(color: .black.opacity(0.5), radius: 22, y: 10)
            }
            // The cup on its saucer.
            Button(action: add) {
                ZStack {
                    Circle().fill(Brew.cup)
                        .overlay(Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.16), .white.opacity(0.02)], startPoint: .top, endPoint: .bottom)))
                        .overlay(Circle().strokeBorder(Brew.line).padding(6))
                        .shadow(color: .black.opacity(0.5), radius: 22, y: 10)
                    CupTop(size: 44).offset(x: -3)
                        .overlay {
                            Image(systemName: "plus").font(.system(size: 14, weight: .black)).foregroundStyle(.white.opacity(0.95)).offset(x: -3)
                        }
                }
                .frame(width: 66, height: 66)
            }
            .buttonStyle(Press())
            .accessibilityLabel("Log a drink")
        }
        .padding(.horizontal, 16).padding(.bottom, 2)
    }

    func item(_ t: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) { selection = t }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: t.icon).font(.system(size: 17, weight: .semibold))
                Text(t.title).font(.ui(11, .semibold))
            }
            .foregroundStyle(selection == t ? Brew.crema : Brew.faint)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background {
                if selection == t {
                    Capsule().fill(Brew.crema.opacity(0.12)).padding(.horizontal, 6).matchedGeometryEffect(id: "sel", in: ns)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selection)
    }
}
