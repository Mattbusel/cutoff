import SwiftUI

/// Bedtime, your usual, how fast you clear caffeine, and the sleep line.
struct SleepView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro

    var body: some View {
        @Bindable var store = store
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    Caps("Your night", color: Brew.moon)
                    Text("Sleep").font(.serif(32, .bold)).foregroundStyle(Brew.cream)
                }
                .padding(.top, 8)

                BedtimeCard()

                Button { router.sheet = .drinks } label: {
                    HStack(spacing: 12) {
                        CupTop(liquid: store.usual.liquidColor, foam: store.usual.foamColor, size: 44)
                        VStack(alignment: .leading, spacing: 1) {
                            Caps("Your usual")
                            Text("\(store.usual.name) · \(Fmt.mg(store.usual.mg))").font(.ui(16, .bold)).foregroundStyle(Brew.cream)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Brew.faint)
                    }
                    .card(14, radius: 22)
                }
                .buttonStyle(Press())

                Sensitivity()
                SleepLine()

                VStack(spacing: 0) {
                    proToggle("Last-call reminder", "A nudge 20 minutes before your cutoff, and one when it passes.", icon: "bell.fill", isOn: Binding(get: { store.db.profile.notify && pro.unlocked }, set: { v in
                        guard pro.allow(.reminders) else { return }
                        store.db.profile.notify = v; store.save()
                        if v { Task { _ = await Alerts.shared.ask(); Alerts.shared.refresh(store) } }
                    }))
                    Divider().overlay(Brew.line).padding(.leading, 44)
                    proToggle("Countdown on the Lock Screen", "Time left for your usual, live on the Lock Screen and in the Dynamic Island.", icon: "lock.iphone", isOn: Binding(get: { store.db.profile.live && pro.unlocked }, set: { v in
                        guard pro.allow(.live) else { return }
                        store.db.profile.live = v; store.save()
                        if v { LiveCup.start(store) } else { LiveCup.end() }
                    }))
                }
                .card(14, radius: 22)

                ProCard()

                Button { router.sheet = .sources } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "book.closed.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Brew.crema).frame(width: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("How Cutoff works").font(.ui(15.5, .bold)).foregroundStyle(Brew.cream)
                            Text("The model, the numbers and the research behind them").font(.ui(12)).foregroundStyle(Brew.dim)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Brew.faint)
                    }
                    .card(14, radius: 22)
                }
                .buttonStyle(Press())

                Text("Cutoff is a planning tool, not medical advice. Everything stays on this phone: no account, no tracking, no ads.")
                    .font(.ui(11.5)).foregroundStyle(Brew.faint).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18).padding(.bottom, 130)
        }
    }

    func proToggle(_ title: String, _ detail: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon).font(.system(size: 15, weight: .bold)).foregroundStyle(Brew.moon).frame(width: 30).padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title).font(.ui(15.5, .bold)).foregroundStyle(Brew.cream)
                        if !pro.unlocked { ProBadge() }
                    }
                    Text(detail).font(.ui(12)).foregroundStyle(Brew.dim).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Brew.crema).padding(.vertical, 10)
    }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO").font(.caps(9.5)).tracking(1).foregroundStyle(Brew.night).padding(.horizontal, 5).padding(.vertical, 1.5).background(Capsule().fill(Brew.crema))
    }
}

/// Bedtime as a big serif clock with a wheel under it.
struct BedtimeCard: View {
    @Environment(Store.self) private var store
    @State private var open = false
    var body: some View {
        let binding = Binding<Date>(get: { Calendar.current.startOfDay(for: Date()).addingTimeInterval(TimeInterval(store.db.profile.bedtime * 60)) },
                                    set: { d in
                                        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                                        store.db.profile.bedtime = (c.hour ?? 23) * 60 + (c.minute ?? 0)
                                        store.save()
                                    })
        VStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { open.toggle() } } label: {
                HStack(alignment: .center, spacing: 14) {
                    Moon(size: 34)
                    VStack(alignment: .leading, spacing: 0) {
                        Caps("Lights out", color: Brew.moon)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(Fmt.hm(store.bed)).font(.serif(48, .bold)).foregroundStyle(Brew.cream).contentTransition(.numericText())
                            Text(Fmt.ampm(store.bed)).font(.serif(20, .semibold)).foregroundStyle(Brew.moon)
                        }
                    }
                    Spacer()
                    Image(systemName: open ? "chevron.up" : "chevron.down").font(.system(size: 13, weight: .bold)).foregroundStyle(Brew.faint)
                }
            }
            .buttonStyle(.plain)
            if open {
                DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel).labelsHidden().frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .card(18, radius: 26)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(RadialGradient(colors: [Brew.moonDeep.opacity(0.25), .clear], center: .topLeading, startRadius: 5, endRadius: 260)))
    }
}

