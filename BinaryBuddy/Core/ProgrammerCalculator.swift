import Foundation

public enum ProgrammerCalculatorError: LocalizedError, Equatable {
    case emptyInput
    case invalidNumber
    case valueOutOfRange

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Enter a value."
        case .invalidNumber:
            return "Invalid number for selected base."
        case .valueOutOfRange:
            return "Value does not fit in selected bit width."
        }
    }
}

public struct ProgrammerCalculator {
    public init() {}

    public func convert(
        input: String,
        base: NumberBase,
        bitWidth: BitWidth
    ) throws -> ProgrammerCalculatorResult {
        let cleanedInput = clean(input, for: base)

        guard !cleanedInput.isEmpty else {
            throw ProgrammerCalculatorError.emptyInput
        }

        guard let parsedValue = UInt64(cleanedInput, radix: base.radix) else {
            throw ProgrammerCalculatorError.invalidNumber
        }

        guard parsedValue <= bitWidth.maxUnsignedValue else {
            throw ProgrammerCalculatorError.valueOutOfRange
        }

        let maskedValue = parsedValue & bitWidth.maxUnsignedValue

        return ProgrammerCalculatorResult(
            rawValue: maskedValue,
            bitWidth: bitWidth,
            decimalText: String(maskedValue),
            hexText: formatHex(maskedValue, bitWidth: bitWidth),
            binaryText: formatBinary(maskedValue, bitWidth: bitWidth),
            octalText: formatOctal(maskedValue),
            signedDecimalText: formatSignedDecimal(maskedValue, bitWidth: bitWidth)
        )
    }

    private func clean(_ input: String, for base: NumberBase) -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "_", with: "")
        value = value.replacingOccurrences(of: " ", with: "")

        switch base {
        case .hexadecimal:
            if value.lowercased().hasPrefix("0x") {
                value.removeFirst(2)
            }
        case .binary:
            if value.lowercased().hasPrefix("0b") {
                value.removeFirst(2)
            }
        case .octal:
            if value.lowercased().hasPrefix("0o") {
                value.removeFirst(2)
            }
        case .decimal:
            break
        }

        return value
    }

    private func formatHex(_ value: UInt64, bitWidth: BitWidth) -> String {
        let raw = String(value, radix: 16, uppercase: true)
        let padded = raw.leftPadded(toLength: bitWidth.hexDigitCount, with: "0")
        return "0x\(group(padded, size: 4))"
    }

    private func formatBinary(_ value: UInt64, bitWidth: BitWidth) -> String {
        let raw = String(value, radix: 2)
        let padded = raw.leftPadded(toLength: bitWidth.rawValue, with: "0")
        return "0b\(group(padded, size: 4))"
    }

    private func formatOctal(_ value: UInt64) -> String {
        "0o\(String(value, radix: 8))"
    }

    private func formatSignedDecimal(_ value: UInt64, bitWidth: BitWidth) -> String {
        let signBit = UInt64(1) << UInt64(bitWidth.rawValue - 1)
        let fullRange = bitWidth.rawValue == 64 ? nil : UInt64(1) << UInt64(bitWidth.rawValue)

        if value & signBit == 0 {
            return String(value)
        }

        if bitWidth == .bit64 {
            let signed = Int64(bitPattern: value)
            return String(signed)
        }

        guard let range = fullRange else {
            return String(value)
        }

        let signedValue = Int64(value) - Int64(range)
        return String(signedValue)
    }

    private func group(_ text: String, size: Int) -> String {
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
}

private extension String {
    func leftPadded(toLength length: Int, with character: Character) -> String {
        guard count < length else { return self }
        return String(repeating: String(character), count: length - count) + self
    }
}
