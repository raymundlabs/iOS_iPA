name: iOS-ipa-build

on:
  workflow_dispatch:

jobs:
  build-ios:
    name: 🎉 iOS Build
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          architecture: x64

      # Install Flutter dependencies
      - run: flutter pub get

      # Generate Podfile if it doesn't exist and configure it
      - name: Generate Podfile if missing
        run: |
          if [ ! -f ios/Podfile ]; then
            echo "platform :ios, '12.0'" > ios/Podfile
            echo "target 'Runner' do" >> ios/Podfile
            echo "  use_frameworks!" >> ios/Podfile
            echo "  # Add your dependencies here" >> ios/Podfile
            echo "end" >> ios/Podfile
          fi

      # Install CocoaPods dependencies
      - run: pod install --project-directory=ios

      # Build iOS app for release
      - run: flutter build ios --release --no-codesign

      # Prepare for IPA export
      - run: mkdir -p Payload
        working-directory: build/ios/iphoneos

      # Move the .app file to Payload folder
      - run: |
          if [ -d "build/ios/iphoneos/Runner.app" ]; then
            mv build/ios/iphoneos/Runner.app Payload/
          else
            echo "Error: Runner.app not found!"
            exit 1
          fi
        working-directory: build/ios/iphoneos

      # Zip the output IPA
      - name: Zip output
        run: zip -qq -r -9 FlutterIpaExport.ipa Payload
        working-directory: build/ios/iphoneos

      # Upload the IPA to GitHub release
      - name: Upload binaries to release
        uses: svenstaro/upload-release-action@v2
        with:
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          file: build/ios/iphoneos/FlutterIpaExport.ipa
          tag: v1.0
          overwrite: true
          body: "This is first release"
