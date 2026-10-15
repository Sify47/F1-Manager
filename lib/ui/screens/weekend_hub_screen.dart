import 'package:flutter/material.dart';
import '../../models/team.dart';
import '../../models/circuit.dart';
import '../../models/car_setup.dart';
import '../../models/weekend_session.dart';
import '../../engine/setup_engine.dart';
import '../../engine/qualifying_engine.dart';
import '../../engine/sprint_engine.dart';
import '../../services/audio_service.dart';
import '../../state/career_controller.dart';
import '../../data/drivers_data.dart';
import '../theme/f1_theme.dart';
import 'race_screen.dart';
import '../widgets/strategy_planner_view.dart';
import '../../models/race_strategy_plan.dart';

class WeekendHubScreen extends StatefulWidget {
  final Circuit circuit;
  final Team playerTeam;
  final CareerController? careerController;

  const WeekendHubScreen({
    super.key,
    required this.circuit,
    required this.playerTeam,
    this.careerController,
  });

  @override
  State<WeekendHubScreen> createState() => _WeekendHubScreenState();
}

class _WeekendHubScreenState extends State<WeekendHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Car Setup & Practice state for Driver 1 & Driver 2 (FP1, FP2, FP3)
  int _selectedDriverIndex = 0; // 0: Driver 1, 1: Driver 2
  int _currentPracticeSession = 1; // 1: FP1, 2: FP2, 3: FP3
  bool _isPracticeRunning = false;

  CarSetup _setupDriver1 = const CarSetup(frontWingAngle: 5, rearWingAngle: 5, suspensionStiffness: 5, camberAngle: 5, gearRatio: 5);
  CarSetup _setupDriver2 = const CarSetup(frontWingAngle: 5, rearWingAngle: 5, suspensionStiffness: 5, camberAngle: 5, gearRatio: 5);
  SetupEvaluationResult? _evaluationDriver1;
  SetupEvaluationResult? _evaluationDriver2;

  // Qualifying state
  QualifyingResults? _qualiResults;
  bool _isQualiRunning = false;

  // Sprint state
  SprintRaceResult? _sprintResults;
  bool _isSprintRunning = false;
  bool _sprintPointsAwarded = false;

  // Race Strategy state
  Map<String, DriverRaceStrategy>? _selectedStrategies;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _runPracticeEvaluation() {
    setState(() => _isPracticeRunning = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final d1 = DriversData.getDriverById(widget.playerTeam.driverIds.first);
      final d2 = widget.playerTeam.driverIds.length > 1
          ? DriversData.getDriverById(widget.playerTeam.driverIds[1])
          : null;

      final eval1 = SetupEngine.evaluateSetup(
        setup: _setupDriver1,
        circuit: widget.circuit,
        driver: d1,
        sessionIndex: _currentPracticeSession,
      );

      final eval2 = d2 != null
          ? SetupEngine.evaluateSetup(
              setup: _setupDriver2,
              circuit: widget.circuit,
              driver: d2,
              sessionIndex: _currentPracticeSession,
            )
          : null;

      AudioService().playEngineFlyby();

      setState(() {
        _evaluationDriver1 = eval1;
        _evaluationDriver2 = eval2;
        _isPracticeRunning = false;
      });
    });
  }

  void _simulateSprintRace() {
    setState(() => _isSprintRunning = true);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final sprintEngine = SprintEngine(circuit: widget.circuit);
      List<String> startingGrid = _qualiResults?.startingGridDriverIds ??
          DriversData.allDrivers.map((d) => d.id).toList();

      final d1 = DriversData.getDriverById(widget.playerTeam.driverIds[0]);
      final d2 = widget.playerTeam.driverIds.length > 1
          ? DriversData.getDriverById(widget.playerTeam.driverIds[1])
          : null;

      final Map<String, double> paceBonuses = {};
      if (d1 != null && _evaluationDriver1 != null) {
        paceBonuses[d1.id] = _evaluationDriver1!.paceDeltaSeconds;
      }
      if (d2 != null && _evaluationDriver2 != null) {
        paceBonuses[d2.id] = _evaluationDriver2!.paceDeltaSeconds;
      }

      final result = sprintEngine.runSprintRace(
        startingGridDriverIds: startingGrid,
        driverPaceBonuses: paceBonuses.isNotEmpty ? paceBonuses : null,
      );

      if (!_sprintPointsAwarded && widget.careerController != null) {
        widget.careerController!.awardRaceResults(
          driverPointsGained: result.driverPointsGained,
          constructorPointsGained: result.constructorPointsGained,
        );
        _sprintPointsAwarded = true;
      }

      AudioService().playChequeredFlag();

      setState(() {
        _sprintResults = result;
        _isSprintRunning = false;
      });
    });
  }

  void _simulateQualifying() {
    setState(() => _isQualiRunning = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final engine = QualifyingEngine(circuit: widget.circuit);
      final d1 = DriversData.getDriverById(widget.playerTeam.driverIds[0]);
      final d2 = widget.playerTeam.driverIds.length > 1
          ? DriversData.getDriverById(widget.playerTeam.driverIds[1])
          : null;

      final Map<String, double> paceBonuses = {};
      if (d1 != null && _evaluationDriver1 != null) {
        paceBonuses[d1.id] = _evaluationDriver1!.paceDeltaSeconds;
      }
      if (d2 != null && _evaluationDriver2 != null) {
        paceBonuses[d2.id] = _evaluationDriver2!.paceDeltaSeconds;
      }

      final results = engine.runFullQualifying(
        driverSetupPaceBonuses: paceBonuses.isNotEmpty ? paceBonuses : null,
      );

      setState(() {
        _qualiResults = results;
        _isQualiRunning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F1Theme.carbonBlack,
      appBar: AppBar(
        backgroundColor: F1Theme.surfaceDark,
        title: Row(
          children: [
            Text(widget.circuit.flagEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              '${widget.circuit.grandPrixName.toUpperCase()} WEEKEND',
              style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: F1Theme.f1Red,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: [
            const Tab(text: '1. SETUP & PRACTICE'),
            Tab(text: widget.circuit.isSprintWeekend ? '2. SPRINT & QUALI' : '2. QUALIFYING (Q1-Q3)'),
            const Tab(text: '3. STARTING GRID'),
            const Tab(text: '4. RACE STRATEGY'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSetupAndPracticeTab(),
            _buildQualifyingTab(),
            _buildStartingGridTab(),
            _buildRaceStrategyTab(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: SETUP & PRACTICE (FP1, FP2, FP3 for Driver 1 & Driver 2) ---
  Widget _buildSetupAndPracticeTab() {
    final d1 = DriversData.getDriverById(widget.playerTeam.driverIds[0]);
    final d2 = widget.playerTeam.driverIds.length > 1
        ? DriversData.getDriverById(widget.playerTeam.driverIds[1])
        : null;

    final activeDriver = _selectedDriverIndex == 0 ? d1 : d2;
    final activeSetup = _selectedDriverIndex == 0 ? _setupDriver1 : _setupDriver2;
    final activeEval = _selectedDriverIndex == 0 ? _evaluationDriver1 : _evaluationDriver2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GARAGE & FREE PRACTICE',
                style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: F1Theme.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: F1Theme.surfaceBorder),
                ),
                child: Text('SESSION: FP$_currentPracticeSession / 3', style: F1Theme.f1Mono(fontSize: 9, color: Colors.amber)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Dial in setups for both drivers across FP1, FP2, & FP3. Each driver has unique preferences!',
            style: F1Theme.f1Body(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // 1. FREE PRACTICE SESSION SELECTOR (FP1, FP2, FP3)
          Row(
            children: [1, 2, 3].map((sessionIdx) {
              final isCurrent = _currentPracticeSession == sessionIdx;
              final isDone = (_evaluationDriver1 != null && _evaluationDriver1!.sessionIndex >= sessionIdx);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: () => setState(() => _currentPracticeSession = sessionIdx),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? F1Theme.f1Red.withValues(alpha: 0.25) : F1Theme.surfaceDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCurrent ? F1Theme.f1Red : (isDone ? Colors.green.withValues(alpha: 0.5) : F1Theme.surfaceBorder),
                          width: isCurrent ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'FP$sessionIdx',
                                style: F1Theme.f1Display(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? Colors.white : (isDone ? Colors.greenAccent : Colors.grey),
                                ),
                              ),
                              if (isDone) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, size: 10, color: Colors.greenAccent),
                              ],
                            ],
                          ),
                          Text(
                            sessionIdx == 1 ? 'BASELINE' : (sessionIdx == 2 ? 'RACE RUN' : 'QUALI SIM'),
                            style: F1Theme.f1Body(fontSize: 8, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 2. DRIVER SWITCHER TABS (Driver 1 & Driver 2)
          Row(
            children: [
              // Driver 1 Tab
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedDriverIndex = 0),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedDriverIndex == 0 ? F1Theme.surfaceDark : F1Theme.carbonBlack,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selectedDriverIndex == 0 ? Colors.cyanAccent : F1Theme.surfaceBorder,
                        width: _selectedDriverIndex == 0 ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('👤', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d1?.fullName.toUpperCase() ?? 'DRIVER 1',
                                style: F1Theme.f1Display(fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _evaluationDriver1 != null
                                    ? '${(_evaluationDriver1!.setupSatisfactionPercentage * 100).toInt()}% SETUP FIT'
                                    : 'FP$_currentPracticeSession UNTESTED',
                                style: F1Theme.f1Mono(
                                  fontSize: 8,
                                  color: _evaluationDriver1 != null ? F1Theme.drsGreen : Colors.grey,
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
              const SizedBox(width: 8),

              // Driver 2 Tab
              if (d2 != null)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedDriverIndex = 1),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedDriverIndex == 1 ? F1Theme.surfaceDark : F1Theme.carbonBlack,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _selectedDriverIndex == 1 ? Colors.cyanAccent : F1Theme.surfaceBorder,
                          width: _selectedDriverIndex == 1 ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('👤', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d2.fullName.toUpperCase(),
                                  style: F1Theme.f1Display(fontSize: 10, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _evaluationDriver2 != null
                                      ? '${(_evaluationDriver2!.setupSatisfactionPercentage * 100).toInt()}% SETUP FIT'
                                      : 'FP$_currentPracticeSession UNTESTED',
                                  style: F1Theme.f1Mono(
                                    fontSize: 8,
                                    color: _evaluationDriver2 != null ? F1Theme.drsGreen : Colors.grey,
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
            ],
          ),
          const SizedBox(height: 12),

          // 3. SETUP SLIDERS BOX (Tuned specifically for the active driver)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: F1Theme.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: F1Theme.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${activeDriver?.shortCode ?? "CAR"} SETUP TUNING',
                      style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                    ),
                    Text('ADJUST SLIDERS', style: F1Theme.f1Mono(fontSize: 9, color: Colors.grey)),
                  ],
                ),
                const Divider(height: 14, color: F1Theme.surfaceBorder),

                _buildSliderRow(
                  label: 'Front Wing Angle',
                  value: activeSetup.frontWingAngle,
                  desc: 'Low-speed turn-in balance & anti-understeer',
                  onChanged: (v) {
                    setState(() {
                      if (_selectedDriverIndex == 0) {
                        _setupDriver1 = _setupDriver1.copyWith(frontWingAngle: v.toInt());
                      } else {
                        _setupDriver2 = _setupDriver2.copyWith(frontWingAngle: v.toInt());
                      }
                    });
                  },
                ),
                _buildSliderRow(
                  label: 'Rear Wing Angle',
                  value: activeSetup.rearWingAngle,
                  desc: 'High-speed downforce vs top-speed straight line drag',
                  onChanged: (v) {
                    setState(() {
                      if (_selectedDriverIndex == 0) {
                        _setupDriver1 = _setupDriver1.copyWith(rearWingAngle: v.toInt());
                      } else {
                        _setupDriver2 = _setupDriver2.copyWith(rearWingAngle: v.toInt());
                      }
                    });
                  },
                ),
                _buildSliderRow(
                  label: 'Suspension Stiffness',
                  value: activeSetup.suspensionStiffness,
                  desc: 'Soft for kerbs & street bumps, stiff for aero platform',
                  onChanged: (v) {
                    setState(() {
                      if (_selectedDriverIndex == 0) {
                        _setupDriver1 = _setupDriver1.copyWith(suspensionStiffness: v.toInt());
                      } else {
                        _setupDriver2 = _setupDriver2.copyWith(suspensionStiffness: v.toInt());
                      }
                    });
                  },
                ),
                _buildSliderRow(
                  label: 'Gear Ratio Spacing',
                  value: activeSetup.gearRatio,
                  desc: 'Short for corner acceleration, tall for top end speed',
                  onChanged: (v) {
                    setState(() {
                      if (_selectedDriverIndex == 0) {
                        _setupDriver1 = _setupDriver1.copyWith(gearRatio: v.toInt());
                      } else {
                        _setupDriver2 = _setupDriver2.copyWith(gearRatio: v.toInt());
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Button to Run Practice Session
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: F1Theme.f1Red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _isPracticeRunning ? null : _runPracticeEvaluation,
                    icon: _isPracticeRunning
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.timer, size: 16),
                    label: Text(
                      _isPracticeRunning
                          ? 'RUNNING FP$_currentPracticeSession SIMULATION...'
                          : 'SEND BOTH CARS FOR FP$_currentPracticeSession STINT ⏱️',
                      style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. TELEMETRY & FEEDBACK RESULT BOX (Displays for the active driver)
          if (activeEval != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: F1Theme.cardHighlight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: F1Theme.drsGreen.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('FP${activeEval.sessionIndex} TELEMETRY DEBRIEF', style: F1Theme.f1Display(fontSize: 11, color: F1Theme.drsGreen)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(3)),
                            child: Text(activeDriver?.shortCode ?? "D", style: F1Theme.f1Mono(fontSize: 9, color: Colors.cyanAccent)),
                          ),
                        ],
                      ),
                      Text(
                        '${(activeEval.setupSatisfactionPercentage * 100).toInt()}% SATISFACTION',
                        style: F1Theme.f1Mono(fontSize: 11, color: F1Theme.drsGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Practice Lap time & Pace Delta bar
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: F1Theme.carbonBlack, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRACTICE LAP TIME', style: F1Theme.f1Display(fontSize: 8, color: Colors.grey)),
                            Text(activeEval.practiceLapTime, style: F1Theme.f1Mono(fontSize: 13, color: Colors.amber, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('QUALI PACE DELTA', style: F1Theme.f1Display(fontSize: 8, color: Colors.grey)),
                            Text('${activeEval.paceDeltaSeconds.toStringAsFixed(2)}s per lap', style: F1Theme.f1Mono(fontSize: 12, color: Colors.greenAccent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(activeEval.overallDriverQuote,
                      style: F1Theme.f1Body(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                  const Divider(height: 14, color: F1Theme.surfaceBorder),
                  _buildFeedbackBullet('Front Wing', activeEval.frontWingFeedback),
                  _buildFeedbackBullet('Rear Wing', activeEval.rearWingFeedback),
                  _buildFeedbackBullet('Suspension', activeEval.suspensionFeedback),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Advance Session or Proceed to Quali
            Row(
              children: [
                if (_currentPracticeSession < 3)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amber),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        setState(() => _currentPracticeSession++);
                      },
                      child: Text('PROCEED TO FP${_currentPracticeSession + 1} ⏩', style: F1Theme.f1Display(fontSize: 11, color: Colors.amber)),
                    ),
                  ),
                if (_currentPracticeSession < 3) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: F1Theme.f1Red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _tabController.animateTo(1),
                    child: Text('PROCEED TO QUALI →', style: F1Theme.f1Display(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required int value,
    required String desc,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(3)),
                child: Text('$value / 10', style: F1Theme.f1Mono(fontSize: 10)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: F1Theme.f1Red,
              thumbColor: Colors.white,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),
          Text(desc, style: F1Theme.f1Body(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFeedbackBullet(String part, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• $part: ', style: F1Theme.f1Display(fontSize: 10, color: Colors.grey)),
          Expanded(child: Text(text, style: F1Theme.f1Body(fontSize: 10, color: Colors.white70))),
        ],
      ),
    );
  }

  // --- TAB 2: QUALIFYING KNOCKOUT (Q1, Q2, Q3) & SPRINT ---
  Widget _buildQualifyingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.circuit.isSprintWeekend) ...[
            _buildSprintSection(),
            const SizedBox(height: 14),
            const Divider(color: F1Theme.surfaceBorder, height: 1),
            const SizedBox(height: 14),
          ],
          _buildQualifyingSection(),
        ],
      ),
    );
  }

  Widget _buildSprintSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('F1 SPRINT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.circuit.sprintLaps} LAPS • 100 KM SPRINT',
                  style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (_sprintResults != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: F1Theme.drsGreen.withValues(alpha: 0.2),
                    border: Border.all(color: F1Theme.drsGreen),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('COMPLETED', style: F1Theme.f1Mono(fontSize: 9, color: F1Theme.drsGreen)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Official championship points awarded to the Top 8 finishers (8-7-6-5-4-3-2-1).',
            style: F1Theme.f1Body(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (_sprintResults == null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _isSprintRunning ? null : _simulateSprintRace,
                icon: _isSprintRunning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.flash_on, size: 16),
                label: Text(
                  _isSprintRunning ? 'RACING SPRINT...' : 'START 100KM SPRINT RACE ⚡',
                  style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            Text('SPRINT RESULTS (TOP 8 POINTS SCORERS)', style: F1Theme.f1Display(fontSize: 10, color: Colors.amber)),
            const SizedBox(height: 6),
            ..._sprintResults!.finishers.take(8).map((finisher) {
              final driver = DriversData.getDriverById(finisher.driverId);
              final isPlayer = widget.playerTeam.driverIds.contains(finisher.driverId);
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isPlayer ? F1Theme.f1Red.withValues(alpha: 0.22) : F1Theme.carbonBlack,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isPlayer ? F1Theme.f1Red : F1Theme.surfaceBorder,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('P${finisher.position}', style: F1Theme.f1Mono(fontSize: 10, color: finisher.position == 1 ? Colors.amber : Colors.white70)),
                    ),
                    Expanded(
                      child: Text(
                        driver?.fullName ?? finisher.driverId,
                        style: F1Theme.f1Display(
                          fontSize: 11,
                          fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal,
                          color: isPlayer ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                    Text(
                      finisher.position == 1 ? 'WINNER' : '+${finisher.gapToLeaderSeconds.toStringAsFixed(2)}s',
                      style: F1Theme.f1Mono(fontSize: 9, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '+${finisher.points} PTS',
                        style: F1Theme.f1Mono(fontSize: 9, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildQualifyingSection() {
    if (_qualiResults == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(Icons.flash_on, size: 48, color: F1Theme.f1Red),
            const SizedBox(height: 12),
            Text('OFFICIAL QUALIFYING SHOOTOUT', style: F1Theme.f1Display(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '3-tier knockout format:\n• Q1: 20 Cars → Bottom 5 eliminated (P16-P20)\n• Q2: 15 Cars → Bottom 5 eliminated (P11-P15)\n• Q3: Top 10 Pole Position Shootout!',
              textAlign: TextAlign.center,
              style: F1Theme.f1Body(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: F1Theme.f1Red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _isQualiRunning ? null : _simulateQualifying,
              child: _isQualiRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('COMMENCE QUALIFYING', style: F1Theme.f1Display(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    final poleLap = _qualiResults!.q3Laps.first;
    final poleDriver = DriversData.getDriverById(poleLap.driverId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pole Position Trophy Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: F1Theme.carbonBlack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('POLE POSITION 🏆', style: F1Theme.f1Display(fontSize: 11, color: Colors.amber)),
                    Text(poleDriver?.fullName.toUpperCase() ?? poleLap.driverShortName,
                        style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.w900)),
                    Text('Lap Time: ${poleLap.formattedLapTime}', style: F1Theme.f1Mono(fontSize: 11, color: F1Theme.purpleSector)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: F1Theme.f1Red,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _tabController.animateTo(2),
                child: Text('VIEW GRID →', style: F1Theme.f1Display(fontSize: 10)),
              ),
            ],
          ),
        ),
          const SizedBox(height: 14),

          // Q3 Results Table
          Text('Q3 TOP 10 SHOOTOUT', style: F1Theme.f1Display(fontSize: 12, color: F1Theme.purpleSector)),
          const SizedBox(height: 6),
          ..._qualiResults!.q3Laps.asMap().entries.map((entry) {
            final idx = entry.key;
            final lap = entry.value;
            return _buildQualiLapRow(idx + 1, lap, isCutoff: false);
          }),
          const SizedBox(height: 14),

          // Q2 Eliminated Table
          Text('Q2 ELIMINATED (P11 - P15)', style: F1Theme.f1Display(fontSize: 12, color: Colors.amber)),
          const SizedBox(height: 6),
          ..._qualiResults!.q2Laps.skip(10).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final lap = entry.value;
            return _buildQualiLapRow(idx + 11, lap, isCutoff: true);
          }),
          const SizedBox(height: 14),

          // Q1 Eliminated Table
          Text('Q1 ELIMINATED (P16 - P20)', style: F1Theme.f1Display(fontSize: 12, color: F1Theme.f1Red)),
          const SizedBox(height: 6),
          ..._qualiResults!.q1Laps.skip(15).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final lap = entry.value;
            return _buildQualiLapRow(idx + 16, lap, isCutoff: true);
          }),
        ],
      );
  }

  Widget _buildQualiLapRow(int pos, DriverQualiLap lap, {required bool isCutoff}) {
    final driver = DriversData.getDriverById(lap.driverId);
    final bool isPlayer = widget.playerTeam.driverIds.contains(lap.driverId);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isPlayer ? F1Theme.f1Red.withValues(alpha: 0.22) : F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPlayer ? F1Theme.f1Red : (isCutoff ? Colors.red.withValues(alpha: 0.4) : F1Theme.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('P$pos', style: F1Theme.f1Mono(fontSize: 10, color: pos <= 3 ? Colors.amber : Colors.white70)),
          ),
          Expanded(
            child: Text(
              driver?.fullName ?? lap.driverShortName,
              style: F1Theme.f1Display(
                fontSize: 11,
                fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal,
                color: isPlayer ? Colors.white : Colors.white70,
              ),
            ),
          ),
          Text(lap.formattedLapTime, style: F1Theme.f1Mono(fontSize: 10)),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              pos == 1 ? 'POLE' : '+${lap.gapToLeader.toStringAsFixed(3)}',
              textAlign: TextAlign.end,
              style: F1Theme.f1Mono(fontSize: 9, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: OFFICIAL STARTING GRID & LAUNCH RACE ---
  Widget _buildStartingGridTab() {
    if (_qualiResults == null) {
      return Center(
        child: Text('Run Qualifying first to determine the Starting Grid!',
            style: F1Theme.f1Body(fontSize: 12, color: Colors.grey)),
      );
    }

    final gridIds = _qualiResults!.startingGridDriverIds;

    return Column(
      children: [
        // Grid List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: gridIds.length,
            itemBuilder: (context, index) {
              final driverId = gridIds[index];
              final driver = DriversData.getDriverById(driverId);
              final isPlayer = widget.playerTeam.driverIds.contains(driverId);

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isPlayer ? F1Theme.f1Red.withValues(alpha: 0.25) : F1Theme.surfaceDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPlayer ? F1Theme.f1Red : F1Theme.surfaceBorder,
                    width: isPlayer ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.amber : (index < 3 ? Colors.white24 : Colors.white12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'GRID ${index + 1}',
                        style: F1Theme.f1Mono(fontSize: 9, color: index == 0 ? Colors.black : Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        driver?.fullName.toUpperCase() ?? driverId,
                        style: F1Theme.f1Display(fontSize: 12, fontWeight: isPlayer ? FontWeight.bold : FontWeight.normal),
                      ),
                    ),
                    if (isPlayer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: F1Theme.f1Red, borderRadius: BorderRadius.circular(3)),
                        child: Text('YOUR CAR', style: F1Theme.f1Display(fontSize: 8, italic: false)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Sticky Bottom CTA: Start Grand Prix
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: F1Theme.surfaceDark,
            border: Border(top: BorderSide(color: F1Theme.surfaceBorder)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: F1Theme.f1Red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () => _tabController.animateTo(3),
              icon: const Icon(Icons.psychology, size: 20),
              label: Text(
                'PROCEED TO RACE STRATEGY →',
                style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 4: MULTI-STINT RACE STRATEGY PLANNER ---
  Widget _buildRaceStrategyTab() {
    return StrategyPlannerView(
      circuit: widget.circuit,
      playerTeam: widget.playerTeam,
      initialStrategies: _selectedStrategies,
      onConfirm: (strategies) {
        setState(() => _selectedStrategies = strategies);
      },
      onLaunchRace: _launchGrandPrix,
    );
  }

  void _launchGrandPrix() async {
    final raceFinished = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RaceScreen(
          circuit: widget.circuit,
          playerTeam: widget.playerTeam,
          startingGridDriverIds: _qualiResults?.startingGridDriverIds,
          startingStrategies: _selectedStrategies,
          careerController: widget.careerController,
        ),
      ),
    );

    if (raceFinished == true && mounted) {
      Navigator.pop(context, true);
    }
  }
}
