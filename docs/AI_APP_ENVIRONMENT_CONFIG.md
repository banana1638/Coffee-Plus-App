# AI App Environment Config

## Required Dart Define Keys

Required API/media keys include:

- COFFEE_API_BASE_URL
- COFFEE_PUBLIC_ORIGIN
- COFFEE_STORAGE_ORIGIN

Optional Reverb keys:

- COFFEE_REVERB_ENABLED (defaults to false)
- COFFEE_REVERB_HOST (required when enabled)
- COFFEE_REVERB_PORT (defaults to 8080)
- COFFEE_REVERB_APP_KEY (required when enabled)
- COFFEE_REVERB_TLS (required when enabled)
- COFFEE_REVERB_AUTH_ENDPOINT (required when enabled)

Optional/debug keys:

- COFFEE_VERBOSE_API_LOGS

## Detected Loader

- lib/services/app_config.dart uses `String.fromEnvironment`, `int.fromEnvironment`, and `bool.fromEnvironment`.
- Missing required string values throw `StateError`.
- `COFFEE_PUBLIC_ORIGIN` can be derived from `COFFEE_API_BASE_URL` when omitted.
- `COFFEE_STORAGE_ORIGIN` can be derived from public origin when omitted.

## Local Run Example

Do not commit real local secrets.

flutter run --dart-define-from-file=.env.local.json

## Rules

- Do not hardcode private LAN IPs in source code.
- Keep machine-specific env files out of source control unless they are examples.
- Fail clearly if required env values are missing.
- Backend public origin must match media/storage URL behavior.
- Reverb config must match backend config.
- Keep COFFEE_REVERB_ENABLED false when no Reverb server is deployed.
