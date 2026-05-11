#!/bin/bash

# Configuration
DMG_PATH="LiveWallpaperPro_1.0.0.dmg"

echo "🔐 Notarizing $DMG_PATH..."
echo "Enter your Apple ID email:"
read APPLE_ID
echo "Enter your App-Specific Password (from appleid.apple.com):"
read -s PASSWORD
echo ""
echo "Enter your Apple Team ID (Found at developer.apple.com):"
read TEAM_ID

# Submit for notarization
echo "🚀 Submitting to Apple..."
if xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait; then
    
    # Staple the ticket to the DMG
    echo "🔗 Stapling notarization ticket..."
    if xcrun stapler staple "$DMG_PATH"; then
        echo "🎉 Notarization complete! Your DMG is ready for distribution."
    else
        echo "❌ Stapling failed. Check the error above."
        exit 1
    fi
else
    echo "❌ Notarization submission failed. Double check your Email, Password, and Team ID."
    exit 1
fi
