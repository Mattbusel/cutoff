import SwiftUI

/// Log a drink: every drink shows its own cutoff, so a tea at 4 PM can be fine when a cold brew isn't.
struct AddSheet: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro
    @Environment(\.dismiss) private var dismiss
    @State private var when = Date()
    @State private var earlier = false
    @State private var logged: String? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("What are you having?").font(.serif(28, .bold)).foregroundStyle(Brew.cream)
                    Spacer()
                    RoundKnob(icon: "xmark", size: 36) { dismiss() }
                }
                .padding(.top, 24)
                timeRow
                if !store.db.custom.isEmpty || pro.unlocked {
                    HStack {
                        Caps("Your drinks")
                        Spacer()
                        Button { router.sheet = .drinks } label: { Text("Edit").font(.ui(13, .bold)).foregroundStyle(Brew.crema) }.buttonStyle(.plain)
                    }
                    grid(store.db.custom, allowNew: true)
                }
                Caps("Menu")
                grid(Drink.menu, allowNew: store.db.custom.isEmpty && !pro.unlocked)
                Text("Caffeine per serving varies by bean, brew and shop. These are typical values from USDA FoodData Central and drink labels. With Pro, add your own order with its real number.")
                    .font(.ui(11.5)).foregroundStyle(Brew.faint).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20).padding(.bottom, 40)
        }
        .onAppear { when = store.now }
    }

    var timeRow: some View {
        HStack(spacing: 8) {
            chip("Just now", on: !earlier) { earlier = false; when = store.now }
            chip("Earlier", on: earlier) { earlier = true }
            if earlier {
                DatePicker("", selection: $when, in: store.now.addingTimeInterval(-20 * 3600)...store.now, displayedComponents: [.hourAndMinute])
                    .labelsHidden().transition(.opacity.combined(with: .scale))
            }
            Spacer()
        }
        .animation(.spring(response: 0.3), value: earlier)
    }

    func chip(_ t: String, on: Bool, _ go: @escaping () -> Void) -> some View {
        Button(action: go) {
            Text(t).font(.ui(14, .bold)).foregroundStyle(on ? Brew.night : Brew.cream)
                .padding(.horizontal, 14).frame(height: 36)
                .background(Capsule().fill(on ? Brew.crema : Brew.cup2))
        }
        .buttonStyle(Press())
    }

    func grid(_ list: [Drink], allowNew: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(list) { d in tile(d) }
            if allowNew {
                Button {
                    guard pro.allow(.drinks) else { return }
                    router.sheet = .drink(Drink(id: UUID().uuidString, name: "", size: "", mg: 100, custom: true))
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "plus").font(.system(size: 20, weight: .bold)).foregroundStyle(Brew.crema)
                        Text("Your own drink").font(.ui(14, .bold)).foregroundStyle(Brew.cream)
                        Text("Any caffeine amount").font(.ui(11.5)).foregroundStyle(Brew.faint)
                    }
                    .frame(maxWidth: .infinity).frame(height: 168)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Brew.crema.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
                }
                .buttonStyle(Press())
            }
        }
    }

    func tile(_ d: Drink) -> some View {
        let cut = store.cutoff(for: d)
        let now = store.now
        let isUsual = store.db.profile.usual == d.id
        return Button {
            store.log(d, at: earlier ? when : nil)
            logged = d.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { dismiss() }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    CupTop(liquid: d.liquidColor, foam: d.foamColor, size: 46)
                        .scaleEffect(logged == d.id ? 1.2 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: logged)
                    Spacer()
                    if isUsual { Text("USUAL").font(.caps(9.5)).tracking(1).foregroundStyle(Brew.night).padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(Brew.crema)) }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(d.name.isEmpty ? "Drink" : d.name).font(.ui(15.5, .bold)).foregroundStyle(Brew.cream).lineLimit(1)
                    Text(d.size.isEmpty ? Fmt.mg(d.mg) : "\(d.size) · \(Fmt.mg(d.mg))").font(.ui(11.5, .medium)).foregroundStyle(Brew.dim).lineLimit(1)
                }
                Spacer(minLength: 0)
                HStack(spacing: 5) {
                    if let cut, cut > now {
                        Image(systemName: "clock").font(.system(size: 10.5, weight: .bold))
                        Text("OK until \(Fmt.time(cut))").font(.ui(11.5, .bold))
                    } else if d.mg < 10 {
                        Image(systemName: "checkmark").font(.system(size: 10.5, weight: .bold))
                        Text("Fine any time").font(.ui(11.5, .bold))
                    } else {
                        Image(systemName: "moon.zzz.fill").font(.system(size: 10.5, weight: .bold))
                        Text("Too late tonight").font(.ui(11.5, .bold))
                    }
                }
                .foregroundStyle(cut.map { $0 > now } == true || d.mg < 10 ? Brew.ok : Brew.hot)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading).frame(height: 168)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Brew.cup.opacity(0.9)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(isUsual ? Brew.crema.opacity(0.5) : Brew.line))
        }
        .buttonStyle(Press())
        .sensoryFeedback(.success, trigger: logged)
        .contextMenu {
            Button { store.db.profile.usual = d.id; store.save() } label: { Label("Make it my usual", systemImage: "star") }
            if d.custom { Button { router.sheet = .drink(d) } label: { Label("Edit", systemImage: "pencil") } }
        }
    }
}

