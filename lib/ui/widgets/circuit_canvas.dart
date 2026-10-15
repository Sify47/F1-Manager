import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/race_state.dart';
import '../../models/circuit.dart';
import '../../data/drivers_data.dart';
import '../../data/teams_data.dart';
import '../theme/f1_theme.dart';

class CircuitCanvasWidget extends StatelessWidget {
  final Circuit circuit;
  final List<CarTelemetry> cars;
  final List<String> playerDriverIds;

  const CircuitCanvasWidget({
    super.key,
    required this.circuit,
    required this.cars,
    required this.playerDriverIds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1219),
        border: Border.all(color: F1Theme.surfaceBorder),
        borderRadius: BorderRadius.circular(8),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            const Color(0xFF161B26),
            const Color(0xFF0A0C11),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Track & Cars CustomPainter
          Positioned.fill(
            child: CustomPaint(
              painter: _CircuitPainter(
                circuit: circuit,
                cars: cars,
                playerDriverIds: playerDriverIds,
              ),
            ),
          ),

          // Top-Left Circuit info badge
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: F1Theme.surfaceBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(circuit.flagEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        circuit.name.toUpperCase(),
                        style: F1Theme.f1Display(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text('${circuit.lengthKm} KM', style: F1Theme.f1Mono(fontSize: 8, color: Colors.grey)),
                          const SizedBox(width: 6),
                          Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('${circuit.totalLaps} LAPS', style: F1Theme.f1Mono(fontSize: 8, color: Colors.grey)),
                          const SizedBox(width: 6),
                          Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('${circuit.drsZonesCount} DRS', style: F1Theme.f1Mono(fontSize: 8, color: F1Theme.drsGreen)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sector Legend at bottom-right
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: F1Theme.surfaceBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSectorLegendDot('S1', const Color(0xFF00E5FF)),
                  const SizedBox(width: 8),
                  _buildSectorLegendDot('S2', const Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  _buildSectorLegendDot('S3', const Color(0xFFD500F9)),
                  const SizedBox(width: 8),
                  _buildSectorLegendDot('DRS', F1Theme.drsGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: F1Theme.f1Display(fontSize: 8, color: Colors.white70)),
      ],
    );
  }
}

class _CircuitPainter extends CustomPainter {
  final Circuit circuit;
  final List<CarTelemetry> cars;
  final List<String> playerDriverIds;

  _CircuitPainter({
    required this.circuit,
    required this.cars,
    required this.playerDriverIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 50 || size.height < 50) return;

    final center = Offset(size.width / 2, size.height / 2);
    final scaleX = size.width * 0.40;
    final scaleY = size.height * 0.38;

    // 1. Generate Authentic Circuit Spline Points
    final List<Offset> normalizedPoints = _getNormalizedTrackPoints(circuit.id);
    final List<Offset> screenPoints = normalizedPoints.map((pt) {
      return Offset(center.dx + pt.dx * scaleX, center.dy + pt.dy * scaleY);
    }).toList();

    if (screenPoints.isEmpty) return;

    // 2. Build Paths for Sectors
    final int totalPoints = screenPoints.length;
    final int s1End = (totalPoints / 3).floor();
    final int s2End = ((totalPoints * 2) / 3).floor();

    final Path fullPath = Path();
    fullPath.moveTo(screenPoints[0].dx, screenPoints[0].dy);
    for (int i = 1; i < totalPoints; i++) {
      fullPath.lineTo(screenPoints[i].dx, screenPoints[i].dy);
    }
    fullPath.close();

    // 3. Draw Track Base (Asphalt & Red/White Curbs)
    final curbPaint = Paint()
      ..color = const Color(0xFF333B4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, curbPaint);

    final asphaltPaint = Paint()
      ..color = const Color(0xFF181C26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, asphaltPaint);

    // 4. Draw Colored Sector Lines on Racing Line
    _drawSectorLine(canvas, screenPoints, 0, s1End, const Color(0xFF00E5FF));
    _drawSectorLine(canvas, screenPoints, s1End, s2End, const Color(0xFF00E676));
    _drawSectorLine(canvas, screenPoints, s2End, totalPoints, const Color(0xFFD500F9));

    // 5. Draw Start / Finish Line
    final startPt = screenPoints[0];
    final nextPt = screenPoints[1];
    final tangent = (nextPt - startPt);
    final normal = Offset(-tangent.dy, tangent.dx) / (tangent.distance + 0.0001);
    final lineStart = startPt - normal * 10;
    final lineEnd = startPt + normal * 10;

    final finishLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0;
    canvas.drawLine(lineStart, lineEnd, finishLinePaint);

    // 6. Render Cars as Authentic F1 Telemetry Badges
    // Draw back-markers first, then leaders, then player cars on top
    final sortedCars = List<CarTelemetry>.from(cars)
      ..sort((a, b) {
        bool aPlayer = playerDriverIds.contains(a.driverId);
        bool bPlayer = playerDriverIds.contains(b.driverId);
        if (aPlayer && !bPlayer) return 1;
        if (!aPlayer && bPlayer) return -1;
        return b.position.compareTo(a.position); // High position (back of grid) drawn first
      });

    for (final car in sortedCars) {
      if (car.status == CarRaceStatus.outOfRace) continue;

      // Position along spline: 0.0 to 1.0
      double lapProgress = ((car.currentSector - 1) / 3.0) + (car.sectorProgress / 3.0);
      lapProgress = lapProgress.clamp(0.0, 0.999);

      int pointIndex = (lapProgress * totalPoints).floor() % totalPoints;
      Offset carPos = screenPoints[pointIndex];

      final team = TeamsData.getTeamById(car.teamId);
      final driver = DriversData.getDriverById(car.driverId);
      final bool isPlayerCar = playerDriverIds.contains(car.driverId);

      Color carColor = Color(team?.primaryColorHex ?? 0xFFFFFFFF);

      // Player halo highlight
      if (isPlayerCar) {
        final haloPaint = Paint()
          ..color = F1Theme.f1Red.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5;
        canvas.drawCircle(carPos, 14.0, haloPaint);

        final glowPaint = Paint()
          ..color = F1Theme.f1Red.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(carPos, 18.0, glowPaint);
      }

      // Outer border circle
      final borderPaint = Paint()
        ..color = isPlayerCar ? Colors.white : Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(carPos, 9.0, borderPaint);

      // Car body circle with team livery color
      final bodyPaint = Paint()
        ..color = carColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(carPos, 9.0, bodyPaint);

      // Position or Driver number inside badge
      final textSpan = TextSpan(
        text: isPlayerCar ? (driver?.shortCode.substring(0, 2) ?? '${car.position}') : '${car.position}',
        style: TextStyle(
          color: (carColor.computeLuminance() > 0.5) ? Colors.black : Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(carPos.dx - textPainter.width / 2, carPos.dy - textPainter.height / 2),
      );

      // DRS flap opening icon
      if (car.hasDrsAvailable) {
        final drsPaint = Paint()
          ..color = F1Theme.drsGreen
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(carPos.dx + 8, carPos.dy - 8), 3.5, drsPaint);
      }
    }
  }

  void _drawSectorLine(Canvas canvas, List<Offset> points, int start, int end, Color color) {
    if (start >= points.length) return;
    int actualEnd = min(end, points.length - 1);

    final path = Path();
    path.moveTo(points[start].dx, points[start].dy);
    for (int i = start + 1; i <= actualEnd; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, paint);
  }

  /// Authentic circuit coordinate profiles normalized between -1.0 and 1.0
  List<Offset> _getNormalizedTrackPoints(String circuitId) {
    List<Offset> pts = [];
    const int segments = 100;

    if (circuitId == 'monza') {
      // Autodromo Nazionale Monza: Long high speed straights with chicanes & Parabolica
      for (int i = 0; i < segments; i++) {
        double t = (i / segments) * 2 * pi;
        // Elongated rectangular speed temple with chicanes
        double x = 0.90 * cos(t) + 0.12 * sin(3 * t);
        double y = 0.45 * sin(t) + 0.08 * cos(2 * t);
        pts.add(Offset(x, y));
      }
    } else if (circuitId == 'monaco') {
      // Circuit de Monaco: Tight street course with harbour chicane & swimming pool
      for (int i = 0; i < segments; i++) {
        double t = (i / segments) * 2 * pi;
        double x = 0.78 * cos(t) - 0.22 * sin(2 * t) + 0.10 * cos(4 * t);
        double y = 0.65 * sin(t) + 0.18 * cos(2 * t) - 0.12 * sin(3 * t);
        pts.add(Offset(x, y));
      }
    } else if (circuitId == 'spa') {
      // Spa-Francorchamps: Triangular profile with Eau Rouge dip & Kemmel straight
      for (int i = 0; i < segments; i++) {
        double t = (i / segments) * 2 * pi;
        double x = 0.82 * cos(t) + 0.15 * sin(2 * t);
        double y = 0.72 * sin(t) - 0.25 * sin(2 * t);
        pts.add(Offset(x, y));
      }
    } else if (circuitId == 'silverstone') {
      // Silverstone: Maggotts/Becketts complex & Hangar straight
      for (int i = 0; i < segments; i++) {
        double t = (i / segments) * 2 * pi;
        double x = 0.85 * cos(t) + 0.10 * cos(3 * t);
        double y = 0.60 * sin(t) + 0.20 * sin(2 * t);
        pts.add(Offset(x, y));
      }
    } else {
      // Bahrain / Suzuka / Interlagos: Grand Prix road course
      for (int i = 0; i < segments; i++) {
        double t = (i / segments) * 2 * pi;
        double x = 0.80 * cos(t) + 0.12 * sin(2 * t);
        double y = 0.68 * sin(t) - 0.10 * cos(3 * t);
        pts.add(Offset(x, y));
      }
    }

    return pts;
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter oldDelegate) => true;
}
