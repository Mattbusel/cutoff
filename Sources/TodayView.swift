import SwiftUI

/// The whole point, in five seconds: the latest time you can have your usual and still sleep.
struct TodayView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro

    var body: some View {
        ScrollView(showsIndicators: false) {
            TimelineView(.periodic(from: .now, by: 30)) { _ in
                VStack(alignment: .leading, spacing: 18) {
                    header
                    Verdict()
                    VStack(alignment: .leading, spacing: 14) {
                        CurveChart()
                        levels
                    }
                    .card(16, radius: 28)
                    quickLog
                    drinksToday
                    dailyTotal
                    Button { router.sheet = .sources } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "book.closed.fill").font(.system(size: 11, weight: .bold))
                            Text("How Cutoff works, and its sources. Not medical advice.").font(.ui(12, .semibold))
                        }
                        .foregroundStyle(Brew.faint)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 130)
            }
        }
    }

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Caps(weekday, color: Brew.crema)
                Text("Cutoff").font(.serif(32, .bold)).foregroundStyle(Brew.cream)
            }
            Spacer()
            Button { withAnimation { router.tab = .you } } label: {
                HStack(spacing: 7) {
                    Moon(size: 14)
                    Text("Bed \(Fmt.time(store.bed))").font(.ui(13.5, .bold)).foregroundStyle(Brew.moon)
                }
                .padding(.horizontal, 12).frame(height: 34)
                .background(Capsule().fill(Brew.moonDeep.opacity(0.18)))
                .overlay(Capsule().strokeBorder(Brew.moon.opacity(0.25)))
            }
            .buttonStyle(Press())
        }
    }

    var weekday: String { let f = DateFormatter(); f.dateFormat = "EEEE"; return f.string(from: store.now) }

    var levels: some View {
        let now = store.level(at: store.now), bed = store.level(at: store.bed), line = store.db.profile.sleepLine
        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Caps("In you now")
                Text(Fmt.mg(now)).font(.serif(26, .bold)).foregroundStyle(Brew.cream).contentTransition(.numericText())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 5) { Moon(size: 10); Caps("At bedtime", color: Brew.moon) }
                HStack(spacing: 6) {
                    Image(systemName: bed <= line ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(bed <= line ? Brew.ok : Brew.hot)
                    Text(Fmt.mg(bed)).font(.serif(26, .bold)).foregroundStyle(bed <= line ? Brew.moon : Brew.hot)
                }
            }
        }
    }

    var quickLog: some View {
        let u = store.usual
        return HStack(spacing: 10) {
            Button { withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { store.log(u) } } label: {
                HStack(spacing: 12) {
                    CupTop(liquid: u.liquidColor, foam: u.foamColor, size: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Had my \(u.name.lowercased())").font(.ui(16, .bold)).foregroundStyle(Color(hex: 0x2A160B))
                        Text("\(Fmt.mg(u.mg)) · just now").font(.ui(12, .semibold)).foregroundStyle(Color(hex: 0x2A160B).opacity(0.65))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14).frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xF3C996), Brew.crema, Brew.cremaDeep], startPoint: .top, endPoint: .bottom))
                        .shadow(color: Brew.crema.opacity(0.3), radius: 16, y: 8)
                )
            }
            .buttonStyle(Press())
            .sensoryFeedback(.success, trigger: store.db.sips.count)
            Button { router.sheet = .add } label: {
                VStack(spacing: 3) {
                    Image(systemName: "square.grid.2x2.fill").font(.system(size: 17, weight: .bold))
                    Text("Other").font(.ui(12, .bold))
                }
                .foregroundStyle(Brew.cream)
                .frame(width: 72, height: 64)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Brew.cup2.opacity(0.9)))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Brew.line))
            }
            .buttonStyle(Press())
        }
    }

    @ViewBuilder var drinksToday: some View {
        let list = store.today
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Caps("Today's cups")
                Spacer()
                if !list.isEmpty { Text("\(list.count)").font(.ui(12, .bold)).foregroundStyle(Brew.faint) }
            }
            if list.isEmpty {
                HStack(spacing: 12) {
                    CupTop(liquid: Brew.cup2, foam: Brew.cup2, size: 36, swirl: false).opacity(0.6)
                    Text("Nothing yet today. Tap the cup when you have one, and the cutoff moves to fit.").font(.ui(13.5)).foregroundStyle(Brew.dim)
                }
                .card(14, radius: 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(list.reversed().enumerated()), id: \.element.id) { i, s in
                        if i > 0 { Divider().overlay(Brew.line).padding(.leading, 62) }
                        SipRow(sip: s)
                    }
                }
                .card(6, radius: 22)
            }
        }
    }

    var dailyTotal: some View {
        let total = store.todayMg
        let frac = min(1, total / 400)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Caps("Today's total")
                Spacer()
                Text("\(Int(total.rounded())) of 400 mg").font(.ui(13, .bold)).foregroundStyle(total > 400 ? Brew.hot : Brew.cream)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brew.cup2)
                    Capsule().fill(LinearGradient(colors: [Brew.crema, total > 400 ? Brew.hot : Brew.cremaDeep], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, g.size.width * frac))
                }
            }
            .frame(height: 10)
            Text("400 mg a day is the amount the FDA says is not generally linked to negative effects for healthy adults.")
                .font(.ui(11.5)).foregroundStyle(Brew.faint).fixedSize(horizontal: false, vertical: true)
        }
        .card(16, radius: 22)
    }
}

