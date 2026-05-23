import Foundation

public struct ProgrammerCalculatorResult: Equatable {
    public let rawValue: UInt64
    public let bitWidth: BitWidth
    public let decimalText: String
    public let hexText: String
    public let binaryText: String
    public let octalText: String
    public let signedDecimalText: String

    public init(
        rawValue: UInt64,
        bitWidth: BitWidth,
        decimalText: String,
        hexText: String,
        binaryText: String,
        octalText: String,
        signedDecimalText: String
    ) {
        self.rawValue = rawValue
        self.bitWidth = bitWidth
        self.decimalText = decimalText
        self.hexText = hexText
        self.binaryText = binaryText
        self.octalText = octalText
        self.signedDecimalText = signedDecimalText
    }
}
