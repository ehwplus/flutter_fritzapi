import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_fritzapi/flutter_fritzapi.dart';

class EnergySeriesChart extends StatelessWidget {
  const EnergySeriesChart({
    required this.entries,
    required this.emptyText,
    this.unitLabel = 'Wh',
    this.summaryLabel = 'Aktuell',
    super.key,
  });

  final List<EnergyReading> entries;
  final String emptyText;
  final String unitLabel;
  final String summaryLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<_EnergySeriesPoint> points = _energySeriesPoints(entries);
    if (points.length < 2) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(emptyText, style: theme.textTheme.bodySmall),
      );
    }
    final List<double> values = points
        .map((point) => point.value)
        .toList(growable: false);
    double minValue = values.reduce(math.min);
    double maxValue = values.reduce(math.max);
    if ((maxValue - minValue).abs() < 0.0001) {
      minValue -= 1;
      maxValue += 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$summaryLabel: ${_formatValue(points.last.value)} $unitLabel | Min: ${_formatValue(minValue)} $unitLabel | Max: ${_formatValue(maxValue)} $unitLabel',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blueGrey.withValues(alpha: 0.25),
              ),
            ),
            child: CustomPaint(
              painter: _EnergySeriesPainter(
                points: points,
                minValue: minValue,
                maxValue: maxValue,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              _formatShortDateTime(points.first.time),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              _formatShortDateTime(points.last.time),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

int? estimateEnergySeriesIntervalSeconds(List<EnergyReading> entries) {
  final List<_EnergySeriesPoint> points = _energySeriesPoints(entries);
  if (points.length < 2) {
    return null;
  }
  final List<int> diffs = <int>[];
  for (int i = 1; i < points.length; i++) {
    final int diff = points[i].time.difference(points[i - 1].time).inSeconds;
    if (diff > 0) {
      diffs.add(diff);
    }
  }
  if (diffs.isEmpty) {
    return null;
  }
  diffs.sort();
  return diffs[diffs.length ~/ 2];
}

String formatEnergyIntervalLabel(int seconds) {
  if (seconds <= 0) {
    return '-';
  }
  if (seconds % 86400 == 0) {
    final int days = seconds ~/ 86400;
    return days == 1 ? '1 Tag' : '$days Tage';
  }
  if (seconds % 3600 == 0) {
    return '${seconds ~/ 3600} h';
  }
  if (seconds % 60 == 0) {
    return '${seconds ~/ 60} Min';
  }
  return '$seconds s';
}

class _EnergySeriesPainter extends CustomPainter {
  const _EnergySeriesPainter({
    required this.points,
    required this.minValue,
    required this.maxValue,
  });

  final List<_EnergySeriesPoint> points;
  final double minValue;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }
    const double horizontalPadding = 8;
    const double verticalPadding = 8;
    final Rect chartRect = Rect.fromLTWH(
      horizontalPadding,
      verticalPadding,
      size.width - horizontalPadding * 2,
      size.height - verticalPadding * 2,
    );
    if (chartRect.width <= 0 || chartRect.height <= 0) {
      return;
    }
    final Paint gridPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final double y = chartRect.top + (chartRect.height * i / 4);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final double range = maxValue - minValue;
    double normalize(double value) {
      if (range <= 0) {
        return 0.5;
      }
      return ((value - minValue) / range).clamp(0.0, 1.0).toDouble();
    }

    final Path linePath = Path();
    for (int i = 0; i < points.length; i++) {
      final _EnergySeriesPoint point = points[i];
      final double x =
          chartRect.left + (chartRect.width * i / (points.length - 1));
      final double y =
          chartRect.bottom - normalize(point.value) * chartRect.height;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final Path fillPath = Path.from(linePath)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.lightBlue.withValues(alpha: 0.28),
          Colors.lightBlue.withValues(alpha: 0.02),
        ],
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    final Paint linePaint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final _EnergySeriesPoint lastPoint = points.last;
    final double lastX = chartRect.right;
    final double lastY =
        chartRect.bottom - normalize(lastPoint.value) * chartRect.height;
    final Paint markerPaint = Paint()..color = Colors.blue.shade900;
    canvas.drawCircle(Offset(lastX, lastY), 3, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _EnergySeriesPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue;
  }
}

class _EnergySeriesPoint {
  const _EnergySeriesPoint({required this.time, required this.value});

  final DateTime time;
  final double value;
}

List<_EnergySeriesPoint> _energySeriesPoints(List<EnergyReading> entries) {
  final List<_EnergySeriesPoint> points = <_EnergySeriesPoint>[];
  for (final EnergyReading entry in entries) {
    final double? value = entry.energyWh;
    final String? dateTime = entry.dateTime;
    if (value == null || dateTime == null || dateTime.isEmpty) {
      continue;
    }
    final DateTime? parsed = DateTime.tryParse(dateTime);
    if (parsed == null) {
      continue;
    }
    points.add(_EnergySeriesPoint(time: parsed.toLocal(), value: value));
  }
  points.sort((a, b) => a.time.compareTo(b.time));
  return points;
}

String _formatShortDateTime(DateTime value) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(value.day)}.${twoDigits(value.month)} ${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

String _formatValue(double value) {
  final double rounded = value.roundToDouble();
  if ((rounded - value).abs() < 0.01) {
    return rounded.toInt().toString();
  }
  return value.toStringAsFixed(1);
}
