import 'dart:convert';

import 'package:genkit/genkit.dart';
import 'package:genkit/client.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiAlarmChoice {
  const AiAlarmChoice({
    required this.hour24,
    required this.minute,
    required this.label,
    required this.aiTag,
  });

  final int hour24;
  final int minute;
  final String label;
  final String aiTag;

  factory AiAlarmChoice.fromMap(Map<String, dynamic> map) {
    final parsedHour = _parseHour(map);
    final parsedMinute = _parseMinute(map);

    return AiAlarmChoice(
      hour24: parsedHour,
      minute: parsedMinute,
      label: (map['label']?.toString().trim().isNotEmpty ?? false)
          ? map['label'].toString().trim()
          : 'Smart Wake',
      aiTag: (map['aiTag']?.toString().trim().isNotEmpty ?? false)
          ? map['aiTag'].toString().trim()
          : 'Daily AI routine',
    );
  }

  static int _parseHour(Map<String, dynamic> map) {
    final directHour = int.tryParse((map['hour24'] ?? map['hour'] ?? '').toString());
    if (directHour != null) {
      return directHour.clamp(0, 23);
    }

    final timeText = (map['time'] ?? map['time24'] ?? map['time_24'] ?? '').toString();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeText);
    if (match == null) {
      return 7;
    }

    return int.parse(match.group(1)!).clamp(0, 23);
  }

  static int _parseMinute(Map<String, dynamic> map) {
    final directMinute = int.tryParse((map['minute'] ?? '').toString());
    if (directMinute != null) {
      return directMinute.clamp(0, 59);
    }

    final timeText = (map['time'] ?? map['time24'] ?? map['time_24'] ?? '').toString();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeText);
    if (match == null) {
      return 30;
    }

    return int.parse(match.group(2)!).clamp(0, 59);
  }
}

class WeeklyAlarmPlanItem {
  const WeeklyAlarmPlanItem({
    required this.dayOfWeek,
    required this.hour24,
    required this.minute,
    required this.label,
    required this.aiTag,
  });

  final int dayOfWeek;
  final int hour24;
  final int minute;
  final String label;
  final String aiTag;

