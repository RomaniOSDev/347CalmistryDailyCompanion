import Foundation

enum ServingScale {
    static let factors: [Double] = [0.5, 1, 2, 4]

    static func label(for factor: Double) -> String {
        if factor == 0.5 { return "½×" }
        if factor == 1 { return "1×" }
        if factor == 2 { return "2×" }
        return "4×"
    }

    static func apply(_ line: String, factor: Double) -> String {
        if factor == 1 { return line }
        guard let regex = try? NSRegularExpression(pattern: #"(\d+\s+\d+/\d+|\d+/\d+|\d+\.\d+|\d+)"#) else {
            return line
        }
        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        var result = line
        for match in matches.reversed() {
            let raw = nsLine.substring(with: match.range)
            guard let value = parse(raw) else { continue }
            let scaled = (result as NSString).replacingCharacters(in: match.range, with: format(value * factor))
            result = scaled
        }
        return result
    }

    static func formatClock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let remain = total % 60
        return String(format: "%d:%02d", minutes, remain)
    }

    private static func parse(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: " ")
        if parts.count == 2, let whole = Double(parts[0]), let fraction = parseFraction(String(parts[1])) {
            return whole + fraction
        }
        if let fraction = parseFraction(trimmed) {
            return fraction
        }
        return Double(trimmed)
    }

    private static func parseFraction(_ raw: String) -> Double? {
        let bits = raw.split(separator: "/")
        guard bits.count == 2, let numerator = Double(bits[0]), let denominator = Double(bits[1]), denominator != 0 else {
            return nil
        }
        return numerator / denominator
    }

    private static func format(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if abs(rounded.rounded() - rounded) < 0.05 {
            return String(Int(rounded.rounded()))
        }
        return String(format: "%g", rounded)
    }
}
