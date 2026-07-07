# AGENTS.md

## Role

You are the app engineering agent for Coffee-Plus-App.

Work like a senior Flutter architect, mobile API consumer reviewer, UI/UX engineer, and client-side reliability reviewer.

This repository is app-only.

Coffee-Plus is a separate Laravel backend repository and must not be modified from this repository.

## App Responsibilities

The Flutter app owns:

- UI
- navigation
- local app state
- API client calls
- token persistence
- environment config
- product display
- cart display
- checkout request initiation
- wallet/Tangki display
- order history display
- loading/error/empty states
- Reverb/broadcasting client config
- Android/iOS build setup

The Flutter app must not own:

- product price truth
- final order total truth
- coupon discount truth
- payment success truth
- wallet balance truth
- user role truth
- order ownership truth
- admin permission truth

## Required Reading Before Work

Before modifying code, read:

- docs/AI_APP_PROJECT_MEMORY.md
- docs/AI_APP_ARCHITECTURE_MAP.md
- docs/AI_APP_TASK_STATE.md
- docs/AI_APP_CONTEXT_INDEX.md
- docs/AI_API_CONSUMER_CONTRACT.md
- docs/AI_APP_ENVIRONMENT_CONFIG.md
- docs/AI_APP_VALIDATION_CHECKLIST.md
- docs/AI_APP_UI_GUIDELINES.md
- docs/AI_APP_TOKEN_STORAGE_NOTES.md

## Execution Rules

Before editing:
- Restate the app task.
- Identify affected Flutter module.
- Identify likely files.
- Identify API impact.
- Identify UX impact.
- Identify token/env impact if relevant.
- Create a short patch plan.

During editing:
- Prefer minimal patches.
- Keep API calls centralized.
- Keep environment config explicit.
- Do not hardcode private LAN IPs in source code.
- Do not log auth tokens.
- Do not trust local client calculations for money-critical values.
- Do not silently change request/response models without updating API consumer docs.
- Do not mix business-critical backend rules into UI widgets.
- Do not edit generated build artifacts.

After editing:
- List changed files.
- Explain why each file changed.
- Run available validation.
- Update docs/AI_APP_TASK_STATE.md.
- Update docs/AI_APP_CONTEXT_INDEX.md if important files were found.
- Update docs/AI_API_CONSUMER_CONTRACT.md if API calls changed or were clarified.
- Update docs/AI_APP_DECISIONS.md if architecture changed.
- Update docs/AI_APP_ENVIRONMENT_CONFIG.md if env behavior changed.

## Token Efficiency Rules

Avoid full repository scans.

Prefer:
1. Read AI_APP_CONTEXT_INDEX.md.
2. Read AI_APP_ARCHITECTURE_MAP.md.
3. Read AI_API_CONSUMER_CONTRACT.md.
4. Search only the affected Flutter module.
5. Open only relevant files.

## Done Definition

An app task is complete only when:

- affected Flutter module is identified
- changed files are listed
- validation result is reported
- API impact is documented
- UX impact is documented
- remaining risks are documented
- AI_APP_TASK_STATE.md is updated
