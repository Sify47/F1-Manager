import 'package:flutter/material.dart';
import '../../models/circuit.dart';
import '../../models/team.dart';
import '../../models/driver.dart';
import '../../models/tire.dart';
import '../../models/race_strategy_plan.dart';
import '../../engine/strategy_generator.dart';
import '../../data/drivers_data.dart';
import '../theme/f1_theme.dart';

class StrategyPlannerView extends StatefulWidget {
  final Circuit circuit;
  final Team playerTeam;
  final Map<String, DriverRaceStrategy>? initialStrategies;
  final Function(Map<String, DriverRaceStrategy> strategies) onConfirm;
  final VoidCallback? onLaunchRace;

  const StrategyPlannerView({
    super.key,
    required this.circuit,
    required this.playerTeam,
    this.initialStrategies,
    required this.onConfirm,
    this.onLaunchRace,
  });

  @override
  State<StrategyPlannerView> createState() => _StrategyPlannerViewState();
}

class _StrategyPlannerViewState extends State<StrategyPlannerView> {
  int _selectedDriverIndex = 0; // 0 = Driver 1, 1 = Driver 2
  late List<StrategyOption> _availablePresets;

  // Selected strategy per driver
  late Map<String, DriverRaceStrategy> _driverStrategies;

  // Custom strategy builder states per driver
  late Map<String, bool> _isCustomMode;
  late Map<String, int> _customNumStops; // 1 or 2
  late Map<String, TireType> _customStint1Tire;
  late Map<String, TireType> _customStint2Tire;
  late Map<String, TireType> _customStint3Tire;
  late Map<String, int> _customPitLap1;
  late Map<String, int> _customPitLap2;
  late Map<String, bool> _autoBox;

  @override
  void initState() {
    super.initState();
    _availablePresets = StrategyGenerator.generateStrategies(widget.circuit);

    final d1Id = widget.playerTeam.driverIds[0];
    final d2Id = widget.playerTeam.driverIds[1];

    _driverStrategies = {};
    _isCustomMode = {d1Id: false, d2Id: false};
    _customNumStops = {d1Id: 1, d2Id: 1};
    _customStint1Tire = {d1Id: TireType.medium, d2Id: TireType.medium};
    _customStint2Tire = {d1Id: TireType.hard, d2Id: TireType.hard};
    _customStint3Tire = {d1Id: TireType.soft, d2Id: TireType.soft};

    int defaultPit1 = (widget.circuit.totalLaps * 0.40).round();
    int defaultPit2 = (widget.circuit.totalLaps * 0.68).round();
    _customPitLap1 = {d1Id: defaultPit1, d2Id: defaultPit1};
    _customPitLap2 = {d1Id: defaultPit2, d2Id: defaultPit2};
    _autoBox = {d1Id: false, d2Id: false};

    // Initialize with presets or passed initial strategies
    for (String dId in [d1Id, d2Id]) {
      if (widget.initialStrategies != null && widget.initialStrategies!.containsKey(dId)) {
        _driverStrategies[dId] = widget.initialStrategies![dId]!;
        _autoBox[dId] = widget.initialStrategies![dId]!.autoExecutePitStops;
      } else {
        // Default to Chief Strategist Pick
        final defaultChoice = _availablePresets.firstWhere(
          (s) => s.isChiefStrategistPick,
          orElse: () => _availablePresets.first,
        );
        _driverStrategies[dId] = DriverRaceStrategy(
          driverId: dId,
          chosenStrategy: defaultChoice,
          activeStints: List.from(defaultChoice.stints),
          currentStintIndex: 0,
          autoExecutePitStops: false,
        );
      }
    }
  }

  void _selectPreset(String driverId, StrategyOption option) {
    setState(() {
      _isCustomMode[driverId] = false;
      _driverStrategies[driverId] = DriverRaceStrategy(
        driverId: driverId,
        chosenStrategy: option,
        activeStints: List.from(option.stints),
        currentStintIndex: 0,
        autoExecutePitStops: _autoBox[driverId] ?? false,
      );
    });
    widget.onConfirm(_driverStrategies);
  }

