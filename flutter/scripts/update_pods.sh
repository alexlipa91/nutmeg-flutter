#!/bin/bash

echo "Updating CocoaPods repos..."
pod repo update

echo "Cleaning pod cache..."
pod cache clean --all

echo "Updating minimum deployment target in Podfile..."
sed -i '' 's/platform :ios, .*/platform :ios, '\''14.0'\''/' ios/Podfile

echo "Updating project deployment target..."
/usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 14.0" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 14.0" ios/Runner/Info.plist

echo "Removing Podfile.lock..."
rm -f ios/Podfile.lock

echo "Removing Pods directory..."
rm -rf ios/Pods

echo "Installing pods with repo update..."
cd ios && pod install --repo-update

echo "Done! Pods have been updated." 