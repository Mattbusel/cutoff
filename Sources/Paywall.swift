import SwiftUI

/// A coffee shop loyalty card, stamping itself full.
struct PaywallView: View {
    @Environment(Pro.self) private var pro
    @Environment(\.dismiss) private var dismiss
    let reason: Pro.Reason
    @State private var stamped = 0

    var body: some View {
        ZStack {
            Sky(night: 0.7)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Caps("Cutoff Pro", color: Brew.crema)
                        Spacer()
                        RoundKnob(icon: "xmark", size: 36) { dismiss() }.accessibilityLabel("Close")
                    }
                    card
                    VStack(alignment: .leading, spacing: 8) {
                        Text(headline).font(.serif(34, .bold)).foregroundStyle(Brew.cream).fixedSize(horizontal: false, vertical: true)
                        Text("Today's cutoff, the curve and logging any drink stay free. Pro tunes it to your body and your order.")
                            .font(.ui(14.5)).foregroundStyle(Brew.dim).fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        feature("figure.stand", Brew.crema, "Your body, not the average", "Set how long caffeine lasts in you and how much you can sleep with.")
                        feature("cup.and.saucer.fill", Brew.cremaDeep, "Your own drinks", "Your actual cafe order, with its real milligrams.")
                        feature("chart.bar.fill", Brew.ok, "Your week", "Seven nights side by side: how much, how late, and which nights you slept under the line.")
                        feature("bell.badge.fill", Brew.moon, "Last call", "A nudge 20 minutes before your cutoff.")
                        feature("lock.iphone", Brew.cream, "Countdown on the Lock Screen", "Time left for your usual, live on the Lock Screen and in the Dynamic Island.")
                    }
                    .card(18, radius: 26)
                    VStack(spacing: 4) {
                        Text(pro.price).font(.serif(46, .bold)).foregroundStyle(Brew.cream)
                        Text("once · no subscription · Family Sharing").font(.ui(12.5, .bold)).foregroundStyle(Brew.dim)
                    }
                    .frame(maxWidth: .infinity)
                    if let m = pro.message {
                        Text(m).font(.ui(13, .semibold)).foregroundStyle(Brew.hot).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    }
                    CremaButton(title: pro.busy ? "One moment" : "Unlock Pro for \(pro.price)", icon: "lock.open.fill") { Task { await pro.buy() } }
                        .disabled(pro.busy)
                    HStack(spacing: 10) {
                        GhostButton(title: "Restore purchase", icon: "arrow.clockwise") { Task { await pro.restore() } }
                        GhostButton(title: "Not now") { dismiss() }
                    }
                    Text("Everything you log is kept, Pro or not.").font(.ui(11.5)).foregroundStyle(Brew.faint)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 40)
            }
        }
        .task {
            for i in 1...8 {
                try? await Task.sleep(for: .milliseconds(140))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { stamped = i }
            }
        }
        .onChange(of: pro.unlocked) { _, now in if now { dismiss() } }
    }

    var headline: String {
        switch reason {
        case .drinks: return "Your order, your number."
        case .week: return "See your whole week."
        case .body: return "Tuned to how you process coffee."
        case .reminders: return "A nudge before last call."
        case .live: return "Watch the window close."
        case .settings: return "Sleep on your own terms."
        }
    }

    /// A kraft loyalty card with eight stamps; the last one is a good night.
    var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("CUTOFF").font(.serif(22, .bold)).tracking(4)
                Spacer()
                Text("PRO CARD").font(.caps(11)).tracking(2).opacity(0.7)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 12) {
                ForEach(0..<8) { i in stamp(i) }
            }
            Text("Every cup counted. The last one's on us: a good night.").font(.ui(12, .semibold)).opacity(0.75)
        }
        .foregroundStyle(Color(hex: 0x3A2616))
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xE3C9A2), Color(hex: 0xCFAE80)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.45), radius: 22, y: 12)
        )
        .rotationEffect(.degrees(-2))
        .padding(.vertical, 8)
    }

    func stamp(_ i: Int) -> some View {
        ZStack {
            Circle().strokeBorder(Color(hex: 0x6B4A2E).opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
            if i < stamped {
                Image(systemName: i == 7 ? "moon.stars.fill" : "cup.and.saucer.fill")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(i == 7 ? Brew.moonDeep : Color(hex: 0x8A3A22).opacity(0.85))
                    .rotationEffect(.degrees(Double((i * 37) % 30) - 15))
                    .transition(.scale(scale: 2).combined(with: .opacity))
            }
        }
        .frame(height: 52)
    }

    func feature(_ icon: String, _ tint: Color, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.system(size: 15, weight: .bold)).foregroundStyle(tint)
                .frame(width: 40, height: 40).background(Circle().fill(tint.opacity(0.14)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ui(15.5, .bold)).foregroundStyle(Brew.cream)
                Text(detail).font(.ui(12.5)).foregroundStyle(Brew.dim).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ProCard: View {
    @Environment(Pro.self) private var pro
    var body: some View {
        if pro.unlocked {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Brew.ok)
                Text("Cutoff Pro is unlocked. Thank you.").font(.ui(14.5, .bold)).foregroundStyle(Brew.cream)
                Spacer()
            }
            .card(14, radius: 20)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    CupTop(size: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cutoff Pro").font(.serif(20, .bold)).foregroundStyle(Brew.cream)
                        Text("Your half-life and sleep line, your own drinks, the week, last call and the Lock Screen countdown. \(pro.price) once.")
                            .font(.ui(12.5)).foregroundStyle(Brew.dim).fixedSize(horizontal: false, vertical: true)
                    }
                }
                HStack(spacing: 10) {
                    GhostButton(title: "See Pro", icon: "sparkles", tint: Brew.crema) { pro.paywall = .settings }
                    GhostButton(title: "Restore", icon: "arrow.clockwise") { Task { await pro.restore() } }
                }
                if let m = pro.message, pro.paywall == nil { Text(m).font(.ui(12, .semibold)).foregroundStyle(Brew.hot) }
            }
            .card(16, radius: 24)
        }
    }
}
