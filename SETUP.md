# 🔐 Setting Up CI/CD Secrets for All Platforms

This guide walks you through configuring GitHub Secrets so the CI workflow can:
- **Android** — Sign APKs with a release keystore
- **iOS** — Sign and export an IPA for App Store distribution
- **Linux / Windows / Web** — Build without extra credentials (just works)

---

## 📱 Android — Release Signing

### 1. Generate a Keystore

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- **Keystore password**
- **Key alias password**
- Your name, organization, location (just fill them in)

### 2. Encode to Base64

**Linux / macOS:**
```bash
base64 -w0 upload-keystore.jks > keystore.txt
```
**Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

### 3. Add Android Secrets

| Secret Name | Value |
|---|---|
| `KEYSTORE_BASE64` | Base64 string of the keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias (e.g. `upload`) |
| `KEY_PASSWORD` | Key alias password |

---

## 🍎 iOS — App Store Signing

> ⚠️ **Prerequisites:** You need an active **Apple Developer Program** membership ($99/year).

### 1. Generate a Distribution Certificate

1. Open **Xcode** → **Settings** → **Accounts** → Sign in with your Apple ID
2. Go to [developer.apple.com](https://developer.apple.com) → **Certificates, IDs & Profiles**
3. Create a **Distribution Certificate** (or let Xcode manage it)
4. **Export the certificate:**
   - Open **Keychain Access**
   - Find your distribution certificate under **My Certificates**
   - Right-click → **Export "..."** → Save as `.p12`
   - **Set a password** for the `.p12` file — remember it!

### 2. Create a Provisioning Profile

1. On [developer.apple.com](https://developer.apple.com), go to **Profiles** → **+**
2. Choose **App Store Distribution**
3. Select your App ID
4. Select your Distribution Certificate
5. Name it and **Download** the `.mobileprovision` file

### 3. Update ExportOptions.plist

Open `ios/Runner/ExportOptions.plist` and replace `YOUR_APPLE_TEAM_ID` with your Team ID:

> Find your Team ID at [developer.apple.com](https://developer.apple.com) → **Membership** → **Team ID**

```xml
<key>teamID</key>
<string>YOUR_ACTUAL_TEAM_ID</string>
```

If you want **TestFlight / Ad-Hoc distribution**, change the method:
```xml
<key>method</key>
<string>ad-hoc</string>
```

### 4. Encode Files to Base64

```bash
# Certificate (.p12)
base64 -w0 certificate.p12 > cert.txt

# Provisioning Profile (.mobileprovision)
base64 -w0 profile.mobileprovision > profile.txt
```

### 5. Add iOS Secrets

| Secret Name | Value |
|---|---|
| `P12_BASE64` | Base64 of your Distribution Certificate `.p12` |
| `P12_PASSWORD` | The password you set when exporting the `.p12` |
| `PROVISIONING_PROFILE_BASE64` | Base64 of your `.mobileprovision` file |
| `KEYCHAIN_PASSWORD` | Any random password for the temporary keychain |

---

## 🖥️ Linux / Windows / Web

No additional secrets needed! These platforms build automatically.

- **Linux** — `flutter build linux --release` → compressed as `.tar.gz`
- **Windows** — `flutter build windows --release` → compressed as `.zip`
- **Web** — `flutter build web --release` → compressed as `.zip`

---

## ✅ Adding All Secrets to GitHub

1. Go to your repository on GitHub → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** for each secret in the tables above

**All required secrets (8 total when both Android & iOS are configured):**

| Secret | Platform |
|---|---|
| `KEYSTORE_BASE64` | Android |
| `KEYSTORE_PASSWORD` | Android |
| `KEY_ALIAS` | Android |
| `KEY_PASSWORD` | Android |
| `P12_BASE64` | iOS |
| `P12_PASSWORD` | iOS |
| `PROVISIONING_PROFILE_BASE64` | iOS |
| `KEYCHAIN_PASSWORD` | iOS |

---

## 🚀 Verify It Works

1. Push a commit to `main` or `master`, or go to **Actions** → **Build & Release** → **Run workflow**
2. The workflow will:
   - ✅ Build signed Android APKs (Universal + Split)
   - ✅ Build signed iOS IPA
   - ✅ Build Linux `.tar.gz`
   - ✅ Build Windows `.zip`
   - ✅ Build Web `.zip`
3. All artifacts are attached to a GitHub Release

---

## 🔧 Troubleshooting

| Problem | Likely Fix |
|---|---|
| `base64: command not found` | `sudo apt install coreutils` (Linux) |
| APK build fails | Check `KEYSTORE_PASSWORD` and `KEY_PASSWORD` |
| `Invalid keystore format` | Re-encode with `base64 -w0` (no line breaks) |
| iOS signing fails | Verify your Distribution Certificate and Provisioning Profile are valid |
| `errSecInternalComponent` during iOS signing | Ensure `KEYCHAIN_PASSWORD` is set correctly |
| `No matching provisioning profiles` | Make sure the profile matches the App ID and certificate |
| Linux build fails | Ensure `ninja-build` and `libgtk-3-dev` are installed (CI handles this) |
| Windows build fails | Verify you're on the Windows runner (should be automatic) |
