import SwiftUI
import UIKit

struct BinaryBuddyRootView: View {
    @State private var selectedTab: BinaryBuddyTab = .calculator

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                persistentTab(.calculator) {
                    ProgrammerCalculatorView()
                }

                persistentTab(.qFormat) {
                    QFormatDraftView()
                }

                persistentTab(.i2c) {
                    I2CToolView()
                }
            }

            BottomModeSwitcher(selection: $selectedTab)
                .padding(.bottom, 4)
        }
        .background(Color.black)
        .tint(.orange)
        .preferredColorScheme(.dark)
    }

    private func persistentTab<Content: View>(
        _ tab: BinaryBuddyTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
            .zIndex(selectedTab == tab ? 1 : 0)
    }
}

private enum BinaryBuddyTab {
    case calculator
    case qFormat
    case i2c
}

private struct BottomModeSwitcher: View {
    @Binding var selection: BinaryBuddyTab

    var body: some View {
        HStack(spacing: 4) {
            modeButton(
                tab: .calculator,
                title: "Calculator",
                systemImage: "number"
            )

            modeButton(
                tab: .qFormat,
                title: "Q-Format",
                systemImage: "slider.horizontal.3"
            )

            modeButton(
                tab: .i2c,
                title: "I2C",
                systemImage: "arrow.left.arrow.right"
            )
        }
        .padding(4)
        .frame(width: 276)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
    }