/// How long caffeine lasts in you: fast, average or slow, with a fine slider (Pro).
struct Sensitivity: View {
    @Environment(Store.self) private var store
    @Environment(Pro.self) private var pro
    static let presets: [(String, Double, String)] = [("Fast", 3, "Clears quickly"), ("Average", 5, "Most adults"), ("Slow", 7, "Lingers")]
    var body: some View {
        let hl = store.db.profile.halfLife
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Caps("How long it lasts in you")
                if !pro.unlocked { ProBadge() }
                Spacer()
                Text("half-life \(String(format: hl.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", hl)) h").font(.ui(12.5, .bold)).foregroundStyle(Brew.crema)
            }
            HStack(spacing: 8) {
                ForEach(Sensitivity.presets, id: \.0) { p in
                    let on = abs(hl - p.1) < 0.01
                    Button {
                        guard pro.allow(.body) else { return }
                        withAnimation(.spring(response: 0.4)) { store.db.profile.halfLife = p.1; store.save() }
                    } label: {
                        VStack(spacing: 6) {
                            DecayGlyph(halfLife: p.1, on: on).frame(height: 30)
                            Text(p.0).font(.ui(14, .bold)).foregroundStyle(on ? Brew.night : Brew.cream)
                            Text(p.2).font(.ui(10.5, .semibold)).foregroundStyle(on ? Brew.night.opacity(0.7) : Brew.faint)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(on ? Brew.crema : Brew.cup2.opacity(0.8)))
                    }
                    .buttonStyle(Press())
                }
            }
            .sensoryFeedback(.selection, trigger: hl)
            if pro.unlocked {
                Slider(value: Binding(get: { hl }, set: { store.db.profile.halfLife = ($0 * 2).rounded() / 2; store.save() }), in: 2...10).tint(Brew.crema)
            }
            Text("Caffeine's half-life varies a lot between people. It runs longer in pregnancy and with some medicines, including oral contraceptives, and shorter in smokers. If coffee at lunch still keeps you up, pick Slow.")
                .font(.ui(11.5)).foregroundStyle(Brew.faint).fixedSize(horizontal: false, vertical: true)
        }
        .card(16, radius: 24)
    }
}

/// A tiny decay curve for each preset.
struct DecayGlyph: View {
    let halfLife: Double
    let on: Bool
    var body: some View {
        Canvas { ctx, s in
            var p = Path()
            for i in 0...40 {
                let t = Double(i) / 40 * 14
                let v = Kinetics.fraction(hours: t, halfLife: halfLife)
                let pt = CGPoint(x: CGFloat(i) / 40 * s.width, y: s.height - CGFloat(v) * s.height * 0.95)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            ctx.stroke(p, with: .color(on ? Brew.night : Brew.crema), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
        }
        .padding(.horizontal, 14)
    }
}

/// The most caffeine you want left when you lie down (Pro).
struct SleepLine: View {
    @Environment(Store.self) private var store
    @Environment(Pro.self) private var pro
    var body: some View {
        let v = store.db.profile.sleepLine
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Caps("Sleep line")
                if !pro.unlocked { ProBadge() }
                Spacer()
                Text("\(Int(v)) mg").font(.serif(22, .bold)).foregroundStyle(Brew.moon).contentTransition(.numericText())
            }
            Slider(value: Binding(get: { v }, set: { n in
                guard pro.allow(.body) else { return }
                store.db.profile.sleepLine = (n / 5).rounded() * 5; store.save()
            }), in: 25...150).tint(Brew.moon)
            Text("How much caffeine you're happy to still be carrying at lights out. Europe's food safety authority found around 100 mg close to bedtime can disturb sleep in some adults, so that's the default. Light sleepers go lower.")
                .font(.ui(11.5)).foregroundStyle(Brew.faint).fixedSize(horizontal: false, vertical: true)
        }
        .card(16, radius: 24)
    }
}

// MARK: - Onboarding

