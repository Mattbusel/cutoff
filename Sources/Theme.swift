import SwiftUI
import UIKit

/// Cutoff's look: the day draining from espresso to night. Warm crema and cream for
/// caffeine, lavender moonlight for sleep, a serif clock for the one number that matters.
enum Brew {
    static let night = Color(hex: 0x120D16)
    static let night2 = Color(hex: 0x1B1522)
    static let cup = Color(hex: 0x241C2B)
    static let cup2 = Color(hex: 0x2F2537)
    static let line = Color.white.opacity(0.08)
    static let crema = Color(hex: 0xE8B27A)
    static let cremaDeep = Color(hex: 0xC98A4E)
    static let roast = Color(hex: 0x6B3F24)
    static let cream = Color(hex: 0xF4E9DC)
    static let dim = Color(hex: 0xA99DAF)
    static let faint = Color(hex: 0x6F6577)
    static let moon = Color(hex: 0xC9C6FF)
    static let moonDeep = Color(hex: 0x7C74E0)
    static let hot = Color(hex: 0xFF7A5C)
    static let ok = Color(hex: 0x8FD9B6)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: alpha)
    }
}

extension Font {
    /// New York, for the clock and headings.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font { .system(size: size, weight: weight, design: .serif) }
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font { .system(size: size, weight: weight, design: .rounded) }
    static func caps(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .bold, design: .rounded) }
}

/// The sky behind everything, warmer in the morning and deeper toward bedtime, with a few stars.
struct Sky: View {
    var night: Double = 0.5
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x2A1B1A).mix(Color(hex: 0x1A1430), night), Brew.night, Color(hex: 0x0D0A14)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Brew.crema.opacity(0.16 * (1 - night)), .clear], center: .init(x: 0.85, y: 0.02), startRadius: 10, endRadius: 420)
            RadialGradient(colors: [Brew.moonDeep.opacity(0.14 * night + 0.04), .clear], center: .init(x: 0.1, y: 0.95), startRadius: 10, endRadius: 520)
            Canvas { ctx, size in
                var seed: UInt64 = 0xC0FFEE
                func rnd() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double(seed >> 33) / Double(1 << 31) }
                for _ in 0..<70 {
                    let x = rnd() * size.width, y = size.height * (0.35 + rnd() * 0.65), r = 0.6 + rnd() * 1.3
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity((0.08 + rnd() * 0.3) * (0.4 + night * 0.6))))
                }
            }
        }
        .ignoresSafeArea()
    }
}

extension Color {
    /// A plain sRGB blend, good enough for backgrounds.
    func mix(_ other: Color, _ t: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0, r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1); b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let k = CGFloat(max(0, min(1, t)))
        return Color(.sRGB, red: Double(r1 + (r2 - r1) * k), green: Double(g1 + (g2 - g1) * k), blue: Double(b1 + (b2 - b1) * k), opacity: Double(a1 + (a2 - a1) * k))
    }
}

struct Card: ViewModifier {
    var pad: CGFloat = 16
    var radius: CGFloat = 24
    func body(content: Content) -> some View {
        content.padding(pad)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Brew.cup.opacity(0.78))
                    .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.03)], startPoint: .top, endPoint: .bottom)))
            )
    }
}
extension View {
    func card(_ pad: CGFloat = 16, radius: CGFloat = 24) -> some View { modifier(Card(pad: pad, radius: radius)) }
}

struct Caps: View {
    let text: String
    var color: Color = Brew.dim
    init(_ text: String, color: Color = Brew.dim) { self.text = text; self.color = color }
    var body: some View { Text(text.uppercased()).font(.caps(11.5)).tracking(1.8).foregroundStyle(color) }
}

struct Press: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// The main button: warm crema, like the top of a fresh espresso.
struct CremaButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let icon { Image(systemName: icon).font(.system(size: 16, weight: .bold)) }
                Text(title).font(.ui(17, .bold))
            }
            .foregroundStyle(Color(hex: 0x2A160B))
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(
                Capsule().fill(LinearGradient(colors: [Color(hex: 0xF3C996), Brew.crema, Brew.cremaDeep], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Brew.crema.opacity(0.35), radius: 18, y: 8)
            )
        }
        .buttonStyle(Press())
    }
}

struct GhostButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = Brew.cream
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let icon { Image(systemName: icon).font(.system(size: 13, weight: .bold)) }
                Text(title).font(.ui(15, .semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity).frame(height: 46)
            .background(Capsule().fill(Brew.cup2.opacity(0.8)))
            .overlay(Capsule().strokeBorder(Brew.line))
        }
        .buttonStyle(Press())
    }
}

struct RoundKnob: View {
    let icon: String
    var size: CGFloat = 38
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: size * 0.36, weight: .bold)).foregroundStyle(Brew.cream)
                .frame(width: size, height: size).background(Circle().fill(Brew.cup2)).overlay(Circle().strokeBorder(Brew.line))
        }
        .buttonStyle(Press())
    }
}

/// A cup seen from above: rim, coffee, crema and a swirl. Colour follows the drink.
struct CupTop: View {
    var liquid: Color = Color(hex: 0x5A3420)
    var foam: Color = Brew.crema
    var size: CGFloat = 56
    var swirl: Bool = true
    var body: some View {
        ZStack {
            // Handle.
            Capsule().fill(Color(hex: 0xEDE6DD)).frame(width: size * 0.3, height: size * 0.16).offset(x: size * 0.5)
            Circle().fill(Color(hex: 0xF7F1EA))
            Circle().fill(Color(hex: 0xD9CFC4)).padding(size * 0.06)
            Circle().fill(RadialGradient(colors: [foam, foam.mix(liquid, 0.55), liquid], center: .init(x: 0.42, y: 0.4), startRadius: 1, endRadius: size * 0.42)).padding(size * 0.1)
            if swirl {
                Circle().trim(from: 0.05, to: 0.7).stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                    .padding(size * 0.26).rotationEffect(.degrees(30))
                Circle().trim(from: 0.2, to: 0.85).stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round))
                    .padding(size * 0.34).rotationEffect(.degrees(160))
            }
        }
        .frame(width: size, height: size)
    }
}

/// A crescent moon.
struct Moon: View {
    var size: CGFloat = 22
    var color: Color = Brew.moon
    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().fill(Brew.night).frame(width: size * 0.82, height: size * 0.82).offset(x: size * 0.28, y: -size * 0.16).blendMode(.destinationOut)
        }
        .compositingGroup()
        .frame(width: size, height: size)
        .shadow(color: color.opacity(0.6), radius: size * 0.3)
    }
}

enum Fmt {
    static func time(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: d) }
    static func hm(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "h:mm"; return f.string(from: d) }
    static func ampm(_ d: Date) -> String { Calendar.current.component(.hour, from: d) < 12 ? "AM" : "PM" }
    static func hour(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "ha"; return f.string(from: d).lowercased() }
    static func span(_ s: TimeInterval) -> String {
        let m = Int((abs(s) / 60).rounded())
        if m < 60 { return "\(m) min" }
        return m % 60 == 0 ? "\(m / 60) h" : "\(m / 60) h \(m % 60) min"
    }
    static func mg(_ v: Double) -> String { "\(Int(v.rounded())) mg" }
    static func day(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEEE d MMM"; return f.string(from: d)
    }
    static func mins(_ m: Int) -> String {
        let h = (m / 60) % 24, mm = m % 60, h12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", h12, mm, h < 12 ? "AM" : "PM")
    }
}
