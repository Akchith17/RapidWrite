import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;
import '../models/handwriting_stroke.dart';

/// Ultra-high precision handwriting OCR service wrapping Google ML Kit Digital Ink Recognition
/// on Android/iOS native platforms, and high-fidelity Google Digital Ink API on Web and tablets.
///
/// Enhancements:
/// - Preserves 100% of punctuation, periods, and dots on 'i' and 'j' (no lossy stroke filtering).
/// - Dynamic handwriting bounding-box writing guide for optimal neural network aspect ratio.
/// - Monotonic time normalization and jitter deduplication.
/// - Multi-candidate contextual ranking matching against target words/sentences.
class DigitalInkService {
  static final DigitalInkService _instance = DigitalInkService._internal();
  factory DigitalInkService() => _instance;
  DigitalInkService._internal();

  final String _languageCode = 'en';
  mlkit.DigitalInkRecognizer? _recognizer;
  final mlkit.DigitalInkRecognizerModelManager _modelManager =
      mlkit.DigitalInkRecognizerModelManager();

  bool _isModelReady = false;
  bool _isDownloading = false;
  String _lastUsedEngine = 'Google Digital Ink';

  bool get isModelReady => _isModelReady;
  bool get isDownloading => _isDownloading;
  String get lastUsedEngine => _lastUsedEngine;

  /// Initializes the recognizer and downloads model if not present.
  Future<void> initialize() async {
    if (kIsWeb) {
      _isModelReady = true;
      _isDownloading = false;
      debugPrint('[DigitalInkService] Web environment detected. Ready with Google Digital Ink Web API.');
      return;
    }

    try {
      _recognizer = mlkit.DigitalInkRecognizer(languageCode: _languageCode);
      final isDownloaded = await _modelManager.isModelDownloaded(_languageCode);

      if (!isDownloaded) {
        _isDownloading = true;
        debugPrint('[DigitalInkService] Downloading ML Kit language model: $_languageCode');
        final success = await _modelManager.downloadModel(_languageCode);
        _isDownloading = false;
        _isModelReady = success;
        debugPrint('[DigitalInkService] Model download finished: $success');
      } else {
        _isModelReady = true;
        debugPrint('[DigitalInkService] ML Kit language model already ready.');
      }
    } catch (e) {
      debugPrint('[DigitalInkService] Error initializing ML Kit: $e');
      _isModelReady = false;
      _isDownloading = false;
    }
  }

  /// Builds optimized Google Input Tools compatible handwriting payload.
  Map<String, dynamic> _buildGoogleInputToolsPayload(List<HandwritingStroke> strokes) {
    int minT = strokes.first.points.isNotEmpty ? strokes.first.points.first.timestampMs : 0;
    double minX = double.infinity, minY = double.infinity;
    double maxX = 0, maxY = 0;

    for (final s in strokes) {
      for (final p in s.points) {
        if (minT == 0 || p.timestampMs < minT) minT = p.timestampMs;
        if (p.x < minX) minX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.x > maxX) maxX = p.x;
        if (p.y > maxY) maxY = p.y;
      }
    }

    // Dynamic guide boundaries matching actual tablet writing geometry
    final guideWidth = (maxX - minX + 150).clamp(600.0, 3200.0).round();
    final guideHeight = (maxY - minY + 150).clamp(400.0, 2400.0).round();

    final ink = <List<List<num>>>[];
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final xs = <num>[];
      final ys = <num>[];
      final ts = <num>[];

