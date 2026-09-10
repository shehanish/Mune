# Privacy Policy for Mune

**Last updated: September 10, 2026**

Mune ("we", "our", or "the app") is a personal wellness app designed to help you track your mood, journal your thoughts, and receive gentle AI-powered reflections. Your privacy is fundamental to how this app was built.

---

## 1. What Data We Collect

### Data stored only on your device
The following is stored locally using Apple's SwiftData framework and stays on your device unless you choose to use an AI feature described below:

- **Your name or nickname** (entered during onboarding)
- **Profile photo** (chosen with the system photo picker)
- **Mood check-ins** (mood selections and any notes you write)
- **Journal entries** (written entries and voice transcriptions)
- **App preferences** (healing focus, reminder time, display settings)
- **Healing-days streak settings** and calm-space drawings you choose to save

### Data sent when you use AI features
When you use mood reflections or Talk to Mune chat, relevant content is sent over HTTPS to generate a response:

- Your nickname
- Mood labels and counts from recent check-ins
- Optional check-in notes you wrote
- Chat messages you type
- Brief recent journal context (such as short journal snippets, transcript highlights, or gratitudes) when chat is personalized from your Home or Journal activity

Requests go through a **Cloudflare Worker proxy we operate** (`mend-openai-proxy`), which forwards them to **OpenAI, LLC**. The proxy is used so an OpenAI API key is not embedded in the app. We do not use this proxy to build marketing profiles or sell your data.

OpenAI's practices are governed by [OpenAI's Privacy Policy](https://openai.com/policies/privacy-policy).

### Data we never collect
- Precise location
- Device advertising identifiers for tracking
- Analytics SDKs or third-party ad tracking
- Cloud accounts or passwords (Mune is local-first; there is no Mune login server)

---

## 2. How We Use Your Data

| Purpose | Data used | Stored where |
|---------|-----------|-------------|
| Display your name in greetings | Name / nickname | On your device |
| Show your mood history and trends | Mood entries | On your device |
| Generate AI mood reflections | Moods, optional notes, name | Sent via proxy to OpenAI |
| AI chat support | Chat messages, optional journal context, name | Sent via proxy to OpenAI |
| Daily reminder notifications | Reminder time | On your device |
| Profile photo display | Photo data | On your device |
| Optional feedback email | Message and photos you choose to send | Sent by you via Mail / Gmail |

---

## 3. Third-Party Services

**Cloudflare Workers**
Used as a secure proxy for AI requests. We do not operate a general Mune user database.

**OpenAI, LLC**
Powers AI reflection and chat. Relevant data (described above) is sent to OpenAI when you use those features. You can avoid this by not using Chat or AI reflections.

**Apple frameworks**
- SwiftData (local database)
- UserNotifications (local notifications only)
- Contacts picker (system picker to call a support contact; Mune does not store your contacts)
- PhotosUI (profile / feedback photos stay on device unless you share feedback)
- Speech framework (voice journal transcription; Mune requests on-device recognition when available)

---

## 4. Permissions We Request

| Permission | Why |
|-----------|-----|
| Microphone | To record voice journal entries |
| Speech Recognition | To turn voice recordings into text |
| Contacts | System contact picker so you can call a friend from Calm Space |
| Notifications | Optional daily check-in reminders |

You can revoke permissions in **Settings → Privacy & Security** on your iPhone.

---

## 5. Important health notice

Mune is a breakup support and wellness tool. It is **not** therapy, **not** medical care, and **not** a crisis service. If you are in crisis, contact:

- **Find a local helpline**: [IASP Find a Helpline](https://www.iasp.info/suicidalthoughts/) (worldwide)
- **Emergency services**: call **112** in the EU (including Germany), or your local emergency number (for example **911** in the US)
- **United States**: call or text **988** (Suicide & Crisis Lifeline)

---

## 6. Children's Privacy

Mune is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you believe a child has used the app, contact us and we will help you remove local data guidance.

---

## 7. Data Retention & Deletion

All data stored locally on your device can be deleted by:
- Leaving or deleting a local profile space in the app
- Deleting the app from your device

We do not keep a cloud copy of your journal. OpenAI retention for API content follows OpenAI's policy.

---

## 8. Changes to This Policy

We may update this Privacy Policy as the app evolves. When we do, we will update the "Last updated" date at the top. Continued use after changes means you accept the updated policy.

---

## 9. Contact

**Email:** shehani1207@gmail.com  
**App:** Mune: Heal What’s Heavy on the Apple App Store  
**Privacy page:** https://shehanish.github.io/Mend/privacy-policy.html

---

*Mune is built with care. Your thoughts are yours.*