/// Fix the time or amount of a drink already logged.
struct SipEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var sip: Sip
    var body: some View {
        let d = store.drink(sip.drink)
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                CupTop(liquid: d.liquidColor, foam: d.foamColor, size: 48)
                Text(sip.name).font(.serif(26, .bold)).foregroundStyle(Brew.cream)
                Spacer()
                RoundKnob(icon: "xmark", size: 36) { dismiss() }
            }
            .padding(.top, 24)
            HStack {
                Caps("Had it at")
                Spacer()
                DatePicker("", selection: $sip.at, in: ...store.now.addingTimeInterval(60), displayedComponents: [.date, .hourAndMinute]).labelsHidden()
            }
            .card(14, radius: 18)
            HStack {
                Caps("Caffeine")
                Spacer()
                Button { sip.mg = max(0, sip.mg - 5) } label: { Image(systemName: "minus.circle.fill").font(.system(size: 26)).foregroundStyle(Brew.cup2) }.buttonStyle(.plain)
                Text(Fmt.mg(sip.mg)).font(.serif(24, .bold)).foregroundStyle(Brew.cream).frame(width: 100).contentTransition(.numericText())
                Button { sip.mg += 5 } label: { Image(systemName: "plus.circle.fill").font(.system(size: 26)).foregroundStyle(Brew.crema) }.buttonStyle(.plain)
            }
            .card(14, radius: 18)
            .sensoryFeedback(.selection, trigger: sip.mg)
            CremaButton(title: "Save", icon: "checkmark") { store.update(sip); dismiss() }
            GhostButton(title: "Delete this drink", icon: "trash", tint: Brew.hot) { store.remove(sip); dismiss() }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }
}