/// Two questions, then the answer. Useful within five seconds.
struct Onboarding: View {
    @Environment(Store.self) private var store
    @State private var step = 0
    @State private var bed = Calendar.current.startOfDay(for: Date()).addingTimeInterval(23 * 3600)
    @State private var usual = "drip"

    var body: some View {
        ZStack {
            Sky(night: step == 0 ? 0.9 : 0.3)
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in Capsule().fill(i <= step ? Brew.crema : Brew.cup2).frame(width: i == step ? 26 : 8, height: 8) }
                }
                .animation(.spring, value: step)
                .padding(.top, 30)
                Group {
                    switch step {
                    case 0: bedStep
                    case 1: usualStep
                    default: reveal
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                Spacer()
                CremaButton(title: step == 2 ? "Start" : "Next", icon: step == 2 ? "cup.and.saucer.fill" : "arrow.right") {
                    if step == 1 { apply() }
                    if step < 2 { withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step += 1 } }
                    else { store.db.profile.setUp = true; store.save() }
                }
            }
            .padding(.horizontal, 22).padding(.bottom, 20)
        }
        .preferredColorScheme(.dark)
    }

    var bedStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Moon(size: 44)
            Text("When do you go to bed?").font(.serif(36, .bold)).foregroundStyle(Brew.cream).fixedSize(horizontal: false, vertical: true)
            Text("Cutoff works backwards from lights out.").font(.ui(15)).foregroundStyle(Brew.dim)
            DatePicker("", selection: $bed, displayedComponents: .hourAndMinute).datePickerStyle(.wheel).labelsHidden().frame(maxWidth: .infinity)
        }
    }

    var usualStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            CupTop(size: 52)
            Text("What's your usual?").font(.serif(36, .bold)).foregroundStyle(Brew.cream)
            Text("The drink you'd reach for this afternoon. You can log anything later.").font(.ui(15)).foregroundStyle(Brew.dim)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(["drip", "espresso", "latte", "coldbrew", "tea", "energy"], id: \.self) { id in
                    let d = store.drink(id), on = usual == id
                    Button { usual = id } label: {
                        HStack(spacing: 10) {
                            CupTop(liquid: d.liquidColor, foam: d.foamColor, size: 36)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(d.name).font(.ui(14.5, .bold)).foregroundStyle(on ? Brew.night : Brew.cream)
                                Text(Fmt.mg(d.mg)).font(.ui(11.5, .semibold)).foregroundStyle(on ? Brew.night.opacity(0.7) : Brew.dim)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(on ? Brew.crema : Brew.cup.opacity(0.9)))
                    }
                    .buttonStyle(Press())
                }
            }
            .sensoryFeedback(.selection, trigger: usual)
        }
    }

    var reveal: some View {
        let cut = store.cutoff()
        return VStack(alignment: .leading, spacing: 12) {
            Caps("Latest \(store.usual.noun) today", color: Brew.crema)
            if let cut, cut > store.now {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Fmt.hm(cut)).font(.serif(88, .bold)).foregroundStyle(Brew.cream)
                    Text(Fmt.ampm(cut)).font(.serif(32, .semibold)).foregroundStyle(Brew.crema)
                }
                Text("After that, a \(store.usual.name.lowercased()) would still be in you at bedtime. Log each drink and the time moves to fit.")
                    .font(.ui(15)).foregroundStyle(Brew.dim).fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Decaf from here").font(.serif(54, .bold)).foregroundStyle(Brew.cream)
                Text("It's already too close to bedtime for a \(store.usual.name.lowercased()). Tomorrow, Cutoff tells you the latest time before you pour.")
                    .font(.ui(15)).foregroundStyle(Brew.dim).fixedSize(horizontal: false, vertical: true)
            }
            CurveChart(height: 200, interactive: false).card(14, radius: 24).padding(.top, 8)
        }
    }

    func apply() {
        let c = Calendar.current.dateComponents([.hour, .minute], from: bed)
        store.db.profile.bedtime = (c.hour ?? 23) * 60 + (c.minute ?? 0)
        store.db.profile.usual = usual
        store.save()
    }
}

// MARK: - Sources

