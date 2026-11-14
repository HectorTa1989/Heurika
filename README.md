# Heurika

**Type naturally. Tap when you want help.**

An agentic iOS keyboard: an original implementation in the spirit of [Acti](https://apps.apple.com/us/app/acti-agentic-keyboard/id6745523677), rebuilt from scratch for [HectorTa1989](https://github.com/HectorTa1989). Type what you need, hold the Heurika Bar, and it either rewrites your text in place or resolves to a real action — a search, a map, a calendar invite, a Notion lookup — instead of just fixing grammar.

> Acti is a closed-source commercial App Store product, not an open repo like some of the other rebuilds in this GitHub — there was no code to fork. Everything below is a fresh implementation of the same *category* of product (type an intent, get an action), built from first principles for what a keyboard extension can actually, honestly do.

---

## What Heurika does

| Mechanic | What it is |
|---|---|
| **Heurika action** | Type your intent, then tap the dedicated Heurika control above the keys. An LLM selects the best rewrite or result Deed. Standard letter, space, and return keys keep standard keyboard behavior. |
| **Deeds** | Two kinds: **rewrite** transforms text in place, while **act** inserts a useful HTTPS link, workspace result, or calendar draft without launching another app. |
| **Typing assistance** | On-device spelling corrections, word completions, user-lexicon suggestions, and automatic capitalization work without Full Access. |
| **Deed Builder** | Describe a rewrite Deed in plain English in the app; Heurika drafts the name, icon, and instruction for you to review and save. |
| **Deed Sharing** | Export any Deed as a small `.json` file through the system share sheet (AirDrop, Messages, etc.) and import one the same way. No account, no backend. |
| **AI privacy** | Consent is explicit and provider-specific. Only text the person deliberately runs through a Deed is sent; ordinary typing is never logged or transmitted. |
| **Heurika Pro** | RevenueCat-gated: unlimited Deeds/day, OpenAI + Anthropic providers, unlimited custom Deeds, Notion Search. Free plan gets the built-ins, Groq only, 15/day. |

## On not making things up

The Heurika Bar's router is explicitly instructed that it has **no access to live data** — no scores, prices, hours, or current events — and to never fabricate an answer. When a request needs real information, it resolves to a search/Maps Deed and hands off to the real source, rather than letting the model guess. This is enforced in the system prompt itself (`PromptBuilder.buildIntentResolution`), not just a README claim.

Two features that could easily have been faked were deliberately scoped to what's real instead:
- **LinkedIn** doesn't offer a public profile-search API to third-party consumer apps. The LinkedIn Deed opens real LinkedIn search results — it does not scrape or claim to "pull" a profile inline.
- **Notion Search** is a real API call against the person's own integration token, scoped to only the pages they've explicitly shared with that integration inside Notion. Nothing is invented if there's no match.

## What a keyboard extension can actually see

This shaped a lot of the design, so it's worth stating plainly: iOS gives a third-party keyboard `documentContextBeforeInput` / `documentContextAfterInput` — a *possibly-truncated, not-guaranteed* window of text around the cursor — and lets it insert text or delete backward. **There is no API for a keyboard extension to read an arbitrary text selection in the host app.** Every Deed in Heurika is therefore scoped to "the text you just typed before the cursor," not "whatever's highlighted." (Interestingly, Android's `InputConnection.getSelectedText()` *can* do this — a future Android port would actually gain a capability here, not just port one over.)

Apple's keyboard-extension rules prohibit launching other apps and repurposing ordinary keyboard buttons. Heurika therefore inserts search/map/meeting links and calendar drafts into the current text field. Consequential actions remain under the person's control in the destination app.

## Screenshots

Not included — this repo was generated without access to a macOS/Xcode toolchain or a simulator to run and capture the app, so there are no real screenshots to show honestly. Build and run it (see Setup) and it'll look like the parchment/espresso/gold system described below.

---

## Design

Vintage: parchment, espresso, antique gold, a crimson accent for destructive/urgent states. Playfair Display carries headlines, Lora carries body text and UI labels — both bundled as static weight instances (Regular/Medium/SemiBold/Bold/Italic) generated from Google Fonts' variable-font sources, licensed OFL (`Heurika/Resources/Fonts/OFL-*.txt`).

The keyboard's own letter keys deliberately **stay on the system font** — legibility at ~15pt and the extension's tight memory budget both favor it over a decorative serif. The vintage identity still comes through via the parchment/gold color palette on the action bar, key caps, and status strip. This is a considered trade-off, not an oversight — see `HeurikaFont.swift`'s doc comment.

The paywall is a fully custom SwiftUI screen built on the core `Purchases` SDK, not RevenueCat's prebuilt `RevenueCatUI` paywall component — that was the only way to get the actual vintage design system onto it rather than a generic template.

---

## Project Structure

```
Heurika/
├── project.yml                        # XcodeGen spec — generates the .xcodeproj
├── README.md
├── LICENSE
├── .gitignore
│
├── Packages/HeurikaCore/              # Shared Swift Package (App + Extension both link this)
│   ├── Package.swift
│   ├── Sources/HeurikaCore/
│   │   ├── HeurikaConstants.swift     # App Group ID, Keychain group, free-plan limits
│   │   ├── Models/
│   │   │   ├── Deed.swift             # The Deed model + the 14 built-in Deeds
│   │   │   ├── AIProviderType.swift   # Groq / OpenAI / Anthropic + per-provider settings
│   │   │   └── SubscriptionStatus.swift
│   │   ├── Deeds/
│   │   │   ├── AIActionService.swift  # Orchestrator: gating → provider → prompt → call
│   │   │   ├── IntentResolver.swift   # Powers the Heurika Bar's routing
│   │   │   ├── IntentResolution.swift # Structured JSON-schema output shape
│   │   │   ├── PromptBuilder.swift    # All prompt construction, pure + testable
│   │   │   └── DeedBuilderAssistant.swift # AI-assisted custom Deed drafting
│   │   ├── Networking/
│   │   │   ├── AIProviderClient.swift # Protocol + shared HTTP helpers
│   │   │   ├── GroqClient.swift
│   │   │   ├── OpenAIClient.swift
│   │   │   ├── AnthropicClient.swift
│   │   │   ├── NotionClient.swift     # Real Notion Search API, BYOK token
│   │   │   └── AIActionError.swift
│   │   ├── Storage/
│   │   │   ├── KeychainStore.swift    # API keys, shared via Keychain access group
│   │   │   ├── SharedDefaults.swift   # Settings/status, shared via App Group
│   │   │   ├── DeedsRepository.swift  # Custom Deed CRUD + export/import
│   │   │   └── UsageTracker.swift     # Free-plan daily counter
│   │   └── DesignSystem/
│   │       ├── HeurikaColor.swift
│   │       ├── HeurikaFont.swift
│   │       └── HeurikaTheme.swift
│   └── Tests/HeurikaCoreTests/        # 6 files — see Testing below
│
├── Heurika/                            # App target
│   ├── App/
│   │   ├── HeurikaApp.swift            # Entry point, RevenueCat config, URL handoff
│   │   ├── PurchasesManager.swift      # The only file that imports RevenueCat
│   ├── Features/
│   │   ├── Root/RootView.swift
│   │   ├── Onboarding/                 # OnboardingView, KeyboardSetupGuideView
│   │   ├── Home/                       # Dashboard + live scratchpad
│   │   ├── Deeds/                      # List, editor (+ AI draft), Deed Key picker
│   │   ├── Settings/                   # Provider/key management, Notion setup
│   │   └── Paywall/                    # Custom vintage paywall UI
│   ├── Components/                     # VintageButton, VintageTextField, DeedIconBadge
│   └── Resources/
│       ├── Info.plist / *.entitlements / PrivacyInfo.xcprivacy
│       ├── Assets.xcassets/            # AppIcon (generated), AccentColor, LaunchBackground
│       └── Fonts/                      # 9 bundled .ttf + 2 OFL license files
│
└── HeurikaKeyboard/                    # Keyboard extension target
    ├── KeyboardViewController.swift    # UIInputViewController — the whole extension's entry point
    ├── Engine/
    │   ├── KeyboardLayoutProvider.swift # Pure QWERTY/numbers/symbols layout data
    │   ├── KeyboardState.swift         # ObservableObject the SwiftUI views observe
    │   ├── TextContextReader.swift     # documentContextBeforeInput, bounded
    │   └── DeedExecutor.swift          # Runs a Deed: rewrite in place, open URL, hand off
    ├── Views/                          # KeyboardRootView, KeyRowView, ActionBarView, ...
    ├── Info.plist / *.entitlements / PrivacyInfo.xcprivacy
```

62 Swift files total: 22 in the app target, 11 in the keyboard extension, 22 Core sources, 6 Core tests, plus `Package.swift`.

---

## Why BYOK (bring your own key)

Every provider — Groq, OpenAI, Anthropic — requires the person's own API key, entered in Settings and stored in Keychain. There is no shared embedded key anywhere in this codebase. Two reasons:

1. **Security.** A key baked into a client binary is extractable by anyone who downloads the app, and gets abused — this is a well-known anti-pattern, not a hypothetical.
2. **No infrastructure dependency.** A "free shared tier" done properly needs a backend proxy holding the real secret server-side with its own rate limiting — real infrastructure to build, host, and pay for. Groq offers a genuinely free API tier for individual developers, so BYOK-with-Groq-as-default means the free plan costs the person $0 without Heurika operating any servers at all.

## Setup

**Prerequisites:** macOS with Xcode 26+ and the iOS 26 SDK for current App Store uploads, plus [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
git clone <this-repo>
cd Heurika
xcodegen generate
open Heurika.xcodeproj
```

1. **Production build settings** — supply `HEURIKA_REVENUECAT_API_KEY`, `HEURIKA_PRIVACY_POLICY_URL`, `HEURIKA_TERMS_OF_USE_URL`, and `HEURIKA_SUPPORT_URL` through an uncommitted xcconfig or CI release settings. Missing values are surfaced in Settings and purchases stay disabled; the app never falls back to fake URLs or template credentials.
2. **RevenueCat dashboard** — create a project at [app.revenuecat.com](https://app.revenuecat.com), add the App Store Connect subscriptions, create an entitlement called exactly `pro`, and attach the packages to the `default` offering.
3. **App Group + Keychain Sharing** — `project.yml` already wires these into both targets' entitlements. If Xcode complains about provisioning, open each target's Signing & Capabilities tab and confirm both capabilities point at your team.
4. **Bundle IDs** — currently `com.hectorta1989.heurika` / `.keyboard`. Change the bundle, App Group, and Keychain identifiers together if you're shipping under another team.
5. **Build & run** the `Heurika` scheme, then in Settings → Keyboards add Heurika and enable **Allow Full Access** for network-backed AI Deeds.
6. **Consent and provider key** — approve the selected provider in onboarding or Settings → AI Privacy & Consent, then add that provider's key under AI Provider & Keys.

## Known limitations

- **No arbitrary text selection** — see "What a keyboard extension can actually see" above. This is an iOS platform constraint, not a missed feature.
- **`deleteBackward()` counts grapheme clusters** the same way `String.count` does for the overwhelming majority of text; a small number of exotic ZWJ emoji sequences can diverge by a character or two. Documented in `KeyboardViewController.replaceContext`, not silently assumed perfect.
- **No swipe/glide typing.** The keyboard now has native spelling/completion suggestions and automatic capitalization, but gesture typing remains a separate input engine.
- **Voice dictation was considered and not built.** It's architecturally independent of everything here (`SFSpeechRecognizer` + a mic button + permission flow) and would be a clean v1.1 addition — flagging this honestly rather than claiming it exists.
- **iPhone only for v1** (`TARGETED_DEVICE_FAMILY: "1"` in `project.yml`) — an iPad-sized keyboard layout is a real design task of its own, not just a checkbox.
- **No Android port.** Acti is actually cross-platform (both App Store and Play Store), but Android's `InputMethodService`/`InputConnection` model is different enough (and, per above, strictly more capable for text selection) that it deserves its own pass rather than a rushed appendix to an iOS-first build.
- **This repo was generated without Xcode/macOS available**, so nothing here has been through `xcodebuild`. Every file was written carefully and cross-checked mechanically (font PostScript names, App Group/Keychain identifiers, and URL scheme were all verified to match byte-for-byte across every file that references them; every `.swift` file passed a brace/paren/string-balance check; every `.plist`/`.entitlements`/`.xcprivacy` was confirmed well-formed XML; `project.yml` was confirmed valid YAML). None of that substitutes for an actual build — do that first before pointing this at a real device.

## Testing

`Packages/HeurikaCore/Tests/HeurikaCoreTests` covers prompt construction, provider-specific AI consent, free/Pro gating, Deed Codable round-tripping, daily-usage rollover, validated custom-Deed CRUD/export/import, and intent-resolution decoding.

Run with `cd Packages/HeurikaCore && swift test`, or via Xcode's Test Navigator once the project is open (package tests surface there automatically).

`KeyboardViewController`, the View/ViewModel layers, and `UITextDocumentProxy` interactions are **not** unit tested. They require a host-app UI-test harness plus physical-device QA before release.

## License

MIT — see `LICENSE`. Playfair Display and Lora are OFL-licensed (Google Fonts); their license files are bundled alongside the fonts in `Heurika/Resources/Fonts/`.
