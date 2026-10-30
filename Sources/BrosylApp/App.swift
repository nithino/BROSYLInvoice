import SwiftUI
import AppKit
import UniformTypeIdentifiers
import BrosylCore

@MainActor final class Store: ObservableObject {
 @Published var archive = Archive()
 @Published var error: String?
 @Published var readOnly = false
 let url = FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("BrosylWorkshop/Workshop.json")
 init() { if FileManager.default.fileExists(atPath:url.path) { do { archive = try Storage.read(url) } catch { self.error = "Could not read saved workshop data. Your file has been preserved. Restore a backup before saving. \(error.localizedDescription)"; readOnly = true } } }
 func persist() { guard !readOnly else { error = "Saving is disabled because the existing data could not be read. Restore a valid backup first."; return }; do { try Storage.save(archive,to:url) } catch { self.error = error.localizedDescription } }
 func backup() { let p = NSSavePanel(); p.nameFieldStringValue = "Brosyl-backup.json"; p.allowedContentTypes = [.json]; if p.runModal() == .OK, let u = p.url { do { try Storage.save(archive,to:u) } catch { self.error = error.localizedDescription } } }
 func restore() { let p = NSOpenPanel(); p.allowedContentTypes = [.json]; if p.runModal() == .OK, let u = p.url { do { let next = try Storage.read(u); if FileManager.default.fileExists(atPath:url.path) { let safety = url.deletingLastPathComponent().appendingPathComponent("Workshop-before-restore-\(UUID().uuidString).json"); try FileManager.default.copyItem(at:url,to:safety) }; try Storage.save(next,to:url); archive = next; readOnly = false } catch { self.error = error.localizedDescription } } }
}
@main struct BrosylApp: App {
 @StateObject private var store = Store()
 var body: some Scene { WindowGroup("Brosyl Workshop Pricing Calculator") { ContentView().environmentObject(store).frame(minWidth:1050,minHeight:720).tint(.teal) }.windowStyle(.automatic) }
}
private var brandingBundle: Bundle {
 if let resourceURL = Bundle.main.resourceURL, let bundled = Bundle(url: resourceURL.appendingPathComponent("BrosylWorkshop_BrosylApp.bundle")) { return bundled }
 return .module
}
func money(_ value: Double) -> String { value.formatted(.currency(code:"INR")) }
struct NumberRow: View {
 var title: String; @Binding var value: Double
 var body: some View { HStack { Text(title); Spacer(); TextField(title,value:$value,format:.number).labelsHidden().multilineTextAlignment(.trailing).frame(width:110).textFieldStyle(.roundedBorder).accessibilityLabel(title) } }
}
struct MachineEditor: View {
 @Binding var machine: Machine
 var body: some View {
  Section("Machine & electricity") { TextField("Machine name",text:$machine.name); Picker("Pricing basis",selection:$machine.mode) { ForEach(PricingMode.allCases,id:\.self) { Text($0.rawValue) } }; NumberRow(title:"Machine input · W",value:$machine.watts); NumberRow(title:"Auxiliary input · W",value:$machine.auxiliaryWatts); NumberRow(title:"Electricity · ₹/kWh",value:$machine.tariff); NumberRow(title:"Charge-out · ₹/hour",value:$machine.hourlyRate); NumberRow(title:"Minimum machine charge · ₹",value:$machine.minimum); Text("10W is laser optical output. Use electrical input here. Power is applied to machine run time.").font(.caption).foregroundStyle(.secondary) }
  Section("Ownership & operating cost estimates") { NumberRow(title:"Purchase cost · ₹",value:$machine.purchase); NumberRow(title:"Residual value · ₹",value:$machine.salvage); NumberRow(title:"Useful life · years",value:$machine.lifeYears); NumberRow(title:"Productive hours / month",value:$machine.productiveHoursMonth); NumberRow(title:"Maintenance · ₹/hour",value:$machine.maintenanceHour); NumberRow(title:"Tooling · ₹/hour",value:$machine.toolingHour) }
  if machine.mode == .hybrid { Section("Already included in the hourly rate") { Toggle("Electricity",isOn:$machine.includesElectricity); Toggle("Ownership",isOn:$machine.includesOwnership); Toggle("Maintenance",isOn:$machine.includesMaintenance); Toggle("Tooling",isOn:$machine.includesTooling); Toggle("Machine-time operator & handling",isOn:$machine.includesOperator); Toggle("Overhead",isOn:$machine.includesOverhead); Text("Only unchecked components are added to the rate. Setup, design, finishing, fixed labour, material and extras are always separate.").font(.caption).foregroundStyle(.secondary) } }
 }
}
struct ContentView: View {
 @EnvironmentObject var store: Store
 @State private var page = "Calculator"
 @State private var job = Job()
 @State private var selectedMachine: UUID?
 @State private var editing = false
 @State private var search = ""
 @State private var saved = ""
 var body: some View {
 NavigationSplitView {
  VStack(alignment:.leading,spacing:12) { Image(nsImage: NSImage(contentsOf: brandingBundle.url(forResource:"BrosylLogo", withExtension:"png")!)!).resizable().scaledToFit().frame(width:150,height:148).padding(10).background(Color.white,in:RoundedRectangle(cornerRadius:14)).padding(.horizontal).accessibilityLabel("Brosyl logo"); Text("WORKSHOP PRICING").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
   List(selection:$page) { Label("Calculator",systemImage:"slider.horizontal.3").tag("Calculator"); Label("Quote history",systemImage:"clock.arrow.circlepath").tag("History"); Label("Machine profiles",systemImage:"gearshape.2").tag("Machines"); Label("Customers",systemImage:"person.2").tag("Customers"); Label("Data & backups",systemImage:"externaldrive").tag("Data") }
   Label("Offline · stored on this Mac",systemImage:"checkmark.shield").font(.caption).foregroundStyle(.secondary).padding()
  }.padding(.top,18).navigationSplitViewColumnWidth(220)
 } detail: {
  Group { switch page { case "History": history; case "Machines": machines; case "Customers": customers; case "Data": dataView; default: calculator } }
   .toolbar { if page == "Calculator" { Button("Save quote",systemImage:"square.and.arrow.down") { save() }.keyboardShortcut("s").disabled(!Calculator.validate(job).isEmpty || store.readOnly); Button("Export PDF",systemImage:"doc.richtext") { exportPDF() }.disabled(!Calculator.validate(job).isEmpty) } }
 }.alert("Workshop notice",isPresented:Binding(get:{store.error != nil},set:{if !$0 {store.error = nil}})) { Button("OK") { store.error = nil } } message: { Text(store.error ?? "") }
 }
 var calculator: some View {
 HSplitView {
  Form {
   Section { HStack { VStack(alignment:.leading) { Text(editing ? "Edit quotation" : "New quotation").font(.largeTitle.bold()); Text("Confident prices. Clear costs.").foregroundStyle(.secondary) }; Spacer() }
    Menu {
     Button("Laser") { job = Job(); selectedMachine = nil; editing = false; saved = "" }
     Button("Mahogany CNC") { job = .cnc; selectedMachine = nil; editing = false; saved = "" }
    } label: { Label("Job preset", systemImage:"list.bullet.rectangle") }
    .menuStyle(.borderedButton)
    TextField("Job description",text:$job.title); TextField("Customer",text:$job.customer); TextField("Contact",text:$job.contact)
    Picker("Apply customer & repeat discount",selection:Binding<UUID?>(get:{nil},set:{ id in if let c = store.archive.customers.first(where:{$0.id == id}) { job.customer = c.name; job.contact = c.contact; job.discountPercent = c.discount } })) { Text("Choose customer…").tag(UUID?.none); ForEach(store.archive.customers) { Text("\($0.name) · \($0.discount.formatted())% off").tag(Optional($0.id)) } }
    Picker("Load machine profile",selection:Binding<UUID?>(get:{selectedMachine},set:{ id in selectedMachine = id; if let m = store.archive.machines.first(where:{$0.id == id}) { job.machine = m } })) { Text("Quote's rate snapshot").tag(UUID?.none); ForEach(store.archive.machines) { Text($0.name).tag(Optional($0.id)) } }
    Text("Machine settings below belong to this quote. Loading a profile explicitly replaces them.").font(.caption).foregroundStyle(.secondary)
   }
   Section("Production") { NumberRow(title:"Quantity · pieces",value:$job.quantity); NumberRow(title:"Sides per piece",value:$job.sides); NumberRow(title:"Passes per side",value:$job.passes); NumberRow(title:"Minutes per side per pass",value:$job.minutesSide); NumberRow(title:"Handling · minutes / piece",value:$job.handlingMinutesPiece); Text("Time per side is multiplied by passes. Include each machine pass once.").font(.caption).foregroundStyle(.secondary) }
   Section("Labour & preparation") { NumberRow(title:"Operator · ₹/hour",value:$job.operatorRate); NumberRow(title:"Setup · minutes / batch",value:$job.setupMinutes); NumberRow(title:"Setup · ₹/hour",value:$job.setupRate); NumberRow(title:"Design · minutes / batch",value:$job.designMinutes); NumberRow(title:"Design · ₹/hour",value:$job.designRate); NumberRow(title:"Finishing · minutes / piece",value:$job.finishingMinutesPiece); NumberRow(title:"Finishing · ₹/hour",value:$job.finishingRate); NumberRow(title:"Fixed labour · ₹",value:$job.fixedLabour) }
   Section("Material & overhead") { Toggle("Customer supplies material",isOn:$job.customerMaterial); if !job.customerMaterial { NumberRow(title:"Material · ₹/piece",value:$job.materialPiece); NumberRow(title:"Material wastage · %",value:$job.wastage) }; NumberRow(title:"Extras / consumables · ₹",value:$job.additional); NumberRow(title:"Overhead · ₹/job hour",value:$job.overheadHour); NumberRow(title:"Fixed overhead · ₹",value:$job.overheadFixed); NumberRow(title:"Overhead · % of direct cost",value:$job.overheadPercent) }
   Section("Price & discount") { Picker("Price method",selection:$job.profitMode) { ForEach(ProfitMode.allCases,id:\.self) { Text($0.rawValue) } }; if job.profitMode == .manual { NumberRow(title:"Manual total before discount · ₹",value:$job.manualTotal) } else { NumberRow(title:job.profitMode.rawValue + " · %",value:$job.profitPercent) }; NumberRow(title:"Repeat / customer discount · %",value:$job.discountPercent); NumberRow(title:"Additional fixed discount · ₹",value:$job.discountFixed); NumberRow(title:"Minimum order after discount · ₹",value:$job.minimumOrder); NumberRow(title:"Cost floor uplift · %",value:$job.floorPercent); NumberRow(title:"Target margin warning · %",value:$job.targetMargin); NumberRow(title:"Tax added · %",value:$job.taxPercent); NumberRow(title:"Round up net to · ₹ (0 = off)",value:$job.rounding); Text("Markup multiplies the basis; margin divides it by 1 − margin. Discounts apply before the minimum order, upward rounding and tax.").font(.caption).foregroundStyle(.secondary) }
   MachineEditor(machine:$job.machine)
   Section("Quote details") { Picker("Status",selection:$job.status) { ForEach(["Draft","Quoted","Accepted","In Progress","Completed","Cancelled"],id:\.self) { Text($0) } }; DatePicker("Quote date",selection:$job.date,displayedComponents:.date); TextField("Customer-facing notes",text:$job.notes,axis:.vertical).lineLimit(3...8) }
  }.formStyle(.grouped).frame(minWidth:510)
  summary.frame(minWidth:310,idealWidth:350,maxWidth:400)
 }
 }
 var summary: some View {
 let r = Calculator.calculate(job)
 return ScrollView { VStack(alignment:.leading,spacing:20) {
  Text("QUOTE PREVIEW").font(.caption.bold()).tracking(2).foregroundStyle(.secondary)
  if Calculator.validate(job).isEmpty {
   Text(money(r.total)).font(.system(size:36,weight:.bold,design:.rounded)).foregroundStyle(.teal)
   Text("\(money(r.total / job.quantity)) per piece · tax included").foregroundStyle(.secondary)
   Divider()
   metric("Machine run time",String(format:"%.2f hours",r.machineHours)); metric("Sequential job time",String(format:"%.2f hours",r.jobHours)); metric("Energy",String(format:"%.3f kWh",r.energy))
   GroupBox("Internal cost estimate") { VStack(spacing:10) { metric("Electricity",money(r.electricity)); metric("Ownership",money(r.ownership)); metric("Maintenance",money(r.maintenance)); metric("Tooling",money(r.tooling)); metric("Labour",money(r.labour)); metric("Material",money(r.material)); metric("Extras",money(job.additional)); metric("Overhead",money(r.overhead)); Divider(); metric("Estimated cost",money(r.cost)) }.padding(6) }
   metric("Machine service charge",money(r.machineCharge)); metric("Selling basis",money(r.basis)); metric("Standard price",money(r.suggested)); metric("Discount requested",money(r.discount)); metric("Net after minimum & rounding",money(r.net)); metric("Tax",money(r.tax)); Divider(); metric("Estimated profit before tax",money(r.profit)); metric("Estimated margin",String(format:"%.1f%%",r.margin)); metric("Revenue / machine hour",r.machineHours > 0 ? money(r.net / r.machineHours) : "—"); metric("Revenue / job hour",r.jobHours > 0 ? money(r.net / r.jobHours) : "—")
   Text("Cost and profit use your estimates. Job time assumes sequential work; operator cost includes the full machine run plus handling.").font(.caption).foregroundStyle(.secondary)
  }
  ForEach(r.warnings,id:\.self) { Label($0,systemImage:"exclamationmark.triangle").font(.callout).foregroundStyle(.orange) }
  if !saved.isEmpty { Label(saved,systemImage:"checkmark.circle.fill").foregroundStyle(.teal) }
 }.padding(26) }
 }
 func metric(_ name:String,_ value:String) -> some View { HStack(alignment:.firstTextBaseline) { Text(name).foregroundStyle(.secondary); Spacer(); Text(value).monospacedDigit() }.font(.callout) }
 func save() { guard Calculator.validate(job).isEmpty, !store.readOnly else { return }; if job.number.isEmpty { job.number = "BW-" + String(UUID().uuidString.prefix(8)).uppercased() }; if let i = store.archive.quotes.firstIndex(where:{$0.id == job.id}) { store.archive.quotes[i] = job } else { store.archive.quotes.insert(job,at:0) }; store.persist(); editing = true; saved = "Saved \(job.number)" }
 var history: some View { VStack(alignment:.leading) { Text("Quote history").font(.largeTitle.bold()).padding(); TextField("Search customer, job or quote number",text:$search).textFieldStyle(.roundedBorder).padding(.horizontal); List { ForEach(store.archive.quotes.filter { search.isEmpty || ($0.title + $0.customer + $0.number).localizedCaseInsensitiveContains(search) }) { q in HStack { VStack(alignment:.leading,spacing:5) { Text(q.title).font(.headline); Text("\(q.number) · \(q.customer) · \(q.status)").foregroundStyle(.secondary); Text(q.date,style:.date).font(.caption) }; Spacer(); Text(money(Calculator.calculate(q).total)).monospacedDigit(); Button("Edit") { job = q; selectedMachine = nil; editing = true; saved = ""; page = "Calculator" }; Button("Duplicate") { job = q; job.id = UUID(); job.number = ""; job.date = Date(); job.status = "Draft"; editing = false; selectedMachine = nil; page = "Calculator" } }.padding(.vertical,8) } }; Text("Editing retains saved rates. Duplicate a quote for repeat work; load a profile to intentionally refresh its rates.").font(.caption).foregroundStyle(.secondary).padding() } }
 var machines: some View { Form { Section { Text("Machine profiles").font(.largeTitle.bold()); Text("These defaults are copied into a quote when selected. Existing quotations keep their own rates.").foregroundStyle(.secondary); Button("Add machine") { store.archive.machines.append(Machine()); store.persist() } }; ForEach($store.archive.machines) { $m in MachineEditor(machine:$m) }; Section { Button("Save profiles") { store.persist() } } }.formStyle(.grouped) }
 var customers: some View { Form { Section { Text("Customers").font(.largeTitle.bold()); Text("Choose a customer in the calculator to explicitly apply their repeat discount.").foregroundStyle(.secondary); Button("Add customer") { store.archive.customers.append(Customer()); store.persist() } }; ForEach($store.archive.customers) { $c in Section { TextField("Name",text:$c.name); TextField("Contact",text:$c.contact); NumberRow(title:"Repeat discount · %",value:$c.discount) } }; Button("Save customers") { if store.archive.customers.contains(where:{ !$0.discount.isFinite || $0.discount < 0 || $0.discount > 100 }) { store.error = "Customer discounts must be between 0 and 100%." } else { store.persist() } } }.formStyle(.grouped) }
 var dataView: some View { Form { Section { Text("Your workshop, on your Mac").font(.largeTitle.bold()); Text("No account, network connection or subscription is required. Quotes, customer details and machine defaults are stored locally as a readable JSON file. Save a backup regularly."); Text(store.url.path).font(.caption).textSelection(.enabled); Button("Export backup…") { store.backup() }; Button("Restore backup…") { store.restore() }; Text("Restore replaces current data after preserving a dated safety copy beside the data file.").font(.caption).foregroundStyle(.secondary) } }.formStyle(.grouped) }
 func exportPDF() { if job.number.isEmpty { save() }; let p = NSSavePanel(); p.allowedContentTypes = [.pdf]; p.nameFieldStringValue = "\(job.number).pdf"; if p.runModal() == .OK, let url = p.url { do { try QuotePDF.write(job,to:url) } catch { store.error = error.localizedDescription } } }
}
