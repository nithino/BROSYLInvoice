import XCTest
@testable import BrosylCore
final class PricingTests: XCTestCase {
 func testLaserAndCNC() {
  let l = Calculator.calculate(Job()); XCTAssertEqual(l.machineHours,1.5); XCTAssertEqual(l.electricity,1.5,accuracy:0.00001); XCTAssertEqual(l.machineCharge,225)
  let c = Calculator.calculate(Job.cnc); XCTAssertEqual(c.machineHours,5); XCTAssertEqual(c.electricity,37.5); XCTAssertEqual(c.net,2700)
 }
 func testNoDoubleCountingAndHybrid() {
  var j = Job(); j.profitPercent = 0; j.rounding = 0
  let a = Calculator.calculate(j); XCTAssertEqual(a.net,225)
  j.machine.tariff = 100; XCTAssertEqual(Calculator.calculate(j).net,225)
  j.machine.mode = .hybrid; XCTAssertEqual(Calculator.calculate(j).net,225)
  j.machine.includesElectricity = false; XCTAssertEqual(Calculator.calculate(j).net,240)
  XCTAssertEqual(Calculator.calculate(j).cost - a.cost,13.5,accuracy:0.00001)
 }
 func testMarkupAndMargin() {
  var j = Job(); j.machine.hourlyRate = 100; j.quantity = 1; j.sides = 1; j.minutesSide = 60; j.rounding = 0
  XCTAssertEqual(Calculator.calculate(j).net,130)
  j.profitMode = .margin; XCTAssertEqual(Calculator.calculate(j).net,142.857142857,accuracy:0.000001)
 }
 func testCostModeMaterialLabourAndMinimums() {
  var j = Job(); j.machine.mode = .cost; j.profitPercent = 0; j.rounding = 0
  j.customerMaterial = false; j.materialPiece = 10; j.wastage = 10
  XCTAssertEqual(Calculator.calculate(j).material,165,accuracy:0.00001)
  j.customerMaterial = true; XCTAssertEqual(Calculator.calculate(j).material,0)
  j.setupMinutes = 60; j.designMinutes = 60; j.finishingMinutesPiece = 4
  XCTAssertEqual(Calculator.calculate(j).labour,825,accuracy:0.00001)
  j.profitMode = .manual; j.manualTotal = 100; j.discountPercent = 20; j.discountFixed = 10; j.minimumOrder = 90; j.rounding = 7; j.taxPercent = 18
  let r = Calculator.calculate(j); XCTAssertEqual(r.discount,30); XCTAssertEqual(r.net,91); XCTAssertEqual(r.tax,16.38); XCTAssertEqual(r.total,107.38); XCTAssertTrue(r.warnings.contains(where:{$0.contains("cost floor")}))
 }
 func testValidation() {
  var j = Job(); j.quantity = 0; j.profitMode = .margin; j.profitPercent = 100; j.machine.lifeYears = 0
  XCTAssertEqual(Calculator.validate(j).count,3)
 }
 func testSavedSnapshotsAndRoundTrip() throws {
  let u = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("test.json")
  var a = Archive(); var j = Job(); j.machine = a.machines[0]; j.number = "BW-TEST"; a.quotes = [j]
  let original = Calculator.calculate(j)
  a.machines[0].hourlyRate = 9999; a.machines[0].tariff = 999
  try Storage.save(a,to:u); let b = try Storage.read(u)
  XCTAssertEqual(b.quotes[0],j); XCTAssertEqual(Calculator.calculate(b.quotes[0]),original); XCTAssertEqual(b.machines[0].hourlyRate,9999)
  var edited = b.quotes[0]; edited.quantity = 30; XCTAssertEqual(Calculator.calculate(edited).machineHours,3); XCTAssertEqual(edited.machine.hourlyRate,150)
 }
}