/// The headline: latest coffee at 2:50 PM, and how long until then.
struct Verdict: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router

    var body: some View {
        let u = store.usual
        let now = store.now
        let cut = store.cutoff()
        VStack(alignment: .leading, spacing: 10) {
            Caps("Latest \(u.noun)", color: Brew.crema)
            if let cut, cut > now.addingTimeInterval(-6 * 3600) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Fmt.hm(cut)).font(.serif(84, .bold)).foregroundStyle(cut > now ? Brew.cream : Brew.dim)
                        .contentTransition(.numericText()).minimumScaleFactor(0.6).lineLimit(1)
                    Text(Fmt.ampm(cut)).font(.serif(30, .semibold)).foregroundStyle(Brew.crema)
                }
                if cut > now {
                    pill(icon: "hourglass", text: "\(Fmt.span(cut.timeIntervalSince(now))) left for a \(u.name.lowercased())", tint: Brew.crema)
                } else {
                    pill(icon: "moon.zzz.fill", text: "That was \(Fmt.span(now.timeIntervalSince(cut))) ago. Decaf from here.", tint: Brew.moon)
                }
            } else {
                Text("Done for today").font(.serif(54, .bold)).foregroundStyle(Brew.cream).minimumScaleFactor(0.6).lineLimit(1)
                if let clear = store.clearTime() {
                    pill(icon: "moon.zzz.fill", text: "Another \(u.name.lowercased()) would still be in you at bedtime. You're under your sleep line from \(Fmt.time(clear)).", tint: Brew.hot)
                } else {
                    pill(icon: "moon.zzz.fill", text: "Another \(u.name.lowercased()) would still be in you at bedtime.", tint: Brew.hot)
                }
            }
            if store.usual.mg > 0 {
                Button { router.sheet = .add } label: {
                    Text("For a smaller drink the cutoff is later. Tap a drink to see its time.")
                        .font(.ui(12, .medium)).foregroundStyle(Brew.faint).multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    func pill(icon: String, text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.system(size: 13, weight: .bold)).padding(.top, 1)
            Text(text).font(.ui(14, .semibold)).fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Capsule(style: .continuous).fill(tint.opacity(0.12)))
        .overlay(Capsule(style: .continuous).strokeBorder(tint.opacity(0.22)))
    }
}

struct SipRow: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    let sip: Sip
    var body: some View {
        let d = store.drink(sip.drink)
        let left = sip.mg * Kinetics.fraction(hours: store.bed.timeIntervalSince(sip.at) / 3600, halfLife: store.db.profile.halfLife)
        Button { router.sheet = .sip(sip) } label: {
            HStack(spacing: 12) {
                CupTop(liquid: d.liquidColor, foam: d.foamColor, size: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text(sip.name).font(.ui(15.5, .bold)).foregroundStyle(Brew.cream)
                    Text("\(Fmt.time(sip.at)) · \(Fmt.mg(sip.mg))").font(.ui(12.5, .medium)).foregroundStyle(Brew.dim)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(left.rounded())) mg").font(.serif(16, .bold)).foregroundStyle(Brew.moon)
                    Text("at bedtime").font(.ui(10.5, .semibold)).foregroundStyle(Brew.faint)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { router.sheet = .sip(sip) } label: { Label("Change time", systemImage: "clock") }
            Button(role: .destructive) { withAnimation { store.remove(sip) } } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
