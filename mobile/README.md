# Mobile development

## iOS (Mac only)

### One-time

1. App Store: install Xcode (`mas install 497799835`). ~15 GB.
2. Launch Xcode → accept license → let it install components.
3. `xcodebuild -runFirstLaunch` (installs the default iOS Simulator runtime).
4. Optional: install extra simulator versions via Xcode → Settings → Components.
5. Code signing:
   - Sign into your Apple Developer account in Xcode → Settings → Accounts.
   - Note your Team ID (Xcode → Settings → Accounts → Manage Certificates).
   - Per-project: configure signing in `ios/<App>.xcworkspace` or via `fastlane match`.

### Per-project

```sh
cd <rn-project>
mise install              # honors project's .tool-versions
bun install               # or npm/yarn/pnpm
cd ios && pod install
cd ..
npx react-native run-ios
```

## Android (Mac + Linux)

### One-time

1. `make mobile-bootstrap` (Mac) — installs watchman, cocoapods, Android SDK components. Linux: `sudo snap install android-studio --classic` then run `bin/setup-android-sdk.sh`.
2. Launch Android Studio once. Confirm SDK Manager shows `platform-tools`, `platforms;android-34`, `build-tools;34.0.0`, `emulator`.
3. Create at least one AVD:
   ```sh
   avdmanager create avd \
     --name pixel_7_api_34 \
     --package "system-images;android-34;google_apis;arm64-v8a" \
     --device "pixel_7"
   ```

### Per-project

```sh
cd <rn-project>
mise install
bun install
npx react-native run-android
```
