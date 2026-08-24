import SwiftUI

extension Color {
    /// Used for the filled favorite star. Plain white (the previous color)
    /// has good contrast in dark mode but nearly vanishes against light
    /// mode's light backgrounds; this gold reads clearly in both.
    static let favoriteGold = Color(red: 1.0, green: 0.72, blue: 0.0)
}

extension ShapeStyle where Self == Color {
    /// Lets `.favoriteGold` be used directly in ShapeStyle contexts (e.g.
    /// alongside `.secondary` in a `.foregroundStyle(condition ? .a : .b)`
    /// ternary), the same way SwiftUI exposes `.secondary`/`.blue`/etc.
    static var favoriteGold: Color { Color.favoriteGold }
}
