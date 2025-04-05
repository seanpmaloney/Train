import SwiftUI

enum NumberPadMode {
    case weight
    case reps
}

struct CustomNumberPadView: View {
    let title: String
    let mode: NumberPadMode
    let onDone: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var inputString: String = "0"
    
    private let quickAddValues = [2.5, 5.0, 10.0, 25.0, 45.0]
    
    init(title: String, initialValue: Double, mode: NumberPadMode, onDone: @escaping (Double) -> Void) {
        self.title = title
        self.mode = mode
        self.onDone = onDone
        _inputString = State(initialValue: CustomNumberPadView.formatInitialValue(initialValue))
    }
    
    private static func formatInitialValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(value)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Main content
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(title)
                            .font(.headline)
                        Spacer()
                        Text(formattedValue)
                            .font(.system(size: 34, weight: .medium, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .frame(width: 120, alignment: .trailing)
                    }
                    .padding()
                    .background(AppStyle.Colors.surface)
                    
                    // Quick-add buttons for weight mode
                    if mode == .weight {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickAddValues, id: \.self) { value in
                                    Button(action: {
                                        addValue(value)
                                    }) {
                                        Text("+\(value == 2.5 ? "2.5" : String(Int(value)))")
                                            .font(.system(.body, design: .rounded))
                                            .foregroundColor(AppStyle.Colors.textPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(AppStyle.Colors.surface)
                                            )
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    // Number pad
                    VStack(spacing: 1) {
                        ForEach(0..<3) { row in
                            HStack(spacing: 1) {
                                ForEach(1...3, id: \.self) { col in
                                    numberButton(number: row * 3 + col)
                                }
                            }
                        }
                        
                        // Bottom row
                        HStack(spacing: 1) {
                            // Empty space
                            AppStyle.Colors.surface
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                            
                            numberButton(number: 0)
                            
                            // Backspace
                            Button(action: backspace) {
                                Image(systemName: "delete.left.fill")
                                    .font(.title2)
                                    .foregroundColor(AppStyle.Colors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(AppStyle.Colors.surface)
                            }
                        }
                    }
                }
                
                // Spacer to push content up and done button down
                Spacer(minLength: 0)
                
                // Done button
                Button(action: {
                    if let value = Double(inputString) {
                        onDone(value)
                    }
                    dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppStyle.Colors.primary)
                }
            }
            .frame(maxHeight: geometry.size.height)
        }
        .background(AppStyle.Colors.background)
    }
    
    private var formattedValue: String {
        // If the value has no decimal part, show as integer
        if let value = Double(inputString),
           value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return inputString
    }
    
    private func numberButton(number: Int) -> some View {
        Button(action: {
            appendDigit(number)
        }) {
            Text(String(number))
                .font(.title)
                .foregroundColor(AppStyle.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppStyle.Colors.surface)
        }
    }
    
    private func appendDigit(_ digit: Int) {
        // If current input is "0", replace it
        if inputString == "0" {
            inputString = String(digit)
            return
        }
        
        // Only allow up to 3 digits
        if inputString.count < 3 {
            inputString += String(digit)
            
            // Ensure we don't exceed 999
            if let value = Double(inputString), value > 999 {
                inputString = "999"
            }
        }
    }
    
    private func backspace() {
        inputString = String(inputString.dropLast())
        if inputString.isEmpty || inputString == "0" {
            inputString = "0"
        }
    }
    
    private func addValue(_ value: Double) {
        if let current = Double(inputString) {
            let newValue = current + value
            
            // Format the result based on whether it has a decimal part
            if newValue.truncatingRemainder(dividingBy: 1) == 0 {
                inputString = String(Int(min(newValue, 999)))
            } else {
                inputString = String(format: "%.1f", min(newValue, 999))
            }
        }
    }
}

#Preview {
    ZStack {
        AppStyle.Colors.background.ignoresSafeArea()
        CustomNumberPadView(
            title: "Weight",
            initialValue: 135,
            mode: .weight
        ) { newValue in
            print("New value: \(newValue)")
        }
    }
    .preferredColorScheme(.dark)
} 
