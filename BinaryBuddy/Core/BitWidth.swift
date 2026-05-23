import Foundation

public enum BitWidth: Int, CaseIterable, Identifiable {
    case bit8 = 8
    case bit16 = 16
    case bit32 = 32
    case bit64 = 64

    public var id: Int { rawValue }

    public var label: String {
        "\(rawValue)-bit"
    }

    public var maxUnsignedValue: UInt64 {
        switch self {
        case .bit8:
            return UInt64(UInt8.max)
        case .bit16:
            return UInt64(UInt16.max)
        case .bit32:
            return UInt64(UInt32.max)
        case .bit64:
            return UInt64.max
        }
    }

    public var hexDigitCount: Int {
        rawValue / 4
    }
}
