import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/quote_analysis.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-2.5-flash';

  Future<String> _callGemini(String prompt, {bool isJson = false}) async {
    final url = Uri.parse(
      '$_baseUrl/$_model:generateContent?key=${AppConfig.geminiApiKey}',
    );

    final Map<String, dynamic> config = {
      'temperature': 0.7,
      'topK': 40,
      'topP': 0.95,
      'maxOutputTokens': 2048,
    };

    if (isJson) {
      config['responseMimeType'] = 'application/json';
    }

    final body = json.encode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': config,
    });

    try {
      print('[GeminiService] Calling Gemini API with model: $_model');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('[GeminiService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) {
          print('[GeminiService] Got response text (${text.length} chars)');
          return text;
        }
        throw Exception('No text in Gemini response: ${response.body}');
      } else {
        print('[GeminiService] API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[GeminiService] Exception: $e');
      rethrow;
    }
  }

  /// Extract JSON object from a string that may contain markdown code blocks
  Map<String, dynamic>? _extractJson(String text) {
    // Step 1: Try to extract from markdown code block ```json ... ``` or ``` ... ```
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final codeBlockMatch = codeBlockRegex.firstMatch(text);
    if (codeBlockMatch != null) {
      final inner = codeBlockMatch.group(1)!.trim();
      try {
        return json.decode(inner) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Step 2: Try to find raw JSON object { ... }
    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace > firstBrace) {
      final jsonStr = text.substring(firstBrace, lastBrace + 1);
      try {
        return json.decode(jsonStr) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Step 3: Try the whole text as JSON
    try {
      return json.decode(text.trim()) as Map<String, dynamic>;
    } catch (_) {}

    return null;
  }

  Future<Map<String, dynamic>> generateSolarReport(
    Map<String, dynamic> solarMetrics,
    Map<String, dynamic> financials,
  ) async {
    final prompt = '''
You are a solar energy consultant. Generate a friendly, jargon-free report for a homeowner.

TECHNICAL DATA:
- System Size: ${solarMetrics['systemSizeKw'].toStringAsFixed(1)} kW (${solarMetrics['maxPanels']} panels)
- Annual Production: ${solarMetrics['annualProductionKwh'].toStringAsFixed(0)} kWh
- Sunshine Hours: ${solarMetrics['sunshineHoursPerYear'].toStringAsFixed(0)} hrs/year
- Roof Area: ${solarMetrics['roofAreaM2'].toStringAsFixed(0)} m2
- Roof Segments: ${solarMetrics['roofSegmentCount']}

FINANCIAL DATA:
- System Cost: USD ${financials['estimatedCost'].toStringAsFixed(0)}
- After Tax Credit: USD ${financials['afterTaxCredit'].toStringAsFixed(0)}
- Annual Savings: USD ${financials['annualSavings'].toStringAsFixed(0)}
- Payback Period: ${financials['paybackYears'].toStringAsFixed(1)} years

Return a JSON object with these keys:
- suitabilityScore: (number 0-100)
- scoreExplanation: (string)
- productionSummary: (string)
- treesEquivalent: (number)
- keyInsights: (list of strings)
''';

    try {
      final text = await _callGemini(prompt, isJson: true);
      final jsonData = _extractJson(text);
      if (jsonData == null) {
        print('[GeminiService] Failed to extract JSON from: $text');
        throw Exception('No JSON found in AI response');
      }
      return jsonData;
    } catch (e) {
      print('[GeminiService] generateSolarReport failed: $e');
      return _generateFallbackReport(solarMetrics);
    }
  }

  Future<String> chatAboutSolar(
    String question,
    Map<String, dynamic> context,
  ) async {
    final prompt = '''
You are a helpful solar energy expert. Answer this homeowner's question in a friendly, jargon-free way.

THEIR ROOF DETAILS:
- System Size: ${context['systemSizeKw']} kW
- Annual Production: ${context['annualProductionKwh']} kWh/year
- Estimated Cost: USD ${context['estimatedCost']}
- Payback Period: ${context['paybackYears']} years

USER QUESTION: $question

Provide a helpful answer in 2-4 paragraphs. Use plain text only.
''';

    try {
      final response = await _callGemini(prompt);
      return response;
    } catch (e) {
      print('[GeminiService] chatAboutSolar failed: $e');
      return 'I\'m having trouble connecting right now. Error: $e';
    }
  }

  Future<QuoteAnalysis> analyzeInstallerQuote(
    String quoteText,
    Map<String, dynamic> solarData,
  ) async {
    final pricePerWatt = AppConfig.pricePerWatt;
    final prompt = '''
You are a solar installation fraud detector. Analyze this installer quote for red flags.

FAIR MARKET BENCHMARKS (2026):
- Price: USD $pricePerWatt per watt
- Financing: 0-3% APR
- Warranties: 25-year panels, 10-year inverter

HOMEOWNER'S ACTUAL NEEDS:
- Optimal System Size: ${solarData['systemSizeKw']} kW
- Annual Production Needed: ${solarData['annualProductionKwh']} kWh
- Fair Price Estimate: USD ${solarData['estimatedCost']}

INSTALLER QUOTE TO ANALYZE:
$quoteText

Analyze for these red flags:
1. OVERPRICING: Compare quote price to market rate
2. SYSTEM OVERSIZING: Compare proposed size to needs
3. PREDATORY FINANCING: Check for APR >3%
4. MISSING WARRANTIES: Check for 25yr panels
5. PRESSURE TACTICS: Check for limited time offers

Return a JSON object in this format:
{
  "redFlags": [
    {
      "severity": "high" | "medium" | "low",
      "icon": "warning",
      "title": "Short title",
      "description": "Full explanation",
      "impact": "Financial impact string"
    }
  ],
  "questions": ["Question 1", "Question 2"],
  "verdict": "AVOID" | "PROCEED_WITH_CAUTION" | "FAIR" | "GOOD"
}
''';

    try {
      final text = await _callGemini(prompt, isJson: true);
      print('[GeminiService] Quote analysis raw response: $text');

      final jsonData = _extractJson(text);
      if (jsonData == null) {
        print('[GeminiService] Failed to extract JSON from quote analysis: $text');
        throw Exception('No JSON found in AI response');
      }

      return QuoteAnalysis.fromJson(jsonData);
    } catch (e) {
      print('[GeminiService] analyzeInstallerQuote failed: $e');
      return QuoteAnalysis(
        redFlags: [
          RedFlag(
            severity: 'medium',
            icon: '⚠️',
            title: 'ANALYSIS ERROR',
            description: 'Unable to analyze quote automatically: $e',
          ),
        ],
        recommendedQuestions: [
          'What is your price per watt?',
          'Can you provide an itemized breakdown?',
          'What warranties are included?',
        ],
        overallVerdict: 'MANUAL_REVIEW_NEEDED',
        analysisDate: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> _generateFallbackReport(Map<String, dynamic> metrics) {
    final score = (metrics['maxPanels'] as int) > 20 ? 85 : 65;
    final annualKwh = metrics['annualProductionKwh'] as double;

    return {
      'suitabilityScore': score,
      'scoreExplanation': score > 75
          ? 'Your roof has excellent solar potential with ample space and good sun exposure.'
          : 'Your roof has moderate solar potential.',
      'productionSummary':
          'Your roof produces approximately ${(annualKwh / 1000).toStringAsFixed(1)} MWh per year.',
      'treesEquivalent': (annualKwh * 0.7 / 21).round(),
      'keyInsights': [
        'Significant clean energy potential',
        'Consider multiple installer quotes',
        '30% federal tax credit available',
      ],
    };
  }
}
