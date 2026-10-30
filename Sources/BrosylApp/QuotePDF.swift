import AppKit
import CoreGraphics
import BrosylCore
// Explicit public fields only: this renderer never receives an internal cost breakdown.
enum QuotePDF {
 static func customerLines(_ j: Job) -> [String] {
  let r = Calculator.calculate(j)
  return ["BROSYL WORKSHOP", "QUOTATION  ·  \(j.number)", j.date.formatted(date:.abbreviated,time:.omitted), "", "Prepared for: \(j.customer.isEmpty ? "Customer" : j.customer)", j.contact, "", j.title, "Quantity: \(Int(j.quantity)) pieces", "Material: \(j.customerMaterial ? "Customer supplied" : "Workshop supplied")", "", "Standard price: \(money(r.suggested))", "Requested discount: \(money(r.discount))", "Net amount after minimum charge and rounding: \(money(r.net))", "Tax (\(j.taxPercent.formatted())%): \(money(r.tax))", "TOTAL PAYABLE: \(money(r.total))", "Per piece including tax: \(money(r.total / j.quantity))", "", "Notes", j.notes, "", "Thank you for choosing Brosyl Workshop."]
 }
 static func write(_ j: Job,to url: URL) throws {
  var box = CGRect(x:0,y:0,width:595,height:842)
  guard let context = CGContext(url as CFURL,mediaBox:&box,nil) else { throw CocoaError(.fileWriteUnknown) }
  var y: CGFloat = 62
  func page() { context.beginPDFPage(nil); NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(cgContext:context,flipped:true); context.translateBy(x:0,y:842); context.scaleBy(x:1,y:-1); y = 62 }
  func end() { NSGraphicsContext.restoreGraphicsState(); context.endPDFPage() }
  page()
  for (i,line) in customerLines(j).enumerated() {
   let font = NSFont.systemFont(ofSize:i == 0 ? 25 : (line.hasPrefix("TOTAL") ? 18 : 12),weight:i == 0 || line.hasPrefix("TOTAL") ? .bold : .regular)
   let attrs: [NSAttributedString.Key:Any] = [.font:font,.foregroundColor:i == 0 ? NSColor.systemTeal : NSColor.black]
   // Wrap and paginate even long notes; never truncate customer text.
   for paragraph in line.components(separatedBy:"\n") {
    let text = NSAttributedString(string:paragraph.isEmpty ? " " : paragraph,attributes:attrs)
    let storage = NSTextStorage(attributedString:text), layout = NSLayoutManager(), container = NSTextContainer(containerSize:NSSize(width:475,height:CGFloat.greatestFiniteMagnitude)); container.lineFragmentPadding = 0; layout.addTextContainer(container); storage.addLayoutManager(layout); layout.ensureLayout(for:container)
    let range = layout.glyphRange(for:container)
    layout.enumerateLineFragments(forGlyphRange:range) { rect, used, _, glyphRange, _ in
     if y + used.height > 780 { end(); page() }
     let chars = layout.characterRange(forGlyphRange:glyphRange,actualGlyphRange:nil)
     text.attributedSubstring(from:chars).draw(in:NSRect(x:60,y:y,width:475,height:used.height + 4)); y += used.height + 3
    }
   }
   y += 5
  }
  end(); context.closePDF()
 }
}