  factory WeeklyAlarmPlanItem.fromMap(Map<String, dynamic> map) {
    final day = int.tryParse((map['dayOfWeek'] ?? map['day'] ?? '').toString())
            ?.clamp(1, 7) ??
        1;
    final parsed = AiAlarmChoice.fromMap(map);
    return WeeklyAlarmPlanItem(
      dayOfWeek: day,
      hour24: parsed.hour24,
      minute: parsed.minute,
      label: parsed.label,
      aiTag: parsed.aiTag,
    );
  }
}

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
  static const _missingKeyMessage =
      'AI is offline. Add GEMINI_API_KEY using --dart-define to enable live Gemini responses.';
  static const _groqModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.1-8b-instant',
  );
  static const _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  bool get _hasApiKey =>
      const String.fromEnvironment('GEMINI_API_KEY').trim().isNotEmpty;

  String get _groqApiKey {
    final env = dotenv.isInitialized ? dotenv.env['GROQ_API_KEY']?.trim() ?? '' : '';
    if (env.isNotEmpty) {
      return env;
    }
    return const String.fromEnvironment('GROQ_API_KEY').trim();
  }

  bool get _hasGroqApiKey => _groqApiKey.isNotEmpty;

  // Configure this with your deployed Genkit endpoint.
  static String suggestAlarmFlowUrl = '';
  static String dailyAlarmChoicesFlowUrl = const String.fromEnvironment(
    'GENKIT_GROQ_DAILY_ALARM_FLOW_URL',
  );
  static String weeklyPlannerFlowUrl = const String.fromEnvironment(
    'GENKIT_GROQ_WEEKLY_PLAN_FLOW_URL',
  );

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

    if (!_hasApiKey) {
      return fallback;
    }

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

  Future<List<AiAlarmChoice>> getDailyAlarmChoices({
    required int dayOfWeek,
    required String routine,
  }) async {
    if (dailyAlarmChoicesFlowUrl.isNotEmpty) {
      try {
        final payload = jsonEncode({
          'model': _groqModel,
          'dayOfWeek': dayOfWeek,
          'routine': routine,
          'task': 'daily_alarm_choices',
          'outputFormat':
              'Return JSON only. {"choices":[{"time":"07:30","label":"Gym Wake","aiTag":"Hydrate first"}]}',
        });

        final flow = defineRemoteAction<String, String, String, void>(
          url: dailyAlarmChoicesFlowUrl,
          fromResponse: (jsonData) => jsonData.toString(),
          fromStreamChunk: (jsonData) => jsonData.toString(),
        );

        final response = await flow.call(input: payload);
        final parsed = _parseChoicesFromResponse(response);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {
        // Fall back to local suggestions when remote Genkit flow is unavailable.
      }
    }

    if (_hasGroqApiKey) {
      try {
        final response = await _groqJsonResponse(
          systemPrompt:
              'You create practical alarm suggestions. Return strictly valid JSON only.',
          userPrompt:
              'Generate 3 alarm choices for dayOfWeek=$dayOfWeek and routine="$routine". '
              'Use model intent: $_groqModel. '
              'Output format: {"choices":[{"time":"07:30","label":"Gym Wake","aiTag":"Hydrate first"}]}.',
        );
        final parsed = _parseChoicesFromResponse(response);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {
        // Continue to local fallback.
      }
    }

    return _localDailyFallback(dayOfWeek, routine);
  }

  List<AiAlarmChoice> _parseChoicesFromResponse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    String jsonText = trimmed;
    final start = trimmed.indexOf('{');
    final listStart = trimmed.indexOf('[');
    final firstToken = (listStart >= 0 && (start == -1 || listStart < start))
        ? listStart
        : start;

    if (firstToken > 0) {
      jsonText = trimmed.substring(firstToken);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      return const [];
    }

    final List<dynamic> choicesRaw;
    if (decoded is List) {
      choicesRaw = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['choices'] is List) {
      choicesRaw = decoded['choices'] as List<dynamic>;
    } else {
      return const [];
    }

    return choicesRaw
        .whereType<Map>()
        .map((item) => AiAlarmChoice.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<AiAlarmChoice> _localDailyFallback(int dayOfWeek, String routine) {
    final normalizedRoutine = routine.toLowerCase();
    final isWeekend = dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday;

    if (normalizedRoutine.contains('gym') || normalizedRoutine.contains('workout')) {
      return const [
        AiAlarmChoice(
          hour24: 6,
          minute: 0,
          label: 'Gym Start',
          aiTag: 'Train before traffic and hydrate early.',
        ),
        AiAlarmChoice(
          hour24: 6,
          minute: 30,
          label: 'Balanced Workout',
          aiTag: 'Wake with enough prep time for breakfast.',
        ),
        AiAlarmChoice(
          hour24: 7,
          minute: 0,
          label: 'Recovery Mode',
          aiTag: 'Slightly later wake for sleep debt recovery.',
        ),
      ];
    }

    if (isWeekend) {
      return const [
        AiAlarmChoice(
          hour24: 7,
          minute: 45,
          label: 'Weekend Reset',
          aiTag: 'Wake consistently without oversleeping.',
        ),
        AiAlarmChoice(
          hour24: 8,
          minute: 15,
          label: 'Light Morning',
          aiTag: 'Gentle weekend wake to keep rhythm stable.',
        ),
        AiAlarmChoice(
          hour24: 8,
          minute: 45,
          label: 'Late Weekend',
          aiTag: 'Use only if you need extra rest today.',
        ),
      ];
    }

    return const [
      AiAlarmChoice(
        hour24: 6,
        minute: 30,
        label: 'Focus Start',
        aiTag: 'Early wake for deep work and planning.',
      ),
      AiAlarmChoice(
        hour24: 7,
        minute: 0,
        label: 'Commute Ready',
        aiTag: 'Buffer for commute and morning routine.',
      ),
      AiAlarmChoice(
        hour24: 7,
        minute: 20,
        label: 'Gentle Workday',
        aiTag: 'Smoother wake-up with lower sleep inertia.',
      ),
    ];
  }

  Future<List<WeeklyAlarmPlanItem>> generateWeeklyAlarmPlan({
    required String routine,
    required String meetings,
    required bool gymDays,
    required int commuteMinutes,
    required int sleepDebtMinutes,
  }) async {
    if (weeklyPlannerFlowUrl.isNotEmpty) {
      try {
        final payload = jsonEncode({
          'model': _groqModel,
          'task': 'weekly_alarm_planner',
          'routine': routine,
          'meetings': meetings,
          'gymDays': gymDays,
          'commuteMinutes': commuteMinutes,
          'sleepDebtMinutes': sleepDebtMinutes,
          'outputFormat':
              'Return JSON only: {"plan":[{"dayOfWeek":1,"time":"06:30","label":"Workday","aiTag":"Reason"}]}',
        });

        final flow = defineRemoteAction<String, String, String, void>(
          url: weeklyPlannerFlowUrl,
          fromResponse: (jsonData) => jsonData.toString(),
          fromStreamChunk: (jsonData) => jsonData.toString(),
        );

        final response = await flow.call(input: payload);
        final parsed = _parseWeeklyPlan(response);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {
        // Fall back locally.
      }
    }

    if (_hasGroqApiKey) {
      try {
        final response = await _groqJsonResponse(
          systemPrompt:
              'You are an alarm planning assistant. Return strictly valid JSON only.',
          userPrompt:
              'Build a 7-day alarm plan from: routine="$routine", meetings="$meetings", '
              'gymDays=$gymDays, commuteMinutes=$commuteMinutes, sleepDebtMinutes=$sleepDebtMinutes. '
              'Use model intent: $_groqModel. '
              'Output format: {"plan":[{"dayOfWeek":1,"time":"06:30","label":"Workday","aiTag":"Reason"}]}.',
        );
        final parsed = _parseWeeklyPlan(response);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {
        // Continue to local fallback.
      }
    }

    return _localWeeklyPlan(
      routine: routine,
      meetings: meetings,
      gymDays: gymDays,
      commuteMinutes: commuteMinutes,
      sleepDebtMinutes: sleepDebtMinutes,
    );
  }

  Future<String> _groqJsonResponse({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final key = _groqApiKey;
    if (key.isEmpty) {
      throw StateError('Missing GROQ_API_KEY');
    }

    final body = {
      'model': _groqModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.3,
      'response_format': {'type': 'json_object'},
    };

    final response = await http.post(
      Uri.parse(_groqApiUrl),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Groq request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw StateError('Invalid Groq response');
    }

    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw StateError('Invalid Groq response item');
    }

    final message = first['message'];
    if (message is! Map<String, dynamic>) {
      throw StateError('Missing Groq message');
    }

    final content = message['content']?.toString() ?? '';
    if (content.trim().isEmpty) {
      throw StateError('Empty Groq content');
    }

    return content;
  }

  List<WeeklyAlarmPlanItem> _parseWeeklyPlan(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    String jsonText = trimmed;
    final start = trimmed.indexOf('{');
    final listStart = trimmed.indexOf('[');
    final firstToken = (listStart >= 0 && (start == -1 || listStart < start))
        ? listStart
        : start;
    if (firstToken > 0) {
      jsonText = trimmed.substring(firstToken);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      return const [];
    }

    final List<dynamic> planRaw;
    if (decoded is List) {
      planRaw = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['plan'] is List) {
      planRaw = decoded['plan'] as List<dynamic>;
    } else {
      return const [];
    }

    return planRaw
        .whereType<Map>()
        .map((item) => WeeklyAlarmPlanItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<WeeklyAlarmPlanItem> _localWeeklyPlan({
    required String routine,
    required String meetings,
    required bool gymDays,
    required int commuteMinutes,
    required int sleepDebtMinutes,
  }) {
    final baseHour = commuteMinutes > 50 ? 6 : 7;
    final debtAdjustment = sleepDebtMinutes > 60 ? 20 : 0;
    final hasEarlyMeetings = meetings.toLowerCase().contains('8:') ||
        meetings.toLowerCase().contains('9:00');

    final plan = <WeeklyAlarmPlanItem>[];
    for (var day = 1; day <= 7; day++) {
      final weekend = day == 6 || day == 7;
      final gymMorning = gymDays && (day == 2 || day == 4 || day == 6);
      final hour = weekend
          ? (baseHour + 1)
          : (gymMorning ? (baseHour - 1).clamp(5, 8) : baseHour);
      final minute = hasEarlyMeetings && !weekend ? 20 : (30 + debtAdjustment).clamp(0, 59);

      plan.add(
        WeeklyAlarmPlanItem(
          dayOfWeek: day,
          hour24: hour,
          minute: minute,
          label: weekend
              ? 'Weekend Plan'
              : gymMorning
                  ? 'Gym Day Plan'
                  : 'Workday Plan',
          aiTag: routine.isEmpty
              ? 'AI weekly baseline optimized'
              : 'AI tuned for $routine',
        ),
      );
    }

    return plan;
  }

  Future<String> chatReply({
    required String userMessage,
    required String insightContext,
    List<String> recentMessages = const [],
  }) async {
    if (!_hasApiKey) {
      return _missingKeyMessage;
    }

    final history = recentMessages.join('\n');
    const fallback =
        'I can help plan your alarms, focus blocks, and sleep schedule. Tell me your goal for today.';

    try {
      final response = await _ai.generate(
        model: googleAI.gemini(_model),
        prompt:
            'You are FlowMind AI, a concise productivity and sleep coach. '
            'Keep replies practical and short (2-5 sentences). '
            'Use this live context from the app when useful: $insightContext '
            'Recent conversation: $history '
            'User message: $userMessage',
      );

      final text = response.text.trim();
      return text.isEmpty ? fallback : text;
    } catch (_) {
      return fallback;
    }
  }

  Future<String> generateInsightSummary({
    required String computedInsight,
    required String alarmsContext,
  }) async {
    if (!_hasApiKey) {
      return computedInsight;
    }

    try {
      final response = await _ai.generate(
        model: googleAI.gemini(_model),
        prompt:
            'You are an insights assistant in a focus app. Rewrite the insight into one short actionable sentence. '
            'Current insight: $computedInsight. Alarm context: $alarmsContext',
      );
      final text = response.text.trim();
      return text.isEmpty ? computedInsight : text;
    } catch (_) {
      return computedInsight;
    }
  }
}
