import Foundation
import SwiftUI

/// A kind of drink and how much caffeine a usual serving has.
struct Drink: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var size: String
    var mg: Double
    /// Coffee-ish colours for the little cup.
    var liquid: UInt32 = 0x5A3420
    var foam: UInt32 = 0xE8B27A
    var custom: Bool = false
    /// What the headline calls it: "Latest coffee".
    var noun: String = "coffee"

    var liquidColor: Color { Color(hex: liquid) }
    var foamColor: Color { Color(hex: foam) }

    /// Typical servings. Figures are USDA FoodData Central values for brewed coffee, espresso,
    /// tea and cola, and label values for energy drinks; see Sources in the app.
    static let menu: [Drink] = [
        Drink(id: "drip", name: "Coffee", size: "12 oz mug", mg: 140, liquid: 0x4A2A18, foam: 0x8A5A38),
        Drink(id: "espresso", name: "Espresso", size: "single shot", mg: 63, liquid: 0x3A1E10, foam: 0xD49A5E, noun: "espresso"),
        Drink(id: "double", name: "Double espresso", size: "two shots", mg: 126, liquid: 0x3A1E10, foam: 0xE0A868, noun: "espresso"),
        Drink(id: "latte", name: "Latte", size: "16 oz, two shots", mg: 126, liquid: 0xB98A62, foam: 0xF1E2CF, noun: "latte"),
        Drink(id: "coldbrew", name: "Cold brew", size: "16 oz", mg: 200, liquid: 0x2E1A10, foam: 0x5C3A24, noun: "cold brew"),
        Drink(id: "tea", name: "Black tea", size: "8 oz cup", mg: 47, liquid: 0x8E4A1C, foam: 0xB4652C, noun: "tea"),
        Drink(id: "green", name: "Green tea", size: "8 oz cup", mg: 28, liquid: 0x9A9A48, foam: 0xC2C47A, noun: "tea"),
        Drink(id: "cola", name: "Cola", size: "12 oz can", mg: 34, liquid: 0x2A1208, foam: 0x7A3E22, noun: "cola"),
        Drink(id: "energy", name: "Energy drink", size: "16 oz can", mg: 160, liquid: 0xC9D84A, foam: 0xE9F08A, noun: "energy drink"),
        Drink(id: "energysmall", name: "Energy drink", size: "8.4 oz can", mg: 80, liquid: 0xC9D84A, foam: 0xE9F08A, noun: "energy drink"),
        Drink(id: "decaf", name: "Decaf", size: "12 oz mug", mg: 3, liquid: 0x5A3A28, foam: 0x9A7458),
    ]
}

/// One drink, drunk at a time.
struct Sip: Codable, Identifiable, Hashable {
    var id = UUID()
    var drink: String
    var name: String
    var mg: Double
    var at: Date
}

struct Profile: Codable, Hashable {
    /// Minutes after midnight. Before noon means after midnight.
    var bedtime: Int = 23 * 60
    var halfLife: Double = 5
    /// The most caffeine you want left when you lie down.
    var sleepLine: Double = 100
    var usual: String = "drip"
    var setUp = false
    var notify = false
    var live = false
}

struct DB: Codable {
    var profile = Profile()
    var sips: [Sip] = []
    var custom: [Drink] = []
}

/// Caffeine in the body after one dose, as a fraction of the dose: first-order absorption
/// (peaks about an hour after drinking) and first-order elimination with the given half-life.
enum Kinetics {
    static let absorbHalfLife = 0.2  // hours
    static func fraction(hours t: Double, halfLife: Double) -> Double {
        guard t > 0 else { return 0 }
        let ka = log(2) / absorbHalfLife, ke = log(2) / max(0.5, halfLife)
        return ka / (ka - ke) * (exp(-ke * t) - exp(-ka * t))
    }
    static func peakHours(halfLife: Double) -> Double {
        let ka = log(2) / absorbHalfLife, ke = log(2) / max(0.5, halfLife)
        return log(ka / ke) / (ka - ke)
    }
}

@MainActor
@Observable
final class Store {
    var db: DB
    let demo: Bool
    @ObservationIgnored private(set) var offset: TimeInterval = 0
    var now: Date { Date().addingTimeInterval(offset) }
    @ObservationIgnored private let url = URL.documentsDirectory.appending(path: "cutoff.json")

    init(demo: Bool) {
        self.demo = demo
        if demo {
            db = DB()
            let target = Calendar.current.startOfDay(for: Date()).addingTimeInterval(13 * 3600 + 24 * 60)
            offset = target.timeIntervalSince(Date())
            Demo.fill(self)
        } else if let data = try? Data(contentsOf: url), let d = try? JSONDecoder().decode(DB.self, from: data) {
            db = d
        } else {
            db = DB()
        }
    }

    func save() {
        guard !demo else { return }
        if let data = try? JSONEncoder().encode(db) { try? data.write(to: url, options: [.atomic]) }
        Alerts.shared.refresh(self)
    }

    // MARK: drinks

    var drinks: [Drink] { db.custom + Drink.menu }
    func drink(_ id: String) -> Drink { drinks.first(where: { $0.id == id }) ?? Drink.menu[0] }
    var usual: Drink { drink(db.profile.usual) }

