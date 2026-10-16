import 'package:flutter/material.dart';
import '../../models/driver.dart';
import '../../models/race_state.dart';
import '../../models/tire.dart';
import '../../models/race_strategy_plan.dart';
import '../../models/interactive_decision.dart';
import '../theme/f1_theme.dart';

class DriverCommandDockWidget extends StatefulWidget {
  final Driver? driver1;
  final CarTelemetry? car1;
  final Driver? driver2;
  final CarTelemetry? car2;
  final DriverRaceStrategy? strategy1;
  final DriverRaceStrategy? strategy2;
  final Function(String driverId, PaceMode mode) onPaceChanged;
  final Function(String driverId, FuelMix mix) onFuelChanged;
  final Function(String driverId, ErsMode mode) onErsChanged;
  final Function(String driverId, TireType nextTire) onPitOrder;
  final Function(String driverId, bool auto)? onToggleAutoStrategy;
  final VoidCallback? onOpenStrategyPlanner;
  final Function(TeamOrderType order)? onTeamOrder;

  const DriverCommandDockWidget({
    super.key,
    required this.driver1,
    required this.car1,
    required this.driver2,
    required this.car2,
    this.strategy1,
    this.strategy2,
    required this.onPaceChanged,
    required this.onFuelChanged,
    required this.onErsChanged,
    required this.onPitOrder,
    this.onToggleAutoStrategy,
    this.onOpenStrategyPlanner,
    this.onTeamOrder,
  });

  @override
  State<DriverCommandDockWidget> createState() => _DriverCommandDockWidgetState();
}

class _DriverCommandDockWidgetState extends State<DriverCommandDockWidget> {
  int _selectedDriverTab = 0; // 0 = Driver 1, 1 = Driver 2

