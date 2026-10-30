# Verification — 30 October 2026

- Release executable built successfully with Apple Swift 5.10 on Apple Silicon.
- Packaged app opened successfully and displayed its native SwiftUI window.
- Ad-hoc code signature verified with strict verification.
- 20 executable core acceptance checks passed, including the laser and CNC examples, anti-double-counting, markup/margin, material wastage, labour, discount/minimum/rounding/tax order, invalid input and saved-rate snapshot persistence.
- PDF public-field checks passed. No internal ownership/profit/maintenance fields appeared.
- Long-note PDF test produced nine pages and retained the final note text.
- PDF screenshot visually inspected. Upside-down text was found, corrected and rebuilt; the corrected PDF was inspected again.
- Live UI confirmed laser 1.50 hours / ₹1.50 electricity and CNC 5.00 hours / ₹37.50 electricity. Zero quantity blocked both Save and PDF export.
- Numeric fields hide their redundant labels in the updated build.
- Version 1.0.1 replaces starter buttons with the Job preset drop-down and packages the supplied logo for the sidebar and application icon.
- XCTest could not run because the installed Command Line Tools do not include XCTest. Equivalent standalone core checks ran successfully. The XCTest suite and GitHub Actions workflow are supplied for a full Xcode environment; that workflow has not yet run.
- Full end-to-end customer/profile editing, restore, and interactive PDF Save panel workflows have not been exercised through the UI. Their implementation compiles; snapshot serialization and PDF rendering were exercised directly.

Run ./validate.sh for core checks. Run ./validate-pdf.sh to build and verify PDF contents and pagination. The generated PDF samples are in .build/pdf-validation/. Run ./build-app.sh to rebuild the source including the label correction.

Updated UI visually inspected: supplied Brosyl logo renders in the sidebar; Job preset opens with Laser and Mahogany CNC, without the word example. Updated release build and strict signature verification passed. The packaged icon is AppIcon.icns with CFBundleIconFile configured.
