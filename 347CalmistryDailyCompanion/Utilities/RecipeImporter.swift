import Foundation

struct ImportedRecipeDraft: Equatable {
    var title: String
    var emoji: String
    var cuisine: String
    var ingredients: [String]
    var instructions: [String]
    var sourceNote: String
}

enum RecipeImporter {
    enum ImportError: LocalizedError {
        case empty
        case invalidURL
        case fetchFailed
        case unreadablePage

        var errorDescription: String? {
            switch self {
            case .empty: return "Paste a recipe or a link first."
            case .invalidURL: return "That link does not look valid."
            case .fetchFailed: return "Could not download the page."
            case .unreadablePage: return "Could not read recipe text from that page."
            }
        }
    }

    static func parseText(_ raw: String, sourceNote: String = "Pasted text") throws -> ImportedRecipeDraft {
        let cleaned = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw ImportError.empty }

        let lines = cleaned
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var title = lines.first ?? "Imported Dish"
        if title.lowercased().hasPrefix("http") || title.count > 80 {
            title = "Imported Dish"
        }

        let ingredientHeader = #"^(ingredients?|you will need|shopping list)\b"#
        let stepHeader = #"^(instructions?|directions?|method|steps?|preparation)\b"#

        var mode = "body"
        var ingredients: [String] = []
        var instructions: [String] = []
        var bodyLines: [String] = []

        for (index, line) in lines.enumerated() {
            if index == 0 && title != "Imported Dish" { continue }
            let lower = line.lowercased()
            if lower.range(of: ingredientHeader, options: .regularExpression) != nil {
                mode = "ingredients"
                continue
            }
            if lower.range(of: stepHeader, options: .regularExpression) != nil {
                mode = "steps"
                continue
            }

            let bullet = stripBullet(line)
            switch mode {
            case "ingredients":
                if !bullet.isEmpty { ingredients.append(bullet) }
            case "steps":
                if !bullet.isEmpty { instructions.append(bullet) }
            default:
                bodyLines.append(bullet)
            }
        }

        if ingredients.isEmpty && instructions.isEmpty {
            let split = heuristicSplit(bodyLines)
            ingredients = split.ingredients
            instructions = split.instructions
        } else if ingredients.isEmpty {
            ingredients = bodyLines.filter { looksLikeIngredient($0) }
        } else if instructions.isEmpty {
            instructions = bodyLines.filter { !looksLikeIngredient($0) }
        }

        if ingredients.isEmpty {
            ingredients = ["See original source for quantities"]
        }
        if instructions.isEmpty {
            instructions = bodyLines.isEmpty ? ["Follow the original method from the source."] : bodyLines
        }

        return ImportedRecipeDraft(
            title: title,
            emoji: guessEmoji(from: title + " " + ingredients.joined(separator: " ")),
            cuisine: "Imported",
            ingredients: ingredients,
            instructions: instructions,
            sourceNote: sourceNote
        )
    }

    static func parseURL(_ string: String) async throws -> ImportedRecipeDraft {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw ImportError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ImportError.fetchFailed
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ImportError.fetchFailed
        }

        let text = htmlToText(html)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.unreadablePage
        }
        return try parseText(text, sourceNote: url.host ?? "Web import")
    }

    private static func stripBullet(_ line: String) -> String {
        var value = line
        let prefixes = ["- ", "• ", "* ", "– ", "— "]
        for prefix in prefixes where value.hasPrefix(prefix) {
            value = String(value.dropFirst(prefix.count))
        }
        if let regex = try? NSRegularExpression(pattern: #"^\d+[\.\)]\s*"#) {
            value = regex.stringByReplacingMatches(in: value, range: NSRange(location: 0, length: (value as NSString).length), withTemplate: "")
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func looksLikeIngredient(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower.count < 3 { return false }
        if lower.contains("preheat") || lower.contains("bake") || lower.contains("simmer") {
            return false
        }
        let hasMeasure = lower.range(of: #"\d|cup|tbsp|tsp|g\b|ml\b|oz|clove|tin|bunch"#, options: .regularExpression) != nil
        return hasMeasure || line.split(separator: " ").count <= 6
    }

    private static func heuristicSplit(_ lines: [String]) -> (ingredients: [String], instructions: [String]) {
        var ingredients: [String] = []
        var instructions: [String] = []
        for line in lines {
            if looksLikeIngredient(line) {
                ingredients.append(line)
            } else {
                instructions.append(line)
            }
        }
        return (ingredients, instructions)
    }

    private static func guessEmoji(from text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("pasta") || lower.contains("noodle") { return "🍝" }
        if lower.contains("soup") || lower.contains("stew") || lower.contains("dal") { return "🍲" }
        if lower.contains("salad") { return "🥗" }
        if lower.contains("chicken") { return "🍗" }
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("prawn") { return "🐟" }
        if lower.contains("bread") || lower.contains("toast") { return "🍞" }
        if lower.contains("egg") { return "🍳" }
        if lower.contains("rice") || lower.contains("bowl") { return "🍚" }
        return "🍽️"
    }

    private static func htmlToText(_ html: String) -> String {
        var text = html
        let patterns = [
            #"<script[^>]*>[\s\S]*?</script>"#,
            #"<style[^>]*>[\s\S]*?</style>"#,
            #"<nav[^>]*>[\s\S]*?</nav>"#,
            #"<footer[^>]*>[\s\S]*?</footer>"#,
            #"<header[^>]*>[\s\S]*?</header>"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                text = regex.stringByReplacingMatches(in: text, range: NSRange(location: 0, length: (text as NSString).length), withTemplate: " ")
            }
        }
        text = text.replacingOccurrences(of: #"<br\s*/?>"#, with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: #"</(p|div|li|h1|h2|h3|tr)> "#, with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        let entities: [(String, String)] = [
            ("&nbsp;", " "), ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'")
        ]
        for (entity, value) in entities {
            text = text.replacingOccurrences(of: entity, with: value)
        }
        text = text.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
        return text
    }
}
