import 'package:flutter/material.dart';
import '../../models/race_state.dart';
import '../../data/drivers_data.dart';
import '../../data/teams_data.dart';
import '../theme/f1_theme.dart';

class TimingTowerWidget extends StatelessWidget {
  final List<CarTelemetry> cars;
  final List<String> playerDriverIds;
  final double? width;
  final Function(String driverId)? onDriverSelected;

  const TimingTowerWidget({
    super.key,
    required this.cars,
    required this.playerDriverIds,
    this.width,
    this.onDriverSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark.withValues(alpha: 0.95),
        border: Border.all(color: F1Theme.surfaceBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Tower Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const BoxDecoration(
              color: F1Theme.carbonBlack,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('POS', style: F1Theme.f1Display(fontSize: 10, color: Colors.grey)),
                ),
                Expanded(
                  child: Text('DRIVER', style: F1Theme.f1Display(fontSize: 10, color: Colors.grey)),
                ),
                Text('TYRE', style: F1Theme.f1Display(fontSize: 10, color: Colors.grey)),
                const SizedBox(width: 28),
                Text('GAP / INT', style: F1Theme.f1Display(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 1, color: F1Theme.surfaceBorder),

          // Tower list of 20 cars
          Expanded(
            child: ListView.builder(
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                final driver = DriversData.getDriverById(car.driverId);
                final team = TeamsData.getTeamById(car.teamId);
                final bool isPlayerCar = playerDriverIds.contains(car.driverId);

                return InkWell(
                  onTap: () => onDriverSelected?.call(car.driverId),
                  child: Container(
                    height: 29,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isPlayerCar
                          ? F1Theme.f1Red.withValues(alpha: 0.22)
                          : (index % 2 == 0 ? Colors.transparent : Colors.white.withValues(alpha: 0.02)),
                      border: isPlayerCar
                          ? Border.all(color: F1Theme.f1Red.withValues(alpha: 0.7), width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Position
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${car.position}',
                            style: F1Theme.f1Mono(
                              fontSize: 11,
                              color: car.position <= 3
                                  ? const Color(0xFFFFD700)
                                  : (car.position <= 10 ? Colors.white : Colors.white70),
                            ),
                          ),
                        ),

                        // Team Color stripe
                        Container(
                          width: 3.5,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(team?.primaryColorHex ?? 0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Driver Code & Box / DRS status
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                driver?.shortCode ?? 'DRV',
                                style: F1Theme.f1Display(
                                  fontSize: 13,
                                  fontWeight: isPlayerCar ? FontWeight.w900 : FontWeight.w700,
                                  color: isPlayerCar ? Colors.white : Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              if (car.boxThisLap) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: F1Theme.f1Red,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text('PIT', style: F1Theme.f1Display(fontSize: 8, italic: false)),
                                ),
                              ],
                              if (car.hasDrsAvailable) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: F1Theme.drsGreen,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    'DRS',
                                    style: F1Theme.f1Display(fontSize: 7, color: Colors.black, italic: false),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Tire Compound Badge & Age
                        Container(
                          width: 17,
                          height: 17,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(car.currentTire.colorHex),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            car.currentTire.shortCode,
                            style: F1Theme.f1Display(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(car.currentTire.colorHex),
                              italic: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 20,
                          child: Text(
                            '${car.lapsOnCurrentTire}L',
                            style: F1Theme.f1Mono(fontSize: 9, color: Colors.grey),
                          ),
                        ),

                        // Interval / Gap
                        SizedBox(
                          width: 62,
                          child: Text(
                            car.status == CarRaceStatus.outOfRace
                                ? 'DNF'
                                : (car.position == 1
                                    ? 'LEADER'
                                    : '+${car.intervalToAheadSeconds.toStringAsFixed(1)}s'),
                            textAlign: TextAlign.end,
                            style: F1Theme.f1Mono(
                              fontSize: 10,
                              color: car.status == CarRaceStatus.outOfRace
                                  ? Colors.redAccent
                                  : (car.intervalToAheadSeconds < 1.0 && car.position > 1
                                      ? F1Theme.drsGreen
                                      : Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
