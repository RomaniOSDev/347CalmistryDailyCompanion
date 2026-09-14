import SwiftUI

struct LeafRatingRow: View {
    let value: Int
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    onSelect(index == value ? 0 : index)
                } label: {
                    Image(systemName: index <= value ? "leaf.fill" : "leaf")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(index)")
            }
        }
    }
}

struct ServingFactorPicker: View {
    @Binding var factor: Double

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ServingScale.factors, id: \.self) { value in
                Button {
                    factor = value
                } label: {
                    Text(ServingScale.label(for: value))
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(factor == value ? Palette.surface : Palette.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(factor == value ? Palette.primary : Palette.surface)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Palette.primary.opacity(0.28), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct StepCheckRow: View {
    let index: Int
    let text: String
    let isChecked: Bool
    var large: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: large ? 28 : 18, weight: .semibold))
                    .foregroundColor(Palette.primary)
                    .padding(.top, 2)
                Text("\(index + 1). \(text)")
                    .font(.system(large ? .title3 : .body, design: .rounded).weight(large ? .bold : .regular))
                    .foregroundColor(isChecked ? Palette.accent.opacity(0.7) : (large ? Palette.primary : Palette.accent))
                    .strikethrough(isChecked, color: Palette.accent.opacity(0.55))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}
