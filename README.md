# Brosyl Workshop Pricing Calculator

Native SwiftUI macOS app, macOS 13 or later. Entirely offline, no dependencies, accounts or subscriptions. INR currency. Apple Silicon build supplied if compilation succeeds; Intel users can build the same source on their Mac.

## Implementation plan and source map

1. Define Codable machine, customer and quote models, including value snapshots of all quote rates (`Sources/BrosylCore/Models.swift`).
2. Implement a pure calculation engine, validation and atomic local JSON persistence in the core module.
3. Build the native sidebar workflow: calculator, machine profiles, customers, editable/duplicable history and backups (`Sources/BrosylApp/App.swift`).
4. Render customer-only PDF fields with wrapped, paginated notes (`Sources/BrosylApp/QuotePDF.swift`).
5. Validate calculations and snapshot round-trips; build and package an ad-hoc signed `.app`.

## Download

The prebuilt Apple Silicon app is available in [Downloads/BrosylWorkshop-macOS.zip](Downloads/BrosylWorkshop-macOS.zip). Unzip it, then copy the app to Applications.

## Install and run

If the supplied app is present in `dist`, copy **Brosyl Workshop Pricing Calculator.app** to Applications and double-click it. This is a locally ad-hoc signed build, not Apple Developer ID notarized. macOS may ask you to approve the app in System Settings → Privacy & Security after attempting to open it. No administrator installation or internet is required by the app.

To build from source, install Apple's Command Line Tools (`xcode-select --install`) or full Xcode. In Terminal, change to this folder and run:

```sh
./validate.sh
./build-app.sh
```

The app appears in `dist/`. To work in Xcode, open `Package.swift`, choose the BrosylWorkshop executable scheme and My Mac, then Run. With full Xcode selected, `swift test` runs the XCTest suite. `validate.sh` runs the core acceptance checks without XCTest.

## Branding and presets

The Job preset drop-down offers Laser and Mahogany CNC. The supplied Brosyl logo appears in the sidebar and is packaged as the macOS app icon. Branding assets are included with the source.

## First use

1. Open Machine profiles, edit your measured costs and charge-out rates, then Save profiles. Starter rates are examples, not verified workshop costs.
2. Optionally add customers and their repeat discount percentages, then Save customers.
3. Choose a Job preset, load a saved profile if desired, and enter production, labour and pricing details. Customer discounts apply explicitly when selected.
4. Save quote (⌘S). PDF export saves a new quote first to allocate its number, then asks where to write the PDF. Unsaved edits on an existing quote can be exported; Save quote to retain those edits in history.
5. History offers Edit and Duplicate. Edit preserves its rate snapshot; Duplicate creates a new number when saved. Loading a profile deliberately updates a quote's machine rates.
6. Export a backup periodically in Data & backups. Restore preserves the previous on-disk file before replacing current data.

## Calculation contract

- Machine hours = quantity × sides × passes × minutes per side per pass / 60. Time already including multiple passes should use passes = 1.
- Energy = (machine input watts + auxiliary watts) / 1000 × machine hours. Laser 10W is optical output; starter input is 100W. CNC is 700W + 50W. Power is charged during machine run time only.
- Ownership = (purchase − residual) / (life years × 12 × productive hours/month) × machine hours.
- Operator cost covers all machine run time plus handling time. Setup and design are batch minutes; finishing and handling are minutes per piece. Job hours are the sequential sum of those times, not a parallel-production schedule.
- Direct costs = power + ownership + maintenance + tooling + labour + workshop material/wastage + extras. Customer-supplied material costs zero. For mixed supply, turn off customer supply and enter only the workshop-supplied material cost per piece; clarify supplies in notes.
- Overhead = job hours × overhead hourly + fixed overhead + direct cost × overhead %. Estimated cost includes every cost once, regardless of pricing mode.
- **Charge-out**: hourly machine service charge, subject to machine minimum, replaces electricity, ownership, maintenance, tooling, machine-time operator/handling and overhead in the selling basis. Setup, design, finishing, fixed labour, material and extras are separate. Cost estimates remain visible for profitability.
- **Hybrid**: same charge-out basis plus only the unchecked/excluded cost components. A checked component is covered by the rate and is never added again.
- **Ownership cost**: selling basis is actual estimated cost. Machine charge-out minimum does not apply here; use minimum order instead.
- Markup = basis × (1 + %). Margin = basis / (1 − %). Manual total replaces that calculation. In charge-out mode, markup/margin are applied to the selling basis, so the actual estimated margin can differ from the percentage entered.
- Discount applies to standard price first (percentage plus fixed), capped at the standard price. The minimum order and upward net rounding apply next. Tax is added last and rounded to paise. “Discount requested” can be offset by minimum/rounding. Tax is always exclusive/additive; enter 0 if not applicable.
- Cost floor = estimated cost × (1 + floor uplift %). Below-floor and below-target-margin warnings never silently raise your price. Manual quotes may be saved below cost after reviewing the warning.
- Internal calculations use Double precision, with explicit final tax/total currency rounding. This is an estimating tool, not an accounting ledger.

## Starter examples

Laser: 15 × 2 sides × 3 minutes = 90 minutes; 100W at ₹10/kWh = ₹1.50; ₹150/hour service = ₹225 before other fees and markup.

CNC: 30 × 10 minutes = 5 hours (conservative upper estimate); 750W at ₹10/kWh = ₹37.50. Customer-supplied 20mm mahogany, no finishing; manual reference price ₹2,700 (₹90/piece), as discussed. Replace 10 minutes with measured time. Default CNC charge-out ₹600/hour provides an editable standard-rate reference.

## Privacy, storage and limitations

Data lives in `~/Library/Application Support/BrosylWorkshop/Workshop.json`. Saves are atomic. Saved quotations contain copies of their machine and customer pricing inputs; later profile edits do not recalculate history. Settings/customer changes require their Save button; calculator drafts are saved only with Save quote. Do not close an unsaved draft expecting autosave.

PDFs include job/customer details, material arrangement, standard price, discount, net amount, tax, total and customer-facing notes. They exclude internal cost breakdowns, machine rates and profit. Notes are printed verbatim: enter only customer-facing text.

Backups contain all internal costs and customer details. If the data cannot be read, the app preserves the file and disables saves until a valid backup is restored. Restore replaces data rather than merging it.

Scope: one machine/time pattern per quote; no inventory, multi-device sync, actual-versus-estimated production tracking, automatic volume-tier rules, separate unequal side times, tax-inclusive entry or customer negotiated machine-rate overrides. Use a separate quote or averaged time for unequal sides. Customer-specific repeat discounts, manual totals and editable machine snapshots are supported. No data deletion UI is provided.
