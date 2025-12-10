//
//  MonthPickerView.swift
//  BudgetSnap
//
//  View for selecting month/year
//

import SwiftUI

struct MonthPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMonthYear: String

    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Month",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()

                Button("Done") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM"
                    selectedMonthYear = formatter.string(from: selectedDate)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM"
                if let date = formatter.date(from: selectedMonthYear) {
                    selectedDate = date
                }
            }
        }
    }
}

#Preview {
    MonthPickerView(selectedMonthYear: .constant(Budget.currentMonthYear()))
}