    func log(_ d: Drink, at: Date? = nil) {
        db.sips.append(Sip(drink: d.id, name: d.name, mg: d.mg, at: at ?? now))
        db.sips.sort { $0.at < $1.at }
        save()
    }
    func update(_ s: Sip) { if let i = db.sips.firstIndex(where: { $0.id == s.id }) { db.sips[i] = s; db.sips.sort { $0.at < $1.at }; save() } }
    func remove(_ s: Sip) { db.sips.removeAll { $0.id == s.id }; save() }
    func upsert(_ d: Drink) {
        if let i = db.custom.firstIndex(where: { $0.id == d.id }) { db.custom[i] = d } else { db.custom.insert(d, at: 0) }
        save()
    }
    func remove(_ d: Drink) {
        db.custom.removeAll { $0.id == d.id }
        if db.profile.usual == d.id { db.profile.usual = "drip" }
        save()
    }

    // MARK: the night

    /// Tonight's bedtime: the next one, unless the last one was under six hours ago.
    func bed(for t: Date? = nil) -> Date {
        let t = t ?? now
        let cal = Calendar.current
        var b = cal.startOfDay(for: t).addingTimeInterval(TimeInterval(db.profile.bedtime * 60))
        if db.profile.bedtime < 12 * 60 { b = b.addingTimeInterval(86400) }
        while b.timeIntervalSince(t) > 18 * 3600 { b = b.addingTimeInterval(-86400) }
        while t.timeIntervalSince(b) > 6 * 3600 { b = b.addingTimeInterval(86400) }
        return b
    }
    var bed: Date { bed() }
    /// Where "today" starts for the drink list: 20 hours before bedtime.
    func dayStart(for bed: Date) -> Date { bed.addingTimeInterval(-20 * 3600) }
    var today: [Sip] { let s = dayStart(for: bed); return db.sips.filter { $0.at >= s && $0.at <= bed.addingTimeInterval(6 * 3600) } }
    var todayMg: Double { today.reduce(0) { $0 + $1.mg } }

    /// Milligrams in the body at `t`, from every drink in the two days before.
    func level(at t: Date, sips: [Sip]? = nil, halfLife: Double? = nil) -> Double {
        let hl = halfLife ?? db.profile.halfLife
        let list = sips ?? db.sips
        var sum = 0.0
        for s in list where s.at <= t && t.timeIntervalSince(s.at) < 60 * 3600 {
            sum += s.mg * Kinetics.fraction(hours: t.timeIntervalSince(s.at) / 3600, halfLife: hl)
        }
        return sum
    }

    /// The most caffeine left at any point from bedtime through the next three hours.
    func peakAfter(_ bed: Date, sips: [Sip]) -> Double {
        var m = 0.0
        for k in 0...36 { m = max(m, level(at: bed.addingTimeInterval(TimeInterval(k * 5 * 60)), sips: sips)) }
        return m
    }

    /// The latest time `drink` can be had and still be under the sleep line from bedtime on.
    /// Nil when even a drink right now is too much.
    func cutoff(for drink: Drink? = nil, bed: Date? = nil) -> Date? {
        let d = drink ?? usual
        let b = bed ?? self.bed
        let line = db.profile.sleepLine
        let past = db.sips.filter { $0.at <= b && b.timeIntervalSince($0.at) < 60 * 3600 }
        let base = peakAfter(b, sips: past)
        if base > line { return nil }
        func ok(_ t: Date) -> Bool { peakAfter(b, sips: past + [Sip(drink: d.id, name: d.name, mg: d.mg, at: t)]) <= line }
        var lo = b.addingTimeInterval(-30 * 3600), hi = b
        if !ok(lo) { return nil }
        if ok(hi) { return hi }
        for _ in 0..<30 {
            let mid = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
            if ok(mid) { lo = mid } else { hi = mid }
        }
        // Rounded down to the minute: never promise a later minute than the maths allows.
        let t = floor(lo.timeIntervalSinceReferenceDate / 60) * 60
        return Date(timeIntervalSinceReferenceDate: t)
    }

    /// When caffeine already in the body falls under the sleep line.
    func clearTime(after t: Date? = nil) -> Date? {
        let start = t ?? now
        for k in 0...(36 * 12) {
            let x = start.addingTimeInterval(TimeInterval(k * 5 * 60))
            if level(at: x) <= db.profile.sleepLine && x >= start { return x }
        }
        return nil
    }

    // MARK: history

    struct Day: Identifiable {
        var id: Date { bed }
        let bed: Date
        let sips: [Sip]
        let total: Double
        let atBed: Double
        let last: Date?
    }

    func days(_ n: Int) -> [Day] {
        (0..<n).map { k in
            let b = bed.addingTimeInterval(TimeInterval(-k * 86400))
            let s = dayStart(for: b)
            let sips = db.sips.filter { $0.at >= s && $0.at < b.addingTimeInterval(4 * 3600) }
            return Day(bed: b, sips: sips, total: sips.reduce(0) { $0 + $1.mg }, atBed: level(at: b), last: sips.last?.at)
        }
    }
}
