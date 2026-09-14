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

enum SeasonalGarden {
    static func herbs(for month: Int) -> [(name: String, note: String)] {
        switch month {
        case 1:
            return [
                ("Rosemary", "Woody and bright in winter stews."),
                ("Thyme", "A pinch lifts roasted roots."),
                ("Sage", "Brown in butter for pasta or squash.")
            ]
        case 2:
            return [
                ("Bay", "One leaf is enough for a slow pot."),
                ("Parsley", "Chop the stalks into broths too."),
                ("Rosemary", "Still the most reliable winter herb.")
            ]
        case 3:
            return [
                ("Chives", "First green of the year on eggs."),
                ("Mint", "Young leaves like a cold water splash."),
                ("Parsley", "Use it as a salad leaf, not just garnish.")
            ]
        case 4:
            return [
                ("Dill", "Soft fronds with new potatoes and fish."),
                ("Chervil", "Gentle anise for spring omelettes."),
                ("Spring onion", "White and green, both belong in the pan.")
            ]
        case 5:
            return [
                ("Basil", "Wait until the nights stay mild."),
                ("Tarragon", "Classic with chicken and lemon."),
                ("Mint", "Now thick enough for a jug of tea.")
            ]
        case 6:
            return [
                ("Basil", "Tear, do not chop, over tomatoes."),
                ("Oregano", "Dry a handful for later in the year."),
                ("Mint", "Keep it in a pot or it will take the bed.")
            ]
        case 7:
            return [
                ("Basil", "Peak month for pesto and caprese."),
                ("Coriander", "Sow often; it bolts in heat."),
                ("Lemon verbena", "A leaf in syrup or evening tea.")
            ]
        case 8:
            return [
                ("Thyme", "Flowers are edible and honey-scented."),
                ("Oregano", "Best flavour just as it starts to bloom."),
                ("Basil", "Pinch tips so it does not seed.")
            ]
        case 9:
            return [
                ("Parsley", "A second flush after summer heat."),
                ("Sage", "Coming back for brown-butter season."),
                ("Rosemary", "Still giving if you do not strip the wood.")
            ]
        case 10:
            return [
                ("Sage", "The October herb for squash and beans."),
                ("Thyme", "Holds through the first cold nights."),
                ("Bay", "Drop a leaf into slow braises.")
            ]
        case 11:
            return [
                ("Rosemary", "Cut sparingly; growth slows now."),
                ("Sage", "Fried leaves over mash or beans."),
                ("Winter savory", "Peppery, made for lentils.")
            ]
        default:
            return [
                ("Rosemary", "The December kitchen’s evergreen."),
                ("Thyme", "A winter staple for gravy and roast."),
                ("Bay", "Keep a jar of dried leaves by the pot.")
            ]
        }
    }
}
