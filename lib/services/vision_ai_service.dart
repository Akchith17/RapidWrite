import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/aesthetic_evaluation.dart';
import '../models/handwriting_metrics.dart';
import '../models/handwriting_stroke.dart';
import 'aesthetic_evaluator_service.dart';

/// Service that coordinates visual handwriting evaluation through either
/// a Vision Model API (Google Gemini 1.5/2.0 Flash via HTTP) or the local computer-vision engine.
class VisionAiService {
  static final VisionAiService _instance = VisionAiService._internal();
  factory VisionAiService() => _instance;
  VisionAiService._internal();

  String? _apiKey;
  String? get apiKey => _apiKey;

  void setApiKey(String? key) {
    _apiKey = key?.trim();
  }

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Performs holistic aesthetic evaluation.
  /// If [imageBytes] and [apiKey] are available, queries the Gemini Vision API.
  /// Otherwise, seamlessly utilizes the local Computer Vision heuristic engine.
  Future<AestheticEvaluation> evaluate({
    required List<HandwritingStroke> strokes,
    required Uint8List? imageBytes,
    required String targetSentence,
    required String ocrRecognizedText,
    required HandwritingMetrics metrics,
  }) async {
    // If no API key or no image bytes, run the robust local computer vision heuristics
    if (!hasApiKey || imageBytes == null || imageBytes.isEmpty) {
      return AestheticEvaluatorService.evaluate(strokes);
    }

    try {
      final base64Image = base64Encode(imageBytes);

      final prompt = '''
You are an expert calligrapher and handwriting analyst evaluating a handwritten tablet stylus sample.
Target sentence: "$targetSentence"
On-device OCR recognized: "$ocrRecognizedText"
Physical active writing velocity: ${metrics.activeVelocityPxPerSec.toStringAsFixed(1)} px/s
Total active drawing duration: ${(metrics.activeDrawingTimeMs / 1000).toStringAsFixed(2)} seconds
Total strokes: ${metrics.strokeCount}

Analyze the visual aesthetics holistically:
1. Baseline straightness & horizontal drift
2. Slant angle consistency
3. Stroke smoothness, curvature, and tremor
4. Line weight dynamics & neatness
5. Overall visual aesthetic appeal

Return ONLY valid JSON matching this schema:
{
  "overallAestheticScore": 88.5,
  "neatnessScore": 90.0,
  "baselineAlignmentScore": 86.0,
  "slantConsistencyScore": 91.0,
  "strokeSmoothnessScore": 89.0,
  "pressureRhythmScore": 87.0,
  "grade": "A",
  "critiqueTitle": "Fluid & Harmonious Penmanship",
  "visualObservations": [
    "Consistent forward slant across letter ascenders",
    "Solid baseline alignment with minimal downward drift"
  ],
  "coachingTips": [
    "Slightly relax downstroke pressure on the final words",
    "Maintain uniform spacing between consecutive word blocks"
  ]
}
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0.2,
          }
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawJsonText =
            decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        final parsed = jsonDecode(rawJsonText);
        return AestheticEvaluation(
          overallAestheticScore: (parsed['overallAestheticScore'] as num).toDouble(),
          neatnessScore: (parsed['neatnessScore'] as num).toDouble(),
          baselineAlignmentScore: (parsed['baselineAlignmentScore'] as num).toDouble(),
          slantConsistencyScore: (parsed['slantConsistencyScore'] as num).toDouble(),
          strokeSmoothnessScore: (parsed['strokeSmoothnessScore'] as num).toDouble(),
          pressureRhythmScore: (parsed['pressureRhythmScore'] as num).toDouble(),
          grade: parsed['grade']?.toString() ?? 'A',
          critiqueTitle: parsed['critiqueTitle']?.toString() ?? 'Visual Aesthetic Assessment',
          visualObservations: List<String>.from(parsed['visualObservations'] ?? []),
          coachingTips: List<String>.from(parsed['coachingTips'] ?? []),
          evaluatedBy: 'Gemini 1.5 Flash Vision AI',
        );
      } else {
        debugPrint('[VisionAiService] API returned code: ${response.statusCode}. Falling back to local engine.');
        return AestheticEvaluatorService.evaluate(strokes);
      }
    } catch (e) {
      debugPrint('[VisionAiService] AI evaluation error: $e. Falling back to local engine.');
      return AestheticEvaluatorService.evaluate(strokes);
    }
  }
}
