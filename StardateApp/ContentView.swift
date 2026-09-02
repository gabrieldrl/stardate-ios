import SwiftUI
import UIKit

struct ContentView: View {
    private enum ComparisonSide: Hashable {
        case primary
        case secondary
    }

    private enum PresentedSheet: Identifiable {
        case settings

        var id: String {
            switch self {
            case .settings:
                return "settings"
            }
        }
    }

    @AppStorage("appDecimalPlaces") private var decimalPlaces = 2
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var presentedSheet: PresentedSheet?
    @State private var selectedDate: Date?
    @State private var comparisonDate: Date?
    @State private var comparisonMode = false
    @State private var editingSide: ComparisonSide?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let liveDate = timeline.date
            let primaryDate = selectedDate ?? liveDate
            let secondaryDate = comparisonDate ?? liveDate
            let primaryStardate = StardateCalculator.stardate(at: primaryDate)
            let secondaryStardate = StardateCalculator.stardate(at: secondaryDate)
            let formattedPrimaryStardate = StardateCalculator.formatted(
                stardate: primaryStardate,
                decimalPlaces: decimalPlaces
            )
            let formattedSecondaryStardate = StardateCalculator.formatted(
                stardate: secondaryStardate,
                decimalPlaces: decimalPlaces
            )

            ZStack {
                StarfieldBackground()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        settingsButton
                    }

                    Spacer(minLength: 24)

                    if comparisonMode {
                        comparisonDisplay(
                            primaryDate: primaryDate,
                            primaryStardate: primaryStardate,
                            formattedPrimaryStardate: formattedPrimaryStardate,
                            secondaryDate: secondaryDate,
                            secondaryStardate: secondaryStardate,
                            formattedSecondaryStardate: formattedSecondaryStardate
                        )
                    } else {
                        stardateValueButton(
                            formattedStardate: formattedPrimaryStardate,
                            stardate: primaryStardate,
                            date: primaryDate,
                            side: .primary,
                            fontSize: 64
                        )
                        .frame(maxWidth: .infinity)

                        if let selectedDate {
                            customTimeSummary(selectedDate)
                        }
                    }

                    Spacer(minLength: 0)

