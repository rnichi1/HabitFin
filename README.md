# HabitFin App

HabitFin is a SwiftUI and SwiftData application designed to help users manage their grocery finances. Features include OCR-based receipt tracking and GPT-powered analysis.

## Preview

### App Logo and Icon
<div style="display: flex; align-items: center; gap: 20px;">
  <img src="https://github.com/rnichi1/HabitFin/blob/main/HabitFin/Preview/HabitFin.png" alt="App Logo" width="300">
  <img src="https://github.com/rnichi1/HabitFin/blob/main/HabitFin/Preview/icon.jpg" alt="App Icon" width="120">
</div>

### App Demo
https://github.com/user-attachments/assets/a15f0e1b-4a0c-48a2-988d-091cf88e6685

---

## Features

- **OCR-powered Receipt Scanning:** Extract data from physical receipts and track expenses seamlessly.
- **GPT-Powered Insights:** Amazing performance and accuracy thanks to GPT-4o-mini integration.
- **Expense Tracker:** Monitor your spending and manage budgets effectively.
- **Virtual Kitchen Integration:** Keep track of your pantry by adding receipt items directly.

---

## Requirements

- **macOS:** Requires macOS Ventura 13.0 or later.
- **iOS:** Requires iOS 16.0 or later (real device recommended for OCR features).
- **Xcode:** Version 14.0 or higher.
- **OpenAI API Key:** You need an OpenAI API key to use the LLM-powered features.

---

## Installation & Setup

### Running on macOS
1. Clone the repository:
   ```bash
   git clone https://github.com/rnichi1/HabitFin.git
   cd HabitFin

2. Open the project in Xcode:
open/create Config.xcconfig
Add GPT_API_KEY and set it to your API key.

3. Build and run the app on a simulator or a real device (recommended for OCR functionality).

### Running on iOS (Real Device)

Ensure your device is connected to your Mac.
Select your device in Xcode and click Run.

### Running on Linux or Windows

HabitFin is designed for iOS/macOS due to SwiftUI not being useable on other platforms.

## OCR

OCR functionality relies on Vision framework, which requires a real iOS device to operate. The simulator will not support OCR features. Ensure the app has permission to access the camera for scanning receipts.
