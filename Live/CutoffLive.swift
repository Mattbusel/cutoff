import ActivityKit
import SwiftUI
import WidgetKit

@main
struct CutoffLiveBundle: WidgetBundle {
    var body: some Widget { CupLive() }
}

private func hex(_ v: UInt32) -> Color {
    Color(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: 1)
}
private let night = hex(0x120D16)
private let crema = hex(0xE8B27A)
private let cream = hex(0xF4E9DC)
private let moon = hex(0xC9C6FF)

private func clock(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: d) }

struct MiniCup: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(hex(0xF7F1EA))
            Circle().fill(RadialGradient(colors: [crema, hex(0x5A3420)], center: .init(x: 0.42, y: 0.4), startRadius: 1, endRadius: size * 0.4)).padding(size * 0.12)
        }
        .frame(width: size, height: size)
    }
}

struct CupLockScreen: View {
    let attrs: CupAttributes
    let state: CupAttributes.ContentState
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                MiniCup(size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("LATEST \(attrs.drink.uppercased())").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1.2).foregroundStyle(crema)
                    Text(clock(state.cutoff)).font(.system(size: 26, weight: .bold, design: .serif)).foregroundStyle(cream)
                }
                Spacer()
                if state.cutoff > Date() {
                    Text(timerInterval: Date()...state.cutoff, countsDown: true)
                        .font(.system(size: 30, weight: .bold, design: .serif).monospacedDigit())
                        .foregroundStyle(crema).multilineTextAlignment(.trailing).frame(maxWidth: 130, alignment: .trailing)
                } else {
                    Text("Decaf now").font(.system(size: 20, weight: .bold, design: .serif)).foregroundStyle(moon)
                }
            }
            ProgressView(timerInterval: state.opened...max(state.opened.addingTimeInterval(60), state.cutoff), countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                .tint(crema)
            HStack {
                Text("Coffee window").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(cream.opacity(0.6))
                Spacer()
                Text("Bed \(clock(state.bed))").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(moon)
            }
        }
        .padding(16)
    }
}

struct CupLive: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CupAttributes.self) { ctx in
            CupLockScreen(attrs: ctx.attributes, state: ctx.state)
                .activityBackgroundTint(night)
                .activitySystemActionForegroundColor(cream)
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        MiniCup(size: 28)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Latest \(ctx.attributes.drink.lowercased())").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(cream.opacity(0.6))
                            Text(clock(ctx.state.cutoff)).font(.system(size: 17, weight: .bold, design: .serif)).foregroundStyle(cream)
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...max(Date(), ctx.state.cutoff), countsDown: true)
                        .font(.system(size: 26, weight: .bold, design: .serif).monospacedDigit())
                        .foregroundStyle(crema).multilineTextAlignment(.trailing).frame(maxWidth: 110, alignment: .trailing).padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(timerInterval: ctx.state.opened...max(ctx.state.opened.addingTimeInterval(60), ctx.state.cutoff), countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                        .tint(crema).padding(.horizontal, 4)
                }
            } compactLeading: {
                MiniCup(size: 20)
            } compactTrailing: {
                Text(timerInterval: Date()...max(Date(), ctx.state.cutoff), countsDown: true)
                    .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(crema).frame(maxWidth: 52)
            } minimal: {
                MiniCup(size: 20)
            }
            .keylineTint(crema)
        }
    }
}