/// Your own drinks (Pro), and which one is your usual.
struct DrinksView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    @Environment(Pro.self) private var pro
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Your drinks").font(.serif(30, .bold)).foregroundStyle(Brew.cream)
                    Spacer()
                    RoundKnob(icon: "xmark", size: 36) { dismiss() }
                }
                .padding(.top, 24)
                Text("The cafe order you actually drink, with its real caffeine from the menu or the can. Your usual drives the big cutoff on the Today screen.")
                    .font(.ui(13.5)).foregroundStyle(Brew.dim).fixedSize(horizontal: false, vertical: true)
                ForEach(store.db.custom) { d in row(d) }
                Button {
                    guard pro.allow(.drinks) else { return }
                    router.sheet = .drink(Drink(id: UUID().uuidString, name: "", size: "", mg: 100, custom: true))
                } label: {
                    Label("New drink", systemImage: "plus").font(.ui(15, .bold)).foregroundStyle(Brew.crema)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Brew.crema.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
                }
                .buttonStyle(Press())
                Caps("Usual from the menu").padding(.top, 8)
                ForEach(Drink.menu) { d in row(d) }
            }
            .padding(.horizontal, 20).padding(.bottom, 40)
        }
    }

    func row(_ d: Drink) -> some View {
        let usual = store.db.profile.usual == d.id
        return HStack(spacing: 12) {
            CupTop(liquid: d.liquidColor, foam: d.foamColor, size: 42)
            VStack(alignment: .leading, spacing: 1) {
                Text(d.name).font(.ui(15.5, .bold)).foregroundStyle(Brew.cream)
                Text(d.size.isEmpty ? Fmt.mg(d.mg) : "\(d.size) · \(Fmt.mg(d.mg))").font(.ui(12)).foregroundStyle(Brew.dim)
            }
            Spacer()
            if d.custom {
                Button { router.sheet = .drink(d) } label: { Image(systemName: "pencil").font(.system(size: 13, weight: .bold)).foregroundStyle(Brew.dim).frame(width: 34, height: 34).background(Circle().fill(Brew.cup2)) }.buttonStyle(.plain)
            }
            Button { withAnimation { store.db.profile.usual = d.id; store.save() } } label: {
                Image(systemName: usual ? "star.fill" : "star").font(.system(size: 15, weight: .bold)).foregroundStyle(usual ? Brew.crema : Brew.faint)
                    .frame(width: 34, height: 34).background(Circle().fill(usual ? Brew.crema.opacity(0.15) : Brew.cup2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(usual ? "Your usual" : "Make it your usual")
        }
        .card(10, radius: 20)
    }
}

struct DrinkEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var drink: Drink
    static let brews: [(UInt32, UInt32, String)] = [(0x4A2A18, 0x8A5A38, "Black"), (0x3A1E10, 0xE0A868, "Espresso"), (0xB98A62, 0xF1E2CF, "Milky"), (0x2E1A10, 0x5C3A24, "Cold"),
                                                    (0x8E4A1C, 0xB4652C, "Tea"), (0x9A9A48, 0xC2C47A, "Green"), (0xC9D84A, 0xE9F08A, "Energy"), (0xD05A7A, 0xF2A0B8, "Pink"), (0x2A1208, 0x7A3E22, "Cola")]
    var body: some View {
        let exists = store.db.custom.contains(where: { $0.id == drink.id })
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(exists ? "Edit drink" : "New drink").font(.serif(28, .bold)).foregroundStyle(Brew.cream)
                    Spacer()
                    RoundKnob(icon: "xmark", size: 36) { dismiss() }
                }
                .padding(.top, 24)
                HStack { Spacer(); CupTop(liquid: drink.liquidColor, foam: drink.foamColor, size: 110).animation(.spring, value: drink.liquid); Spacer() }
                field("Name", $drink.name, "Venti oat latte")
                field("Size", $drink.size, "20 oz")
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Caps("Caffeine")
                        Spacer()
                        Text(Fmt.mg(drink.mg)).font(.serif(26, .bold)).foregroundStyle(Brew.crema).contentTransition(.numericText())
                    }
                    Slider(value: $drink.mg, in: 0...400, step: 5).tint(Brew.crema)
                    Text("Coffee shops and cans list it. A 16 oz cafe drip is often 250 to 330 mg.").font(.ui(11.5)).foregroundStyle(Brew.faint)
                }
                .card(14, radius: 18)
                VStack(alignment: .leading, spacing: 10) {
                    Caps("Looks like")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(DrinkEditor.brews, id: \.2) { b in
                            Button { drink.liquid = b.0; drink.foam = b.1 } label: {
                                VStack(spacing: 4) {
                                    CupTop(liquid: Color(hex: b.0), foam: Color(hex: b.1), size: 44, swirl: false)
                                        .overlay(Circle().strokeBorder(Brew.crema, lineWidth: drink.liquid == b.0 ? 2.5 : 0).padding(-3))
                                    Text(b.2).font(.ui(10, .semibold)).foregroundStyle(Brew.dim)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                CremaButton(title: "Save", icon: "checkmark") {
                    if drink.name.trimmingCharacters(in: .whitespaces).isEmpty { drink.name = "My drink" }
                    drink.noun = drink.name.lowercased()
                    store.upsert(drink); dismiss()
                }
                if exists { GhostButton(title: "Delete", icon: "trash", tint: Brew.hot) { store.remove(drink); dismiss() } }
            }
            .padding(.horizontal, 20).padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    func field(_ label: String, _ text: Binding<String>, _ prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Caps(label)
            TextField("", text: text, prompt: Text(prompt).foregroundColor(Brew.faint))
                .font(.ui(17, .semibold)).foregroundStyle(Brew.cream)
                .padding(.horizontal, 14).frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Brew.cup2))
        }
    }
}
