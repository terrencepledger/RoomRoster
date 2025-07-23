import Foundation

struct DepreciationCalculator {
    static func depreciatedValue(for item: Item, annualRate: Double) -> Double? {
        guard let price = item.estimatedPrice,
              let added = Date.fromShortString(item.dateAdded) else { return nil }
        let months = Calendar.current.dateComponents([.month], from: added, to: Date()).month ?? 0
        let monthlyRate = annualRate / 12
        return price * pow(1 - monthlyRate, Double(max(0, months)))
    }
}
