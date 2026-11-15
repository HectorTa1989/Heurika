# App Store release workflow

The repository now contains a manual GitHub Actions workflow at
`.github/workflows/release.yml`. It runs on a macOS runner, requires Xcode 26 or
newer, generates the Xcode project with XcodeGen, signs both the app and keyboard
extension, exports an IPA, and uploads it to App Store Connect. Submission for
review is an explicit workflow input and defaults to false.

## Required GitHub Actions secrets

Add these under repository Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `APPLE_DISTRIBUTION_CERTIFICATE_BASE64` | Base64-encoded Apple Distribution `.p12` |
| `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password for the `.p12` |
| `HEURIKA_APP_PROFILE_NAME` | App Store provisioning-profile name |
| `HEURIKA_APP_PROFILE_BASE64` | Base64-encoded app `.mobileprovision` |
| `HEURIKA_KEYBOARD_PROFILE_NAME` | Keyboard-extension provisioning-profile name |
| `HEURIKA_KEYBOARD_PROFILE_BASE64` | Base64-encoded extension `.mobileprovision` |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded App Store Connect `.p8` private key |
| `HEURIKA_REVENUECAT_API_KEY` | RevenueCat Apple public SDK key |
| `HEURIKA_PRIVACY_POLICY_URL` | HTTPS privacy-policy URL |
| `HEURIKA_TERMS_OF_USE_URL` | HTTPS terms URL |
| `HEURIKA_SUPPORT_URL` | HTTPS support URL |

The app and extension profiles must match these bundle IDs:

- `com.heurika.app`
- `com.heurika.app.keyboard`

## Running a release

1. Add and verify all secrets.
2. Open Actions → **Release to App Store Connect** → Run workflow.
3. Enter the marketing version. The workflow uses the GitHub run number as the build number.
4. Keep **Submit the uploaded build for App Review** disabled for the first run.
5. Verify the processed build, metadata, age rating, privacy answers, screenshots, and export-compliance response in App Store Connect.
6. Run the workflow again with submission enabled only after the App Store record is complete.

The workflow deliberately does not create or modify Apple certificates, profiles,
API keys, App Store metadata, screenshots, or legal content. Those remain account
owner responsibilities.
