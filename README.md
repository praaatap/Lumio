# Lumio

Lumio is a Flutter alarm and focus app with AI-assisted alarm suggestions.

## AI Setup

The app supports two AI paths:

- Gemini direct calls (existing features):
	- `GEMINI_API_KEY`
- Genkit remote flow for Groq daily alarm choices:
	- `GENKIT_GROQ_DAILY_ALARM_FLOW_URL`
	- `GROQ_MODEL` (optional, default: `llama-3.1-8b-instant`)
	- `GROQ_API_KEY` (optional direct Groq fallback when flow URL is not set)

Example run command:

```bash
flutter run \
	--dart-define=GEMINI_API_KEY=your_gemini_key \
	--dart-define=GENKIT_GROQ_DAILY_ALARM_FLOW_URL=https://your-genkit-host/dailyAlarmChoices \
	--dart-define=GROQ_MODEL=llama-3.1-8b-instant
```

You can also place `GROQ_API_KEY` in `.env` for device runtime usage:

```dotenv
GROQ_API_KEY="your_groq_key"
```

The app loads `.env` at startup and will use `GROQ_API_KEY` directly for daily choices and weekly planner if a Genkit flow URL is unavailable.

The `GENKIT_GROQ_DAILY_ALARM_FLOW_URL` endpoint should be a Genkit flow that:

1. Accepts a JSON string payload with day and routine context.
2. Calls Groq with a Llama Instant model.
3. Returns JSON with alarm options, for example:

```json
{
	"choices": [
		{"time":"06:30","label":"Focus Start","aiTag":"Early deep-work wake"},
		{"time":"07:00","label":"Balanced Start","aiTag":"Commute-friendly wake"}
	]
}
```
