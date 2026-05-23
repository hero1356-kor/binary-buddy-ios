import XCTest
@testable import BinaryBuddy

final class ProgrammerCalculatorTests: XCTestCase {
    private let calculator = ProgrammerCalculator()

    func testDecimalToHexAndBinary() throws {
        let result = try calculator.convert(
            input: "1234",
            base: .decimal,
            bitWidth: .bit16
        )

        XCTAssertEqual(result.decimalText, "1234")
        XCTAssertEqual(result.hexText, "0x04D2")
        XCTAssertEqual(result.binaryText, "0b0000_0100_1101_0010")
    }

    func testHexPrefixInput() throws {
        let result = try calculator.convert(
            input: "0xFF",
            base: .hexadecimal,
            bitWidth: .bit8
        )

        XCTAssertEqual(result.decimalText, "255")
        XCTAssertEqual(result.hexText, "0xFF")
        XCTAssertEqual(result.binaryText, "0b1111_1111")
    }

    func testBinaryPrefixInput() throws {
        let result = try calculator.convert(
            input: "0b1010",
            base: .binary,
            bitWidth: .bit8
        )

        XCTAssertEqual(result.decimalText, "10")
        XCTAssertEqual(result.hexText, "0x0A")
        XCTAssertEqual(result.binaryText, "0b0000_1010")
    }

    func testValueOutOfRange() {
        XCTAssertThrowsError(
            try calculator.convert(
                input: "256",
                base: .decimal,
                bitWidth: .bit8
            )
        )
    }
}
