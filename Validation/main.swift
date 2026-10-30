import Foundation
var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) { checks += 1; guard condition() else { fatalError("FAIL: \(label)") }; print("PASS: \(label)") }
func near(_ a: Double,_ b: Double) -> Bool { abs(a-b) < 0.00001 }
var j = Job(); var r = Calculator.calculate(j)
check(r.machineHours == 1.5,"15 × 2 × 3 minutes = 90 minutes")
check(near(r.electricity,1.5),"Laser electricity ₹1.50")
check(r.machineCharge == 225,"Laser charge ₹225")
r = Calculator.calculate(.cnc)
check(r.machineHours == 5 && r.electricity == 37.5,"CNC upper estimate and ₹37.50 power")
check(r.net == 2700,"Mahogany manual reference ₹2700")
j.profitPercent = 0; j.rounding = 0
check(Calculator.calculate(j).net == 225,"Bundled charge-out does not add costs twice")
j.machine.mode = .hybrid
check(Calculator.calculate(j).net == 225,"Hybrid covered costs excluded")
j.machine.includesElectricity = false
check(near(Calculator.calculate(j).net,226.5),"Hybrid adds only excluded electricity")
j = Job(); j.quantity = 1; j.sides = 1; j.minutesSide = 60; j.machine.hourlyRate = 100; j.rounding = 0
check(Calculator.calculate(j).net == 130,"30% markup")
j.profitMode = .margin
check(near(Calculator.calculate(j).net,142.857142857),"30% margin")
j = Job(); j.customerMaterial = false; j.materialPiece = 10; j.wastage = 10
check(near(Calculator.calculate(j).material,165),"Workshop material and wastage")
j.customerMaterial = true
check(Calculator.calculate(j).material == 0,"Customer supplied excludes material")
j.setupMinutes = 60; j.designMinutes = 60; j.finishingMinutesPiece = 4
check(Calculator.calculate(j).labour == 825,"Operator, setup, design and finishing")
j.profitMode = .manual; j.manualTotal = 100; j.discountPercent = 20; j.discountFixed = 10; j.minimumOrder = 90; j.rounding = 7; j.taxPercent = 18
r = Calculator.calculate(j)
check(r.discount == 30 && r.net == 91 && r.tax == 16.38 && r.total == 107.38,"Discount, minimum, rounding then tax")
check(r.warnings.contains(where:{$0.contains("cost floor")}),"Below floor warning")
j.quantity = 0; check(!Calculator.validate(j).isEmpty,"Invalid quantity rejected")
j = Job(); j.profitMode = .margin; j.profitPercent = 100
check(!Calculator.validate(j).isEmpty,"100% margin rejected")
var a = Archive(); a.quotes = [Job()]; let before = Calculator.calculate(a.quotes[0]); a.machines[0].hourlyRate = 9999
let url = FileManager.default.temporaryDirectory.appendingPathComponent("Brosyl-validation-\(UUID().uuidString).json")
try Storage.save(a,to:url); let loaded = try Storage.read(url)
check(Calculator.calculate(loaded.quotes[0]) == before,"Saved rate snapshot survives profile changes and disk round-trip")
check(loaded.machines[0].hourlyRate == 9999,"Changed profile saved independently")
var edited = loaded.quotes[0]; edited.quantity = 30
check(Calculator.calculate(edited).machineHours == 3 && edited.machine.hourlyRate == 150,"History edit keeps saved rates")
print("\(checks) checks passed")