    private func modeButton(tab: BinaryBuddyTab, title: String, systemImage: String) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))

                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 84, height: 48)
            .foregroundStyle(selection == tab ? .orange : .white)
            .background(selection == tab ? Color.white.opacity(0.16) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ProgrammerCalculatorView: View {
    @State private var decimalText: String = "0"
    @State private var signedDecimalText: String = "0"
    @State private var hexText: String = "0x0000"
    @State private var binaryText: String = "0b0000_0000_0000_0000"

    @State private var selectedBitWidth: BitWidth = .bit16
    @State private var numberInterpretation: NumberInterpretation = .unsigned
    @State private var errorMessage: String?
    @State private var activeBase: NumberBase = .decimal
    @State private var isSyncingFields = false
    @State private var pendingValue: UInt64?
    @State private var pendingOperator: CalculatorOperator?
    @State private var isEnteringNewOperand = false

    private let calculator = ProgrammerCalculator()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 7) {
                        titleSection
                        controlSection
                        inputSection
                        if let errorMessage {
                            errorSection(errorMessage)
                        }
                        bitViewSection
                        keypadSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 0)
                    .padding(.bottom, contentBottomPadding)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            sync(from: .decimal, input: decimalText)
        }
        .onChange(of: selectedBitWidth) {
            syncFromActiveBase()
        }
    }

    private var titleSection: some View {
        Text("Programmer Calculator")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.72))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.top, 2)
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Picker("Number Interpretation", selection: $numberInterpretation) {
                    ForEach(NumberInterpretation.allCases) { interpretation in
                        Text(interpretation.title).tag(interpretation)
                    }
                }
                .pickerStyle(.segmented)
                .tint(.orange)

                Picker("Bit Width", selection: $selectedBitWidth) {
                    ForEach(BitWidth.allCases) { width in
                        Text(width.rawValue.description).tag(width)
                    }
                }
                .pickerStyle(.segmented)
                .tint(.orange)
            }

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var inputSection: some View {
        VStack(spacing: 0) {
            EditableBaseRow(
                base: .decimal,
                title: "DEC",
                text: decimalDisplayText,
                isActive: activeBase == .decimal,
                onSelect: { activeBase = .decimal }
            )
            divider
            EditableBaseRow(
                base: .hexadecimal,
                title: "HEX",
                text: hexText,
                isActive: activeBase == .hexadecimal,
                onSelect: { activeBase = .hexadecimal }
            )
            divider
            EditableBaseRow(
                base: .binary,
                title: "BIN",
                text: binaryText,
                isActive: activeBase == .binary,
                onSelect: { activeBase = .binary }
            )
        }
        .padding(.vertical, 2)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var bitViewSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            let bits = bitCells
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: bitGridColumnSpacing), count: 8),
                spacing: bitGridRowSpacing
            ) {
                ForEach(bits) { bit in
                    VStack(spacing: 1) {
                        Text(bit.position.description)
                            .font(.system(size: bitPositionFontSize, weight: .semibold, design: .monospaced))
                            .foregroundStyle(bit.isEnabled ? Color.white.opacity(0.48) : Color.white.opacity(0.18))

                        Text(String(bit.value))
                            .font(.system(size: bitValueFontSize, weight: .medium, design: .monospaced))
                            .foregroundStyle(bit.isEnabled ? .white : Color.white.opacity(0.28))
                    }
                        .frame(height: bitCellHeight)
                        .frame(maxWidth: .infinity)
                        .background(bitBackground(for: bit))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .onTapGesture {
                            toggleBit(bit)
                        }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var contentBottomPadding: CGFloat {
        selectedBitWidth == .bit64 ? 118 : 82
    }

    private var bitCellHeight: CGFloat {
        selectedBitWidth == .bit64 ? 27 : 31
    }

    private var bitGridRowSpacing: CGFloat {
        selectedBitWidth == .bit64 ? 3 : 4
    }

    private var bitGridColumnSpacing: CGFloat {
        selectedBitWidth == .bit64 ? 4 : 5
    }

    private var bitPositionFontSize: CGFloat {
        selectedBitWidth == .bit64 ? 6 : 7
    }

    private var bitValueFontSize: CGFloat {
        selectedBitWidth == .bit64 ? 15 : 17
    }

    private var keypadButtonHeight: CGFloat {
        selectedBitWidth == .bit64 ? 33 : 36
    }

    private var keypadRowSpacing: CGFloat {
        selectedBitWidth == .bit64 ? 4 : 5
    }

    private var keypadVerticalPadding: CGFloat {
        selectedBitWidth == .bit64 ? 8 : 10
    }

    private var keypadFontSize: CGFloat {
        selectedBitWidth == .bit64 ? 22 : 24
    }

    private var keypadSection: some View {
        VStack(alignment: .leading, spacing: keypadRowSpacing) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: keypadRowSpacing
            ) {
                ForEach(keypadKeys) { key in
                    if let title = key.title {
                        let isEnabled = isKeyEnabled(title)

                        Button {
                            handleKeypadInput(title)
                        } label: {
                            Text(title)
                                .font(.system(size: keypadFontSize, weight: .semibold, design: .rounded))
                                .fontWeight(.semibold)
                                .frame(height: keypadButtonHeight)
                                .frame(maxWidth: .infinity)
                                .background(keypadBackground(for: title, isEnabled: isEnabled))
                                .foregroundStyle(keypadForeground(isEnabled: isEnabled))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!isEnabled)
                    } else {
                        Color.clear
                            .frame(height: keypadButtonHeight)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, keypadVerticalPadding)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var bitCells: [BitCell] {
        let displayBitCount = max(selectedBitWidth.rawValue, 32)
        let disabledPrefixBitCount = displayBitCount - selectedBitWidth.rawValue
        let rawBits = binaryText
            .replacingOccurrences(of: "0b", with: "")
            .replacingOccurrences(of: "_", with: "")
        let paddedBits = String(repeating: "0", count: max(0, displayBitCount - rawBits.count)) + rawBits

        return Array(paddedBits.suffix(displayBitCount).enumerated()).map { offset, value in
            BitCell(
                index: offset,
                position: displayBitCount - offset - 1,
                value: value,
                isEnabled: offset >= disabledPrefixBitCount
            )
        }
    }

    private func bitBackground(for bit: BitCell) -> Color {
        guard bit.isEnabled else {
            return Color.white.opacity(0.04)
        }

        return bit.value == "1" ? Color.orange : Color.white.opacity(0.12)
    }

    private func toggleBit(_ bit: BitCell) {
        guard bit.isEnabled else { return }

        resetPendingOperation()

        var values = bitCells.map(\.value)
        values[bit.index] = bit.value == "1" ? "0" : "1"

        let enabledBits = String(values.suffix(selectedBitWidth.rawValue))
        sync(from: .binary, input: enabledBits, shouldUpdateSource: true)
    }

    private var keypadKeys: [KeypadKey] {
        [
            "7", "8", "9", "÷",
            "4", "5", "6", "×",
            "1", "2", "3", "-",
            "A", "0", "B", "+",
            "C", "D", "E", "=",
            "F", "AC", "⌫", "±"
        ].enumerated().map { offset, title in
            KeypadKey(index: offset, title: title)
        }
    }

    private func isKeyEnabled(_ key: String) -> Bool {
        if key == "AC" || key == "⌫" {
            return true
        }

        if key == "±" {
            return numberInterpretation == .signed && activeBase == .decimal
        }

        if CalculatorOperator(symbol: key) != nil {
            return key != "=" || pendingOperator != nil
        }

        guard let scalar = key.unicodeScalars.first else {
            return false
        }

        if CharacterSet.decimalDigits.contains(scalar) {
            return Int(key).map { $0 < activeBase.radix } ?? false
        }

        return activeBase == .hexadecimal && ("A"..."F").contains(key)
    }

    private func keypadBackground(for key: String, isEnabled: Bool) -> Color {
        guard isEnabled else {
            return Color.white.opacity(0.04)
        }

        switch key {
        case "+", "-", "×", "÷":
            guard let operation = CalculatorOperator(symbol: key) else {
                return Color.white.opacity(0.11)
            }
            return operationBackground(for: operation)
        case "=":
            return Color.orange.opacity(0.34)
        case "AC", "⌫", "±":
            return Color.white.opacity(0.20)
        default:
            return Color.white.opacity(0.11)
        }
    }

    private func keypadForeground(isEnabled: Bool) -> Color {
        isEnabled ? .white : Color.white.opacity(0.26)
    }

    private func operationBackground(for operation: CalculatorOperator) -> Color {
        if operation == pendingOperator {
            return Color.orange.opacity(0.34)
        }

        return Color.white.opacity(0.14)
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [Color.white.opacity(0.14), Color.white.opacity(0.07)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 1)
            .padding(.leading, 16)
    }

    private func errorSection(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.red)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func handleKeypadInput(_ key: String) {
        if let operation = CalculatorOperator(symbol: key) {
            handleOperationInput(operation)
            return
        }

        switch key {
        case "AC":
            clearAll()
        case "⌫":
            deleteLastInput()
        case "±":
            toggleDecimalSign()
        default:
            appendInput(key)
        }
    }

    private func handleOperationInput(_ operation: CalculatorOperator) {
        if operation == .equals {
            evaluatePendingOperation()
            return
        }

        do {
            let currentValue = try currentRawValue()

            if let pendingValue, let pendingOperator, !isEnteringNewOperand {
                guard let result = evaluate(pendingValue, pendingOperator, currentValue) else {
                    return
                }

                syncRawValue(result)
                self.pendingValue = result & selectedBitWidth.maxUnsignedValue
            } else {
                self.pendingValue = currentValue
            }

            pendingOperator = operation
            isEnteringNewOperand = true
            errorMessage = nil
        } catch let error as ProgrammerCalculatorError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unknown error."
        }
    }

    private func evaluatePendingOperation() {
        guard let pendingValue, let pendingOperator else {
            return
        }

        do {
            let currentValue = try currentRawValue()

            guard let result = evaluate(pendingValue, pendingOperator, currentValue) else {
                return
            }

            syncRawValue(result)
            self.pendingValue = nil
            self.pendingOperator = nil
            isEnteringNewOperand = true
            errorMessage = nil
        } catch let error as ProgrammerCalculatorError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unknown error."
        }
    }

    private func evaluate(
        _ left: UInt64,
        _ operation: CalculatorOperator,
        _ right: UInt64
    ) -> UInt64? {
        guard let arithmeticOperator = operation.arithmeticOperator else {
            return right
        }

        do {
            return try calculator.evaluate(
                left: left,
                right: right,
                operation: arithmeticOperator,
                bitWidth: selectedBitWidth
            )
        } catch let error as ProgrammerCalculatorError {
            errorMessage = error.errorDescription
            return nil
        } catch {
            errorMessage = "Unknown error."
            return nil
        }
    }

    private func currentRawValue() throws -> UInt64 {
        try calculator.convert(
            input: displayText(for: activeBase),
            base: activeBase,
            bitWidth: selectedBitWidth
        ).rawValue
    }

    private func syncRawValue(_ value: UInt64) {
        let maskedValue = value & selectedBitWidth.maxUnsignedValue
        let input = String(maskedValue, radix: activeBase.radix, uppercase: true)
        sync(from: activeBase, input: input, shouldUpdateSource: true)
    }

    private func resetPendingOperation() {
        pendingValue = nil
        pendingOperator = nil
        isEnteringNewOperand = false
    }

    private func clearAll() {
        resetPendingOperation()
        sync(from: activeBase, input: "0", shouldUpdateSource: true)
    }

    private func toggleDecimalSign() {
        guard numberInterpretation == .signed else { return }

        resetPendingOperation()
        activeBase = .decimal

        let input = sanitizedInput(signedDecimalText, for: .decimal)

        if input == "0" || input.isEmpty {
            signedDecimalText = "-"
            decimalText = "0"
            errorMessage = nil
            return
        }

        if input == "-" {
            sync(from: .decimal, input: "0", shouldUpdateSource: true)
        } else if input.hasPrefix("-") {
            sync(from: .decimal, input: String(input.dropFirst()), shouldUpdateSource: true)
        } else {
            sync(from: .decimal, input: "-\(input)", shouldUpdateSource: true)
        }
    }

    private func deleteLastInput() {
        isEnteringNewOperand = false
        var input = sanitizedInput(displayText(for: activeBase), for: activeBase)

        if !input.isEmpty {
            input.removeLast()
        }

        sync(from: activeBase, input: input.isEmpty ? "0" : input, shouldUpdateSource: true)
    }

    private func appendInput(_ character: String) {
        var input = isEnteringNewOperand ? "" : sanitizedInput(displayText(for: activeBase), for: activeBase)
        isEnteringNewOperand = false

        if input == "0" {
            input = ""
        }

        sync(from: activeBase, input: input + character, shouldUpdateSource: true)
    }

    private func displayText(for base: NumberBase) -> String {
        switch base {
        case .decimal:
            return decimalDisplayText
        case .hexadecimal:
            return hexText
        case .binary:
            return binaryText
        }
    }

    private var decimalDisplayText: String {
        numberInterpretation == .signed ? signedDecimalText : decimalText
    }

    private func sanitizedInput(_ text: String, for base: NumberBase) -> String {
        var input = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")

        switch base {
        case .hexadecimal:
            if input.lowercased().hasPrefix("0x") {
                input.removeFirst(2)
            }
        case .binary:
            if input.lowercased().hasPrefix("0b") {
                input.removeFirst(2)
            }
        case .decimal:
            break
        }

        return input
    }

    private func syncFromActiveBase() {
        let input = displayText(for: activeBase)
        sync(from: activeBase, input: input)
    }

    private func sync(
        from base: NumberBase,
        input: String,
        shouldUpdateSource: Bool = false
    ) {
        activeBase = base
        isSyncingFields = true
        defer { isSyncingFields = false }

        do {
            let result = try calculator.convert(
                input: input,
                base: base,
                bitWidth: selectedBitWidth
            )

            errorMessage = nil
            if base != .decimal || shouldUpdateSource { decimalText = result.decimalText }
            signedDecimalText = result.signedDecimalText
            if base != .hexadecimal || shouldUpdateSource { hexText = result.hexText }
            if base != .binary || shouldUpdateSource { binaryText = result.binaryText }
        } catch let error as ProgrammerCalculatorError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unknown error."
        }
    }

}

