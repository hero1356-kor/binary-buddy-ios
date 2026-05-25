import Foundation

public enum NumberBase: String, CaseIterable, Identifiable, Hashable {
    case decimal = "DEC"
    case hexadecimal = "HEX"
    case binary = "BIN"

    public var id: String { rawValue }

    public var radix: Int {
        switch self {
        case .decimal:
            return 10
        case .hexadecimal:
            return 16
        case .binary:
            return 2
        }
    }

    public var placeholder: String {
        switch self {
        case .decimal:
            return "1234"
        case .hexadecimal:
            return "04D2"
        case .binary:
            return "10011010010"
        }
    }
}