      if (stroke.points.length == 1) {
        // Crucial: Single-point dots (on 'i', 'j', periods, commas) must not be lost.
        // We synthesize a micro-point 1px away with +12ms delta so OCR neural networks recognize it.
        final p = stroke.points.first;
        final relT = (p.timestampMs - minT).clamp(0, 9999999);
        xs.addAll([p.x.round(), (p.x + 0.5).round()]);
        ys.addAll([p.y.round(), (p.y + 0.5).round()]);
        ts.addAll([relT, relT + 12]);
      } else {
        num lastT = -1;
        for (int i = 0; i < stroke.points.length; i++) {
          final p = stroke.points[i];
          num relT = (p.timestampMs - minT).clamp(0, 9999999);
          if (relT <= lastT) {
            relT = lastT + 2; // enforce strict monotonic time progression
          }
          lastT = relT;
          xs.add(p.x.round());
          ys.add(p.y.round());
          ts.add(relT);
        }
      }
      ink.add([xs, ys, ts]);
    }

    return {
      'requests': [
        {
          'writing_guide': {
            'writing_area_width': guideWidth,
            'writing_area_height': guideHeight,
          },
          'ink': ink,
          'language': _languageCode,
        }
      ]
    };
  }

  /// Selects the best candidate from neural network predictions, taking advantage of
  /// target sentence hints when available while preserving natural handwritten variance.
  String _selectBestCandidate(List<dynamic> candidates, String? targetHint) {
    if (candidates.isEmpty) return '';
    final strCandidates = candidates
        .map((c) => c.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (strCandidates.isEmpty) return '';
    if (targetHint == null || targetHint.trim().isEmpty) {
      return strCandidates.first;
    }

    final targetClean = targetHint.trim().toLowerCase();
    String bestCandidate = strCandidates.first;
    double bestScore = -1.0;

    for (final cand in strCandidates) {
      final candClean = cand.toLowerCase();
      final dist = _levenshteinDistance(targetClean, candClean);
      final maxLen = targetClean.length > candClean.length ? targetClean.length : candClean.length;
      double score = maxLen > 0 ? (1.0 - (dist / maxLen)) * 100.0 : 0.0;

      // Bonus for preserving word boundaries (spaces)
      if (cand.contains(' ') && targetHint.contains(' ')) {
        score += 8.0;
      }
      // Bonus for matching initial capitalization
      if (cand.isNotEmpty && targetHint.isNotEmpty && cand[0] == targetHint[0]) {
        score += 3.0;
      }
      // Bonus for ending punctuation match
      if (cand.endsWith('.') && targetHint.endsWith('.')) {
        score += 4.0;
      }

      if (score > bestScore) {
        bestScore = score;
        bestCandidate = cand;
      }
    }

    return bestCandidate;
  }

  /// Converts user drawn strokes into recognized text.
  /// Seamlessly utilizes on-device ML Kit on native mobile (Android/iOS tablets),
  /// and connects via high-speed Google Digital Ink API on Web.
  Future<String> recognizeStrokes(
    List<HandwritingStroke> strokes, {
    String? targetHint,
  }) async {
    if (strokes.isEmpty) return '';

    // Filter out completely empty strokes, but preserve dots & small strokes!
    final validStrokes = strokes
        .where((s) => s.points.isNotEmpty)
        .toList();

    debugPrint(
      '[DigitalInkService] Total strokes: ${strokes.length}, valid: ${validStrokes.length}',
    );

    if (validStrokes.isEmpty) {
      _lastUsedEngine = 'Google Digital Ink';
      return '';
    }

    // ── 1. On-device Google ML Kit (Android / iOS tablets) ───────────────────
    if (!kIsWeb) {
      try {
        _recognizer ??= mlkit.DigitalInkRecognizer(languageCode: _languageCode);

        if (!_isModelReady) {
          await initialize();
        }

        final mlkit.Ink mlkitInk = mlkit.Ink();

        for (final stroke in validStrokes) {
          final mlkitStroke = mlkit.Stroke();
          if (stroke.points.length == 1) {
            final p = stroke.points.first;
            mlkitStroke.points.add(mlkit.StrokePoint(x: p.x, y: p.y, t: p.timestampMs));
            mlkitStroke.points.add(
              mlkit.StrokePoint(x: p.x + 0.5, y: p.y + 0.5, t: p.timestampMs + 10),
            );
          } else {
            for (final p in stroke.points) {
              mlkitStroke.points.add(
                mlkit.StrokePoint(x: p.x, y: p.y, t: p.timestampMs),
              );
            }
          }
          mlkitInk.strokes.add(mlkitStroke);
        }

        final candidates = await _recognizer!.recognize(mlkitInk);
        debugPrint(
          '[DigitalInkService] ML Kit returned ${candidates.length} candidates: '
          '${candidates.take(5).map((c) => '"${c.text}"').join(', ')}',
        );

        if (candidates.isNotEmpty) {
          final candidateTexts = candidates.map((c) => c.text).toList();
          final bestMatch = _selectBestCandidate(candidateTexts, targetHint);
          if (bestMatch.isNotEmpty) {
            _lastUsedEngine = 'Google ML Kit (On-Device)';
            return bestMatch;
          }
        }
      } catch (e) {
        debugPrint('[DigitalInkService] On-device ML Kit fallback to Cloud API: $e');
      }
    }

    // ── 2. Google Digital Ink Cloud API (Web, iPad Safari & universal fallback) ─
    try {
      final payload = _buildGoogleInputToolsPayload(validStrokes);
      final jsonPayload = jsonEncode(payload);

      final candidateEndpoints = <Uri>[
        if (kIsWeb) Uri.parse('/api/handwriting'),
        Uri.parse('http://localhost:8080/api/handwriting'),
        Uri.parse(
          'https://www.google.com/inputtools/request?ime=handwriting&app=mobilesearch&cs=1&oe=UTF-8',
        ),
      ];

      for (final endpoint in candidateEndpoints) {
        try {
          debugPrint('[DigitalInkService] Querying Google Digital Ink endpoint: $endpoint');
          final response = await http
              .post(
                endpoint,
                headers: {'Content-Type': 'application/json'},
                body: jsonPayload,
              )
              .timeout(const Duration(seconds: 8));

          if (response.statusCode == 200) {
            final dynamic decoded = jsonDecode(response.body);
            if (decoded is List && decoded.length > 1 && decoded[0] == 'SUCCESS') {
              final resultBlock = decoded[1];
              if (resultBlock is List && resultBlock.isNotEmpty) {
                final List<String> segmentMatches = [];

                // Iterate through all blocks (handles segmented multi-word sentences)
                for (final block in resultBlock) {
                  if (block is List && block.length > 1) {
                    final candidates = block[1];
                    if (candidates is List && candidates.isNotEmpty) {
                      final segment = _selectBestCandidate(candidates, targetHint);
                      if (segment.isNotEmpty) {
                        segmentMatches.add(segment);
                      }
                    }
                  }
                }

                if (segmentMatches.isNotEmpty) {
                  final recognized = segmentMatches.join(' ').trim();
                  _lastUsedEngine = kIsWeb
                      ? 'Google Digital Ink (Web Engine)'
                      : 'Google Digital Ink Cloud';
                  debugPrint('[DigitalInkService] Successfully recognized: "$recognized"');
                  return recognized;
                }
              }
            }
          }
        } catch (innerErr) {
          debugPrint('[DigitalInkService] Endpoint $endpoint failed: $innerErr');
        }
      }
    } catch (e) {
      debugPrint('[DigitalInkService] Cloud handwriting recognition error: $e');
    }

    _lastUsedEngine = 'Google Digital Ink';
    debugPrint('[DigitalInkService] Exhausted recognizers – returning empty.');
    return '';
  }

  /// Calculates text accuracy percentage using Levenshtein distance.
  static double calculateCharacterAccuracy(String target, String recognized) {
    if (target.isEmpty) return recognized.isEmpty ? 100.0 : 0.0;
    if (recognized.isEmpty) return 0.0;

    final t = target.trim().toLowerCase();
    final r = recognized.trim().toLowerCase();

    final distance = _levenshteinDistance(t, r);
    final maxLen = t.length > r.length ? t.length : r.length;
    final similarity = ((maxLen - distance) / maxLen) * 100.0;
    return similarity.clamp(0.0, 100.0);
  }

  /// Calculates word-level match percentage.
  static double calculateWordAccuracy(String target, String recognized) {
    final targetWords = target
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final recognizedWords = recognized
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toSet();

    if (targetWords.isEmpty) return 100.0;

    int matches = 0;
    for (final word in targetWords) {
      if (recognizedWords.contains(word)) {
        matches++;
      }
    }

    return (matches / targetWords.length) * 100.0;
  }

  static int _levenshteinDistance(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,      // deletion
          dp[i][j - 1] + 1,      // insertion
          dp[i - 1][j - 1] + cost // substitution
        ].reduce((curr, next) => curr < next ? curr : next);
      }
    }

    return dp[m][n];
  }

  void dispose() {
    _recognizer?.close();
  }
}
