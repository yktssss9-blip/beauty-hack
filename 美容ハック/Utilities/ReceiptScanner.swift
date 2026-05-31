import Vision
import UIKit

struct ParsedReceipt {
    var title: String?
    var date: Date?
    var amount: Double?
    var storeName: String?
    var detectedCategoryName: String?
}

class ReceiptScanner {
    static func scan(image: UIImage) async -> ParsedReceipt {
        var receipt = ParsedReceipt()

        guard let cgImage = image.cgImage else { return receipt }

        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])

        let lines: [String] = (request.results as? [VNRecognizedTextObservation] ?? [])
            .compactMap { $0.topCandidates(1).first?.string }

        receipt.date = extractDate(lines)
        receipt.amount = extractAmount(lines)
        receipt.storeName = extractStoreName(lines)
        let (category, title) = extractCategoryAndTitle(lines)
        receipt.detectedCategoryName = category
        receipt.title = title

        return receipt
    }

    // MARK: - Private

    private static func extractDate(_ lines: [String]) -> Date? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        let patterns: [(String, String)] = [
            (#"\d{4}年(\d{1,2})月(\d{1,2})日"#, "yyyy年M月d日"),
            (#"\d{4}/\d{1,2}/\d{1,2}"#,         "yyyy/M/d"),
            (#"\d{4}\.\d{1,2}\.\d{1,2}"#,       "yyyy.M.d"),
            (#"\d{1,2}月\d{1,2}日"#,             "M月d日"),
        ]

        let timePattern = try? NSRegularExpression(pattern: #"\d{1,2}:\d{2}"#)

        for line in lines {
            for (pattern, format) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern),
                      let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                      let range = Range(match.range, in: line) else { continue }

                let matched = String(line[range])

                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ja_JP")

                // 年なしパターンは今年を補完
                let dateString: String
                if format == "M月d日" {
                    dateString = "\(currentYear)年\(matched)"
                    formatter.dateFormat = "yyyy年M月d日"
                } else {
                    dateString = matched
                    formatter.dateFormat = format
                }

                guard var date = formatter.date(from: dateString) else { continue }

                // 同行に時刻があれば合成
                let nsLine = line as NSString
                if let timeMatch = timePattern?.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)),
                   let timeRange = Range(timeMatch.range, in: line) {
                    let timeParts = String(line[timeRange]).split(separator: ":").compactMap { Int($0) }
                    if timeParts.count == 2 {
                        var comps = calendar.dateComponents([.year, .month, .day], from: date)
                        comps.hour = timeParts[0]
                        comps.minute = timeParts[1]
                        date = calendar.date(from: comps) ?? date
                    }
                }

                return date
            }
        }
        return nil
    }

    private static func extractAmount(_ lines: [String]) -> Double? {
        let patterns = [
            #"[¥￥]([\d,]+)"#,
            #"([\d,]+)円"#,
        ]

        var candidates: [Double] = []

        for line in lines {
            for pattern in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let nsLine = line as NSString
                let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
                for match in matches {
                    let groupRange = match.range(at: 1)
                    guard let range = Range(groupRange, in: line) else { continue }
                    let numString = String(line[range]).replacingOccurrences(of: ",", with: "")
                    if let value = Double(numString), value >= 10_000 {
                        candidates.append(value)
                    }
                }
            }
        }

        return candidates.max()
    }

    private static func extractStoreName(_ lines: [String]) -> String? {
        let keywords = ["サロン", "クリニック", "エステ", "スパ", "SALON", "CLINIC",
                        "美容室", "アイラッシュ", "ネイル"]

        for line in lines {
            if keywords.contains(where: { line.contains($0) }) {
                return line
            }
        }

        return lines.first { $0.count >= 5 && $0.count <= 20 }
    }

    private static func extractCategoryAndTitle(_ lines: [String]) -> (category: String?, title: String?) {
        let keywords: [String: (category: String, title: String)] = [
            "カラコン":     ("カラコン",    "カラコン"),
            "コンタクト":   ("カラコン",    "カラコン"),
            "ボトックス":   ("整形",        "ボトックス"),
            "ヒアルロン":   ("整形",        "ヒアルロン酸"),
            "埋没":         ("整形",        "埋没法"),
            "二重":         ("整形",        "埋没法"),
            "脱毛":         ("エステ",      "脱毛"),
            "ハイフ":       ("エステ",      "HIFU（ハイフ）"),
            "まつ毛エクステ": ("マツエク",  "まつ毛エクステ"),
            "まつ毛パーマ": ("マツエク",    "まつ毛パーマ"),
            "マツエク":     ("マツエク",    "まつ毛エクステ"),
            "パーマ":       ("ヘア",        "パーマ"),
            "カラー":       ("ヘア",        "全体カラー"),
            "カット":       ("ヘア",        "カット"),
            "縮毛矯正":     ("ヘア",        "縮毛矯正"),
            "ヘッドスパ":   ("ヘア",        "ヘッドスパ"),
            "ネイル":       ("ネイル",      "ジェルネイル"),
            "ジェルネイル": ("ネイル",      "ジェルネイル"),
            "美容液":       ("スキンケア",  "美容液"),
            "化粧水":       ("スキンケア",  "化粧水"),
            "ホワイトニング": ("整形",      "ホワイトニング"),
            "眉毛":         ("マツエク",    "眉毛サロン"),
        ]

        for line in lines {
            for (keyword, result) in keywords {
                if line.contains(keyword) {
                    return (result.category, result.title)
                }
            }
        }

        return (nil, nil)
    }
}
