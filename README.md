# Hanger — Wardrobe Home UI

SwiftUI wardrobe home screen source for the existing Hanger Xcode project (iOS 17+, SwiftData, no external assets or packages).

## Included

- Wood-toned cabinet frame with hanging rail, folded-clothing shelf, footwear shelf and accessory drawer.
- Gentle repeating hanger swing animation and custom SwiftUI hanger/garment shapes.
- Category filter chips, tappable garments, detail sheet, dominant-color chip and Mark as worn action.
- Wear-count summary, haptic feedback and adaptive light/dark palette.
- Seeded SwiftData preview data and reusable small views.

## Install

Copy the `Hanger/` files into the matching groups in your project. If the Xcode project uses folder references rather than synchronized groups, add the new files (`WardrobeSampleData.swift`, `WardrobeShapes.swift`) to the target manually. Replace the placeholder `ContentView.swift` with the included version.

The code expects your existing `Garment`, `GarmentCategory`, and `Season` types from `Hanger/Models`. The sample uses the existing model initializer, including `imageFilename: ""` because all garment art is drawn with SF Symbols.

## Camera integration

The camera button currently opens a small integration placeholder. Replace `CaptureComingSoonView` in `WardrobeView.swift` with your existing `GarmentCaptureView` presentation when the capture flow is ready.

## Notes

- Drag gestures are enabled as drag sources; actual reordering needs a drop destination and a persisted order field on `Garment`. This avoids pretending the current model stores order.
- Matched geometry is not used in this version: a modal detail sheet is simpler and avoids depending on a namespace for a sheet transition.
- The `@Query` path uses real SwiftData records. In DEBUG previews, sample data is shown when the persistent store has no garments.
