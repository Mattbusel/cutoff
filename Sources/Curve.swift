import SwiftUI

/// The caffeine in you across the day: what's there now, where it's heading, the sleep
/// line, the moon at bedtime, and a dotted ghost of one more drink at the cutoff.
struct CurveChart: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    var height: CGFloat = 230
    var interactive = true

    var body: some View {
        let bed = store.bed
        let x0 = store.dayStart(for: bed).addingTimeInterval(2 * 3600)
        let x1 = bed.addingTimeInterval(3 * 3600)
        let now = store.now
        let line = store.db.profile.sleepLine
        let cutoff = store.cutoff(bed: bed)
        let usual = store.usual
        let step: TimeInterval = 10 * 60
        let n = Int(x1.timeIntervalSince(x0) / step)
        let pts: [Double] = (0...n).map { store.level(at: x0.addingTimeInterval(Double($0) * step)) }
        let ghostSips = cutoff.map { store.db.sips + [Sip(drink: usual.id, name: usual.name, mg: usual.mg, at: $0)] }
        let ghost: [Double]? = ghostSips.map { g in (0...n).map { store.level(at: x0.addingTimeInterval(Double($0) * step), sips: g) } }
        let top = max(line * 1.9, (pts.max() ?? 0) * 1.18, (ghost?.max() ?? 0) * 1.08)
        let sips = store.db.sips.filter { $0.at >= x0 && $0.at <= x1 }

        GeometryReader { g in
            let W = g.size.width, H = g.size.height - 22
            let span = x1.timeIntervalSince(x0)
            let X: (Date) -> CGFloat = { CGFloat($0.timeIntervalSince(x0) / span) * W }
            let Y: (Double) -> CGFloat = { H - CGFloat($0 / top) * (H - 8) }
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    let dayGrad = Gradient(stops: [.init(color: Brew.crema, location: 0), .init(color: Brew.crema, location: 0.45), .init(color: Brew.moon, location: 0.9)])
                    // Hour grid.
                    let cal = Calendar.current
                    var h = cal.nextDate(after: x0, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? x0
                    while h < x1 {
                        let hr = cal.component(.hour, from: h)
                        if hr % 3 == 0 {
                            let x = X(h)
                            var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: H))
                            ctx.stroke(p, with: .color(.white.opacity(0.05)), lineWidth: 1)
                            let label = hr == 0 ? "12a" : hr == 12 ? "12p" : hr < 12 ? "\(hr)a" : "\(hr - 12)p"
                            ctx.draw(Text(label).font(.ui(10.5, .semibold)).foregroundColor(Brew.faint), at: CGPoint(x: x, y: H + 12))
                        }
                        h = h.addingTimeInterval(3600)
                    }
                    // The night after bedtime.
                    let bx = X(bed)
                    ctx.fill(Path(CGRect(x: bx, y: 0, width: W - bx, height: H)), with: .linearGradient(Gradient(colors: [Brew.moonDeep.opacity(0.16), Brew.moonDeep.opacity(0.04)]), startPoint: CGPoint(x: bx, y: 0), endPoint: CGPoint(x: W, y: 0)))

                    // Area and line.
                    var area = Path(), curve = Path()
                    area.move(to: CGPoint(x: 0, y: H))
                    for (i, v) in pts.enumerated() {
                        let p = CGPoint(x: CGFloat(i) / CGFloat(n) * W, y: Y(v))
                        area.addLine(to: p)
                        if i == 0 { curve.move(to: p) } else { curve.addLine(to: p) }
                    }
                    area.addLine(to: CGPoint(x: W, y: H)); area.closeSubpath()
                    ctx.fill(area, with: .linearGradient(dayGrad, startPoint: .zero, endPoint: CGPoint(x: W, y: 0)))
                    ctx.fill(area, with: .linearGradient(Gradient(colors: [Brew.night.opacity(0.35), Brew.night.opacity(0.92)]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: H)))
                    // Past solid, future dashed.
                    let nx = X(now)
                    var past = ctx, future = ctx
                    past.clip(to: Path(CGRect(x: 0, y: -10, width: nx, height: H + 20)))
                    future.clip(to: Path(CGRect(x: nx, y: -10, width: W - nx, height: H + 20)))
                    past.stroke(curve, with: .linearGradient(dayGrad, startPoint: .zero, endPoint: CGPoint(x: W, y: 0)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    future.stroke(curve, with: .linearGradient(dayGrad, startPoint: .zero, endPoint: CGPoint(x: W, y: 0)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [5, 5]))

                    // One more at the cutoff.
                    if let ghost {
                        var gp = Path()
                        var started = false
                        for (i, v) in ghost.enumerated() where abs(v - pts[i]) > 0.5 {
                            let p = CGPoint(x: CGFloat(i) / CGFloat(n) * W, y: Y(v))
                            if !started { gp.move(to: CGPoint(x: p.x, y: Y(pts[i]))); started = true }
                            gp.addLine(to: p)
                        }
                        ctx.stroke(gp, with: .color(Brew.crema.opacity(0.55)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [1.5, 4.5]))
                    }

                    // Sleep line.
                    var sl = Path(); sl.move(to: CGPoint(x: 0, y: Y(line))); sl.addLine(to: CGPoint(x: W, y: Y(line)))
                    ctx.stroke(sl, with: .color(Brew.moon.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
                    ctx.draw(Text("sleep line \(Int(line)) mg").font(.ui(10, .bold)).foregroundColor(Brew.moon), at: CGPoint(x: W - 4, y: Y(line) + 10), anchor: .trailing)

                    // Bedtime.
                    var bl = Path(); bl.move(to: CGPoint(x: bx, y: 14)); bl.addLine(to: CGPoint(x: bx, y: H))
                    ctx.stroke(bl, with: .color(Brew.moon.opacity(0.55)), lineWidth: 1.2)

                    // Drinks along the floor.
                    for s in sips {
                        let x = X(s.at)
                        ctx.fill(Path(ellipseIn: CGRect(x: x - 4.5, y: H - 4.5, width: 9, height: 9)), with: .color(Brew.crema))
                        ctx.stroke(Path(ellipseIn: CGRect(x: x - 4.5, y: H - 4.5, width: 9, height: 9)), with: .color(Brew.night), lineWidth: 2)
                    }

                    // Now.
                    if now > x0 && now < x1 {
                        var nl = Path(); nl.move(to: CGPoint(x: nx, y: 0)); nl.addLine(to: CGPoint(x: nx, y: H))
                        ctx.stroke(nl, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                        let v = store.level(at: now)
                        let c = CGPoint(x: nx, y: Y(v))
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 12, y: c.y - 12, width: 24, height: 24)), with: .color(Brew.crema.opacity(0.22)))
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 5.5, y: c.y - 5.5, width: 11, height: 11)), with: .color(Brew.cream))
                    }
                    // Cutoff tick.
                    if let c = cutoff, c > x0 {
                        let cx = X(c)
                        var cl = Path(); cl.move(to: CGPoint(x: cx, y: H - 16)); cl.addLine(to: CGPoint(x: cx, y: H))
                        ctx.stroke(cl, with: .color(Brew.crema), lineWidth: 2)
                    }
                }
                // Moon over bedtime.
                Moon(size: 16).position(x: X(bed), y: 8)
                if let c = cutoff, c > x0 {
                    Text("last call").font(.ui(9.5, .heavy)).foregroundStyle(Brew.night)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(Brew.crema))
                        .position(x: min(max(X(c), 30), W - 30), y: H - 26)
                }
                if let t = router.scrub, t >= x0, t <= x1 {
                    let v = store.level(at: t)
                    let x = X(t)
                    Rectangle().fill(Brew.cream.opacity(0.6)).frame(width: 1, height: H).position(x: x, y: H / 2)
                    Circle().fill(Brew.cream).frame(width: 12, height: 12).overlay(Circle().strokeBorder(Brew.night, lineWidth: 2)).position(x: x, y: Y(v))
                    VStack(spacing: 0) {
                        Text(Fmt.mg(v)).font(.serif(17, .bold)).foregroundStyle(Brew.night)
                        Text(Fmt.time(t)).font(.ui(10.5, .bold)).foregroundStyle(Brew.night.opacity(0.7))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Brew.cream))
                    .position(x: min(max(x, 44), W - 44), y: max(24, Y(v) - 34))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { v in
                        guard interactive else { return }
                        // Let vertical swipes scroll the page.
                        if router.scrub == nil && abs(v.translation.height) > abs(v.translation.width) { return }
                        let f = max(0, min(1, v.location.x / W))
                        let t = x0.addingTimeInterval(span * Double(f))
                        router.scrub = t
                    }
                    .onEnded { _ in
                        guard interactive else { return }
                        withAnimation(.easeOut(duration: 0.25)) { router.scrub = nil }
                    }
            )
            .sensoryFeedback(.selection, trigger: router.scrub.map { Int($0.timeIntervalSince1970 / 1800) })
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Caffeine curve. \(Fmt.mg(store.level(at: now))) now, \(Fmt.mg(store.level(at: bed))) at bedtime.")
    }
}
