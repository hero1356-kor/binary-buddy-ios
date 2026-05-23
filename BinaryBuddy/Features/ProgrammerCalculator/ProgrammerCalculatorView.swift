import SwiftUI
import UIKit

struct ProgrammerCalculatorView: View {
    @State private var decimalText: String = "1234"
    @State private var hexText: String = "0x04D2"
    @State private var binaryText: String = "0b0000_0100_1101_0010"
    @State private var octalText: String = "0o2322"

    @State private var selectedBitWidth: BitWidth = .bit16
    @State private var isSignedMode: Bool = false
    @State private var signedDecimalText: String = "1234"
    @State private var errorMessage: String?
    @State private var activeBase: NumberBase = .decimal
    @State private var isSyncingFields = false

    private let calculator = ProgrammerCalculator()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        headerSection
                        controlSection
                        inputSection
                        if let errorMessage {
                            errorSection(errorMessage)
                        }
                        signedSection
                        bitViewSection
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            sync(from: .decimal, input: decimalText)
        }
        .onChange(of: decimalText) { newValue in
            syncIfNeeded(from: .decimal, input: newValue)
        }
        .onChange(of: hexText) { newValue in
            syncIfNeeded(from: .hexadecimal, input: newValue)
        }
        .onChange(of: binaryText) { newValue in
            syncIfNeeded(from: .binary, input: newValue)
        }
        .onChange(of: octalText) { newValue in
            syncIfNeeded(from: .octal, input: newValue)
        }
        .onChange(of: selectedBitWidth) { _ in
            syncFromActiveBase()
        }
        .onChange(of: isSignedMode) { _ in
            syncFromActiveBase()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BinaryBuddy")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Programmer Calculator")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 18)
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
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

            VStack(alignment: .leading, spacing: 8) {
                Text("MODE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Picker("Mode", selection: $isSignedMode) {
                    Text("Unsigned").tag(false)
                    Text("Signed").tag(true)
                }
                .pickerStyle(.segmented)
                .tint(.orange)
            }
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var inputSection: some View {
        VStack(spacing: 0) {
            EditableBaseRow(title: "DEC", text: $decimalText, isActive: activeBase == .decimal)
            divider
            EditableBaseRow(title: "HEX", text: $hexText, isActive: activeBase == .hexadecimal)
            divider
            EditableBaseRow(title: "BIN", text: $binaryText, isActive: activeBase == .binary)
            divider
            EditableBaseRow(title: "OCT", text: $octalText, isActive: activeBase == .octal)
        }
        .padding(.vertical, 6)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var signedSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SIGNED")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text("\(selectedBitWidth.rawValue)-bit interpretation")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(signedDecimalText)
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(isSignedMode ? .orange : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                copyButton(signedDecimalText)
            }
            .padding(16)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var bitViewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BIT VIEW (\(selectedBitWidth.rawValue)-bit)")
                .font(.headline)
                .foregroundStyle(.white)

            let bits = bitCharacters
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 8), spacing: 6) {
                ForEach(Array(bits.enumerated()), id: \.offset) { _, bit in
                    Text(String(bit))
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 32)
                        .frame(maxWidth: .infinity)
                        .background(bit == "1" ? Color.orange : Color.white.opacity(0.12))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var bitCharacters: [Character] {
        binaryText
            .replacingOccurrences(of: "0b", with: "")
            .replacingOccurrences(of: "_", with: "")
            .map { $0 }
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
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func syncIfNeeded(from base: NumberBase, input: String) {
        guard !isSyncingFields else { return }
        sync(from: base, input: input)
    }

    private func syncFromActiveBase() {
        let input: String
        switch activeBase {
        case .decimal:
            input = decimalText
        case .hexadecimal:
            input = hexText
        case .binary:
            input = binaryText
        case .octal:
            input = octalText
        }
        sync(from: activeBase, input: input)
    }

    private func sync(from base: NumberBase, input: String) {
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
            signedDecimalText = result.signedDecimalText

            if base != .decimal { decimalText = result.decimalText }
            if base != .hexadecimal { hexText = result.hexText }
            if base != .binary { binaryText = result.binaryText }
            if base != .octal { octalText = result.octalText }
        } catch let error as ProgrammerCalculatorError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unknown error."
        }
    }

    private func copyButton(_ value: String) -> some View {
        Button {
            UIPasteboard.general.string = value
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.body)
                .foregroundStyle(.orange)
        }
        .buttonStyle(.plain)
    }
}

private struct EditableBaseRow: View {
    let title: String
    @Binding var text: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 44, alignment: .leading)

            TextField("0", text: $text)
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.vertical, 10)

            Image(systemName: isActive ? "circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(isActive ? .orange : .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    ProgrammerCalculatorView()
}
