# Hanger — AI Wardrobe

A SwiftUI wardrobe app that feels like a real closet, captures garments with the live camera,
cuts out the background on-device, and uses AI to name, categorise and de-clutter your clothes.

Built as the iOS take-home for SMARRTIF AI / SPAAK KAI (Task 3 — AI Wardrobe).

**Stack:** SwiftUI · SwiftData · MVVM · AVFoundation · Vision · Core Image · OpenAI Responses API
**Target:** iOS 17.6+ · no third-party packages · no external assets (SF Symbols, gradients and custom shapes only)

## Features

| Assignment feature | What's implemented |
|---|---|
| **1. AI de-clutter** | Wardrobe summary (name, category, colour, season, wear count, days since last worn) is sent to `gpt-4.1-mini` with a strict JSON schema. Cards show action (donate / keep / pair / rotate), reason and confidence. Accepting a *donate* suggestion archives the item (restorable). If the API fails or no key is set, a rule-based engine covers duplicates, long-unused items, seasonal mismatch and low-wear pieces. |
| **2. Live camera capture** | `AVCaptureSession` preview with a garment outline guide, permission handling and error states, photo-library fallback (Simulator), retake/confirm flow. Background removal uses `VNGenerateForegroundInstanceMaskRequest` (transparent PNG cropped to the subject). Dominant colour comes from a quantised histogram that ignores transparent pixels, with a human colour name. The photo is also sent (downscaled) to the AI to auto-fill name, category, season and style tags. |
| **3. Realistic wardrobe** | Wooden cabinet with a hanging rail (swinging hangers), folded-clothes shelf, footwear shelf and accessories drawer. Category filter chips, detail sheet, *Mark as worn*, haptics, light/dark mode. Captured cut-outs hang on the rail as real photos. |

## Architecture

```
Hanger/
├── HangerApp.swift            // @main, creates the SwiftData container
├── ContentView.swift          // TabView: Wardrobe | Insights
├── Models/                    // Garment (@Model), GarmentCategory, Season
├── Features/
│   ├── Wardrobe/              // cabinet UI, shelves, cards, filter chips, sample data
│   ├── Capture/               // camera screen, preview layer, capture view model
│   ├── GarmentDetail/         // detail sheet
│   └── Insights/              // AI recommendations screen + card
├── Services/                  // CameraService, BackgroundRemoval, ColorAnalysis,
│                              // GarmentImageStore, OpenAIWardrobeService, fallback engine
├── DesignSystem/              // colours, spacing
└── Utilities/                 // UIImage resizing
```

**Data model.** `Garment` is a SwiftData `@Model` (id, name, category, colorHex, season, imageFilename,
wearCount, lastWornDate, createdAt, tags, isArchived). Enums are stored as raw strings so the store stays
schema-stable. Images are *not* stored in the database: only a filename is, and the PNG lives in Application
Support with an in-memory `NSCache`. Insights and the wardrobe read the same store through `@Query`, so a
newly captured garment appears everywhere without manual syncing.

**Concurrency.** The project uses MainActor default isolation, so image work (`BackgroundRemovalService`,
`ColorAnalysisService`, `GarmentImageProcessor`) is explicitly `nonisolated` / `@concurrent` to keep Vision
off the main thread. Images are downscaled before segmentation, storage and upload.

## Run it

1. Open `Hanger.xcodeproj` in Xcode 26+, select an iPhone simulator or device, run.
2. First launch shows an empty wardrobe. Tap **Load sample wardrobe** to see it full, or tap the camera to capture.
3. **AI features (optional):** copy `Config/Secrets.example.plist` to `Hanger/Secrets.plist` and put your OpenAI key
   in it (git-ignored, bundled automatically). Alternatively set `OPENAI_API_KEY` in the scheme's environment variables.
   Without a key the app still works and uses the offline recommendation engine.

## Known limitations

- The Simulator has no camera, so use the Library button. Vision's foreground mask can also be unreliable on the Simulator;
  on failure the original photo is saved instead. Test on a real device (iOS 17+) for the full pipeline.
- The OpenAI key lives on-device. For production, route calls through your own backend.
- Wardrobe items cannot be reordered yet; there is no cloud sync.

## Next feature

Outfit builder: pick a top, bottom and shoes and let the AI rate the combination, using the same wear data to
suggest outfits that use under-worn pieces.
