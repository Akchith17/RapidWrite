import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import 'models/evaluation_result.dart';
import 'models/handwriting_stroke.dart';
import 'models/practice_settings.dart';
import 'models/target_sentence_model.dart';
import 'services/digital_ink_service.dart';
import 'services/aesthetic_evaluator_service.dart';
import 'services/profile_storage_service.dart';
import 'services/sentence_engine_service.dart';
import 'services/speed_calculator_service.dart';
import 'theme/app_theme.dart';
import 'widgets/canvas_background_painter.dart';
import 'widgets/canvas_toolbar.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/practice_settings_modal.dart';
import 'widgets/results_dashboard.dart';
import 'widgets/target_sentence_card.dart';
import 'services/prompt_generator_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer landscape orientation for tablet stylus penmanship, while allowing portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  runApp(const StylusEvaluatorApp());
}

class StylusEvaluatorApp extends StatelessWidget {
  const StylusEvaluatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAPID WRITE – Stylus Evaluator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HandwritingEvaluatorScreen(),
    );
  }
}

class HandwritingEvaluatorScreen extends StatefulWidget {
  const HandwritingEvaluatorScreen({super.key});

  @override
  State<HandwritingEvaluatorScreen> createState() =>
      _HandwritingEvaluatorScreenState();
}

class _HandwritingEvaluatorScreenState extends State<HandwritingEvaluatorScreen>
    with TickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey<DrawingCanvasState>();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Starting App Entrance Animation
  late final AnimationController _entranceController;
  late final Animation<double> _headerAnim;
  late final Animation<double> _cardAnim;
  late final Animation<double> _toolbarAnim;
  late final Animation<double> _canvasAnim;
  late final Animation<double> _bottomAnim;

  // Target sentence & adaptive practice settings state
  String _targetSentence = 'The quick brown fox jumps over the lazy dog';
  PracticeSettings _practiceSettings = PracticeSettings.defaultSettings();
  TargetSentenceModel? _targetSentenceModel;

  // Canvas tool states
  Color _selectedInkColor = AppTheme.inkMidnight;
  double _selectedStrokeWidth = 3.2;
  bool _isEraser = false;
  bool _strictStylusMode = true; // Palm rejection active by default for iPad & Android tablets
  PaperStyle _paperStyle = PaperStyle.ruled;
  bool _showResultAboveCanvas = false;

  // Active strokes and timing
  List<HandwritingStroke> _currentStrokes = [];
  int _firstStrokeTimeMs = 0;
  bool _hasStartedWriting = false;
  Timer? _liveTickerTimer;
  int _liveElapsedMs = 0;

  // Evaluation states
  bool _isEvaluating = false;
  String _evaluationStatusText = '';
  EvaluationResult? _lastResult;

  // Personal reference profile
  final ProfileStorageService _profileStorage = ProfileStorageService();
  bool _needsCalibration = false;

  @override
  void initState() {
    super.initState();
    _initServices();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Starting App Entrance Sequence with staggered fluid curves
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );

    _headerAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );

    _cardAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 0.65, curve: Curves.easeOutCubic),
    );

    _toolbarAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.82, curve: Curves.easeOutBack),
    );

    _canvasAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.95, curve: Curves.easeOutCubic),
    );

    _bottomAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
  }

  Future<void> _initServices() async {
    DigitalInkService().initialize();
    // Initialize profile & practice settings storage
    await _profileStorage.initialize();
    final loadedSettings = _profileStorage.cachedSettings;
    final generatedModel = SentenceEngineService.generateSentence(loadedSettings);

    if (mounted) {
      setState(() {
        _needsCalibration = !_profileStorage.hasProfile;
        _practiceSettings = loadedSettings;
        _targetSentenceModel = generatedModel;
        _targetSentence = generatedModel.text;
      });
    }
  }

  @override
  void dispose() {
    _liveTickerTimer?.cancel();
    _pulseController.dispose();
    _entranceController.dispose();
    DigitalInkService().dispose();
    super.dispose();
  }

  void _onFirstStrokeDown(int timestampMs) {
    if (!_hasStartedWriting) {
      setState(() {
        _hasStartedWriting = true;
        _firstStrokeTimeMs = timestampMs;
      });

      _liveTickerTimer?.cancel();
      _liveTickerTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted && _hasStartedWriting) {
          setState(() {
            _liveElapsedMs = DateTime.now().millisecondsSinceEpoch - _firstStrokeTimeMs;
          });
        }
      });
    }
  }

  void _onStrokesChanged(List<HandwritingStroke> strokes) {
    setState(() {
      _currentStrokes = strokes;
    });
  }

  void _clearCanvas() {
    _liveTickerTimer?.cancel();
    setState(() {
      _hasStartedWriting = false;
      _firstStrokeTimeMs = 0;
      _liveElapsedMs = 0;
      _currentStrokes = [];
      _lastResult = null;
      _showResultAboveCanvas = false;
    });
    _canvasKey.currentState?.clearCanvas();
  }

  void _openPracticeSettings() {
    PracticeSettingsModal.show(
      context: context,
      initialSettings: _practiceSettings,
      onStartPractice: (model) {
        setState(() {
          _targetSentenceModel = model;
          _targetSentence = model.text;
        });
        _clearCanvas();
      },
      onSaveSettings: (settings) async {
        setState(() {
          _practiceSettings = settings;
        });
        await _profileStorage.saveSettings(settings);
      },
    );
  }

  void _regenerateTargetSentence() {
    final model = SentenceEngineService.generateSentence(
      _practiceSettings,
      currentText: _targetSentence,
    );
    setState(() {
      _targetSentenceModel = model;
      _targetSentence = model.text;
    });
    _clearCanvas();
  }

  Future<void> _submitAndAnalyze() async {
    if (_currentStrokes.isEmpty || !_hasStartedWriting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write the sentence on the canvas using your stylus first!'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final submitTimeMs = DateTime.now().millisecondsSinceEpoch;
    _liveTickerTimer?.cancel();

    setState(() {
      _isEvaluating = true;
      _evaluationStatusText = 'Measuring physical stylus velocity...';
    });

    try {
      final metrics = SpeedCalculatorService.calculate(
        startTimeMs: _firstStrokeTimeMs,
        endTimeMs: submitTimeMs,
        strokes: _currentStrokes,
      );

      setState(() {
        _evaluationStatusText = 'Capturing high-resolution canvas snapshot...';
      });

      Uint8List? capturedImageBytes;
      String? savedImagePath;

      try {
        capturedImageBytes = await _canvasKey.currentState?.captureFullCanvas(pixelRatio: 2.0) ??
            await _screenshotController.capture(
              pixelRatio: 2.0,
              delay: const Duration(milliseconds: 50),
            );

        if (!kIsWeb && capturedImageBytes != null) {
          final tempDir = await getTemporaryDirectory();
          final filePath =
              '${tempDir.path}/canvas_eval_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(filePath);
          await file.writeAsBytes(capturedImageBytes);
          savedImagePath = filePath;
        }
      } catch (e) {
        debugPrint('[Evaluation] Screenshot capture error: $e');
      }

      setState(() {
        _evaluationStatusText = 'Recognizing digital ink with Google ML Kit...';
      });

      final recognizedText = await DigitalInkService().recognizeStrokes(
        _currentStrokes,
        targetHint: _targetSentence,
      );

      final charAccuracy = DigitalInkService.calculateCharacterAccuracy(
        _targetSentence,
        recognizedText,
      );
      final wordAccuracy = DigitalInkService.calculateWordAccuracy(
        _targetSentence,
        recognizedText,
      );

      setState(() {
        _evaluationStatusText = 'Evaluating aesthetics with RapidWrite 5-Stage Algorithm...';
      });

      final aestheticEvaluation = AestheticEvaluatorService.evaluate(
        _currentStrokes,
        targetSentence: _targetSentence,
        referenceProfile: _profileStorage.cachedProfile,
        ageCohort: _practiceSettings.difficulty == PracticeDifficulty.beginner
            ? 'School Students Cohort (Elementary / Middle School)'
            : 'Senior / College Cohort',
      );

      final evaluationResult = EvaluationResult(
        targetSentence: _targetSentence,
        recognizedText: recognizedText,
        characterAccuracy: charAccuracy,
        wordAccuracy: wordAccuracy,
        metrics: metrics,
        aesthetic: aestheticEvaluation,
        screenshotPath: savedImagePath,
        timestamp: DateTime.now(),
        strokes: List<HandwritingStroke>.from(_currentStrokes),
        ocrEngine: DigitalInkService().lastUsedEngine,
        targetWpm: _targetSentenceModel?.targetWpm ?? _practiceSettings.targetWpm,
        recommendedDurationSec: _targetSentenceModel?.recommendedDurationSec,
      );

      if (!mounted) return;

      // Record session in history
      unawaited(_profileStorage.recordSession(evaluationResult));

      setState(() {
        _isEvaluating = false;
        _lastResult = evaluationResult;
        _showResultAboveCanvas = true;
      });
    } catch (e) {
      debugPrint('[Evaluation] Unexpected error: $e');
      if (mounted) {
        setState(() {
          _isEvaluating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evaluation error: $e'),
            backgroundColor: AppTheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showResultsDashboard(EvaluationResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResultsDashboard(
        result: result,
        onDismiss: () => Navigator.pop(ctx),
        onRetry: () {
          Navigator.pop(ctx);
          _clearCanvas();
        },
      ),
    );
  }

  void _showSettingsDialog() {
    final cachedProfile = _profileStorage.cachedProfile;
    final isSchool = _practiceSettings.difficulty == PracticeDifficulty.beginner;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accentPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '5-Stage Aesthetic Engine',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppTheme.secondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Official Evaluation Engine Active',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Cohort: ${isSchool ? "Elementary / Middle (Unlined Adaptive)" : "Senior / College (Standard Lined)"}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Five Mandatory Evaluation Stages:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              const Text(
                '1. Repeated letters & common stroke pattern identification\n'
                '2. Geometric feature extraction (height, width, slant moments, baseline drift)\n'
                '3. Personal reference profile construction (Median + MAD)\n'
                '4. Deviation analysis (|Z| <= 1.5 natural style tolerance)\n'
                '5. Multi-dimensional consistency scoring (7 dimensions)',
                style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              const Text(
                'Personal Handwriting Calibration Profile',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              if (cachedProfile != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.success.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                          SizedBox(width: 6),
                          Text('Personal Baseline Calibrated', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Style: ${cachedProfile.personalStyleTags.join(" • ")}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _profileStorage.clearProfile();
                    if (!mounted) return;
                    setState(() {});
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Personal reference profile reset.')),
                    );
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                  label: const Text('Reset to Population Baseline', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                const Text(
                  'No individual baseline recorded yet. The app currently scores against validated cohort baselines. Submit a normal handwriting sample to establish your personal reference profile.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveDurationSec = (_liveElapsedMs / 1000.0).toStringAsFixed(1);
    final isCanvasKeyReady = _canvasKey.currentState;
    final canUndo = isCanvasKeyReady?.canUndo ?? false;
    final canRedo = isCanvasKeyReady?.canRedo ?? false;

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPad = screenWidth < 600 ? 10.0 : (screenWidth < 1024 ? 16.0 : 22.0);
    final verticalPad = screenWidth < 600 ? 8.0 : 12.0;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080B14), Color(0xFF0A0F1E), Color(0xFF080B14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                // TOP BAR
                // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.35),
                    end: Offset.zero,
                  ).animate(_headerAnim),
                  child: FadeTransition(
                    opacity: _headerAnim,
                    child: _buildTopBar(liveDurationSec),
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic Target Sentence Card
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(_cardAnim),
                  child: FadeTransition(
                    opacity: _cardAnim,
                    child: TargetSentenceCard(
                      targetSentence: _targetSentence,
                      hasStartedWriting: _hasStartedWriting,
                      activeStrokeCount: _currentStrokes.length,
                      sentenceModel: _targetSentenceModel,
                      settings: _practiceSettings,
                      onOpenSettings: _openPracticeSettings,
                      onRegenerate: _regenerateTargetSentence,
                      onSentenceChanged: (newSentence) {
                        setState(() {
                          _targetSentence = newSentence;
                          _targetSentenceModel = TargetSentenceModel.fromText(
                            text: newSentence,
                            settings: _practiceSettings,
                          );
                        });
                        _clearCanvas();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                // CANVAS TOOLBAR
                // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                // ─── RESULT ANALYSIS (ABOVE WRITING AREA) ───────────────────
                if (_lastResult != null && _showResultAboveCanvas) ...[
                  _buildResultAnalysisAboveCanvas(_lastResult!),
                  const SizedBox(height: 8),
                ],

                // ─── ACTION BAR (CLEAR & SUBMIT & ANALYZE ABOVE CANVAS) ─────
                FadeTransition(
                  opacity: _bottomAnim,
                  child: _buildActionControlsAboveCanvas(liveDurationSec),
                ),
                const SizedBox(height: 8),

                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_toolbarAnim),
                  child: FadeTransition(
                    opacity: _toolbarAnim,
                    child: CanvasToolbar(
                      selectedColor: _selectedInkColor,
                      selectedWidth: _selectedStrokeWidth,
                      isEraser: _isEraser,
                      strictStylusMode: _strictStylusMode,
                      paperStyle: _paperStyle,
                      canUndo: canUndo,
                      canRedo: canRedo,
                      onColorChanged: (c) => setState(() => _selectedInkColor = c),
                      onWidthChanged: (w) => setState(() => _selectedStrokeWidth = w),
                      onEraserToggled: (e) => setState(() => _isEraser = e),
                      onPalmRejectionToggled: (palmGuard) {
                        setState(() => _strictStylusMode = palmGuard);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              palmGuard
                                  ? 'Palm Guard ON: Only Stylus Input Registered'
                                  : 'Palm Guard OFF: Touch & Stylus Allowed',
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      onPaperStyleChanged: (style) => setState(() => _paperStyle = style),
                      onUndo: () => _canvasKey.currentState?.undo(),
                      onRedo: () => _canvasKey.currentState?.redo(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isEvaluating) ...[
                  _buildEvaluatingBanner(),
                  const SizedBox(height: 10),
                ],
                if (_needsCalibration && !_isEvaluating) ...[
                  _buildCalibrationBanner(),
                  const SizedBox(height: 10),
                ],

                // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                // DRAWING CANVAS
                // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
                Expanded(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1.0).animate(_canvasAnim),
                    child: FadeTransition(
                      opacity: _canvasAnim,
                      child: DrawingCanvas(
                        key: _canvasKey,
                        screenshotController: _screenshotController,
                        inkColor: _selectedInkColor,
                        strokeWidth: _selectedStrokeWidth,
                        isEraser: _isEraser,
                        strictStylusMode: _strictStylusMode,
                        paperStyle: _paperStyle,
                        onFirstStrokeDown: _onFirstStrokeDown,
                        onStrokesChanged: _onStrokesChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String liveDurationSec) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;

        return Row(
          children: [
            // App logo pill
            Container(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accentPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  const Text(
                    'RAPID WRITE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            if (!isCompact) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Stylus Handwriting Evaluator',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Adaptive speed calibration & aesthetic assessment',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ] else
              const Spacer(),

            // Live Timer Pill
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _hasStartedWriting
                        ? AppTheme.secondary.withValues(alpha: 0.6)
                        : AppTheme.borderDark.withValues(alpha: 0.4),
                  ),
                  boxShadow: _hasStartedWriting
                      ? [
                          BoxShadow(
                            color: AppTheme.secondary.withValues(alpha: 0.15 * _pulseAnim.value),
                            blurRadius: 14,
                            spreadRadius: -2,
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: _hasStartedWriting ? AppTheme.secondary : Colors.white30,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _hasStartedWriting ? '${liveDurationSec}s' : '0.0s',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _hasStartedWriting ? Colors.white : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // About Aesthetic Engine info button
            IconButton(
              onPressed: _showSettingsDialog,
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 20),
              tooltip: 'About 5-Stage Aesthetic Engine',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        );
      },
    );
  }

    Widget _buildResultAnalysisAboveCanvas(EvaluationResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFEA580C)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 8),
              const Text(
                'RESULT ANALYSIS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  result.ocrEngine,
                  style: const TextStyle(
                    color: Color(0xFFFF8A3D),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              // Full sheet report button
              IconButton(
                icon: const Icon(Icons.open_in_full_rounded, color: Colors.white70, size: 15),
                tooltip: 'Open Full Sheet Modal',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showResultsDashboard(result),
              ),
              // Close / Collapse
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                tooltip: 'Dismiss Results',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _showResultAboveCanvas = false),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3 Hero Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              final items = [
                _buildCompactMetricTile(
                  title: 'ACTUAL SPEED',
                  value: result.netWpm.toStringAsFixed(1),
                  unit: 'WPM',
                  icon: Icons.electric_bolt_rounded,
                  color: const Color(0xFFFF6B00),
                ),
                _buildCompactMetricTile(
                  title: 'ACCURACY',
                  value: result.characterAccuracy.toStringAsFixed(0),
                  unit: '%',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                ),
                _buildCompactMetricTile(
                  title: 'AESTHETIC',
                  value: result.aesthetic.grade,
                  unit: 'Grade (${result.aesthetic.overallAestheticScore.toStringAsFixed(0)}/100)',
                  icon: Icons.draw_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ];

              if (isSmall) {
                return Column(
                  children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 6), child: w)).toList(),
                );
              }

              return Row(
                children: items
                    .map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w)))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),

          // OCR Comparison Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF334155),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.text_fields_rounded, color: Color(0xFFFF6B00), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Recognized: ',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '"${result.recognizedText.isEmpty ? "(No text recognized)" : result.recognizedText}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (result.characterAccuracy >= 85) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'MATCHED',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() => _showResultAboveCanvas = false);
                  _clearCanvas();
                  final pangrams = PromptGeneratorService.pangrams;
                  if (pangrams.isNotEmpty) {
                    final next = pangrams[DateTime.now().millisecondsSinceEpoch % pangrams.length];
                    setState(() => _targetSentence = next);
                  }
                },
                icon: const Icon(Icons.navigate_next_rounded, color: Color(0xFFFF6B00), size: 16),
                label: const Text(
                  'Next Sentence',
                  style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetricTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControlsAboveCanvas(String liveDurationSec) {
    final double? recSec = _targetSentenceModel?.recommendedDurationSec;
    final double currentSec = _liveElapsedMs / 1000.0;
    final bool isOverTime = recSec != null && currentSec > recSec;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Clear Canvas Button
          InkWell(
            onTap: _currentStrokes.isNotEmpty ? _clearCanvas : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _currentStrokes.isNotEmpty
                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _currentStrokes.isNotEmpty
                      ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_sweep_rounded,
                    size: 15,
                    color: _currentStrokes.isNotEmpty ? const Color(0xFFF87171) : Colors.white30,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Clear',
                    style: TextStyle(
                      color: _currentStrokes.isNotEmpty ? Colors.white : Colors.white30,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Adaptive Timer & Pacing Pill
          if (_hasStartedWriting) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOverTime
                    ? const Color(0xFF451A03)
                    : const Color(0xFF0F2D14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOverTime
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF22C55E),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.speed_rounded,
                    size: 13,
                    color: isOverTime ? const Color(0xFFFBBF24) : const Color(0xFF4ADE80),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    recSec != null
                        ? '${liveDurationSec}s / ${recSec.round()}s target'
                        : '${liveDurationSec}s (${_currentStrokes.length} strokes)',
                    style: TextStyle(
                      color: isOverTime ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // If last result exists, button to toggle results card above canvas
          if (_lastResult != null) ...[
            InkWell(
              onTap: () => setState(() => _showResultAboveCanvas = !_showResultAboveCanvas),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: _showResultAboveCanvas
                      ? const Color(0xFFFF6B00).withValues(alpha: 0.2)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showResultAboveCanvas ? Icons.visibility_off_rounded : Icons.insights_rounded,
                      size: 14,
                      color: const Color(0xFFFF8A3D),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _showResultAboveCanvas ? 'Hide Results' : 'View Results',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // SUBMIT & ANALYZE BUTTON (Vibrant Solar Orange Gradient)
          InkWell(
            onTap: _isEvaluating ? null : _submitAndAnalyze,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: _isEvaluating
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isEvaluating ? const Color(0xFF1E293B) : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isEvaluating
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isEvaluating)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8A3D)),
                    )
                  else
                    const Icon(Icons.rocket_launch_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _isEvaluating ? 'Evaluating...' : 'Submit & Analyze',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// Calibration banner — shown to first-time users who have no reference profile
  Widget _buildCalibrationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2D14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint_rounded, color: Color(0xFF4ADE80), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Write a sample sentence below, then tap "Set as My Baseline" to personalize your scores.',
              style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11.5),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _hasStartedWriting ? _saveAsBaseline : null,
            child: AnimatedOpacity(
              opacity: _hasStartedWriting ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Set as My Baseline',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _needsCalibration = false),
            child: const Icon(Icons.close_rounded, color: Color(0xFF4ADE80), size: 16),
          ),
        ],
      ),
    );
  }

  /// Saves current canvas strokes as the user's personal handwriting baseline.
  Future<void> _saveAsBaseline() async {
    if (_currentStrokes.isEmpty) return;
    try {
      // Use AestheticEvaluatorService to build the reference profile (synchronous)
      final profile = AestheticEvaluatorService.calibrateBaseline(
        strokes: _currentStrokes,
        targetSentence: _targetSentence,
      );
      await _profileStorage.saveProfile(profile);
      if (mounted) {
        setState(() => _needsCalibration = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Your handwriting baseline has been saved! Future scores will be personalised.'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Calibration] Error saving baseline: $e');
    }
  }

Widget _buildEvaluatingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _evaluationStatusText,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'AI Processing',
              style: TextStyle(color: AppTheme.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
