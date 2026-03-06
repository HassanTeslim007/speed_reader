# Speed Reader

A high-performance Flutter application designed to help you read faster using the **Rapid Serial Visual Presentation (RSVP)** method. This app allows you to import text from documents or paste URLs to read at adjustable speeds, with optional Text-to-Speech (TTS) narration.

## Features

- **Rapid Serial Visual Presentation (RSVP)**: Displays words one at a time in the center of the screen to eliminate subvocalization and improve reading speed.
- **Adjustable Speed**: Control the reading speed in Words Per Minute (WPM) to match your comfort level.
- **Text-to-Speech (TTS)**: Listen to the text being read aloud using your device's native speech engine.
- **Web Article Support**: Paste a URL, and the app will automatically fetch and format the article content for RSVP reading.
- **Document Support**: Import text from PDF and TXT files.
- **Clean & Minimalist UI**: A distraction-free interface focused on the text.

## Getting Started

### Prerequisites

- **Flutter**: Ensure you have Flutter installed and configured.
- **Dart**: Ensure you have Dart installed and configured.

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd speed_reader
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

Start the application on your desired device:

```bash
flutter run
```

## Usage

1. **Launch the App**: Open Speed Reader on your device.
2. **Import or Paste**: Use the "+" button to either paste a URL, import a document, or paste plain text.
3. **Configure**: Adjust the **WPM** (Words Per Minute) slider and toggle **TTS** (Text-to-Speech) if desired.
4. **Start Reading**: Tap the **Play** button to begin the RSVP reading session.
5. **Control**: Use the pause/resume and stop buttons to manage your reading session.

## Privacy Policy

We take your privacy seriously. Speed Reader is designed to be a **local-first** application.

- **No Data Collection**: We do not collect, store, or transmit any personal data.
- **Local Processing**: All text processing and file access happen locally on your device.
- **Web Articles**: When you input a URL, the app fetches the content directly from the website to your device. This URL is not logged or stored.

For more details, please refer to our [Privacy Policy](docs/index.html).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
