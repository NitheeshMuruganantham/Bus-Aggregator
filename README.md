# seatfirst

India first seat-preference-first bus discovery app.

## Prerequisites

Before running the app, install:

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel recommended)
2. [Git](https://git-scm.com/downloads)
3. For Android builds:
   - [Android Studio](https://developer.android.com/studio) (optional if you use the CLI only)
   - Android SDK and platform tools (installed via Android Studio or standalone SDK)
4. For iOS builds (macOS only): Xcode

Verify your setup:

```bash
flutter doctor
```

Fix any issues reported before continuing.

---

## Run with Android Studio

### 1. Open the project

1. Launch **Android Studio**.
2. Choose **Open** (or **File → Open**).
3. Select the `seatfirst` folder (the one containing `pubspec.yaml`).
4. Wait for Gradle sync and dependency indexing to finish.

### 2. Install dependencies

Android Studio usually runs this automatically. If not, open the terminal inside Android Studio and run:

```bash
flutter pub get
```

### 3. Set up a device

**Physical Android phone**

1. Enable **Developer options** and **USB debugging** on the phone.
2. Connect the phone via USB.
3. Accept the debugging prompt on the device.
4. The device should appear in the device dropdown in the toolbar.

**Android Emulator**

1. Go to **Tools → Device Manager** (or **AVD Manager**).
2. Click **Create device**, pick a phone profile, and download a system image if prompted.
3. Start the emulator from Device Manager.

### 4. Run the app

1. Select your device or emulator from the toolbar dropdown.
2. Click the green **Run** button (or press **Shift + F10**).
3. The app builds and launches on the selected device.

To stop the app, click the red **Stop** button in the toolbar.

---

## Run without Android Studio (command line)

You can run the app using only the Flutter CLI and a terminal—no IDE required.

### 1. Open a terminal in the project folder

```bash
cd path/to/seatfirst
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Check available devices

```bash
flutter devices
```

You should see at least one connected phone, emulator, or desktop target (e.g. Chrome, Windows).

### 4. Start an emulator (if you don't have a physical device)

List available emulators:

```bash
flutter emulators
```

Launch one (replace the ID with yours from the list above):

```bash
flutter emulators --launch <emulator_id>
```

Wait for the emulator to boot, then run `flutter devices` again to confirm it is listed.

### 5. Run the app

Run on the default device:

```bash
flutter run
```

Or run on a specific device:

```bash
flutter run -d <device_id>
```

Example for Chrome:

```bash
flutter run -d chrome
```

### 6. Useful commands while running

| Action | Command / key |
|--------|----------------|
| Hot reload | Press `r` in the terminal |
| Hot restart | Press `R` in the terminal |
| Quit | Press `q` in the terminal |

### 7. Build a release APK (Android, no IDE)

```bash
flutter build apk --release
```

The APK is generated at:

`build/app/outputs/flutter-apk/app-release.apk`

---

## Troubleshooting

- **No devices found** — Start an emulator, connect a phone with USB debugging enabled, or use `flutter run -d chrome`.
- **`flutter doctor` shows Android license issues** — Run `flutter doctor --android-licenses` and accept the licenses.
- **Dependencies fail to resolve** — Run `flutter clean`, then `flutter pub get`, and try again.
- **Gradle or build errors** — Ensure Android SDK is installed and `ANDROID_HOME` is set correctly.

For more help, see the [Flutter documentation](https://docs.flutter.dev/).