struct SourcesView: View {
    @Environment(\.dismiss) private var dismiss
    struct Ref: Identifiable { let id: Int; let text: String; let url: String; let supports: String }
    static let refs: [Ref] = [
        Ref(id: 1, text: "Drake C, Roehrs T, Shambroom J, Roth T. Caffeine effects on sleep taken 0, 3, or 6 hours before going to bed. J Clin Sleep Med. 2013;9(11):1195–1200.", url: "https://doi.org/10.5664/jcsm.3170",
            supports: "400 mg of caffeine even 6 hours before bed measurably disrupted sleep. Why the cutoff sits hours before bedtime."),
        Ref(id: 2, text: "Nehlig A. Interindividual differences in caffeine metabolism and factors driving caffeine consumption. Pharmacol Rev. 2018;70(2):384–411.", url: "https://doi.org/10.1124/pr.117.014407",
            supports: "Half-life varies widely between people; longer in pregnancy and with oral contraceptives, shorter in smokers. Why you can pick Fast, Average or Slow."),
        Ref(id: 3, text: "EFSA Panel on Dietetic Products, Nutrition and Allergies. Scientific Opinion on the safety of caffeine. EFSA Journal. 2015;13(5):4102.", url: "https://doi.org/10.2903/j.efsa.2015.4102",
            supports: "Caffeine's absorption and elimination in adults, and the effect of evening doses on sleep."),
        Ref(id: 4, text: "Blanchard J, Sawers SJ. The absolute bioavailability of caffeine in man. Eur J Clin Pharmacol. 1983;24(1):93–98.", url: "https://doi.org/10.1007/BF00613933",
            supports: "Caffeine by mouth is almost completely absorbed and peaks in the blood within about an hour. Why the curve rises before it falls."),
        Ref(id: 5, text: "Clark I, Landolt HP. Coffee, caffeine, and sleep: a systematic review of epidemiological studies and randomized controlled trials. Sleep Med Rev. 2017;31:70–78.", url: "https://doi.org/10.1016/j.smrv.2016.01.006",
            supports: "Caffeine lengthens the time to fall asleep and reduces deep sleep; sensitivity differs between people."),
        Ref(id: 6, text: "U.S. Food and Drug Administration. Spilling the Beans: How Much Caffeine is Too Much?", url: "https://www.fda.gov/consumers/consumer-updates/spilling-beans-how-much-caffeine-too-much",
            supports: "400 mg a day is an amount not generally associated with negative effects for healthy adults. The daily bar on Today."),
        Ref(id: 7, text: "U.S. Department of Agriculture. FoodData Central.", url: "https://fdc.nal.usda.gov/",
            supports: "Typical caffeine in brewed coffee, espresso, black and green tea and cola. Energy drink values are from can labels."),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("How Cutoff works").font(.serif(30, .bold)).foregroundStyle(Brew.cream)
                    Spacer()
                    RoundKnob(icon: "xmark", size: 36) { dismiss() }
                }
                .padding(.top, 24)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Each drink is modelled on its own: caffeine is absorbed over roughly the first hour [4], then cleared at your half-life, 5 hours unless you change it [2, 3]. Cutoff adds every drink from the last two days together to draw the curve.")
                    Text("Your cutoff is the latest minute your usual drink could be had so that, added to what's already in you, the total stays under your sleep line from bedtime through the next three hours [1, 5]. The sleep line is 100 mg unless you change it.")
                    Text("It's a planning tool built on population averages, not medical advice. If you're pregnant, take medication, or have a heart, liver or sleep condition, ask your doctor what's right for you.")
                        .foregroundStyle(Brew.moon)
                }
                .font(.ui(14.5)).foregroundStyle(Brew.cream.opacity(0.9)).fixedSize(horizontal: false, vertical: true)
                .card(16, radius: 22)
                Caps("Sources")
                ForEach(SourcesView.refs) { r in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(r.id)").font(.serif(15, .bold)).foregroundStyle(Brew.night).frame(width: 24, height: 24).background(Circle().fill(Brew.crema))
                            Text(r.text).font(.ui(13.5, .semibold)).foregroundStyle(Brew.cream).fixedSize(horizontal: false, vertical: true)
                        }
                        Text(r.supports).font(.ui(12.5)).foregroundStyle(Brew.dim).fixedSize(horizontal: false, vertical: true).padding(.leading, 34)
                        if let u = URL(string: r.url) {
                            Link(destination: u) {
                                Label(r.url.replacingOccurrences(of: "https://", with: ""), systemImage: "arrow.up.right.square").font(.ui(12, .bold)).foregroundStyle(Brew.crema).lineLimit(1)
                            }
                            .padding(.leading, 34)
                        }
                    }
                    .card(14, radius: 20)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 40)
        }
    }
}
