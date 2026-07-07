# AI App Validation Checklist

Try safe commands:

flutter pub get
flutter analyze
flutter test

For local run:

flutter run --dart-define-from-file=.env.local.json

For debug build:

flutter build apk --debug --dart-define-from-file=.env.local.json

If dependencies or device are unavailable, record the limitation.
