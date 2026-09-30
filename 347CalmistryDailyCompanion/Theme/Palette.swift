import SwiftUI

enum Palette {
    /// Brand greens / reds (unchanged asset colors)
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")

    /// Readable text & surfaces layered on brand colors
    static let card = Color(red: 0.985, green: 0.975, blue: 0.955)
    static let cardSoft = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let ink = Color(red: 0.09, green: 0.14, blue: 0.08)
    static let muted = Color(red: 0.30, green: 0.36, blue: 0.28)
    static let onPrimary = Color.white
    static let hairline = Color.black.opacity(0.06)
    static let glow = Color.black.opacity(0.22)
}
