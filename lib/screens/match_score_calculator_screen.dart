import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../theme/app_theme.dart';

class MatchScoreCalculatorScreen extends StatefulWidget {
  final MatchModel match;

  const MatchScoreCalculatorScreen({
    Key? key,
    required this.match,
  }) : super(key: key);

  @override
  State<MatchScoreCalculatorScreen> createState() =>
      _MatchScoreCalculatorScreenState();
}

class _MatchScoreCalculatorScreenState extends State<MatchScoreCalculatorScreen> {
  late int _teamAScore;
  late int _teamBScore;

  @override
  void initState() {
    super.initState();
    _teamAScore = widget.match.score?['teamA'] ?? 0;
    _teamBScore = widget.match.score?['teamB'] ?? 0;
  }

  _CalculatorConfig get _config =>
      _CalculatorConfig.forGame(widget.match.gameType);

  void _updateScore({
    required bool isTeamA,
    required int delta,
  }) {
    setState(() {
      if (isTeamA) {
        _teamAScore = (_teamAScore + delta).clamp(0, 999);
      } else {
        _teamBScore = (_teamBScore + delta).clamp(0, 999);
      }
    });
  }

  void _resetScores() {
    setState(() {
      _teamAScore = 0;
      _teamBScore = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Calculator'),
        actions: [
          TextButton(
            onPressed: _resetScores,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.match.gameType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.match.location,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _config.helperText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.surfaceCardDecoration(elevated: false),
                  child: Text(
                    'Use this calculator during active matches. It helps players track live scores locally without changing the final saved result.',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ScoreTeamCard(
                  title: 'Team A',
                  score: _teamAScore,
                  accentColor: AppTheme.primary,
                  quickSteps: _config.quickSteps,
                  onIncrease: (value) => _updateScore(isTeamA: true, delta: value),
                  onDecrease: (value) =>
                      _updateScore(isTeamA: true, delta: -value),
                ),
                const SizedBox(height: 18),
                _ScoreTeamCard(
                  title: 'Team B',
                  score: _teamBScore,
                  accentColor: AppTheme.secondary,
                  quickSteps: _config.quickSteps,
                  onIncrease: (value) => _updateScore(isTeamA: false, delta: value),
                  onDecrease: (value) =>
                      _updateScore(isTeamA: false, delta: -value),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: AppTheme.tintedCardDecoration(AppTheme.secondary),
                  child: Column(
                    children: [
                      const Text(
                        'Live Score',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$_teamAScore  -  $_teamBScore',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreTeamCard extends StatelessWidget {
  final String title;
  final int score;
  final Color accentColor;
  final List<int> quickSteps;
  final ValueChanged<int> onIncrease;
  final ValueChanged<int> onDecrease;

  const _ScoreTeamCard({
    required this.title,
    required this.score,
    required this.accentColor,
    required this.quickSteps,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.surfaceCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.sports_score,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickSteps.map((step) {
              return _StepButton(
                label: '+$step',
                color: accentColor,
                onTap: () => onIncrease(step),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickSteps.map((step) {
              return _StepButton(
                label: '-$step',
                color: AppTheme.mutedText,
                onTap: () => onDecrease(step),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StepButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CalculatorConfig {
  final List<int> quickSteps;
  final String helperText;

  const _CalculatorConfig({
    required this.quickSteps,
    required this.helperText,
  });

  factory _CalculatorConfig.forGame(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'cricket':
        return const _CalculatorConfig(
          quickSteps: [1, 2, 4, 6],
          helperText: 'Quick add for singles, doubles, boundaries, and sixes.',
        );
      case 'basketball':
        return const _CalculatorConfig(
          quickSteps: [1, 2, 3],
          helperText: 'Track free throws, field goals, and three-pointers.',
        );
      case 'football':
      case 'futsal':
      case 'soccer':
      case 'hockey':
        return const _CalculatorConfig(
          quickSteps: [1, 2],
          helperText: 'Simple goal tracking for live match play.',
        );
      case 'badminton':
      case 'tennis':
      case 'pickleball':
      case 'volleyball':
      default:
        return const _CalculatorConfig(
          quickSteps: [1],
          helperText: 'Tap to keep rally or point-based scoring moving.',
        );
    }
  }
}
