# Device Playground

> iOS playground для тестирования всех аппаратных и системных функций iPhone / iPad. Каждая функция — отдельная карточка с переключателем **On/Off** и кнопками действий.
> An iOS playground that tests every device & system feature. Each feature is its own card with an **On/Off** toggle and action buttons.

| | |
|---|---|
| Stack | SwiftUI · iOS 17+ · Swift 5.10 |
| UI | Liquid Glass cards (`.ultraThinMaterial` + tinted gradients), animated aurora background |
| Themes | Light / Dark / System |
| Languages | English / Русский / System |
| Build | GitHub Actions (macOS-15) → unsigned `.ipa` |

## ✨ Что внутри / What's inside

16 категорий, каждая — экран с независимыми переключателями:

1. 🔔 **Notifications** — local, push registration, action buttons, badge
2. 📳 **Haptics** — basic vibration, all impact styles, notification feedback, custom CHHaptic patterns
3. 🔊 **Audio** — playback, mic recording, background audio, system volume monitor
4. 📷 **Camera & Photo** — capture, gallery, QR/barcode, OCR via Vision
5. 📍 **Location** — current GPS, background tracking, geofencing, compass
6. 📡 **Sensors** — accelerometer, gyroscope, barometer, pedometer (CoreMotion)
7. ❤️ **Health & Fitness** — HealthKit availability, steps, heart rate
8. 🔐 **Biometry & Security** — Face ID/Touch ID, Keychain, AES-GCM (CryptoKit)
9. 🌐 **Network** — HTTP, WebSocket echo, BLE scanning, Wi-Fi SSID
10. 📁 **Storage** — FileManager, iCloud check, URLCache, Files-app integration
11. 🧠 **System Integrations** — App Intents (Siri/Shortcuts), Spotlight indexing
12. 📞 **Communication** — `tel://`, `sms://`, `mailto:`, Safari, Share Sheet
13. 🎮 **Graphics** — animations demo, gestures (drag/pinch/rotate/tap), ARKit/RealityKit cube
14. 🕒 **Background** — `BGAppRefreshTask`, `BGProcessingTask`, significant location changes
15. 💳 **Payments** — StoreKit 2 product fetch, Apple Pay button availability
16. 🚗 **Extras** — CarPlay/HomeKit notes, AirDrop via Share, NFC NDEF reader

## 🏗 Сборка / Building

Локально (нужен macOS + Xcode 15+):

```bash
brew install xcodegen
xcodegen generate
open DevicePlayground.xcodeproj
```

Через CI: каждый push в `main`/`master` или ручной запуск **Actions → Build unsigned IPA → Run workflow** соберёт unsigned `.ipa` и приложит как артефакт.

## 📲 Установка `.ipa` на iPhone / Installing the `.ipa`

`.ipa` собирается **без подписи** (без платного Apple Developer аккаунта). Ставьте одним из способов:

### 1. AltStore (бесплатный Apple ID, 7 дней)
1. Установите [AltServer](https://altstore.io) на macOS/Windows.
2. Установите AltStore на iPhone.
3. Скачайте `.ipa` из артефактов GitHub Actions.
4. AltStore → **+** → выбрать `.ipa` → войти Apple ID. Каждые 7 дней нужно "обновлять".

### 2. Sideloadly (бесплатный Apple ID)
1. [Sideloadly](https://sideloadly.io) → подключите iPhone по кабелю.
2. Перетащите `.ipa`, введите Apple ID, нажмите Start.

### 3. TrollStore (только устройства, на которые он ставится)
Если ваш iPhone поддерживает [TrollStore](https://github.com/opa334/TrollStore), `.ipa` ставится навсегда без перепрошивки.

### 4. Apple Developer ($99/год)
В Xcode откройте проект → выберите Team в Signing & Capabilities → Run.

## 🔑 Разрешения / Permissions

Все usage-описания заданы в `App/Info.plist`:
- Camera, Microphone, Photo Library
- Location (When-In-Use + Always)
- Motion, Health, Bluetooth, Local Network
- Face ID, Speech, Calendars, Reminders, Siri
- NFC, Nearby Interaction, Tracking

## ⚠️ Ограничения unsigned-сборки

Эти функции **не будут работать** без платного Apple Developer аккаунта и соответствующих entitlements:
- Push-уведомления (через сервер) — регистрация работает, доставка нет
- HealthKit (требует HealthKit entitlement)
- iCloud Documents / CloudKit
- Apple Pay (платежи)
- CarPlay, HomeKit
- Background modes для некоторых сценариев

В UI у таких карточек висит метка `Requires paid Apple Developer account`.

## 🗂 Структура проекта

```
App/
├── DevicePlaygroundApp.swift     # @main, AppDelegate
├── Info.plist                    # все NS*UsageDescription
├── Core/
│   ├── AppSettings.swift         # тема + язык (AppStorage)
│   ├── GlassStyle.swift          # liquid glass + animated aurora
│   └── FeatureCard.swift         # переиспользуемая карточка с toggle
├── Views/
│   ├── RootView.swift            # сетка категорий
│   ├── SettingsView.swift        # тема / язык
│   └── CategoryView.swift        # экран категории
├── Modules/
│   ├── NotificationsSection.swift
│   ├── HapticsSection.swift
│   ├── AudioSection.swift
│   ├── CameraSection.swift
│   ├── LocationSection.swift
│   ├── SensorsSection.swift
│   ├── HealthSection.swift
│   ├── BiometrySection.swift
│   ├── NetworkSection.swift
│   ├── StorageSection.swift
│   ├── SystemIntegrationsSection.swift
│   ├── CommunicationSection.swift
│   ├── GraphicsSection.swift
│   ├── BackgroundSection.swift
│   ├── PaymentsSection.swift
│   └── ExtrasSection.swift
├── Resources/
│   ├── en.lproj/Localizable.strings
│   └── ru.lproj/Localizable.strings
└── Assets.xcassets/
    ├── AppIcon.appiconset/       # сгенерированная liquid-glass иконка
    └── AccentColor.colorset/

scripts/make_icon.py              # перегенерировать иконку
project.yml                       # XcodeGen
.github/workflows/build-ipa.yml   # CI
```

## 📜 Лицензия

MIT
