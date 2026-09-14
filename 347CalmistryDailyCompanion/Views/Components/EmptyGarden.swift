import SwiftUI

struct EmptyGarden: View {
    let title: String
    let systemImage: String
    var message: String? = nil

    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(Palette.primary)

                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)

                if let message, !message.isEmpty {
                    Text(message)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Palette.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
    }
}
