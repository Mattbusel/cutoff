import Foundation

/// A week of coffee for screenshots and the review recording. Never saved.
@MainActor
enum Demo {
    static func fill(_ s: Store) {
        s.db.profile = Profile(bedtime: 23 * 60, halfLife: 5, sleepLine: 100, usual: "drip", setUp: true, notify: true, live: true)
        s.db.custom = [
            Drink(id: "c-cortado", name: "Oat cortado", size: "Corner cafe", mg: 130, liquid: 0xA27450, foam: 0xEEDCC4, custom: true, noun: "cortado"),
            Drink(id: "c-office", name: "Office drip", size: "16 oz", mg: 260, liquid: 0x4A2A18, foam: 0x8A5A38, custom: true, noun: "coffee"),
            Drink(id: "c-preworkout", name: "Pre-workout", size: "1 scoop", mg: 200, liquid: 0xD05A7A, foam: 0xF2A0B8, custom: true, noun: "pre-workout"),
        ]
        let T = Calendar.current.startOfDay(for: Date())
        func at(_ day: Int, _ h: Int, _ m: Int) -> Date { T.addingTimeInterval(TimeInterval(day * 86400 + h * 3600 + m * 60)) }
        func sip(_ id: String, _ d: Date) -> Sip { let k = s.drink(id); return Sip(drink: k.id, name: k.name, mg: k.mg, at: d) }
        var list: [Sip] = [sip("drip", at(0, 7, 12)), sip("latte", at(0, 9, 54)), sip("espresso", at(0, 12, 18))]
        let week: [[(String, Int, Int)]] = [
            [("drip", 7, 5), ("c-cortado", 10, 40), ("cola", 15, 30)],
            [("drip", 6, 50), ("c-office", 9, 30), ("c-office", 13, 10), ("energy", 16, 45)],
            [("drip", 7, 20), ("latte", 11, 0)],
            [("drip", 8, 10), ("tea", 14, 20), ("c-preworkout", 17, 30)],
            [("drip", 7, 0), ("double", 10, 15), ("tea", 13, 0)],
            [("coldbrew", 9, 30), ("latte", 12, 45)],
        ]
        for (i, day) in week.enumerated() {
            for (id, h, m) in day { list.append(sip(id, at(-(i + 1), h, m))) }
        }
        s.db.sips = list.sorted { $0.at < $1.at }
    }
}
