# **Status V2** — Pock Widget

> ### **GIF Supporting**
> Show an animated GIF directly on your Touch Bar, right alongside your status items.

A Touch Bar widget for [Pock](https://pock.app) that combines a full system status bar with animated GIF playback — all in one widget.

---

## Features

- **Clock** — customizable date & time format
- **WiFi** — signal strength indicator
- **Battery** — icon and/or percentage
- **Input Source** — current keyboard language
- **Animated GIF** — load from a local file or any URL, displayed on the right edge of the widget

---

## Requirements

- macOS 10.15 or later
- [Pock](https://pock.app) installed

---

## Installation

1. Download the latest `.pock` file from [Releases](../../releases)
2. Double-click it — Pock will install it automatically
3. Open Pock → Widgets Manager and enable **Status V2**

---

## Building from Source

No CocoaPods required. The project uses **Swift Package Manager**.

1. Clone the repo
2. Open `Status.xcodeproj` in Xcode
3. Xcode will automatically resolve the SPM dependencies ([PockKit](https://github.com/pock/pockkit), [TinyConstraints](https://github.com/roberthein/TinyConstraints))
4. Build (`⌘B`) — the `.pock` bundle appears in the Products group
5. Double-click the built `.pock` to install

---

## Preferences

Open **Pock → Widgets Manager → Status V2** to configure:

| Setting | Description |
|---|---|
| Language / Input Source | Toggle the input source indicator |
| WiFi Signal | Toggle the WiFi signal icon |
| Battery | Toggle battery display; choose icon and/or percentage |
| Date & Time | Toggle the clock; set a custom date/time format |
| **Show GIF** | Enable animated GIF on the right edge |
| Source | Load GIF from a local **file** or a **URL** |
| Width | Set the GIF display width (30–300 pt) |
| Scaling | Fit / Fill (crop) / Stretch |
| Preview | Live preview of your GIF at Touch Bar height |

---

## Credits

Based on the original [status-widget](https://github.com/pock/status-widget) by [Pierluigi Galdi](https://github.com/pigigaldi).
GIF integration and Status V2 by [EvyatarEshkar](https://github.com/EvyatarEshkar).
