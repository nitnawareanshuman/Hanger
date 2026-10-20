#!/bin/bash
# Run from the ROOT of your Hanger repo after copying the changed files over it.
git rm -r --cached --ignore-unmatch .DS_Store Hanger.xcodeproj/xcuserdata Hanger.xcodeproj/project.xcworkspace/xcuserdata >/dev/null 2>&1 || true
rm -rf Hanger.xcodeproj/xcuserdata Hanger.xcodeproj/project.xcworkspace/xcuserdata .DS_Store
rm -f "Config/Secrets.xcconfig.example"
rm -f "Hanger/App/AIWardrobeApp.swift"
rm -f "Hanger/App/AppDependencies.swift"
rm -f "Hanger/DesignSystem/AppTheme.swift"
rm -f "Hanger/DesignSystem/AppTypograph.swift"
rm -f "Hanger/DesignSystem/Components/ColorSwatch.swift"
rm -f "Hanger/DesignSystem/Components/PrimaryButton.swift"
rm -f "Hanger/DesignSystem/Components/SectionHeaderView..swift"
rm -f "Hanger/Features/Capture/GarmentReviewView.swift"
rm -f "Hanger/Features/GarmentDetail/EditGarmentView.swift"
rm -f "Hanger/Features/GarmentDetail/GarmentDetailViewModel.swift"
rm -f "Hanger/Features/Insights/RecommendationDetailView.swift"
rm -f "Hanger/Models/WardrobeRecommendation.swift"
rm -f "Hanger/Models/WardrobeSection.swift"
rm -f "Hanger/Utilities/Color+Hex.swift"
rm -f "Hanger/Utilities/Date+Formatting.swift"
rm -f Config/Secrets.xcconfig.example
rmdir Hanger/App Hanger/DesignSystem/Components 2>/dev/null || true
echo "Cleanup done. Now: git add -A && git commit -m \"Fix app wiring, AI auto-fill, polish\""