  void _rebuildCustomStrategy(String driverId) {
    int stops = _customNumStops[driverId] ?? 1;
    StrategyOption customOpt;

    if (stops == 1) {
      customOpt = StrategyGenerator.createCustom1Stop(
        circuit: widget.circuit,
        compound1: _customStint1Tire[driverId] ?? TireType.medium,
        compound2: _customStint2Tire[driverId] ?? TireType.hard,
        pitLap: _customPitLap1[driverId] ?? (widget.circuit.totalLaps * 0.40).round(),
      );
    } else {
      customOpt = StrategyGenerator.createCustom2Stop(
        circuit: widget.circuit,
        compound1: _customStint1Tire[driverId] ?? TireType.soft,
        compound2: _customStint2Tire[driverId] ?? TireType.medium,
        compound3: _customStint3Tire[driverId] ?? TireType.soft,
        pitLap1: _customPitLap1[driverId] ?? (widget.circuit.totalLaps * 0.30).round(),
        pitLap2: _customPitLap2[driverId] ?? (widget.circuit.totalLaps * 0.65).round(),
      );
    }

    setState(() {
      _isCustomMode[driverId] = true;
      _driverStrategies[driverId] = DriverRaceStrategy(
        driverId: driverId,
        chosenStrategy: customOpt,
        activeStints: List.from(customOpt.stints),
        currentStintIndex: 0,
        autoExecutePitStops: _autoBox[driverId] ?? false,
      );
    });
    widget.onConfirm(_driverStrategies);
  }

  void _toggleAutoBox(String driverId, bool val) {
    setState(() {
      _autoBox[driverId] = val;
      if (_driverStrategies.containsKey(driverId)) {
        _driverStrategies[driverId] = _driverStrategies[driverId]!.copyWith(autoExecutePitStops: val);
      }
    });
    widget.onConfirm(_driverStrategies);
  }

