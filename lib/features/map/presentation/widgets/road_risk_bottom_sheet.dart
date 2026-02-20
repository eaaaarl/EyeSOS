import 'package:eyesos/features/map/data/datasources/road_risk_mock_data.dart';
import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:flutter/material.dart';

class RoadRiskBottomSheet extends StatelessWidget {
  final RoadRiskEntity road;

  const RoadRiskBottomSheet({super.key, required this.road});

  @override
  Widget build(BuildContext context) {
    final color = road.riskLevel.color;
    final scoreFraction = (road.riskScore / 100).clamp(0.0, 1.0);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Colored header ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.09)),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _riskIcon(road.riskLevel),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          road.riskLevel.label.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const Text(
                          'RISK LEVEL',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Road name
                    Row(
                      children: [
                        const Icon(Icons.route, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            road.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Score bar
                    Row(
                      children: [
                        const Text(
                          'Risk Score',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${road.riskScore}/100',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: scoreFraction,
                        minHeight: 7,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Accident count
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: road.accidentCount > 0
                            ? Colors.orange.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 15,
                            color: road.accidentCount > 0
                                ? Colors.orange.shade600
                                : Colors.grey,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            road.accidentCount > 0
                                ? '${road.accidentCount} accident${road.accidentCount > 1 ? "s" : ""} recorded'
                                : 'No accidents recorded',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: road.accidentCount > 0
                                  ? Colors.orange.shade700
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Time insights
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'TIME INSIGHTS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeChip(
                                  icon: Icons.warning_amber_rounded,
                                  label: 'Peak Risk',
                                  value: RoadRiskMockData.getPeakTimeLabel(
                                    road.id,
                                    road.name,
                                  ),
                                  color: Colors.red.shade400,
                                  bgColor: Colors.red.shade50,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _TimeChip(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: 'Safest Time',
                                  value: RoadRiskMockData.getSafestTimeLabel(
                                    road.id,
                                    road.name,
                                  ),
                                  color: Colors.green.shade600,
                                  bgColor: Colors.green.shade50,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _HourlyRiskBar(road: road),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _riskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return Icons.dangerous_rounded;
      case RiskLevel.high:
        return Icons.warning_rounded;
      case RiskLevel.moderate:
        return Icons.info_rounded;
      case RiskLevel.minor:
        return Icons.check_circle_rounded;
      case RiskLevel.none:
        return Icons.shield_rounded;
    }
  }
}

// ── Time Chip ──────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _TimeChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hourly Risk Bar ────────────────────────────────────────────────────────────

class _HourlyRiskBar extends StatelessWidget {
  final RoadRiskEntity road;

  const _HourlyRiskBar({required this.road});

  @override
  Widget build(BuildContext context) {
    final scores = RoadRiskMockData.getHourlyScores(road.id, road.name);
    final currentHour = DateTime.now().hour;
    final startHour = (currentHour - 3).clamp(0, 18);
    final visibleHours = List.generate(6, (i) => startHour + i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Risk by hour (today)',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: visibleHours.map((hour) {
            final score = scores[hour];
            final isNow = hour == currentHour;
            final barColor = RoadRiskMockData.scoreToRisk(score).color;
            const maxHeight = 36.0;
            final barHeight = (score / 100 * maxHeight).clamp(4.0, maxHeight);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'now',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 14),
                const SizedBox(height: 2),
                Container(
                  width: 28,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: isNow ? barColor : barColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: isNow
                        ? Border.all(color: Colors.blue, width: 1.5)
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatHourShort(hour),
                  style: TextStyle(
                    fontSize: 9,
                    color: isNow ? Colors.blue : Colors.grey,
                    fontWeight: isNow ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatHourShort(int hour) {
    if (hour == 0) return '12a';
    if (hour == 12) return '12p';
    return hour > 12 ? '${hour - 12}p' : '${hour}a';
  }
}