  @override
  Widget build(BuildContext context) {
    final activeDriver = _selectedDriverTab == 0 ? widget.driver1 : widget.driver2;
    final activeCar = _selectedDriverTab == 0 ? widget.car1 : widget.car2;
    final activeStrategy = _selectedDriverTab == 0 ? widget.strategy1 : widget.strategy2;

    if (activeDriver == null || activeCar == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        return Container(
          decoration: BoxDecoration(
            color: F1Theme.surfaceDark.withValues(alpha: 0.95),
            border: Border.all(color: F1Theme.surfaceBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Driver Tabs + Box This Lap Button + Strategy Planner Button
              Row(
                children: [
                  _buildDriverTab(0, widget.driver1, widget.car1),
                  const SizedBox(width: 6),
                  _buildDriverTab(1, widget.driver2, widget.car2),
                  const Spacer(),
                  if (widget.onTeamOrder != null && widget.car1 != null && widget.car2 != null) ...[
                    PopupMenuButton<TeamOrderType>(
                      icon: const Icon(Icons.swap_calls, size: 16, color: Colors.amberAccent),
                      tooltip: 'Team Orders (Radio Instructions)',
                      padding: EdgeInsets.zero,
                      color: F1Theme.surfaceDark,
                      onSelected: (order) => widget.onTeamOrder?.call(order),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: TeamOrderType.swapPositions,
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz, color: Colors.amberAccent, size: 16),
                              SizedBox(width: 8),
                              Text('SWAP POSITIONS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: TeamOrderType.holdPositions,
                          child: Row(
                            children: [
                              Icon(Icons.pan_tool, color: Colors.redAccent, size: 16),
                              SizedBox(width: 8),
                              Text('HOLD STATIONS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: TeamOrderType.letTeammatesRace,
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.greenAccent, size: 16),
                              SizedBox(width: 8),
                              Text('FREE RACING', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (widget.onOpenStrategyPlanner != null) ...[
                    IconButton(
                      icon: const Icon(Icons.tune, size: 16, color: Colors.white70),
                      tooltip: 'Race Strategy Planner',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onOpenStrategyPlanner,
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Box This Lap Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeCar.boxThisLap ? Colors.amber[800] : F1Theme.f1Red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showPitStopDialog(context, activeDriver.id),
                    icon: const Icon(Icons.build, size: 14),
                    label: Text(
                      activeCar.boxThisLap ? 'BOXING' : 'BOX THIS LAP',
                      style: F1Theme.f1Display(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Active Strategy & Target Pit Window Strip
              _buildStrategyBanner(activeDriver, activeCar, activeStrategy),
              const SizedBox(height: 6),

              // Real-Time Thermal & Aerodynamic Insight Badges
              _buildPhysicsInsightBadge(activeCar),
              const SizedBox(height: 4),

              // Telemetry Gauges (Responsive: 2x2 on narrow, 1x4 on wide)
              if (isNarrow)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTelemetryMeter(
                            label: 'TYRE WEAR',
                            value: '${(activeCar.tireWearPercentage * 100).toStringAsFixed(1)}%',
                            progress: activeCar.tireWearPercentage,
                            color: activeCar.tireWearPercentage > 0.70
                                ? Colors.redAccent
                                : (activeCar.tireWearPercentage > 0.45 ? Colors.amber : Colors.greenAccent),
                            subText: '${activeCar.currentTire.shortCode} (${activeCar.lapsOnCurrentTire}L)',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTelemetryMeter(
                            label: 'TYRE TEMP',
                            value: '${activeCar.tireTemperature.toStringAsFixed(0)}°C',
                            progress: (activeCar.tireTemperature - 60) / 70.0,
                            color: (activeCar.tireTemperature > 115 || activeCar.tireTemperature < 80)
                                ? Colors.redAccent
                                : Colors.lightBlueAccent,
                            subText: 'Optimum: 90-110°C',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTelemetryMeter(
                            label: 'FUEL REMAINING',
                            value: '${activeCar.fuelRemainingKg.toStringAsFixed(1)} kg',
                            progress: activeCar.fuelRemainingKg / 105.0,
                            color: activeCar.fuelRemainingKg < 10.0 ? Colors.redAccent : Colors.amberAccent,
                            subText: 'Burn: ~1.9 kg/L',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTelemetryMeter(
                            label: 'ERS BATTERY',
                            value: '${(activeCar.ersBatteryPercentage * 100).toStringAsFixed(0)}%',
                            progress: activeCar.ersBatteryPercentage,
                            color: F1Theme.drsGreen,
                            subText: 'Hybrid System',
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildTelemetryMeter(
                        label: 'TYRE WEAR',
                        value: '${(activeCar.tireWearPercentage * 100).toStringAsFixed(1)}%',
                        progress: activeCar.tireWearPercentage,
                        color: activeCar.tireWearPercentage > 0.70
                            ? Colors.redAccent
                            : (activeCar.tireWearPercentage > 0.45 ? Colors.amber : Colors.greenAccent),
                        subText: '${activeCar.currentTire.name} (${activeCar.lapsOnCurrentTire} Laps)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTelemetryMeter(
                        label: 'TYRE TEMP',
                        value: '${activeCar.tireTemperature.toStringAsFixed(0)}°C',
                        progress: (activeCar.tireTemperature - 60) / 70.0,
                        color: (activeCar.tireTemperature > 115 || activeCar.tireTemperature < 80)
                            ? Colors.redAccent
                            : Colors.lightBlueAccent,
                        subText: 'Optimum: 90-110°C',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTelemetryMeter(
                        label: 'FUEL REMAINING',
                        value: '${activeCar.fuelRemainingKg.toStringAsFixed(1)} kg',
                        progress: activeCar.fuelRemainingKg / 105.0,
                        color: activeCar.fuelRemainingKg < 10.0 ? Colors.redAccent : Colors.amberAccent,
                        subText: 'Burn: ~1.9 kg/lap',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTelemetryMeter(
                        label: 'ERS BATTERY',
                        value: '${(activeCar.ersBatteryPercentage * 100).toStringAsFixed(0)}%',
                        progress: activeCar.ersBatteryPercentage,
                        color: F1Theme.drsGreen,
                        subText: 'Hybrid System',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Strategy Mode Selectors
              _buildStrategyControls(activeDriver.id, activeCar, isNarrow),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStrategyBanner(Driver driver, CarTelemetry car, DriverRaceStrategy? strategy) {
    if (strategy == null) return const SizedBox.shrink();

    final currentStint = strategy.currentStint;
    final nextStint = strategy.nextStint;
    final isAuto = strategy.autoExecutePitStops;
    final int stintNum = strategy.currentStintIndex + 1;
    final int totalStints = strategy.activeStints.length;

    if (car.boxThisLap) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber[900]?.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.amber, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.amber, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'BOX THIS LAP CONFIRMED: Fitting ${car.nextPitTire?.name.toUpperCase() ?? "NEW TYRES"}!',
                style: F1Theme.f1Display(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: F1Theme.carbonBlack,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      child: Row(
        children: [
          // Stint indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: F1Theme.f1Red.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'STINT $stintNum/$totalStints',
              style: F1Theme.f1Mono(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),

          // Pit Window Info
          Expanded(
            child: Text(
              currentStint != null && nextStint != null
                  ? 'Pit Window: Lap ${currentStint.endLap} → Next: ${nextStint.compound.name.toUpperCase()}'
                  : 'Final Stint to Chequered Flag',
              style: F1Theme.f1Display(fontSize: 10, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),

          // AI Auto-Box Toggle Pill
          InkWell(
            onTap: () {
              if (widget.onToggleAutoStrategy != null) {
                widget.onToggleAutoStrategy!(driver.id, !isAuto);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isAuto ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: isAuto ? Colors.greenAccent : Colors.grey, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_toy, size: 11, color: isAuto ? Colors.greenAccent : Colors.grey),
                  const SizedBox(width: 3),
                  Text(
                    isAuto ? 'AUTO-BOX' : 'MANUAL',
                    style: F1Theme.f1Display(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isAuto ? Colors.greenAccent : Colors.grey,
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

  Widget _buildDriverTab(int tabIndex, Driver? driver, CarTelemetry? car) {
    if (driver == null || car == null) return const SizedBox.shrink();
    final bool isSelected = _selectedDriverTab == tabIndex;

    return InkWell(
      onTap: () => setState(() => _selectedDriverTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? F1Theme.f1Red.withValues(alpha: 0.25) : F1Theme.carbonBlack,
          border: Border.all(
            color: isSelected ? F1Theme.f1Red : F1Theme.surfaceBorder,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
              child: Text(
                'P${car.position}',
                style: F1Theme.f1Mono(fontSize: 10, color: Colors.amber),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              driver.shortCode,
              style: F1Theme.f1Display(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryMeter({
    required String label,
    required String value,
    required double progress,
    required Color color,
    required String subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: F1Theme.carbonBlack,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: F1Theme.f1Display(fontSize: 8, color: Colors.grey)),
              Text(value, style: F1Theme.f1Mono(fontSize: 10, color: color)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 2),
          Text(subText, style: F1Theme.f1Body(fontSize: 8, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildStrategyControls(String driverId, CarTelemetry car, bool isNarrow) {
    if (isNarrow) {
      return Column(
        children: [
          _buildPaceRow(driverId, car),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildFuelRow(driverId, car)),
              const SizedBox(width: 6),
              Expanded(child: _buildErsRow(driverId, car)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 4, child: _buildPaceRow(driverId, car)),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: _buildFuelRow(driverId, car)),
        const SizedBox(width: 8),
        Expanded(flex: 4, child: _buildErsRow(driverId, car)),
      ],
    );
  }

  Widget _buildPaceRow(String driverId, CarTelemetry car) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PACE', style: F1Theme.f1Display(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 3),
        Row(
          children: PaceMode.values.map((mode) {
            final isSel = car.paceMode == mode;
            final color = _getPaceColor(mode);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: InkWell(
                  onTap: () => widget.onPaceChanged(driverId, mode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isSel ? color.withValues(alpha: 0.25) : F1Theme.carbonBlack,
                      border: Border.all(color: isSel ? color : F1Theme.surfaceBorder, width: isSel ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      mode.name.substring(0, 3).toUpperCase(),
                      style: F1Theme.f1Display(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : Colors.white60,
                        italic: false,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 3),
        Text(
          _getPaceDescription(car.paceMode),
          style: F1Theme.f1Body(fontSize: 8, color: _getPaceColor(car.paceMode)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFuelRow(String driverId, CarTelemetry car) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FUEL', style: F1Theme.f1Display(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 3),
        Row(
          children: FuelMix.values.map((mix) {
            final isSel = car.fuelMix == mix;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: InkWell(
                  onTap: () => widget.onFuelChanged(driverId, mix),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.amber.withValues(alpha: 0.25) : F1Theme.carbonBlack,
                      border: Border.all(color: isSel ? Colors.amber : F1Theme.surfaceBorder, width: isSel ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      mix.name.substring(0, 3).toUpperCase(),
                      style: F1Theme.f1Display(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : Colors.white60,
                        italic: false,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErsRow(String driverId, CarTelemetry car) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ERS', style: F1Theme.f1Display(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 3),
        Row(
          children: ErsMode.values.map((ers) {
            final isSel = car.ersMode == ers;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: InkWell(
                  onTap: () => widget.onErsChanged(driverId, ers),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isSel ? F1Theme.drsGreen.withValues(alpha: 0.25) : F1Theme.carbonBlack,
                      border: Border.all(color: isSel ? F1Theme.drsGreen : F1Theme.surfaceBorder, width: isSel ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ers.name.substring(0, 3).toUpperCase(),
                      style: F1Theme.f1Display(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : Colors.white60,
                        italic: false,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getPaceColor(PaceMode mode) {
    switch (mode) {
      case PaceMode.conserve:
        return Colors.blueAccent;
      case PaceMode.balanced:
        return Colors.greenAccent;
      case PaceMode.push:
        return Colors.amberAccent;
      case PaceMode.attack:
        return F1Theme.f1Red;
    }
  }

  String _getPaceDescription(PaceMode mode) {
    switch (mode) {
      case PaceMode.conserve:
        return '🛡️ Save tyre wear (-40%) | +1.0s laptime loss';
      case PaceMode.balanced:
        return '⚖️ Delta target | Standard tire wear';
      case PaceMode.push:
        return '⚡ Push (+0.4s lap delta) | +45% tire wear';
      case PaceMode.attack:
        return '🔥 Max Attack (+0.8s pace) | 2.1x wear & blister risk!';
    }
  }

  Widget _buildPhysicsInsightBadge(CarTelemetry car) {
    Widget? badge;
    if (car.tireTemperature > 115) {
      badge = _buildInsightChip(
        icon: Icons.local_fire_department,
        color: Colors.redAccent,
        text: 'OVERHEATING BLISTER RISK (${car.tireTemperature.toStringAsFixed(0)}°C): Thermal grip loss!',
      );
    } else if (car.tireTemperature < 80) {
      badge = _buildInsightChip(
        icon: Icons.ac_unit,
        color: Colors.lightBlueAccent,
        text: 'COLD GRAINING (${car.tireTemperature.toStringAsFixed(0)}°C): Under operating temperature window!',
      );
    } else if (car.isInDirtyAir) {
      badge = _buildInsightChip(
        icon: Icons.air,
        color: Colors.amberAccent,
        text: 'DIRTY AIR TURBULENCE: -25% aerodynamic downforce, +35% tire degradation!',
      );
    } else if (car.isInSlipstream) {
      badge = _buildInsightChip(
        icon: Icons.bolt,
        color: Colors.greenAccent,
        text: 'SLIPSTREAM DRAFT: Aerodynamic high-speed tow active (-0.28s delta)!',
      );
    }

    if (badge == null) return const SizedBox.shrink();
    return badge;
  }

  Widget _buildInsightChip({required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: F1Theme.f1Display(fontSize: 9, color: color, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showPitStopDialog(BuildContext context, String driverId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: F1Theme.surfaceDark,
          title: Text('CALL PIT STOP', style: F1Theme.f1Display(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select compound for next stint:', style: F1Theme.f1Body(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTireChoiceButton(ctx, driverId, TireType.soft, 'SOFT', Colors.redAccent),
                  _buildTireChoiceButton(ctx, driverId, TireType.medium, 'MED', Colors.amber),
                  _buildTireChoiceButton(ctx, driverId, TireType.hard, 'HARD', Colors.white),
                  _buildTireChoiceButton(ctx, driverId, TireType.intermediate, 'INTER', Colors.greenAccent),
                  _buildTireChoiceButton(ctx, driverId, TireType.wet, 'WET', Colors.blueAccent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTireChoiceButton(BuildContext ctx, String driverId, TireType type, String label, Color color) {
    return InkWell(
      onTap: () {
        widget.onPitOrder(driverId, type);
        Navigator.pop(ctx);
      },
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
              color: color.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              label[0],
              style: F1Theme.f1Display(fontSize: 15, fontWeight: FontWeight.bold, color: color, italic: false),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: F1Theme.f1Display(fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