                    comparisonButton
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsView(decimalPlaces: $decimalPlaces)
                }
            }
        }
    }

    private func resetToCurrentTime() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            selectedDate = nil
        }
    }

    private func beginTimeSelection(for side: ComparisonSide) {
        editingSide = side
    }

    private func toggleComparison() {
        let shouldShowComparison = !comparisonMode
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28)) {
            comparisonMode = shouldShowComparison
            if shouldShowComparison {
                comparisonDate = selectedDate
            } else {
                comparisonDate = nil
                editingSide = nil
            }
        }
    }

    private func copyStardate(_ formattedStardate: String) {
        UIPasteboard.general.string = formattedStardate
        UIAccessibility.post(
            notification: .announcement,
            argument: "Stardate \(formattedStardate) copied"
        )
    }

    private var settingsButton: some View {
        Button {
            presentedSheet = .settings
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.10), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
        .accessibilityHint("Choose the number of decimal places")
    }

    private func stardateValueButton(
        formattedStardate: String,
        stardate: Double,
        date: Date,
        side: ComparisonSide,
        fontSize: CGFloat
    ) -> some View {
        Button {
            beginTimeSelection(for: side)
        } label: {
            Text(formattedStardate)
                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .foregroundStyle(.white)
                .contentTransition(reduceMotion ? .identity : .numericText(value: stardate))
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.22),
                    value: stardate
                )
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.55)
                .onEnded { _ in
                    copyStardate(formattedStardate)
                }
        )
        .accessibilityLabel(accessibilityLabel(for: side))
        .accessibilityValue(formattedStardate)
        .accessibilityHint("Tap to edit the date and time. Touch and hold to copy.")
        .accessibilityAction(named: "Edit date and time") {
            beginTimeSelection(for: side)
        }
        .accessibilityAction(named: "Copy stardate") {
            copyStardate(formattedStardate)
        }
        .popover(
            isPresented: editingBinding(for: side),
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .top
        ) {
            TimeSelectionSheet(
                selectedDate: dateBinding(for: side),
                fallbackDate: date
            )
            .frame(width: 340, height: 270)
        }
    }

    private func accessibilityLabel(for side: ComparisonSide) -> String {
        guard comparisonMode else { return "Stardate" }
        switch side {
        case .primary:
            return "Left stardate"
        case .secondary:
            return "Right stardate"
        }
    }

    private func comparisonDisplay(
        primaryDate: Date,
        primaryStardate: Double,
        formattedPrimaryStardate: String,
        secondaryDate: Date,
        secondaryStardate: Double,
        formattedSecondaryStardate: String
    ) -> some View {
        let difference = secondaryStardate - primaryStardate
        let isDifferent = abs(difference) > 0.000_000_1

        return VStack(spacing: 12) {
            HStack(spacing: 8) {
                stardateValueButton(
                    formattedStardate: formattedPrimaryStardate,
                    stardate: primaryStardate,
                    date: primaryDate,
                    side: .primary,
                    fontSize: 72
                )
                .frame(maxWidth: .infinity)

                if isDifferent {
                    ComparisonConnector(
                        direction: difference > 0 ? .right : .left
                    )
                    .frame(minWidth: 44, maxWidth: .infinity)
                }

                stardateValueButton(
                    formattedStardate: formattedSecondaryStardate,
                    stardate: secondaryStardate,
                    date: secondaryDate,
                    side: .secondary,
                    fontSize: 72
                )
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            if isDifferent {
                comparisonDifferenceSummary(
                    primaryDate: primaryDate,
                    secondaryDate: secondaryDate,
                    stardateDifference: abs(difference)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func comparisonDifferenceSummary(
        primaryDate: Date,
        secondaryDate: Date,
        stardateDifference: Double
    ) -> some View {
        let duration = formattedRelativeDuration(
            abs(secondaryDate.timeIntervalSince(primaryDate))
        )
        let formattedStardateDifference = StardateCalculator.formatted(
            stardate: stardateDifference,
            decimalPlaces: max(decimalPlaces, 3)
        )

        return VStack(spacing: 4) {
            Text("\(duration) relative")
            Text("\(formattedStardateDifference) stardates relative")
        }
        .font(.footnote.monospacedDigit())
        .foregroundStyle(.white.opacity(0.62))
        .multilineTextAlignment(.center)
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
        .accessibilityElement(children: .combine)
    }

    private func formattedRelativeDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds / 60))
        guard totalMinutes > 0 else { return "< 1m" }

        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            if hours > 0 {
                return "\(days)d \(hours)h"
            }
            return "\(days)d"
        }
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        return "\(minutes)m"
    }

    private func customTimeSummary(_ date: Date) -> some View {
        HStack(spacing: 8) {
            Text(date, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button {
                resetToCurrentTime()
            } label: {
                Image(systemName: "eraser")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Use current time")
            .accessibilityHint("Clear the selected date and time")
        }
        .frame(maxWidth: .infinity)
        .transition(
            reduceMotion
                ? .opacity
                : .opacity.combined(with: .move(edge: .top))
        )
    }

    private var comparisonButton: some View {
        Button {
            toggleComparison()
        } label: {
            Image(systemName: "circle.circle")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(comparisonMode ? "Hide comparison" : "Compare stardates")
        .accessibilityValue(comparisonMode ? "On" : "Off")
        .accessibilityHint(
            comparisonMode
                ? "Show only the primary stardate"
                : "Show a second stardate for comparison"
        )
    }

    private func editingBinding(for side: ComparisonSide) -> Binding<Bool> {
        Binding(
            get: { editingSide == side },
            set: { isPresented in
                if !isPresented, editingSide == side {
                    editingSide = nil
                }
            }
        )
    }

    private func dateBinding(for side: ComparisonSide) -> Binding<Date?> {
        switch side {
        case .primary:
            return $selectedDate
        case .secondary:
            return $comparisonDate
        }
    }
}

private enum ComparisonDirection: Hashable {
    case right
    case left
}

private struct ComparisonConnector: View {
    let direction: ComparisonDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dashPhase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let endpointInset: CGFloat = 10

            ZStack {
                DottedLine()
                    .stroke(
                        Color.white.opacity(0.58),
                        style: StrokeStyle(
                            lineWidth: 1.8,
                            lineCap: .round,
                            dash: [2, 6],
                            dashPhase: dashPhase
                        )
                    )
                    .frame(
                        width: max(proxy.size.width - endpointInset * 2, 1),
                        height: 20
                    )

                arrow
                    .position(
                        x: direction == .right
                            ? proxy.size.width - endpointInset
                            : endpointInset,
                        y: proxy.size.height / 2
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            direction == .right
                ? "Right stardate is later"
                : "Left stardate is later"
        )
        .onAppear {
            animateDots()
        }
        .onChange(of: direction) { _, _ in
            dashPhase = 0
            animateDots()
        }
    }

    private var arrow: some View {
        Image(systemName: direction == .right ? "arrow.right" : "arrow.left")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.68))
    }

    private func animateDots() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            dashPhase = 6
        }
    }
}

private struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

private struct TimeSelectionSheet: View {
    @Binding var selectedDate: Date?
    let fallbackDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var draftDate: Date

    init(selectedDate: Binding<Date?>, fallbackDate: Date) {
        self._selectedDate = selectedDate
        self.fallbackDate = fallbackDate
        self._draftDate = State(
            initialValue: dateAlignedToMinute(
                selectedDate.wrappedValue ?? fallbackDate
            )
        )
    }

    private var dateSelection: Binding<Date> {
        Binding(
            get: { draftDate },
            set: {
                let alignedDate = dateAlignedToMinute($0)
                draftDate = alignedDate
                selectedDate = alignedDate
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    selectedDate = nil
                    draftDate = dateAlignedToMinute(fallbackDate)
                    dismiss()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Use current time")

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .font(.body.weight(.semibold))
            }

            DatePicker(
                "Date and time",
                selection: dateSelection,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Date and time")
        }
        .padding(.horizontal, 16)
        .presentationDetents([.height(270)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.black)
        .onAppear {
            draftDate = dateAlignedToMinute(selectedDate ?? fallbackDate)
        }
    }
}

private func dateAlignedToMinute(_ date: Date) -> Date {
    Calendar.current.date(bySetting: .second, value: 0, of: date) ?? date
}

private struct SettingsView: View {
    @Binding var decimalPlaces: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Decimal places", selection: $decimalPlaces) {
                        ForEach(0...4, id: \.self) { places in
                            Text("\(places) decimal place\(places == 1 ? "" : "s")")
                                .tag(places)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Stardate display")
                } footer: {
                    Text("Configure the widget's decimal places and update frequency in widget edit mode.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct StarfieldBackground: View {
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
        .init(x: 0.62, y: 0.90, radius: 1.0, opacity: 0.46), .init(x: 0.92, y: 0.94, radius: 0.7, opacity: 0.66)
    ]

    var body: some View {
        GeometryReader { proxy in
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

                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 2.4, height: 2.4)
                    .position(x: proxy.size.width * 0.78, y: proxy.size.height * 0.44)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ContentView()
}
