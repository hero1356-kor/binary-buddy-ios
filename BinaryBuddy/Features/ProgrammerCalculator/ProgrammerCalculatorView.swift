import SwiftUI

struct ProgrammerCalculatorView: View {
    @State private var inputText: String = "1234"
    @State private var selectedBase: NumberBase = .decimal
    @State private var selectedBitWidth: BitWidth = .bit16
    @State private var result: ProgrammerCalculatorResult?
    @State private var errorMessage: String?

    private let calculator = ProgrammerCalculator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    inputSection
                    optionSection
                    resultSection
                }
                .padding()
            }
            .navigationTitle("BinaryBuddy")
            .onAppear(perform: updateResult)
            .onChange(of: inputText) { _, _ in updateResult() }
            .onChange(of: selectedBase) { _, newBase in
                if inputText.isEmpty {
                    inputText = newBase.placeholder
                }
                updateResult()
            }
            .onChange(of: selectedBitWidth) { _, _ in updateResult() }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input")
                .font(.headline)

            TextField(selectedBase.placeholder, text: $inputText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(.title2, design: .monospaced))
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var optionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)

            Picker("Base", selection: $selectedBase) {
                ForEach(NumberBase.allCases) { base in
                    Text(base.rawValue).tag(base)
                }
            }
            .pickerStyle(.segmented)

            Picker("Width", selection: $selectedBitWidth) {
                ForEach(BitWidth.allCases) { width in
                    Text(width.label).tag(width)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else if let result {
            VStack(alignment: .leading, spacing: 12) {
                Text("Result")
                    .font(.headline)

                OutputRow(title: "DEC", value: result.decimalText)
                OutputRow(title: "SIGNED", value: result.signedDecimalText)
                OutputRow(title: "HEX", value: result.hexText)
                OutputRow(title: "BIN", value: result.binaryText)
                OutputRow(title: "OCT", value: result.octalText)
            }
        }
    }

    private func updateResult() {
        do {
            result = try calculator.convert(
                input: inputText,
                base: selectedBase,
                bitWidth: selectedBitWidth
            )
            errorMessage = nil
        } catch let error as ProgrammerCalculatorError {
            result = nil
            errorMessage = error.errorDescription
        } catch {
            result = nil
            errorMessage = "Unknown error."
        }
    }
}

private struct OutputRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Copy") {
                    UIPasteboard.general.string = value
                }
                .font(.caption)
            }

            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ProgrammerCalculatorView()
}
