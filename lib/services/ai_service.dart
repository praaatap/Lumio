import 'package:genkit/genkit.dart';
import 'package:genkit/client.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';

class AiService {
  AiService({String? apiKey, String model = 'gemini-2.5-flash'})
    : _model = model,
      _ai = Genkit(
        plugins: [
          googleAI(
            apiKey: apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
          ),
        ],
      );

  final String _model;
  final Genkit _ai;

  // Configure this with your deployed Genkit endpoint.
  static String suggestAlarmFlowUrl = '';

  Future<String> getAISuggestion(String userInput) async {
    if (suggestAlarmFlowUrl.isNotEmpty) {
      try {
        final flow = defineRemoteAction<String, String, String, void>(
          url: suggestAlarmFlowUrl,
          fromResponse: (jsonData) => jsonData.toString(),
          fromStreamChunk: (jsonData) => jsonData.toString(),
        );
        return await flow.call(input: userInput);
      } catch (_) {
        // Fall through to direct model generation when remote flow is unavailable.
      }
    }

    return suggestBedtime(userInput);
  }

  Future<String> suggestBedtime(String context) async {
    const fallback = 'Try sleeping around 11:15 PM for recovery.';

    try {
      final response = await _ai.generate(
        model: googleAI.gemini(_model),
        prompt:
            'You are a sleep and focus assistant. Suggest one bedtime with a '
            'short rationale. User context: $context',
      );

      final text = response.text.trim();
      if (text.isEmpty) {
        return fallback;
      }
      return text;
    } catch (_) {
      return fallback;
    }
  }
}
