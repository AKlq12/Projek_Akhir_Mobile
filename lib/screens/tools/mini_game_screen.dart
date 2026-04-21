import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/local_cache_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GAME STATE
// ═══════════════════════════════════════════════════════════════════════════════

enum _GamePhase { idle, countdown, waiting, ready, tooEarly, roundResult, finished }

/// Reaction Reflex Mini Game — test your reaction speed!
///
/// 5 rounds of tapping when the circle turns green.
/// Fitness-themed exercise icons appear as targets.
/// High scores are persisted locally via Hive.
class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen>
    with TickerProviderStateMixin {
  // ── Game Config ──────────────────────────────────────────────────────────
  static const int _totalRounds = 5;
  static const int _minWaitMs = 1500;
  static const int _maxWaitMs = 4000;

  // ── Game State ───────────────────────────────────────────────────────────
  _GamePhase _phase = _GamePhase.idle;
  int _currentRound = 0;
  final List<int> _roundTimes = []; // Reaction times in ms
  int _lastReactionMs = 0;
  int _bestScore = 0; // Best average from history
  bool _isNewRecord = false;

  // ── Timing ───────────────────────────────────────────────────────────────
  Timer? _waitTimer;
  DateTime? _goTime; // When the circle turned green
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  int _countdownValue = 3;

  // ── Fitness icons for the "GO!" target ───────────────────────────────────
  static const List<_FitnessTarget> _fitnessTargets = [
    _FitnessTarget(Icons.fitness_center_rounded, 'Dumbbell'),
    _FitnessTarget(Icons.directions_run_rounded, 'Sprint'),
    _FitnessTarget(Icons.directions_bike_rounded, 'Cycling'),
    _FitnessTarget(Icons.pool_rounded, 'Swimming'),
    _FitnessTarget(Icons.sports_martial_arts_rounded, 'Martial Arts'),
    _FitnessTarget(Icons.sports_gymnastics_rounded, 'Gymnastics'),
    _FitnessTarget(Icons.self_improvement_rounded, 'Yoga'),
    _FitnessTarget(Icons.rowing_rounded, 'Rowing'),
  ];
  _FitnessTarget _currentTarget = _fitnessTargets.first;
  final _random = Random();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _loadBestScore();
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  // ── Hive persistence ────────────────────────────────────────────────────
  void _loadBestScore() {
    final data = LocalCacheService.instance
        .get(LocalCacheService.settingsBox, 'reflex_best_score');
    if (data != null && data['score'] != null) {
      setState(() => _bestScore = data['score'] as int);
    }
  }

  Future<void> _saveBestScore(int score) async {
    await LocalCacheService.instance.put(
      LocalCacheService.settingsBox,
      'reflex_best_score',
      {'score': score},
    );
  }

  // ── Game Logic ──────────────────────────────────────────────────────────
  void _startGame() {
    setState(() {
      _currentRound = 0;
      _roundTimes.clear();
      _isNewRecord = false;
      _phase = _GamePhase.countdown;
      _countdownValue = 3;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _countdownValue = 3;
    _countdownController.reset();
    setState(() => _phase = _GamePhase.countdown);

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdownValue--);

      if (_countdownValue <= 0) {
        timer.cancel();
        _startRound();
      }
    });
  }

  void _startRound() {
    _currentTarget = _fitnessTargets[_random.nextInt(_fitnessTargets.length)];
    setState(() {
      _phase = _GamePhase.waiting;
      _currentRound++;
    });

    // Random wait before "GO!"
    final waitMs = _minWaitMs + _random.nextInt(_maxWaitMs - _minWaitMs);
    _waitTimer = Timer(Duration(milliseconds: waitMs), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _phase = _GamePhase.ready;
        _goTime = DateTime.now();
      });
      _pulseController.repeat(reverse: true);
    });
  }

  void _onTap() {
    switch (_phase) {
      case _GamePhase.waiting:
        // Too early!
        _waitTimer?.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _phase = _GamePhase.tooEarly);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _startRound(); // Retry same round
          setState(() => _currentRound--); // Don't increment
        });
        break;

      case _GamePhase.ready:
        // Record reaction time
        final reactionMs =
            DateTime.now().difference(_goTime!).inMilliseconds;
        _pulseController.stop();
        HapticFeedback.lightImpact();

        _roundTimes.add(reactionMs);
        _lastReactionMs = reactionMs;

        if (_currentRound >= _totalRounds) {
          _finishGame();
        } else {
          setState(() => _phase = _GamePhase.roundResult);
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            _startRound();
          });
        }
        break;

      default:
        break;
    }
  }

  void _finishGame() {
    final avg = averageTime;
    if (_bestScore == 0 || avg < _bestScore) {
      _bestScore = avg;
      _isNewRecord = true;
      _saveBestScore(avg);
    }
    setState(() => _phase = _GamePhase.finished);
  }

  int get averageTime {
    if (_roundTimes.isEmpty) return 0;
    return (_roundTimes.reduce((a, b) => a + b) / _roundTimes.length).round();
  }

  String get _ratingEmoji {
    final avg = averageTime;
    if (avg < 200) return '⚡';
    if (avg < 300) return '🔥';
    if (avg < 400) return '💪';
    if (avg < 500) return '👍';
    return '🐢';
  }

  String get _ratingText {
    final avg = averageTime;
    if (avg < 200) return 'Superhuman!';
    if (avg < 250) return 'Excellent Reflexes!';
    if (avg < 300) return 'Lightning Fast!';
    if (avg < 350) return 'Great Reaction!';
    if (avg < 400) return 'Good Speed!';
    if (avg < 500) return 'Not Bad!';
    return 'Keep Practicing!';
  }

  Color get _ratingColor {
    final avg = averageTime;
    if (avg < 200) return const Color(0xFF8B5CF6);
    if (avg < 300) return const Color(0xFF10B981);
    if (avg < 400) return const Color(0xFF3B82F6);
    if (avg < 500) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Main content
            Expanded(
              child: _phase == _GamePhase.finished
                  ? _buildResultsScreen(context)
                  : _buildGameArea(context),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Reaction Reflex',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Best score badge
          if (_bestScore > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_bestScore}ms',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME AREA — idle, countdown, waiting, ready, tooEarly, roundResult
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGameArea(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // ── Round Indicator ────────────────────────────────────────────
          if (_phase != _GamePhase.idle)
            _buildRoundIndicator(context),

          const Spacer(),

          // ── Main Circle ───────────────────────────────────────────────
          _buildMainCircle(context),

          const SizedBox(height: 28),

          // ── Instruction Text ──────────────────────────────────────────
          _buildInstructionText(context),

          const Spacer(),

          // ── Round History ─────────────────────────────────────────────
          if (_roundTimes.isNotEmpty && _phase != _GamePhase.idle)
            _buildRoundHistory(context),

          // ── Start Button (idle only) ──────────────────────────────────
          if (_phase == _GamePhase.idle) _buildStartButton(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Round Indicator (dots) ──────────────────────────────────────────────
  Widget _buildRoundIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Text(
            _phase == _GamePhase.countdown
                ? 'Get Ready!'
                : 'Round $_currentRound of $_totalRounds',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalRounds, (i) {
              final isCompleted = i < _roundTimes.length;
              final isCurrent = i == _currentRound - 1;

              return Container(
                width: isCurrent ? 28 : 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : isCurrent
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHigh,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Main Circle ─────────────────────────────────────────────────────────
  Widget _buildMainCircle(BuildContext context) {
    Color circleColor;
    Color glowColor;
    Widget innerContent;

    switch (_phase) {
      case _GamePhase.idle:
        circleColor = const Color(0xFFF97316).withValues(alpha: 0.15);
        glowColor = const Color(0xFFF97316).withValues(alpha: 0.1);
        innerContent = _buildIdleContent();
        break;

      case _GamePhase.countdown:
        circleColor = const Color(0xFF3B82F6).withValues(alpha: 0.15);
        glowColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        innerContent = _buildCountdownContent();
        break;

      case _GamePhase.waiting:
        circleColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        glowColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        innerContent = _buildWaitingContent();
        break;

      case _GamePhase.ready:
        circleColor = const Color(0xFF10B981).withValues(alpha: 0.2);
        glowColor = const Color(0xFF10B981).withValues(alpha: 0.25);
        innerContent = _buildReadyContent();
        break;

      case _GamePhase.tooEarly:
        circleColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        glowColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        innerContent = _buildTooEarlyContent();
        break;

      case _GamePhase.roundResult:
        circleColor = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        glowColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        innerContent = _buildRoundResultContent();
        break;

      default:
        circleColor = Colors.transparent;
        glowColor = Colors.transparent;
        innerContent = const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: innerContent,
      ),
    );
  }

  Widget _buildIdleContent() {
    return Column(
      key: const ValueKey('idle'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.sports_esports_rounded,
          size: 52,
          color: Color(0xFFF97316),
        ),
        const SizedBox(height: 8),
        Text(
          'TAP TO\nSTART',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: const Color(0xFFF97316),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownContent() {
    return Column(
      key: ValueKey('countdown_$_countdownValue'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$_countdownValue',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF3B82F6),
          ),
        )
            .animate(onPlay: (c) => c.forward())
            .scale(
              begin: const Offset(1.5, 1.5),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 200.ms),
      ],
    );
  }

  Widget _buildWaitingContent() {
    return Column(
      key: const ValueKey('waiting'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.do_not_touch_rounded,
          size: 44,
          color: Color(0xFFEF4444),
        ),
        const SizedBox(height: 10),
        Text(
          'WAIT...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }

  Widget _buildReadyContent() {
    return Column(
      key: const ValueKey('ready'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _currentTarget.icon,
          size: 52,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 8),
        Text(
          'TAP NOW!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    )
        .animate()
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          duration: 200.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 150.ms);
  }

  Widget _buildTooEarlyContent() {
    return Column(
      key: const ValueKey('tooEarly'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.warning_rounded,
          size: 44,
          color: Color(0xFFF59E0B),
        ),
        const SizedBox(height: 10),
        Text(
          'TOO EARLY!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Wait for green',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
          ),
        ),
      ],
    )
        .animate()
        .shakeX(duration: 400.ms, hz: 5, amount: 6)
        .fadeIn(duration: 200.ms);
  }

  Widget _buildRoundResultContent() {
    return Column(
      key: ValueKey('result_$_currentRound'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${_lastReactionMs}ms',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getRoundRating(_lastReactionMs),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B82F6).withValues(alpha: 0.7),
          ),
        ),
      ],
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 200.ms);
  }

  String _getRoundRating(int ms) {
    if (ms < 200) return '⚡ Incredible!';
    if (ms < 300) return '🔥 Blazing Fast!';
    if (ms < 400) return '💪 Great!';
    if (ms < 500) return '👍 Good';
    return '🐢 Slow';
  }

  // ── Instruction Text ────────────────────────────────────────────────────
  Widget _buildInstructionText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String text;

    switch (_phase) {
      case _GamePhase.idle:
        text = 'Test your reaction speed!\nTap when the circle turns GREEN';
        break;
      case _GamePhase.countdown:
        text = 'Focus on the circle...';
        break;
      case _GamePhase.waiting:
        text = 'Wait for it...';
        break;
      case _GamePhase.ready:
        text = 'TAP THE SCREEN!';
        break;
      case _GamePhase.tooEarly:
        text = 'Patience! Try again...';
        break;
      case _GamePhase.roundResult:
        text = 'Next round coming up...';
        break;
      default:
        text = '';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        text,
        key: ValueKey(text),
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: _phase == _GamePhase.ready ? 18 : 14,
          fontWeight: _phase == _GamePhase.ready
              ? FontWeight.w800
              : FontWeight.w600,
          color: _phase == _GamePhase.ready
              ? const Color(0xFF10B981)
              : colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }

  // ── Round History Bar ──────────────────────────────────────────────────
  Widget _buildRoundHistory(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_totalRounds, (i) {
            final hasResult = i < _roundTimes.length;
            return Column(
              children: [
                Text(
                  'R${i + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasResult ? '${_roundTimes[i]}ms' : '--',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: hasResult
                        ? _getTimeColor(_roundTimes[i])
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Color _getTimeColor(int ms) {
    if (ms < 250) return const Color(0xFF10B981);
    if (ms < 350) return const Color(0xFF3B82F6);
    if (ms < 450) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // ── Start Button ────────────────────────────────────────────────────────
  Widget _buildStartButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 0, 48, 0),
      child: GestureDetector(
        onTap: _startGame,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'START GAME',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULTS SCREEN — after 5 rounds
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildResultsScreen(BuildContext context) {
    final avg = averageTime;
    final fastest = _roundTimes.reduce(min);
    final slowest = _roundTimes.reduce(max);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        children: [
          // ── Trophy / New Record ────────────────────────────────────────
          _buildResultHeader(context),

          const SizedBox(height: 28),

          // ── Average Time (big) ────────────────────────────────────────
          _buildAverageCard(context, avg),

          const SizedBox(height: 20),

          // ── Stats Row ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _buildStatMini(context, 'Fastest', '${fastest}ms', const Color(0xFF10B981))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatMini(context, 'Slowest', '${slowest}ms', const Color(0xFFEF4444))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatMini(context, 'Best Ever', '${_bestScore}ms', const Color(0xFF8B5CF6))),
            ],
          ),

          const SizedBox(height: 24),

          // ── Round Breakdown ───────────────────────────────────────────
          _buildRoundBreakdown(context),

          const SizedBox(height: 28),

          // ── Action Buttons ────────────────────────────────────────────
          _buildPlayAgainButton(context),

          const SizedBox(height: 12),

          _buildBackButton(context),
        ],
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context) {
    return Column(
      children: [
        // Trophy icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isNewRecord
                  ? [const Color(0xFFFBBF24), const Color(0xFFF97316)]
                  : [_ratingColor.withValues(alpha: 0.15), _ratingColor.withValues(alpha: 0.25)],
            ),
            boxShadow: [
              BoxShadow(
                color: (_isNewRecord
                        ? const Color(0xFFFBBF24)
                        : _ratingColor)
                    .withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(
            _isNewRecord
                ? Icons.emoji_events_rounded
                : Icons.timer_rounded,
            size: 40,
            color: _isNewRecord ? Colors.white : _ratingColor,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 16),

        // Title
        Text(
          _isNewRecord ? '🎉 New Record!' : 'Your Results',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 400.ms),

        const SizedBox(height: 4),

        Text(
          '$_ratingEmoji $_ratingText',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ratingColor,
          ),
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: 400.ms),
      ],
    );
  }

  Widget _buildAverageCard(BuildContext context, int avg) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: _ratingColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Average Reaction Time',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$avg',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  height: 1,
                  color: _ratingColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  'ms',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ratingColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Visual bar showing where this falls on a scale
          _buildSpeedScale(context, avg),
        ],
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildSpeedScale(BuildContext context, int avg) {
    final colorScheme = Theme.of(context).colorScheme;
    // Map 100-600ms to 0.0-1.0
    final pos = ((avg - 100).clamp(0, 500) / 500).clamp(0.0, 1.0);

    return Column(
      children: [
        Stack(
          children: [
            // Background track
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF10B981),
                    Color(0xFFF59E0B),
                    Color(0xFFEF4444),
                  ],
                ),
              ),
            ),
            // Indicator
            Positioned(
              left: (MediaQuery.of(context).size.width - 96) * pos,
              top: -3,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: _ratingColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _ratingColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fast',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant)),
            Text('Slow',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatMini(
      BuildContext context, String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    )
        .animate(delay: 500.ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildRoundBreakdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Round Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(_totalRounds, (i) {
            final time = _roundTimes[i];
            final maxTime = _roundTimes.reduce(max);
            final barWidth = maxTime > 0 ? (time / maxTime) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Round label
                  SizedBox(
                    width: 32,
                    child: Text(
                      'R${i + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // Bar
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              width: constraints.maxWidth * barWidth,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  colors: [
                                    _getTimeColor(time),
                                    _getTimeColor(time).withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Time value
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${time}ms',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _getTimeColor(time),
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 600 + (i * 100)))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1, end: 0);
          }),
        ],
      ),
    )
        .animate(delay: 550.ms)
        .fadeIn(duration: 400.ms);
  }

  Widget _buildPlayAgainButton(BuildContext context) {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF97316).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.replay_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'PLAY AGAIN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 800.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildBackButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'Back to Tools',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    )
        .animate(delay: 900.ms)
        .fadeIn(duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class _FitnessTarget {
  final IconData icon;
  final String label;

  const _FitnessTarget(this.icon, this.label);
}
