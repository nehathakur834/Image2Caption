# ai_caption_app

Flutter app for generating image-based social captions and hashtags with OpenAI.

## Run

1. Install dependencies:
   `flutter pub get`
2. Add your key in a local `.env` file:
   `OPENAI_API_KEY=your_openai_api_key`
3. Start the app:
   `flutter run`

If you change `.env`, do a full restart of the app so Flutter reloads the asset.

You can also pass the key at runtime instead:
   `flutter run --dart-define=OPENAI_API_KEY=your_openai_api_key`

## What It Does

- Pick an image from camera or gallery
- Send the image to OpenAI for analysis
- Generate 3 caption suggestions
- Generate matching hashtags
- Save generated results to local history

## Security Note

Do not hardcode your OpenAI API key in the app source. Passing it with
`--dart-define` or a local `.env` file is safer for local development, but for
a production app you should move OpenAI requests behind your own backend so the
key is never shipped inside the client app.
