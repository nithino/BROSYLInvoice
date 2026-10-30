import AppKit
import PDFKit
import BrosylCore
func money(_ value:Double) -> String { value.formatted(.currency(code:"INR")) }
var j = Job.cnc; j.number = "BW-SAMPLE"; j.customer = "Sample customer"; j.notes = "CNC cutting of customer-supplied 20mm mahogany. No finishing."
let url = URL(fileURLWithPath:CommandLine.arguments[1])
try QuotePDF.write(j,to:url)
guard let doc = PDFDocument(url:url), let text = doc.string else { fatalError("Unreadable PDF") }
assert(text.contains("2,700")); assert(!text.contains("Ownership")); assert(!text.contains("profit")); assert(!text.contains("maintenance"))
let page = doc.page(at:0)!, box = page.bounds(for:.mediaBox)
let img = page.thumbnail(of:NSSize(width:box.width*1.5,height:box.height*1.5),for:.mediaBox)
let rep = NSBitmapImageRep(data:img.tiffRepresentation!)!
try rep.representation(using:.png,properties:[:])!.write(to:url.deletingPathExtension().appendingPathExtension("png"))
print("PDF public-fields check passed; \(doc.pageCount) page")
j.notes = String(repeating:"Long customer note that must wrap and continue onto subsequent pages. ",count:300) + "END OF NOTES"
let longURL = url.deletingLastPathComponent().appendingPathComponent("long-notes.pdf")
try QuotePDF.write(j,to:longURL)
let longDoc = PDFDocument(url:longURL)!
assert(longDoc.pageCount > 1); assert(longDoc.string!.contains("END OF NOTES"))
print("Long-note pagination check passed; \(longDoc.pageCount) pages")
