# Testing SMS OTP on Real Devices

Testing SMS OTP functionality requires a real device because verifying SMS reception and autofill behavior is difficult or impossible on standard emulators/simulators.

## 📱 Prerequisites

1.  **Connect your device** via USB or WiFi.
2.  **Enable Developer Mode**:
    *   **Android**: Settings > About Phone > Tap "Build Number" 7 times. Then Enable "USB Debugging" in Developer Options.
    *   **iOS**: Enable Developer Mode in Settings > Privacy & Security > Developer Mode (requires restart).
3.  **Verify connection**:
    ```bash
    flutter devices
    ```

---

## 🚀 Method 1: Running the Example App (Manual Testing)

The example app is designed to help you verify all features easily.

1.  **Run the app**:
    ```bash
    cd example
    flutter run -d <your-device-id> --release
    ```
    *(Using `--release` is recommended for performance, but `debug` works too).*

### Testing Android Auto-Read (SMS Retriever API)

1.  Open the example app on your Android device.
2.  Tap on the **"Android Auto-Read"** or **"Controller"** tab (depending on the example UI).
3.  Look for the **App Signature** displayed on the screen (e.g., `AbCdEfGhIjK`).
    *   *Note: This signature is unique to your keystore. It will differ between debug and release builds.*
4.  **Send an SMS** to this device from **another phone**. The message **MUST** follow this format exactly:
    ```text
    <#> Your verification code is 123456
    AbCdEfGhIjK
    ```
    *   Starts with `<#>`
    *   Contains the OTP (e.g., `123456`)
    *   Ends with the App Signature string
5.  **Result**: The app should automatically detect the SMS, extract `123456`, and fill the field without you touching anything.

### Testing iOS Autofill

1.  Open the example app on your iPhone.
2.  Tap on any OTP field to focus it.
3.  **Send an SMS** to this device from **another phone**. content:
    ```text
    Your verification code is 123456
    ```
    *   *Use standard words like "code", "OTP", or "verification".*
4.  **Result**: You should see the code `123456` appear in the QuickType bar above the keyboard. Tap it to fill the field.

---

## 🤖 Method 2: Running Automated Integration Tests

We have created an integration test validation flow.

1.  **Run the test**:
    ```bash
    flutter test integration_test/otp_flow_test.dart -d <your-device-id>
    ```

This will:
*   Launch the app on your device.
*   Automatically tap through the UI.
*   Verify widgets render correctly.
*   Test input validation.

*Note: The automated test cannot simulate receiving a real cellular SMS, but it verifies that the app implementation and UI are correct.*
