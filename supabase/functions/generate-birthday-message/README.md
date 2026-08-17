# `generate-birthday-message`

Supabase Edge Function that generates a short birthday SMS via OpenRouter (`google/gemma-4-26b-a4b-it:free`). The OpenRouter API key stays on the server — the iOS app only calls this function with the Supabase anon key.

## Secrets

```bash
supabase secrets set OPENROUTER_API_KEY=sk-or-v1-...
```

## Deploy

From the repo root (with the Supabase CLI linked to your project):

```bash
supabase functions deploy generate-birthday-message
```

Endpoint:

```text
https://<project-ref>.supabase.co/functions/v1/generate-birthday-message
```

## Request

`POST` JSON:

```json
{
  "name": "Alex",
  "tone": "casual",
  "age": 30,
  "userHint": "mention hiking",
  "previousMessageToAvoid": null
}
```

`tone`, `age`, `userHint`, and `previousMessageToAvoid` may be `null` / omitted.

## Response

```json
{ "message": "Happy birthday, Alex! Hope the trails are amazing this year." }
```

## App config

In the iOS app, set placeholders in `Birthday/Model/OpenRouterConfig.swift` (or Info.plist keys `SUPABASE_URL` / `SUPABASE_ANON_KEY`):

- `SUPABASE_URL` — project root **or** full invoke URL (both work):
  - `https://xxxx.supabase.co`
  - `https://xxxx.supabase.co/functions/v1/generate-birthday-message`
- `SUPABASE_ANON_KEY` — project anon key (public)

Never put `OPENROUTER_API_KEY` in the app.
