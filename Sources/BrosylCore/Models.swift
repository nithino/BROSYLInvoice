import Foundation
public enum PricingMode: String, Codable, CaseIterable { case chargeOut = "Charge-out", cost = "Ownership cost", hybrid = "Hybrid" }
public enum ProfitMode: String, Codable, CaseIterable { case markup = "Markup", margin = "Margin", manual = "Manual total" }
public struct Machine: Codable, Identifiable, Equatable {
 public var id = UUID()
 public var name = "New machine"
 public var watts = 100.0, auxiliaryWatts = 0.0, tariff = 10.0, hourlyRate = 150.0
 public var purchase = 30000.0, salvage = 0.0, lifeYears = 5.0, productiveHoursMonth = 80.0
 public var maintenanceHour = 10.0, toolingHour = 5.0, minimum = 0.0
 public var mode = PricingMode.chargeOut
 public var includesElectricity = true, includesOwnership = true, includesMaintenance = true, includesTooling = true, includesOperator = true, includesOverhead = true
 public init() {}
 public static var laser: Machine { var m = Machine(); m.name = "10W diode laser"; return m }
 public static var cnc: Machine { var m = Machine(); m.name = "CNC · 700W router + 50W machine"; m.watts = 700; m.auxiliaryWatts = 50; m.hourlyRate = 600; m.purchase = 100000; m.toolingHour = 50; return m }
}
public struct Customer: Codable, Identifiable, Equatable {
 public var id = UUID(); public var name = "New customer", contact = ""; public var discount = 0.0
 public init() {}
}
public struct Job: Codable, Identifiable, Equatable {
 public var id = UUID(); public var number = ""; public var date = Date(); public var title = "Two-sided laser pieces", customer = "", contact = "", notes = "", status = "Draft"
 public var machine = Machine.laser
 public var quantity = 15.0, sides = 2.0, passes = 1.0, minutesSide = 3.0
 public var setupMinutes = 0.0, designMinutes = 0.0, finishingMinutesPiece = 0.0, handlingMinutesPiece = 0.0
 public var operatorRate = 150.0, setupRate = 150.0, designRate = 300.0, finishingRate = 150.0, fixedLabour = 0.0
 public var customerMaterial = true; public var materialPiece = 0.0, wastage = 0.0, additional = 0.0
 public var overheadHour = 0.0, overheadFixed = 0.0, overheadPercent = 0.0
 public var profitMode = ProfitMode.markup; public var profitPercent = 30.0, manualTotal = 675.0, discountPercent = 0.0, discountFixed = 0.0, minimumOrder = 0.0, floorPercent = 0.0, targetMargin = 0.0, taxPercent = 0.0, rounding = 1.0
 public init() {}
 public static var cnc: Job { var j = Job(); j.title = "20mm mahogany CNC pieces"; j.machine = .cnc; j.quantity = 30; j.sides = 1; j.minutesSide = 10; j.profitPercent = 0; j.profitMode = .manual; j.manualTotal = 2700; j.notes = "CNC cutting of customer-supplied 20mm mahogany. No finishing. Time is a conservative 10-minute upper estimate per piece; replace with measured time."; return j }
}
public struct Result: Equatable {
 public var machineHours: Double, jobHours: Double, energy: Double, electricity: Double, ownership: Double, maintenance: Double, tooling: Double, labour: Double, material: Double, overhead: Double, cost: Double, machineCharge: Double, basis: Double, suggested: Double, discount: Double, net: Double, tax: Double, total: Double, profit: Double, margin: Double
 public var warnings: [String]
}
public enum Calculator {
 public static func validate(_ j: Job) -> [String] {
  let nonnegative = [j.machine.watts,j.machine.auxiliaryWatts,j.machine.tariff,j.machine.hourlyRate,j.machine.purchase,j.machine.salvage,j.machine.maintenanceHour,j.machine.toolingHour,j.machine.minimum,j.minutesSide,j.setupMinutes,j.designMinutes,j.finishingMinutesPiece,j.handlingMinutesPiece,j.operatorRate,j.setupRate,j.designRate,j.finishingRate,j.fixedLabour,j.materialPiece,j.wastage,j.additional,j.overheadHour,j.overheadFixed,j.overheadPercent,j.profitPercent,j.manualTotal,j.discountPercent,j.discountFixed,j.minimumOrder,j.floorPercent,j.targetMargin,j.taxPercent,j.rounding]
  var errors: [String] = []
  if nonnegative.contains(where: { !$0.isFinite || $0 < 0 }) { errors.append("Amounts and times must be finite and nonnegative.") }
  if [j.quantity,j.sides,j.passes].contains(where: { !$0.isFinite || $0 < 1 || $0.rounded() != $0 || $0 > 1000000 }) { errors.append("Quantity, sides and passes must be whole numbers from 1 to 1,000,000.") }
  if !j.machine.lifeYears.isFinite || !j.machine.productiveHoursMonth.isFinite || j.machine.lifeYears <= 0 || j.machine.productiveHoursMonth <= 0 { errors.append("Useful life and productive hours must be greater than zero.") }
  if j.discountPercent > 100 || j.targetMargin >= 100 || (j.profitMode == .margin && j.profitPercent >= 100) { errors.append("Discount must be at most 100%; margins must be below 100%.") }
  if j.machine.salvage > j.machine.purchase { errors.append("Residual value cannot exceed purchase cost.") }
  return errors
 }
 public static func calculate(_ j: Job) -> Result {
  let m = j.machine, h = j.quantity * j.sides * j.passes * j.minutesSide / 60
  let jobHours = h + (j.setupMinutes + j.designMinutes + j.quantity * (j.finishingMinutesPiece + j.handlingMinutesPiece)) / 60
  let energy = (m.watts + m.auxiliaryWatts) / 1000 * h, electricity = energy * m.tariff
  let ownership = max(0,m.purchase - m.salvage) / max(1,m.lifeYears * 12 * m.productiveHoursMonth) * h
  let maintenance = m.maintenanceHour * h, tooling = m.toolingHour * h
  let operatorCost = (h + j.quantity * j.handlingMinutesPiece / 60) * j.operatorRate
  let otherLabour = j.setupMinutes / 60 * j.setupRate + j.designMinutes / 60 * j.designRate + j.quantity * j.finishingMinutesPiece / 60 * j.finishingRate + j.fixedLabour
  let labour = operatorCost + otherLabour
  let material = j.customerMaterial ? 0 : j.quantity * j.materialPiece * (1 + j.wastage / 100)
  let direct = electricity + ownership + maintenance + tooling + labour + material + j.additional
  let overhead = jobHours * j.overheadHour + j.overheadFixed + direct * j.overheadPercent / 100
  let cost = direct + overhead, charge = max(m.minimum,h * m.hourlyRate)
  // Estimated cost always includes every real cost once. Charge-out replaces covered components only in the selling basis.
  let uncovered = (m.includesElectricity ? 0 : electricity) + (m.includesOwnership ? 0 : ownership) + (m.includesMaintenance ? 0 : maintenance) + (m.includesTooling ? 0 : tooling) + (m.includesOperator ? 0 : operatorCost) + (m.includesOverhead ? 0 : overhead)
  let basis = m.mode == .cost ? cost : charge + otherLabour + material + j.additional + (m.mode == .hybrid ? uncovered : 0)
  let suggested: Double
  switch j.profitMode { case .manual: suggested = j.manualTotal; case .markup: suggested = basis * (1 + j.profitPercent / 100); case .margin: suggested = basis / max(0.000001,1 - j.profitPercent / 100) }
  let discount = min(suggested, suggested * j.discountPercent / 100 + j.discountFixed)
  let preRound = max(j.minimumOrder, suggested - discount)
  let net = j.rounding > 0 ? ceil(preRound / j.rounding) * j.rounding : preRound
  let tax = (net * j.taxPercent).rounded() / 100, total = ( (net + tax) * 100 ).rounded() / 100
  let profit = net - cost, margin = net > 0 ? profit / net * 100 : 0
  var warnings = validate(j)
  if net < cost * (1 + j.floorPercent / 100) { warnings.append("Quote is below the configured cost floor.") }
  if margin < j.targetMargin { warnings.append("Quote is below the target margin.") }
  if m.mode == .chargeOut { warnings.append("Bundled rate: electricity, ownership, maintenance, tooling, machine-time operator labour and overhead are covered by the hourly rate. Use Hybrid to add excluded items.") }
  return Result(machineHours:h,jobHours:jobHours,energy:energy,electricity:electricity,ownership:ownership,maintenance:maintenance,tooling:tooling,labour:labour,material:material,overhead:overhead,cost:cost,machineCharge:charge,basis:basis,suggested:suggested,discount:discount,net:net,tax:tax,total:total,profit:profit,margin:margin,warnings:warnings)
 }
}
public struct Archive: Codable { public var version = 1; public var machines: [Machine] = [.laser,.cnc]; public var customers: [Customer] = []; public var quotes: [Job] = []; public init() {} }
public enum Storage {
 public static func save(_ archive: Archive, to url: URL) throws { let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted,.sortedKeys]; let data = try e.encode(archive); try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true); try data.write(to:url,options:.atomic) }
 public static func read(_ url: URL) throws -> Archive { let a = try JSONDecoder().decode(Archive.self,from:Data(contentsOf:url)); guard a.version == 1 else { throw CocoaError(.fileReadCorruptFile) }; return a }
}
