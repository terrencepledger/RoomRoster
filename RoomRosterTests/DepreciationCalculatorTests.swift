import XCTest
@testable import RoomRoster

final class DepreciationCalculatorTests: XCTestCase {
    func testDepreciatedValueSixMonths() {
        let now = Date()
        let past = Calendar.current.date(byAdding: .month, value: -6, to: now)!
        let item = Item(id: "1", imageURL: "", name: "Test", description: "", quantity: 1,
                        dateAdded: past.toShortString(), estimatedPrice: 120,
                        status: .available, lastKnownRoom: .empty(), updatedBy: "", lastUpdated: nil, propertyTag: nil)
        let expected = 120 * pow(1 - 0.12/12, 6)
        let value = DepreciationCalculator.depreciatedValue(for: item, annualRate: 0.12)
        XCTAssertEqual(value!, expected, accuracy: 0.0001)
    }

    func testDepreciatedValueNoMonths() {
        let now = Date()
        let item = Item(id: "1", imageURL: "", name: "Test", description: "", quantity: 1,
                        dateAdded: now.toShortString(), estimatedPrice: 100,
                        status: .available, lastKnownRoom: .empty(), updatedBy: "", lastUpdated: nil, propertyTag: nil)
        let value = DepreciationCalculator.depreciatedValue(for: item, annualRate: 0.1)
        XCTAssertEqual(value!, 100, accuracy: 0.0001)
    }

    func testDepreciatedValueInvalidDate() {
        let item = Item(id: "1", imageURL: "", name: "Test", description: "", quantity: 1,
                        dateAdded: "invalid", estimatedPrice: 50,
                        status: .available, lastKnownRoom: .empty(), updatedBy: "", lastUpdated: nil, propertyTag: nil)
        XCTAssertNil(DepreciationCalculator.depreciatedValue(for: item, annualRate: 0.1))
    }
}