private enum NumberInterpretation: String, CaseIterable, Identifiable {
    case unsigned
    case signed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unsigned:
            return "Unsigned"
        case .signed:
            return "Signed"
        }
    }
}

private struct QFormatDraftView: View {
    @State private var numberInterpretation: NumberInterpretation = .signed
    @State private var integerBitsText: String = "0"
    @State private var fractionalBitsText: String = "15"
    @State private var realText: String = "0"

    private var sample: QFormatSample {
        QFormatSample(
            realText: realText,
            signBitCount: signBitCount,
            integerBits: integerBitCount,
            fractionalBits: fractionalBitCount
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 13) {
                        header
                        formatControls
                        realInput
                        encodedOutput
                        decodedSummary
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 94)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    dismissKeyboard()
                }
                .fontWeight(.semibold)
            }
        }
        .onChange(of: numberInterpretation) {
            normalizeBitInputs()
        }
        .onChange(of: integerBitsText) {
            normalizeBitInputs()
        }
        .onChange(of: fractionalBitsText) {
            normalizeBitInputs()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Q-Format")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(sample.formatLabel)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(.top, 6)
    }

    private var formatControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Number Interpretation", selection: $numberInterpretation) {
                ForEach(NumberInterpretation.allCases) { interpretation in
                    Text(interpretation.title).tag(interpretation)
                }
            }
            .pickerStyle(.segmented)
            .tint(.orange)

            HStack(spacing: 10) {
                QFormatBitTextField(title: "Integer bits", text: $integerBitsText)
                QFormatBitTextField(title: "Fraction bits", text: $fractionalBitsText)
            }

            HStack(spacing: 8) {
                Text("Total bits")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(totalBitCount)  /  S\(signBitCount) I\(integerBitCount) F\(fractionalBitCount)")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white.opacity(0.72))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(qCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var realInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REAL")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            TextField("0", text: $realText)
                .font(.system(size: 34, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.trailing)
                .keyboardType(.numbersAndPunctuation)
                .foregroundStyle(.white)
                .padding(.vertical, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(qCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var encodedOutput: some View {
        VStack(spacing: 0) {
            QFormatValueRow(title: "RAW", value: sample.rawText)
            qDivider
            QFormatValueRow(title: "HEX", value: sample.hexText)
            qDivider
            QFormatValueRow(title: "BIN", value: sample.binaryText)
        }
        .padding(.vertical, 2)
        .background(qCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var decodedSummary: some View {
        VStack(spacing: 0) {
            QFormatMetricRow(title: "Decoded", value: sample.decodedText)
            qDivider
            QFormatMetricRow(title: "Error", value: sample.errorText)
            qDivider
            QFormatMetricRow(title: "Range", value: sample.rangeText)
            qDivider
            QFormatMetricRow(title: "Step", value: sample.stepText)
        }
        .padding(.vertical, 2)
        .background(qCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var signBitCount: Int {
        numberInterpretation == .signed ? 1 : 0
    }

    private var integerBitCount: Int {
        clampBitInput(integerBitsText, min: 0, max: maxIntegerBits)
    }

    private var fractionalBitCount: Int {
        clampBitInput(fractionalBitsText, min: 0, max: maxFractionalBits)
    }

    private var totalBitCount: Int {
        max(1, signBitCount + integerBitCount + fractionalBitCount)
    }

    private var maxIntegerBits: Int {
        max(0, maxQFormatBits - signBitCount)
    }

    private var maxFractionalBits: Int {
        max(0, maxQFormatBits - signBitCount - integerBitCount)
    }

    private var maxQFormatBits: Int {
        64
    }

    private func normalizeBitInputs() {
        let integer = integerBitCount
        let fraction = fractionalBitCount
        let normalizedInteger = integer.description
        let normalizedFraction = fraction.description

        if integerBitsText != normalizedInteger {
            integerBitsText = normalizedInteger
        }

        if fractionalBitsText != normalizedFraction {
            fractionalBitsText = normalizedFraction
        }

        if numberInterpretation == .unsigned,
           integer == 0,
           fraction == 0 {
            fractionalBitsText = "1"
        }
    }

    private var qDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 1)
            .padding(.leading, 16)
    }

    private var qCardBackground: some ShapeStyle {
        LinearGradient(
            colors: [Color.white.opacity(0.14), Color.white.opacity(0.07)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func clampBitInput(_ text: String, min: Int, max: Int) -> Int {
        let digits = text.filter(\.isNumber)
        let value = Int(digits) ?? min
        return Swift.min(Swift.max(value, min), max)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private struct I2CToolView: View {
    @State private var mode: I2CConversionMode = .littleEndianHexToBinary
    @State private var inputText: String = I2CConversionMode.littleEndianHexToBinary.sampleInput
    @State private var busText: String = "1"
    @State private var addressText: String = "0x50"
    @State private var registerText: String = "0x00"

    private let converter = I2C32BitLittleEndianConverter()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                        modeSelector
                        inputCard
                        outputCard
                        bitViewCard
                        scriptCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 94)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("I2C 32-bit")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(mode.subtitle)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(.top, 6)
    }

    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(I2CConversionMode.allCases) { item in
                Button {
                    switchMode(to: item)
                } label: {
                    Text(item.title)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(mode == item ? .orange : .white)
                        .background(mode == item ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(i2cCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(mode.inputTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            TextField(mode.placeholder, text: $inputText)
                .font(.system(size: mode.inputFontSize, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.trailing)
                .keyboardType(mode.keyboardType)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(i2cCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var outputCard: some View {
        switch conversionResult {
        case .success(let decodedValue):
            VStack(spacing: 0) {
                I2CValueRow(title: "HEX", value: decodedValue.hexText)
                i2cDivider
                I2CValueRow(title: "BIN", value: decodedValue.binaryText)
                i2cDivider
                I2CValueRow(title: "Little Endian", value: decodedValue.littleEndianHexBytesText)
            }
            .padding(.vertical, 2)
            .background(i2cCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        case .failure(let error):
            Text(error.errorDescription ?? "Invalid input.")
                .font(.callout)
                .foregroundStyle(.red)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private var bitViewCard: some View {
        if decodedValue != nil {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 8),
                spacing: 4
            ) {
                ForEach(i2cBitCells) { bit in
                    VStack(spacing: 1) {
                        Text(bit.position.description)
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.48))

                        Text(String(bit.value))
                            .font(.system(size: 17, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .frame(height: 31)
                    .frame(maxWidth: .infinity)
                    .background(bit.value == "1" ? Color.orange : Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .onTapGesture {
                        toggleI2CBit(bit)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(i2cCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var scriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SCRIPT")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                I2CScriptTextField(title: "Bus", text: $busText)
                I2CScriptTextField(title: "Addr", text: $addressText)
                I2CScriptTextField(title: "Reg", text: $registerText)
            }

            VStack(spacing: 0) {
                I2CCommandRow(title: "READ", value: readCommand)
                i2cDivider
                I2CCommandRow(title: "WRITE", value: writeCommand)
            }
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(i2cCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var conversionResult: Result<I2C32BitDecodedValue, I2C32BitConversionError> {
        do {
            switch mode {
            case .littleEndianHexToBinary:
                return .success(try converter.decodeLittleEndianHexBytes(inputText))
            case .binaryToLittleEndianHex:
                return .success(try converter.decodeBinary32(inputText))
            }
        } catch let error as I2C32BitConversionError {
            return .failure(error)
        } catch {
            return .failure(.invalidCharacters)
        }
    }

    private var decodedValue: I2C32BitDecodedValue? {
        try? conversionResult.get()
    }

    private var i2cBitCells: [BitCell] {
        guard let decodedValue else { return [] }

        return Array(decodedValue.binaryText.enumerated()).map { offset, value in
            BitCell(
                index: offset,
                position: 31 - offset,
                value: value,
                isEnabled: true
            )
        }
    }

    private var readCommand: String {
        "i2ctransfer -y \(busArgument) w1@\(addressArgument) \(registerArgument) r4"
    }

    private var writeCommand: String {
        guard let decodedValue else {
            return "Enter valid 32-bit data."
        }

        return "i2ctransfer -y \(busArgument) w5@\(addressArgument) \(registerArgument) \(decodedValue.littleEndianByteArguments)"
    }

    private var busArgument: String {
        scriptArgument(busText, defaultValue: "1")
    }

    private var addressArgument: String {
        scriptArgument(addressText, defaultValue: "0x50")
    }

    private var registerArgument: String {
        scriptArgument(registerText, defaultValue: "0x00")
    }

    private func scriptArgument(_ text: String, defaultValue: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    private func switchMode(to nextMode: I2CConversionMode) {
        guard mode != nextMode else { return }

        let currentValue = decodedValue
        mode = nextMode

        if let currentValue {
            inputText = nextMode.inputText(from: currentValue)
        } else {
            inputText = nextMode.sampleInput
        }
    }

    private func toggleI2CBit(_ bit: BitCell) {
        guard let decodedValue else { return }

        let newValue = decodedValue.value ^ (UInt32(1) << UInt32(bit.position))
        let newDecodedValue = I2C32BitDecodedValue(value: newValue)
        mode = .binaryToLittleEndianHex
        inputText = newDecodedValue.binaryText
    }

    private var i2cDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 1)
            .padding(.leading, 16)
    }

    private var i2cCardBackground: some ShapeStyle {
        LinearGradient(
            colors: [Color.white.opacity(0.14), Color.white.opacity(0.07)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private enum I2CConversionMode: String, CaseIterable, Identifiable {
    case littleEndianHexToBinary
    case binaryToLittleEndianHex

    var id: String { rawValue }

    var title: String {
        switch self {
        case .littleEndianHexToBinary:
            return "Little Endian -> BIN"
        case .binaryToLittleEndianHex:
            return "BIN -> Little Endian"
        }
    }

    var subtitle: String {
        switch self {
        case .littleEndianHexToBinary:
            return "4 bytes Little Endian"
        case .binaryToLittleEndianHex:
            return "32 bits"
        }
    }

    var inputTitle: String {
        switch self {
        case .littleEndianHexToBinary:
            return "Little Endian HEX"
        case .binaryToLittleEndianHex:
            return "BIN"
        }
    }

    var placeholder: String {
        sampleInput
    }

    var sampleInput: String {
        switch self {
        case .littleEndianHexToBinary:
            return "00 00 00 00"
        case .binaryToLittleEndianHex:
            return "00000000000000000000000000000000"
        }
    }

    var inputFontSize: CGFloat {
        switch self {
        case .littleEndianHexToBinary:
            return 26
        case .binaryToLittleEndianHex:
            return 16
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .littleEndianHexToBinary:
            return .asciiCapable
        case .binaryToLittleEndianHex:
            return .numberPad
        }
    }

    func inputText(from decodedValue: I2C32BitDecodedValue) -> String {
        switch self {
        case .littleEndianHexToBinary:
            return decodedValue.littleEndianHexBytesText
        case .binaryToLittleEndianHex:
            return decodedValue.binaryText
        }
    }
}

private struct I2CValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 108, alignment: .leading)

            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct I2CScriptTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            TextField("", text: $text)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .frame(height: 34)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct I2CCommandRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct QFormatBitTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            TextField("0", text: $text)
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .foregroundStyle(.white)
                .frame(height: 38)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct QFormatValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 44, alignment: .leading)

            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct QFormatMetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.55)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct QFormatSample {
    let realText: String
    let signBitCount: Int
    let integerBits: Int
    let fractionalBits: Int

    private var totalBits: Int {
        max(1, signBitCount + integerBits + fractionalBits)
    }

    private var realValue: Double {
        Double(realText) ?? 0
    }

    private var scale: Double {
        pow(2, Double(fractionalBits))
    }

    private var signed: Bool {
        signBitCount > 0
    }

    private var minRaw: Double {
        signed ? -pow(2, Double(totalBits - 1)) : 0
    }

    private var maxRaw: Double {
        signed ? pow(2, Double(totalBits - 1)) - 1 : pow(2, Double(totalBits)) - 1
    }

    private var rawRounded: Double {
        (realValue * scale).rounded(.toNearestOrAwayFromZero)
    }

    private var rawClamped: Double {
        min(max(rawRounded, minRaw), maxRaw)
    }

    private var encodedValue: UInt64 {
        let mask = bitMask

        if signed {
            let signedRaw = Int64(rawClamped)
            return UInt64(bitPattern: signedRaw) & mask
        }

        return uint64Clamped(from: rawClamped) & mask
    }

    private var decodedValue: Double {
        rawClamped / scale
    }

    var formatLabel: String {
        let mode = signed ? "Signed" : "Unsigned"
        return "\(mode) / S\(signBitCount) I\(integerBits) F\(fractionalBits) / \(totalBits)-bit"
    }

    var rawText: String {
        if signed, rawClamped < 0 {
            return "\(Int64(rawClamped))  (\(encodedValue))"
        }

        return encodedValue.description
    }

    var hexText: String {
        let digits = max(1, Int(ceil(Double(totalBits) / 4)))
        let value = String(encodedValue, radix: 16, uppercase: true).leftPaddedForQFormat(toLength: digits, with: "0")
        return "0x\(value)"
    }

    var binaryText: String {
        let raw = String(encodedValue, radix: 2)
        let padded = raw.leftPaddedForQFormat(toLength: totalBits, with: "0")
        return fixedPointGroupedBinary(padded)
    }

    var decodedText: String {
        fixedDecimalFromRaw(rawClamped)
    }

    var errorText: String {
        formatDouble(realValue - decodedValue)
    }

    var rangeText: String {
        "\(minimumText) ~ \(maximumText)"
    }

    var stepText: String {
        Self.fixedPointDecimal(
            magnitude: 1,
            isNegative: false,
            fractionalBits: fractionalBits
        )
    }

    private var minimumText: String {
        guard signed else { return "0" }

        return Self.fixedPointDecimal(
            magnitude: signedMinimumMagnitude,
            isNegative: true,
            fractionalBits: fractionalBits
        )
    }

    private var maximumText: String {
        Self.fixedPointDecimal(
            magnitude: maximumMagnitude,
            isNegative: false,
            fractionalBits: fractionalBits
        )
    }

    private var signedMinimumMagnitude: UInt64 {
        guard signed else { return 0 }

        let shift = max(0, totalBits - 1)
        return UInt64(1) << shift
    }

    private var maximumMagnitude: UInt64 {
        if signed {
            let shift = max(0, totalBits - 1)
            return shift == 0 ? 0 : (UInt64(1) << shift) - 1
        }

        return totalBits == 64 ? UInt64.max : (UInt64(1) << totalBits) - 1
    }

    private var bitMask: UInt64 {
        totalBits == 64 ? UInt64.max : (UInt64(1) << totalBits) - 1
    }

    private func uint64Clamped(from value: Double) -> UInt64 {
        guard value.isFinite, value > 0 else { return 0 }

        if value >= Double(UInt64.max) {
            return UInt64.max
        }

        return UInt64(value)
    }

    private func fixedDecimalFromRaw(_ raw: Double) -> String {
        if raw < 0 {
            return Self.fixedPointDecimal(
                magnitude: UInt64(abs(raw)),
                isNegative: true,
                fractionalBits: fractionalBits
            )
        }

        return Self.fixedPointDecimal(
            magnitude: UInt64(raw),
            isNegative: false,
            fractionalBits: fractionalBits
        )
    }

    private func formatDouble(_ value: Double) -> String {
        guard value.isFinite else { return "0" }

        let places = min(max(fractionalBits, 8), 24)
        let text = String(format: "%.\(places)f", value)
        return Self.trimDecimalZeros(text)
    }

    private static func fixedPointDecimal(
        magnitude: UInt64,
        isNegative: Bool,
        fractionalBits: Int
    ) -> String {
        guard magnitude != 0 else { return "0" }

        var digits = magnitude.description
        if fractionalBits > 0 {
            for _ in 0..<fractionalBits {
                digits = multiplyDecimalString(digits, by: 5)
            }

            if digits.count <= fractionalBits {
                digits = String(repeating: "0", count: fractionalBits - digits.count + 1) + digits
            }

            let splitIndex = digits.index(digits.endIndex, offsetBy: -fractionalBits)
            digits.insert(".", at: splitIndex)
        }

        let trimmed = trimDecimalZeros(digits)
        return isNegative ? "-\(trimmed)" : trimmed
    }

    private static func multiplyDecimalString(_ text: String, by multiplier: Int) -> String {
        var carry = 0
        var result = ""

        for character in text.reversed() {
            let digit = Int(String(character)) ?? 0
            let product = digit * multiplier + carry
            result.insert(Character(String(product % 10)), at: result.startIndex)
            carry = product / 10
        }

        while carry > 0 {
            result.insert(Character(String(carry % 10)), at: result.startIndex)
            carry /= 10
        }

        return result
    }

    private static func trimDecimalZeros(_ text: String) -> String {
        guard text.contains(".") else { return text }

        var result = text
        while result.last == "0" {
            result.removeLast()
        }

        if result.last == "." {
            result.removeLast()
        }

        return result == "-0" ? "0" : result
    }

    private func fixedPointGroupedBinary(_ text: String) -> String {
        let wholeBitCount = signBitCount + integerBits
        let wholeBits = String(text.prefix(wholeBitCount))
        let fractionBits = String(text.dropFirst(wholeBitCount))
        let groupedWhole = groupedFromRight(wholeBits, size: 4)
        let groupedFraction = groupedFromLeft(fractionBits, size: 4)

        guard !groupedFraction.isEmpty else {
            return groupedWhole
        }

        return "\(groupedWhole).\(groupedFraction)"
    }

    private func groupedFromRight(_ text: String, size: Int) -> String {
        guard size > 0, text.count > size else { return text }

        var groups: [String] = []
        var current = ""

        for character in text.reversed() {
            current.insert(character, at: current.startIndex)
            if current.count == size {
                groups.insert(current, at: 0)
                current = ""
            }
        }

        if !current.isEmpty {
            groups.insert(current, at: 0)
        }

        return groups.joined(separator: "_")
    }

    private func groupedFromLeft(_ text: String, size: Int) -> String {
        guard size > 0, text.count > size else { return text }

        var groups: [String] = []
        var current = ""

        for character in text {
            current.append(character)
            if current.count == size {
                groups.append(current)
                current = ""
            }
        }

        if !current.isEmpty {
            groups.append(current)
        }

        return groups.joined(separator: "_")
    }
}

private extension String {
    func leftPaddedForQFormat(toLength length: Int, with character: Character) -> String {
        guard count < length else { return self }
        return String(repeating: String(character), count: length - count) + self
    }
}

private enum CalculatorOperator: String, CaseIterable, Identifiable {
    case add
    case subtract
    case multiply
    case divide
    case equals

    static let arithmeticCases: [CalculatorOperator] = [.add, .subtract, .multiply, .divide]

    var id: String { rawValue }

    init?(symbol: String) {
        switch symbol {
        case "+":
            self = .add
        case "-":
            self = .subtract
        case "×":
            self = .multiply
        case "÷":
            self = .divide
        case "=":
            self = .equals
        default:
            return nil
        }
    }

    var symbol: String {
        switch self {
        case .add:
            return "+"
        case .subtract:
            return "-"
        case .multiply:
            return "×"
        case .divide:
            return "÷"
        case .equals:
            return "="
        }
    }

    var arithmeticOperator: ProgrammerArithmeticOperator? {
        switch self {
        case .add:
            return .add
        case .subtract:
            return .subtract
        case .multiply:
            return .multiply
        case .divide:
            return .divide
        case .equals:
            return nil
        }
    }
}

private struct KeypadKey: Identifiable {
    let index: Int
    let title: String?

    var id: Int { index }
}

private struct BitCell: Identifiable {
    let index: Int
    let position: Int
    let value: Character
    let isEnabled: Bool

    var id: Int { index }
}

private struct EditableBaseRow: View {
    let base: NumberBase
    let title: String
    let text: String
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isActive ? "circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(isActive ? .orange : .secondary)
                .frame(width: 14)

            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 44, alignment: .leading)

            Text(text.isEmpty ? "0" : text)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    ProgrammerCalculatorView()
}