  @override
  Widget build(BuildContext context) {
    final driver1 = DriversData.getDriverById(widget.playerTeam.driverIds[0]);
    final driver2 = DriversData.getDriverById(widget.playerTeam.driverIds[1]);
    final activeDriver = _selectedDriverIndex == 0 ? driver1 : driver2;
    if (activeDriver == null) return const SizedBox.shrink();

    final activeStrategy = _driverStrategies[activeDriver.id];
    final isCustom = _isCustomMode[activeDriver.id] ?? false;

    return Column(
      children: [
        // Driver Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: F1Theme.surfaceDark,
          child: Row(
            children: [
              Expanded(
                child: _buildDriverTabButton(
                  index: 0,
                  driver: driver1,
                  isSelected: _selectedDriverIndex == 0,
                  strategy: _driverStrategies[driver1?.id ?? ''],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDriverTabButton(
                  index: 1,
                  driver: driver2,
                  isSelected: _selectedDriverIndex == 1,
                  strategy: _driverStrategies[driver2?.id ?? ''],
                ),
              ),
            ],
          ),
        ),

        // Content Area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Strategy Mode Header & AI Strategist Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: F1Theme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: F1Theme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: F1Theme.f1Red.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology, color: F1Theme.f1Red, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI RACE STRATEGIST / المهندس الآلي',
                              style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _autoBox[activeDriver.id] == true
                                  ? 'Active: AI will automatically box on scheduled lap or during rain/tyre cliff.'
                                  : 'Manual: Chief Strategist advises via radio, you trigger box orders.',
                              style: F1Theme.f1Body(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoBox[activeDriver.id] ?? false,
                        activeTrackColor: F1Theme.f1Red,
                        onChanged: (val) => _toggleAutoBox(activeDriver.id, val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Mode Selector: Presets vs Custom
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (isCustom) {
                            final defaultChoice = _availablePresets.firstWhere(
                              (s) => s.isChiefStrategistPick,
                              orElse: () => _availablePresets.first,
                            );
                            _selectPreset(activeDriver.id, defaultChoice);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !isCustom ? F1Theme.f1Red.withValues(alpha: 0.2) : F1Theme.surfaceDark,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: !isCustom ? F1Theme.f1Red : F1Theme.surfaceBorder, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '⭐ CHIEF STRATEGIST PROPOSALS',
                            style: F1Theme.f1Display(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: !isCustom ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!isCustom) {
                            _rebuildCustomStrategy(activeDriver.id);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isCustom ? F1Theme.f1Red.withValues(alpha: 0.2) : F1Theme.surfaceDark,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isCustom ? F1Theme.f1Red : F1Theme.surfaceBorder, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🛠️ CUSTOM STRATEGY BUILDER',
                            style: F1Theme.f1Display(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCustom ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Presets List or Custom Builder
                if (!isCustom) ...[
                  ..._availablePresets.map((option) {
                    final isSelected = activeStrategy?.chosenStrategy.id == option.id;
                    return _buildStrategyCard(
                      driverId: activeDriver.id,
                      option: option,
                      isSelected: isSelected,
                    );
                  }),
                ] else ...[
                  _buildCustomStrategyBuilder(activeDriver.id),
                ],
              ],
            ),
          ),
        ),

        // Sticky Bottom Summary & CTA
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: F1Theme.surfaceDark,
            border: Border(top: BorderSide(color: F1Theme.surfaceBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${driver1?.shortCode}: ${_driverStrategies[driver1?.id ?? '']?.chosenStrategy.name.split(':')[0] ?? "1-Stop"}',
                          style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Auto-Box: ${_autoBox[driver1?.id] == true ? "ON" : "OFF"}',
                          style: F1Theme.f1Body(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: F1Theme.surfaceBorder),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${driver2?.shortCode}: ${_driverStrategies[driver2?.id ?? '']?.chosenStrategy.name.split(':')[0] ?? "1-Stop"}',
                          style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Auto-Box: ${_autoBox[driver2?.id] == true ? "ON" : "OFF"}',
                          style: F1Theme.f1Body(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.onLaunchRace != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: F1Theme.f1Red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      widget.onConfirm(_driverStrategies);
                      widget.onLaunchRace?.call();
                    },
                    icon: const Icon(Icons.sports_score, size: 20),
                    label: Text(
                      'CONFIRM STRATEGY & START RACE 🏁',
                      style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverTabButton({
    required int index,
    required Driver? driver,
    required bool isSelected,
    required DriverRaceStrategy? strategy,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedDriverIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? F1Theme.carbonBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? F1Theme.f1Red : F1Theme.surfaceBorder, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'CAR ${index + 1}: ${driver?.shortCode ?? "DRV"}',
                  style: F1Theme.f1Display(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: F1Theme.f1Red),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              strategy?.chosenStrategy.name.split('(')[0].trim() ?? 'Strategy A',
              style: F1Theme.f1Mono(fontSize: 9, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCard({
    required String driverId,
    required StrategyOption option,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? F1Theme.f1Red : (option.isChiefStrategistPick ? Colors.amber.withValues(alpha: 0.5) : F1Theme.surfaceBorder),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _selectPreset(driverId, option),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Name + Chief Strategist Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.name,
                        style: F1Theme.f1Display(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                    if (option.isChiefStrategistPick)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: Text(
                          '⭐ RECOMMENDED',
                          style: F1Theme.f1Display(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.amber),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  option.description,
                  style: F1Theme.f1Body(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // Stints Visual Progress Bar
                _buildStintsTimelineBar(option.stints),
                const SizedBox(height: 10),

                // Metrics: Stops count, Risk Score, Undercut potential
                Row(
                  children: [
                    _buildMetricChip(
                      icon: Icons.refresh,
                      label: '${option.totalStops} Pit Stop${option.totalStops > 1 ? "s" : ""}',
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      icon: Icons.speed,
                      label: 'Tyre Risk: ${(option.tireRiskScore * 100).toInt()}%',
                      color: option.tireRiskScore > 0.5 ? Colors.redAccent : Colors.greenAccent,
                    ),
                    const Spacer(),
                    if (isSelected)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: F1Theme.f1Red, size: 16),
                          const SizedBox(width: 4),
                          Text('SELECTED', style: F1Theme.f1Display(fontSize: 10, color: F1Theme.f1Red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStintsTimelineBar(List<StintPlan> stints) {
    int totalLaps = widget.circuit.totalLaps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 22,
            child: Row(
              children: stints.map((stint) {
                double flexFactor = (stint.endLap - stint.startLap + 1) / totalLaps;
                Color compoundColor = _getCompoundColor(stint.compound);

                return Expanded(
                  flex: (flexFactor * 1000).round(),
                  child: Container(
                    color: compoundColor.withValues(alpha: 0.85),
                    alignment: Alignment.center,
                    child: Text(
                      '${stint.compound.name.substring(0, 1).toUpperCase()} (${stint.startLap}-${stint.endLap})',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Titillium Web',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Lap 1 (Start)', style: F1Theme.f1Mono(fontSize: 8, color: Colors.grey)),
            Text('Lap $totalLaps (Finish)', style: F1Theme.f1Mono(fontSize: 8, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomStrategyBuilder(String driverId) {
    int stops = _customNumStops[driverId] ?? 1;
    int totalLaps = widget.circuit.totalLaps;
    int pit1 = _customPitLap1[driverId] ?? (totalLaps * 0.40).round();
    int pit2 = _customPitLap2[driverId] ?? (totalLaps * 0.65).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: F1Theme.f1Red.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOM PIT STRATEGY DESIGNER',
            style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Fine-tune each stint compound and choose exact pit stop laps.',
            style: F1Theme.f1Body(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // 1-Stop vs 2-Stop Toggle
          Row(
            children: [
              Text('Strategy Structure:', style: F1Theme.f1Display(fontSize: 11)),
              const Spacer(),
              ChoiceChip(
                label: Text('1-Stop', style: F1Theme.f1Display(fontSize: 10)),
                selected: stops == 1,
                selectedColor: F1Theme.f1Red,
                onSelected: (sel) {
                  if (sel) {
                    setState(() => _customNumStops[driverId] = 1);
                    _rebuildCustomStrategy(driverId);
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('2-Stop', style: F1Theme.f1Display(fontSize: 10)),
                selected: stops == 2,
                selectedColor: F1Theme.f1Red,
                onSelected: (sel) {
                  if (sel) {
                    setState(() => _customNumStops[driverId] = 2);
                    _rebuildCustomStrategy(driverId);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stint 1 Controls
          _buildStintConfigRow(
            stintNumber: 1,
            selectedTire: _customStint1Tire[driverId] ?? TireType.medium,
            onTireSelected: (t) {
              setState(() => _customStint1Tire[driverId] = t);
              _rebuildCustomStrategy(driverId);
            },
            lapRangeText: 'Laps 1 to $pit1',
          ),
          const SizedBox(height: 8),

          // Pit Stop 1 Lap Slider
          Row(
            children: [
              Text('Pit Stop 1 Lap: ', style: F1Theme.f1Display(fontSize: 10)),
              Text('Lap $pit1', style: F1Theme.f1Mono(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: pit1.toDouble(),
                  min: 4,
                  max: stops == 1 ? (totalLaps - 4).toDouble() : (pit2 - 3).toDouble(),
                  divisions: stops == 1 ? (totalLaps - 8) : (pit2 - 7),
                  activeColor: F1Theme.f1Red,
                  onChanged: (val) {
                    setState(() => _customPitLap1[driverId] = val.round());
                    _rebuildCustomStrategy(driverId);
                  },
                ),
              ),
            ],
          ),
          const Divider(color: F1Theme.surfaceBorder),

          // Stint 2 Controls
          _buildStintConfigRow(
            stintNumber: 2,
            selectedTire: _customStint2Tire[driverId] ?? TireType.hard,
            onTireSelected: (t) {
              setState(() => _customStint2Tire[driverId] = t);
              _rebuildCustomStrategy(driverId);
            },
            lapRangeText: stops == 1 ? 'Laps ${pit1 + 1} to $totalLaps' : 'Laps ${pit1 + 1} to $pit2',
          ),

          // If 2-Stop: Pit Stop 2 Lap Slider & Stint 3 Controls
          if (stops == 2) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Pit Stop 2 Lap: ', style: F1Theme.f1Display(fontSize: 10)),
                Text('Lap $pit2', style: F1Theme.f1Mono(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Slider(
                    value: pit2.toDouble(),
                    min: (pit1 + 3).toDouble(),
                    max: (totalLaps - 3).toDouble(),
                    divisions: (totalLaps - pit1 - 6),
                    activeColor: F1Theme.f1Red,
                    onChanged: (val) {
                      setState(() => _customPitLap2[driverId] = val.round());
                      _rebuildCustomStrategy(driverId);
                    },
                  ),
                ),
              ],
            ),
            const Divider(color: F1Theme.surfaceBorder),
            _buildStintConfigRow(
              stintNumber: 3,
              selectedTire: _customStint3Tire[driverId] ?? TireType.soft,
              onTireSelected: (t) {
                setState(() => _customStint3Tire[driverId] = t);
                _rebuildCustomStrategy(driverId);
              },
              lapRangeText: 'Laps ${pit2 + 1} to $totalLaps',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStintConfigRow({
    required int stintNumber,
    required TireType selectedTire,
    required Function(TireType) onTireSelected,
    required String lapRangeText,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
          child: Text('STINT $stintNumber', style: F1Theme.f1Display(fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(lapRangeText, style: F1Theme.f1Mono(fontSize: 10, color: Colors.grey)),
        const Spacer(),
        // Tire choice chips
        ...[TireType.soft, TireType.medium, TireType.hard].map((t) {
          final isSel = selectedTire == t;
          final color = _getCompoundColor(t);
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              onTap: () => onTireSelected(t),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSel ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSel ? Colors.black : color,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: F1Theme.f1Mono(fontSize: 9, color: Colors.white70)),
        ],
      ),
    );
  }

  Color _getCompoundColor(TireType type) {
    switch (type) {
      case TireType.soft:
        return Colors.redAccent;
      case TireType.medium:
        return Colors.amber;
      case TireType.hard:
        return Colors.white;
      case TireType.intermediate:
        return Colors.greenAccent;
      case TireType.wet:
        return Colors.blueAccent;
    }
  }
}
