import XCTest
@testable import BinaryBuddy

final class ProgrammerCalculatorTests: XCTestCase {
    private let calculator = ProgrammerCalculator()
    private let i2cConverter = I2C32BitLittleEndianConverter()

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
        XCTAssertEqual(result.signedDecimalText, "-1")
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

    func testValueIsMaskedToSelectedWidth() throws {
        let result = try calculator.convert(
            input: "256",
            base: .decimal,
            bitWidth: .bit8
        )

        XCTAssertEqual(result.decimalText, "0")
        XCTAssertEqual(result.hexText, "0x00")
        XCTAssertEqual(result.binaryText, "0b0000_0000")
    }

    func testNegativeDecimalInputUsesBitPattern() throws {
        let result = try calculator.convert(
            input: "-1",
            base: .decimal,
            bitWidth: .bit16
        )

        XCTAssertEqual(result.decimalText, "65535")
        XCTAssertEqual(result.hexText, "0xFFFF")
        XCTAssertEqual(result.signedDecimalText, "-1")
    }

    func testAdditionWrapsToSelectedWidth() throws {
        let result = try calculator.evaluate(
            left: 255,
            right: 1,
            operation: .add,
            bitWidth: .bit8
        )

        XCTAssertEqual(result, 0)
    }

    func testSubtractionWrapsToSelectedWidth() throws {
        let result = try calculator.evaluate(
            left: 0,
            right: 1,
            operation: .subtract,
            bitWidth: .bit8
        )

        XCTAssertEqual(result, 255)
    }

    func testDivisionByZeroThrows() {
        XCTAssertThrowsError(
            try calculator.evaluate(
                left: 10,
                right: 0,
                operation: .divide,
                bitWidth: .bit16
            )
        ) { error in
            XCTAssertEqual(error as? ProgrammerCalculatorError, .divisionByZero)
        }
    }

    func testI2CLittleEndianHexBytesDecodeToBinary32() throws {
        let result = try i2cConverter.decodeLittleEndianHexBytes("78 56 34 12")

        XCTAssertEqual(result.hexText, "0x12345678")
        XCTAssertEqual(result.binaryText, "00010010001101000101011001111000")
        XCTAssertEqual(result.littleEndianHexBytesText, "78 56 34 12")
    }

    func testI2CHexBytePrefixesAreSupported() throws {
        let result = try i2cConverter.decodeLittleEndianHexBytes("0x78 0x56 0x34 0x12")

        XCTAssertEqual(result.hexText, "0x12345678")
    }

    func testI2CBinary32DecodesToLittleEndianHexBytes() throws {
        let result = try i2cConverter.decodeBinary32("00010010001101000101011001111000")

        XCTAssertEqual(result.hexText, "0x12345678")
        XCTAssertEqual(result.littleEndianHexBytesText, "78 56 34 12")
    }

    func testI2CRejectsNon32BitBinaryInput() {
        XCTAssertThrowsError(try i2cConverter.decodeBinary32("1010")) { error in
            XCTAssertEqual(error as? I2C32BitConversionError, .invalidBinaryBitCount)
        }
    }
}
