<div align="center">

# Mune

### Heal what’s heavy

*A private companion for breakup healing — especially when the hurt feels unbearable.*

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-green.svg)](#)
[![Privacy](https://img.shields.io/badge/Privacy-Local%20First-purple.svg)](#)

</div>

---

## App in Action

<div align="center">
<table>
  <tr>
    <td align="center" width="50%">
      <b>Welcome & Home</b><br><br>
      <img src=".github/assets/welcome-home.gif" width="200" alt="Welcome and Home">
    </td>
    <td align="center" width="50%">
      <b>Chat & Journal</b><br><br>
      <img src=".github/assets/chat-journal.gif" width="200" alt="Chat and Journal">
    </td>
  </tr>
  <tr>
    <td align="center">
      <b>Calm Space</b><br><br>
      <img src=".github/assets/calm-space.gif" width="200" alt="Calm Space">
    </td>
    <td align="center">
      <b>Settings & Privacy</b><br><br>
      <img src=".github/assets/settings-privacy.gif" width="200" alt="Settings and Privacy">
    </td>
  </tr>
</table>
</div>

---

## What is Mune?

Mune is a private, local-first iOS app for people going through a breakup. It helps you process heavy feelings, find calm in hard moments, and slowly come back to yourself — with daily check-ins, breakup-aware AI chat, journaling, healing days, and a Calm Space when you're overwhelmed. Everything stays privately on your device.

---

## Features

**Daily check-ins**
Log how you feel each day after the breakup. Mune tracks your healing week and shows gentle patterns over time.

**Breakup support — Talk to Mune**
Have a real conversation with AI that understands breakup recovery — grief, hard urges, and rebuilding. Powered by OpenAI via a secure backend proxy. Chat stays in memory only and is never stored by Mune.

**Journal**
Process the breakup in writing or by voice. Log gratitudes and reflect on what you're learning. Your journal stays entirely on your device using SwiftData.

**Calm Space**
For the moments you want to text them, checked their socials, or feel like day one again. Includes guided breathing, 5-4-3-2-1 grounding, a private vent pad (say it without sending it), a drawing canvas, a call-a-friend contact picker, and worldwide crisis links (IASP Find a Helpline + local emergency).

**Healing days**
Optionally track gentle days of space from your ex as a quiet reminder you’re caring for yourself — not as a streak-pressure tool.

**Personal setup**
Choose your name and healing goals during onboarding — healing days, processing grief, hard-moment support, rebuilding your routine. Everything adapts to feel like *your* Mune.

---

## Privacy

- All mood entries, journal entries, and profile data are stored **locally on your device** using SwiftData
- AI features may send moods, optional notes, chat messages, and brief journal context to OpenAI through a secure proxy
- No account required, no tracking, no third-party analytics
- [Privacy Policy](https://shehanish.github.io/Mend/privacy-policy.html)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Architecture | MVVM |
| Local storage | SwiftData |
| AI | OpenAI API via Cloudflare Workers proxy |
| Notifications | UserNotifications (local only) |
| Voice | AVFoundation + Speech framework (on-device) |

---

## Running Locally

1. **Clone the repo**
   ```bash
   git clone https://github.com/shehanish/Mend.git
   cd Mend
   ```

2. **Open in Xcode**
   Open `Mend.xcodeproj`

3. **Configure the API key** *(optional — only needed for AI features)*

   The app uses a Cloudflare Workers proxy by default. To run AI features locally:
   - Duplicate `Mend/Config/Secrets.example.xcconfig` → rename to `Secrets.xcconfig`
   - Add your OpenAI key: `MYAPI_KEY = sk-your-key-here`
   - In `AppConfig.swift`, set `proxyURL = nil` to call OpenAI directly

4. **Build and run**
   Select a simulator or device → `Cmd + R`

---

## Project Structure

```
Mend/
├── AI/                  OpenAI service + insight models
├── Config/              AppConfig, xcconfig files
├── Data/Repositories/   SwiftData repositories (mood, journal)
├── Models/              MoodEntry, JournalEntry, ChatMessage
├── ViewModel/           HomeViewModel, ChatViewModel, JournalViewModel...
└── Views/
    ├── Components/      Reusable views (HomeView, MoodPicker, BlobAvatar...)
    ├── AuthView         Onboarding flow
    ├── ChatView         AI chat
    ├── JournalView      Journal + history
    ├── PanicRoomView    Calm Space
    └── SettingsView     Notifications + preferences
```

---

## Crisis Resources

Calm Space and Chat point people to **[IASP Find a Helpline](https://www.iasp.info/suicidalthoughts/)** (worldwide) and local emergency services (**112** in the EU, **911** in the US). US devices may also see **988**. Mune is not a crisis service.

Calm Space ambient audio is from Pixabay; see `THIRD_PARTY_AUDIO.md`.

---

<div align="center">
  <sub>Built with care · Your breakup story is yours</sub>
</div>
