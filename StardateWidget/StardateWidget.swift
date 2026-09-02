import AppIntents
import SwiftUI
import WidgetKit

enum StardatePrecision: String, AppEnum, CaseIterable {
    case zero = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Decimal places"

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .zero: "0 places",
        .one: "1 place",
        .two: "2 places",
        .three: "3 places",
        .four: "4 places"
    ]

    var places: Int { Int(rawValue) ?? 2 }
}

enum WidgetRefreshInterval: String, AppEnum, CaseIterable {
    case five = "5"
    case fifteen = "15"
    case thirty = "30"
    case sixty = "60"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Update frequency"

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .five: "5 minutes",
        .fifteen: "15 minutes",
        .thirty: "30 minutes",
        .sixty: "60 minutes"
    ]

    var minutes: Int { Int(rawValue) ?? 15 }
}

struct StardateWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Stardate widget"
    static let description = IntentDescription("Display the current stardate.")

    @Parameter(title: "Decimal places", default: .two)
    var decimalPlaces: StardatePrecision

    @Parameter(title: "Update frequency", default: .fifteen)
    var refreshInterval: WidgetRefreshInterval

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$decimalPlaces) decimal places, updating every \(\.$refreshInterval)")
    }
}

struct StardateWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: StardateWidgetConfiguration
}

struct StardateWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StardateWidgetEntry {
        StardateWidgetEntry(date: .now, configuration: StardateWidgetConfiguration())
    }

    func snapshot(for configuration: StardateWidgetConfiguration, in context: Context) async -> StardateWidgetEntry {
        StardateWidgetEntry(date: .now, configuration: configuration)
    }

    func timeline(for configuration: StardateWidgetConfiguration, in context: Context) async -> Timeline<StardateWidgetEntry> {
        let start = Date()
        let interval = TimeInterval(configuration.refreshInterval.minutes * 60)
        let horizon: TimeInterval = 3 * 60 * 60
        let entryCount = max(1, Int(horizon / interval))
        let entries = (0...entryCount).map { index in
            StardateWidgetEntry(
                date: start.addingTimeInterval(Double(index) * interval),
                configuration: configuration
            )
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct StardateWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: StardateWidgetEntry

    private var formattedStardate: String {
        StardateCalculator.formatted(
            date: entry.date,
            decimalPlaces: entry.configuration.decimalPlaces.places
        )
    }

    private var fontSize: CGFloat {
        switch family {
        case .systemSmall:
            return 31
        case .systemMedium:
            return 42
        case .systemLarge:
            return 60
        default:
            return 15
        }
    }

    var body: some View {
        Text(formattedStardate)
            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .minimumScaleFactor(0.55)
            .lineLimit(1)
            .foregroundStyle(.white)
            .widgetAccentable()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .containerBackground(for: .widget) {
                WidgetStarfieldBackground()
            }
    }
}

private struct WidgetStarfieldBackground: View {
    private struct Star {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let opacity: Double
    }

    private let stars: [Star] = [
        .init(x: 0.06, y: 0.10, radius: 1.1, opacity: 0.80), .init(x: 0.18, y: 0.22, radius: 0.7, opacity: 0.45),
        .init(x: 0.31, y: 0.08, radius: 1.0, opacity: 0.70), .init(x: 0.43, y: 0.32, radius: 0.6, opacity: 0.42),
        .init(x: 0.56, y: 0.14, radius: 0.8, opacity: 0.64), .init(x: 0.68, y: 0.25, radius: 1.2, opacity: 0.55),
        .init(x: 0.83, y: 0.10, radius: 0.6, opacity: 0.76), .init(x: 0.94, y: 0.34, radius: 0.9, opacity: 0.42),
        .init(x: 0.10, y: 0.50, radius: 0.6, opacity: 0.52), .init(x: 0.24, y: 0.66, radius: 1.1, opacity: 0.60),
        .init(x: 0.38, y: 0.54, radius: 0.7, opacity: 0.44), .init(x: 0.53, y: 0.74, radius: 0.9, opacity: 0.68),
        .init(x: 0.72, y: 0.57, radius: 0.6, opacity: 0.50), .init(x: 0.88, y: 0.72, radius: 1.0, opacity: 0.72),
        .init(x: 0.05, y: 0.88, radius: 0.9, opacity: 0.48), .init(x: 0.30, y: 0.92, radius: 0.6, opacity: 0.70),
        .init(x: 0.62, y: 0.90, radius: 1.0, opacity: 0.46), .init(x: 0.92, y: 0.94, radius: 0.7, opacity: 0.66),
        .init(x: 0.78, y: 0.44, radius: 1.2, opacity: 0.90)
    ]

    var body: some View {
        ZStack {
            Color.black

            Canvas { context, size in
                for star in stars {
                    let point = CGPoint(x: star.x * size.width, y: star.y * size.height)
                    let rect = CGRect(
                        x: point.x - star.radius,
                        y: point.y - star.radius,
                        width: star.radius * 2,
                        height: star.radius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(star.opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct StardateWidget: Widget {
    let kind = "StardateWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: StardateWidgetConfiguration.self,
            provider: StardateWidgetProvider()
        ) { entry in
            StardateWidgetView(entry: entry)
        }
        .configurationDisplayName("Stardate")
        .description("See the current stardate at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct StardateWidgetBundle: WidgetBundle {
    var body: some Widget {
        StardateWidget()
    }
}

#Preview(as: .systemSmall) {
    StardateWidget()
} timeline: {
    StardateWidgetEntry(
        date: Date(timeIntervalSince1970: 1_759_382_400),
        configuration: StardateWidgetConfiguration()
    )
}

#Preview(as: .systemMedium) {
    StardateWidget()
} timeline: {
    StardateWidgetEntry(
        date: Date(timeIntervalSince1970: 1_759_382_400),
        configuration: StardateWidgetConfiguration()
    )
}
