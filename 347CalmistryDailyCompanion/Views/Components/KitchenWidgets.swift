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
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(index <= value ? Palette.primary : Palette.muted.opacity(0.55))
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
                        .foregroundColor(factor == value ? Palette.onPrimary : Palette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(factor == value ? Palette.primary : Palette.cardSoft)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(factor == value ? Color.clear : Palette.hairline, lineWidth: 1)
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
                    .foregroundColor(isChecked ? Palette.surface : Palette.primary)
                    .padding(.top, 2)
                Text("\(index + 1). \(text)")
                    .font(.system(large ? .title3 : .body, design: .rounded).weight(large ? .bold : .medium))
                    .foregroundColor(isChecked ? Palette.muted.opacity(0.7) : (large ? Palette.ink : Palette.ink.opacity(0.9)))
                    .strikethrough(isChecked, color: Palette.muted.opacity(0.5))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}
