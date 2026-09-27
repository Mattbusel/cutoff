import SwiftUI

/// The last seven nights: how much, how late, and whether you went to bed under the line (Pro).
struct WeekView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro

    var body: some View {
        let days = store.days(7)
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 0) {
                    Caps("Last 7 nights", color: Brew.crema)
                    Text("Your week").font(.serif(32, .bold)).foregroundStyle(Brew.cream)
                }
                .padding(.top, 8)
                ZStack {
                    VStack(alignment: .leading, spacing: 18) {
                        summary(days)
                        WeekBars(days: days.reversed(), line: store.db.profile.sleepLine).frame(height: 230).card(16, radius: 28)
                        ForEach(days.filter { !$0.sips.isEmpty }) { d in DayRow(day: d) }
                        if days.allSatisfy({ $0.sips.isEmpty }) {
                            Text("Nothing logged this week yet. Every cup you log shows up here, night by night.")
                                .font(.ui(13.5)).foregroundStyle(Brew.dim).card(16, radius: 20)
                        }
                    }
                    .blur(radius: pro.unlocked ? 0 : 10)
                    .allowsHitTesting(pro.unlocked)
                    if !pro.unlocked { locked }
                }
            }
            .padding(.horizontal, 18).padding(.bottom, 130)
        }
    }

    func summary(_ days: [Store.Day]) -> some View {
        let logged = days.filter { !$0.sips.isEmpty }
        let avg = logged.isEmpty ? 0 : logged.reduce(0) { $0 + $1.total } / Double(logged.count)
        let under = days.filter { $0.atBed <= store.db.profile.sleepLine }.count
        let lasts = logged.compactMap(\.last).map { Calendar.current.dateComponents([.hour, .minute], from: $0) }.map { Double(($0.hour ?? 0) * 60 + ($0.minute ?? 0)) }
        let avgLast = lasts.isEmpty ? nil : Int(lasts.reduce(0, +) / Double(lasts.count))
        return HStack(spacing: 10) {
            stat("\(Int(avg.rounded()))", "mg a day", Brew.crema)
            stat("\(under)/7", "nights under the line", Brew.moon)
            stat(avgLast.map { Fmt.mins($0).replacingOccurrences(of: " ", with: "\u{00a0}") } ?? "–", "usual last cup", Brew.cream)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    func stat(_ v: String, _ l: String, _ c: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(v).font(.serif(24, .bold)).foregroundStyle(c).lineLimit(1).minimumScaleFactor(0.55)
            Text(l).font(.ui(11, .semibold)).foregroundStyle(Brew.dim).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .card(14, radius: 20)
    }

    var locked: some View {
        VStack(spacing: 12) {
            Moon(size: 34)
            Text("Your week is waiting").font(.serif(26, .bold)).foregroundStyle(Brew.cream)
            Text("Every cup you log is kept. Cutoff Pro shows your nights side by side: how much, how late, and which nights you went to bed under the line.")
                .font(.ui(13.5)).foregroundStyle(Brew.dim).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            CremaButton(title: "See Cutoff Pro", icon: "sparkles") { pro.paywall = .week }.frame(width: 240)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Brew.night2.opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Brew.line))
        .padding(.top, 40)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// Seven nights as bars of caffeine, with a moon above each showing what was left at bedtime.
struct WeekBars: View {
    let days: [Store.Day]
    let line: Double
    var body: some View {
        let top = max(420, days.map(\.total).max() ?? 0)
        GeometryReader { g in
            let W = g.size.width, H = g.size.height - 44
            let bw = W / CGFloat(max(1, days.count))
            ZStack(alignment: .topLeading) {
                // 400 mg guide.
                let gy = H - CGFloat(400 / top) * H
                Path { p in p.move(to: CGPoint(x: 0, y: gy)); p.addLine(to: CGPoint(x: W, y: gy)) }
                    .stroke(Brew.hot.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                Text("400 mg").font(.ui(9.5, .bold)).foregroundStyle(Brew.hot.opacity(0.8)).position(x: W - 22, y: gy - 8)
                ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                    let h = max(4, CGFloat(d.total / top) * H)
                    let cx = bw * (CGFloat(i) + 0.5)
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LinearGradient(colors: [Brew.crema, Brew.roast], startPoint: .top, endPoint: .bottom))
                                .frame(width: bw * 0.52, height: h)
                            // Each cup, a stripe.
                            VStack(spacing: 0) {
                                ForEach(d.sips.reversed()) { s in
                                    Rectangle().fill(Brew.night.opacity(0.35)).frame(width: bw * 0.52, height: 1.5)
                                        .padding(.bottom, max(0, CGFloat(s.mg / top) * H - 1.5))
                                }
                            }
                            .frame(height: h, alignment: .bottom).clipped()
                        }
                        .frame(height: h)
                    }
                    .frame(width: bw, height: H)
                    .position(x: cx, y: H / 2)
                    Moon(size: 12, color: d.atBed <= line ? Brew.moon : Brew.hot)
                        .position(x: cx, y: max(10, H - h - 14))
                    VStack(spacing: 1) {
                        Text(Self.wd(d.bed)).font(.ui(11, .bold)).foregroundStyle(i == days.count - 1 ? Brew.crema : Brew.dim)
                        Text("\(Int(d.total.rounded()))").font(.ui(10, .semibold)).foregroundStyle(Brew.faint)
                    }
                    .position(x: cx, y: H + 22)
                }
            }
        }
    }
    static func wd(_ d: Date) -> String {
        // Name a night by the day it started.
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: d.addingTimeInterval(-6 * 3600))
    }
}

struct DayRow: View {
    @Environment(Store.self) private var store
    let day: Store.Day
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Fmt.day(day.bed.addingTimeInterval(-6 * 3600))).font(.ui(15, .bold)).foregroundStyle(Brew.cream)
                HStack(spacing: -8) {
                    ForEach(day.sips.prefix(8)) { s in
                        let d = store.drink(s.drink)
                        CupTop(liquid: d.liquidColor, foam: d.foamColor, size: 28, swirl: false)
                    }
                }
                if let last = day.last { Text("\(day.sips.count) \(day.sips.count == 1 ? "drink" : "drinks") · last at \(Fmt.time(last))").font(.ui(12)).foregroundStyle(Brew.dim) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Fmt.mg(day.total)).font(.serif(20, .bold)).foregroundStyle(Brew.crema)
                HStack(spacing: 4) {
                    Moon(size: 9, color: day.atBed <= store.db.profile.sleepLine ? Brew.moon : Brew.hot)
                    Text("\(Int(day.atBed.rounded())) at bed").font(.ui(11.5, .semibold)).foregroundStyle(day.atBed <= store.db.profile.sleepLine ? Brew.moon : Brew.hot)
                }
            }
        }
        .card(14, radius: 22)
    }
}
