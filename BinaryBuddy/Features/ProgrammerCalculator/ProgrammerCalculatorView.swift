import SwiftUI

struct ProgrammerCalculatorView: View {
    @State private var decimalText: String = "1234"
    @State private var hexText: String = "0x04D2"
    @State private var binaryText: String = "0b0000_0100_1101_0010"

    @State private var selectedBitWidth: BitWidth = .bit16
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
                    VStack(alignment: .leading, spacing: 12) {
                        headerSection
                        controlSection
                        inputSection
                        if let errorMessage {
                            errorSection(errorMessage)
                        }
                        bitViewSection
                        keypadSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Programmer Calculator")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 6)
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BIT WIDTH")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

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
        .padding(.vertical, 12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var inputSection: some View {
        VStack(spacing: 0) {
            EditableBaseRow(
                base: .decimal,
                title: "DEC",
                text: decimalText,
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
        VStack(alignment: .leading, spacing: 10) {
            Text("BIT VIEW (\(selectedBitWidth.rawValue)-bit)")
                .font(.headline)
                .foregroundStyle(.white)

            let bits = bitCells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 8), spacing: 5) {
                ForEach(bits) { bit in
                    Text(String(bit.value))
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 29)
                        .frame(maxWidth: .infinity)
                        .background(bitBackground(for: bit))
                        .foregroundStyle(bit.isEnabled ? .white : Color.white.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .onTapGesture {
                            toggleBit(bit)
                        }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var keypadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(activeBase.rawValue) KEYPAD")
                .font(.headline)
                .foregroundStyle(.white)

            operationRow

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(keypadKeys) { key in
                    if let title = key.title {
                        let isEnabled = isKeyEnabled(title)

                        Button {
                            handleKeypadInput(title)
                        } label: {
                            Text(title)
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.semibold)
                                .frame(height: 40)
                                .frame(maxWidth: .infinity)
                                .background(keypadBackground(for: title, isEnabled: isEnabled))
                                .foregroundStyle(keypadForeground(isEnabled: isEnabled))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!isEnabled)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var operationRow: some View {
        HStack(spacing: 8) {
            ForEach(CalculatorOperator.allCases) { operation in
                let isEnabled = operation != .equals || pendingOperator != nil

                Button {
                    handleOperationInput(operation)
                } label: {
                    Text(operation.symbol)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                        .background(operationBackground(for: operation, isEnabled: isEnabled))
                        .foregroundStyle(isEnabled ? .white : Color.white.opacity(0.26))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
            }
        }
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
            "7", "8", "9", "⌫",
            "4", "5", "6", "AC",
            "1", "2", "3", "0",
            "A", "B", "C", "D",
            "E", "F", nil, nil
        ].enumerated().map { offset, title in
            KeypadKey(index: offset, title: title)
        }
    }

    private func isKeyEnabled(_ key: String) -> Bool {
        if key == "AC" || key == "⌫" {
            return true
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
        case "AC", "⌫":
            return Color.white.opacity(0.20)
        default:
            return Color.white.opacity(0.11)
        }
    }

    private func keypadForeground(isEnabled: Bool) -> Color {
        isEnabled ? .white : Color.white.opacity(0.26)
    }

    private func operationBackground(for operation: CalculatorOperator, isEnabled: Bool) -> Color {
        guard isEnabled else {
            return Color.white.opacity(0.04)
        }

        if operation == pendingOperator || operation == .equals {
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
        switch key {
        case "AC":
            clearAll()
        case "⌫":
            deleteLastInput()
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
            return decimalText
        case .hexadecimal:
            return hexText
        case .binary:
            return binaryText
        }
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
            if base != .hexadecimal || shouldUpdateSource { hexText = result.hexText }
            if base != .binary || shouldUpdateSource { binaryText = result.binaryText }
        } catch let error as ProgrammerCalculatorError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unknown error."
        }
    }

}

private enum CalculatorOperator: String, CaseIterable, Identifiable {
    case add
    case subtract
    case multiply
    case divide
    case equals

    var id: String { rawValue }

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
