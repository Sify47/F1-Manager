import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/race_event.dart';
import '../../models/race_state.dart';
import '../../models/circuit.dart';
import '../../models/team.dart';
import '../../state/race_controller.dart';
import '../theme/f1_theme.dart';
import '../widgets/timing_tower.dart';
import '../widgets/circuit_canvas.dart';
import '../widgets/driver_command_dock.dart';
import '../widgets/weather_radar_widget.dart';
import '../widgets/undercut_widget.dart';
import '../widgets/battle_card.dart';
import '../../models/press_conference.dart';
import '../../data/drivers_data.dart';
import '../../models/race_strategy_plan.dart';
import '../widgets/strategy_planner_view.dart';
import '../../services/audio_service.dart';
import '../../state/career_controller.dart';

class RaceScreen extends StatelessWidget {
  final Circuit circuit;
  final Team playerTeam;
  final List<String>? startingGridDriverIds;
  final Map<String, DriverRaceStrategy>? startingStrategies;
  final CareerController? careerController;

  const RaceScreen({
    super.key,
    required this.circuit,
    required this.playerTeam,
    this.startingGridDriverIds,
    this.startingStrategies,
    this.careerController,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RaceController(
        circuit: circuit,
        playerTeam: playerTeam,
        startingGridDriverIds: startingGridDriverIds,
        startingStrategies: startingStrategies,
      ),
      child: _RaceScreenContent(
        careerController: careerController,
        playerTeam: playerTeam,
      ),
    );
  }
}

class _RaceScreenContent extends StatefulWidget {
  final CareerController? careerController;
  final Team playerTeam;

  const _RaceScreenContent({
    this.careerController,
    required this.playerTeam,
  });

  @override
  State<_RaceScreenContent> createState() => _RaceScreenContentState();
}

class _RaceScreenContentState extends State<_RaceScreenContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _resultsAwarded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _finishRaceAndReturnToCareer(BuildContext context, BuildContext? modalCtx, RaceController controller) {
    if (!_resultsAwarded && widget.careerController != null) {
      final List<CarTelemetry> sortedCars = List.from(controller.cars);
      sortedCars.sort((a, b) => a.position.compareTo(b.position));

      const List<int> f1Points = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
      final Map<String, int> driverPointsGained = {};
      final Map<String, int> constructorPointsGained = {};

      for (int i = 0; i < sortedCars.length; i++) {
        final car = sortedCars[i];
        final pts = i < f1Points.length ? f1Points[i] : 0;
        if (pts > 0) {
          driverPointsGained[car.driverId] = pts;
          final driver = DriversData.getDriverById(car.driverId);
          if (driver != null) {
            constructorPointsGained[driver.teamId] =
                (constructorPointsGained[driver.teamId] ?? 0) + pts;
          }
        }
      }

      int prizeMoney = 4; // Base participation payout in millions
      final playerCars = sortedCars.where((c) => widget.playerTeam.driverIds.contains(c.driverId)).toList();
      if (playerCars.isNotEmpty) {
        final bestPos = playerCars.map((c) => c.position).reduce((a, b) => a < b ? a : b);
        if (bestPos == 1) {
          prizeMoney += 12;
        } else if (bestPos <= 3) {
          prizeMoney += 8;
        } else if (bestPos <= 10) {
          prizeMoney += 4;
        }
      }

      widget.careerController!.awardRaceResults(
        driverPointsGained: driverPointsGained,
        constructorPointsGained: constructorPointsGained,
        prizeMoneyMillions: prizeMoney,
      );

      widget.careerController!.advanceToNextRace();
      _resultsAwarded = true;
    }

    if (modalCtx != null) {
      Navigator.pop(modalCtx);
    }
    Navigator.pop(context, true);
  }

  void _confirmAbandonRace(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: F1Theme.surfaceDark,
        title: Text('ABANDON GRAND PRIX?', style: F1Theme.f1Display(fontSize: 15, color: F1Theme.f1Red)),
        content: Text(
          'Are you sure you want to abandon the race and return to Headquarters? Current race progress will be lost.',
          style: F1Theme.f1Body(fontSize: 11, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CONTINUE RACING', style: F1Theme.f1Display(fontSize: 11, color: Colors.greenAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: F1Theme.f1Red),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false); // Exit race without finishing
            },
            child: Text('ABANDON', style: F1Theme.f1Display(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showLiveStrategySheet(BuildContext context, RaceController controller) {
    final d1Id = controller.playerTeam.driverIds[0];
    final d2Id = controller.playerTeam.driverIds[1];
    final s1 = controller.getDriverStrategy(d1Id);
    final s2 = controller.getDriverStrategy(d2Id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: F1Theme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: F1Theme.surfaceBorder)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: F1Theme.f1Red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE PIT WALL STRATEGY OVERVIEW',
                      style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StrategyPlannerView(
                  circuit: controller.circuit,
                  playerTeam: controller.playerTeam,
                  initialStrategies: {
                    d1Id: ?s1,
                    d2Id: ?s2,
                  },
                  onConfirm: (updatedMap) {
                    for (var entry in updatedMap.entries) {
                      controller.updateDriverStrategy(entry.key, entry.value);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RaceController>();
    final engine = controller.engine;
    final weather = engine.weatherEngine.currentState;
    final playerDriverIds = controller.playerTeam.driverIds;

    final latestIncident = controller.eventsHistory.isNotEmpty ? controller.eventsHistory.last : null;
    final latestBattle = controller.recentBattles.isNotEmpty ? controller.recentBattles.first : null;
    final undercutPred = controller.getUndercutPrediction(playerDriverIds.first);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              if (controller.isRaceFinished) {
                _finishRaceAndReturnToCareer(context, null, controller);
              } else {
                _confirmAbandonRace(context);
              }
            }
          },
          child: Scaffold(
            backgroundColor: F1Theme.carbonBlack,
            body: SafeArea(
              child: Column(
                children: [
                  // TOP HEADER BAR (Broadcast style)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: const BoxDecoration(
                      color: F1Theme.surfaceDark,
                      border: Border(bottom: BorderSide(color: F1Theme.surfaceBorder)),
                    ),
                    child: Row(
                      children: [
                        // Official Team Badge & Live Status (Prevents accidental exit)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Color(controller.playerTeam.primaryColorHex),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            controller.playerTeam.shortName.toUpperCase(),
                            style: F1Theme.f1Display(fontSize: 10, fontWeight: FontWeight.w900, italic: true),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Grand Prix Title & Lap
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.circuit.country.toUpperCase(),
                              style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'LAP ${controller.currentLap}/${controller.circuit.totalLaps}',
                              style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.w900, color: F1Theme.f1Red),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),

                        // Safety Car / Flag banner
                        _buildFlagBanner(controller.safetyCarStatus, isMobile),

                        const Spacer(),

                        // Weather Radar (Compact on mobile)
                        if (!isMobile) ...[
                          WeatherRadarWidget(weather: weather),
                          const SizedBox(width: 8),
                        ],

                        // Simulation Speed Controls (0x, 1x, 2x, 5x, 10x, 30x!)
                        _buildSpeedControls(controller, isMobile),
                        const SizedBox(width: 4),

                        // Audio Mute Toggle
                        IconButton(
                          icon: Icon(
                            AudioService().isMuted ? Icons.volume_off : Icons.volume_up,
                            color: AudioService().isMuted ? Colors.redAccent : Colors.greenAccent,
                            size: 18,
                          ),
                          tooltip: AudioService().isMuted ? 'Unmute F1 Audio' : 'Mute F1 Audio',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () {
                            setState(() {
                              AudioService().toggleMute();
                            });
                          },
                        ),
                        const SizedBox(width: 4),

                        // Protected Abandon / Exit Button
                        IconButton(
                          icon: const Icon(Icons.exit_to_app, color: Colors.white54, size: 18),
                          tooltip: controller.isRaceFinished ? 'Finish & Return to Career' : 'Abandon Race',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () {
                            if (controller.isRaceFinished) {
                              _finishRaceAndReturnToCareer(context, null, controller);
                            } else {
                              _confirmAbandonRace(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // MOBILE SEGMENTED TAB BAR
                  if (isMobile)
                    Container(
                      height: 36,
                      decoration: const BoxDecoration(
                        color: F1Theme.surfaceDark,
                        border: Border(bottom: BorderSide(color: F1Theme.surfaceBorder)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: F1Theme.f1Red,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'PIT WALL & TRACK'),
                          Tab(text: 'TIMING TOWER'),
                          Tab(text: 'RADIO & FEED'),
                        ],
                      ),
                    ),

                  // RACE FINISHED CELEBRATION BAR
                  if (controller.isRaceFinished)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      color: Colors.amber,
                      child: Row(
                        children: [
                          const Text('🏁', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CHEQUERED FLAG! RACE COMPLETE',
                              style: F1Theme.f1Display(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: F1Theme.f1Red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _showPodiumAndPressModal(context, controller),
                            child: Text('PODIUM & PRESS →', style: F1Theme.f1Display(fontSize: 10)),
                          ),
                        ],
                      ),
                    ),

                  // MAIN CONTENT (Adaptive Mobile TabBarView vs Desktop Multi-column)
                  Expanded(
                    child: isMobile
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              // TAB 1: 2D Track, Alerts, Undercut, & Driver Commands
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  children: [
                                    // 2D Track Map (Clean & Unobstructed!)
                                    Expanded(
                                      flex: 4,
                                      child: CircuitCanvasWidget(
                                        circuit: controller.circuit,
                                        cars: controller.cars,
                                        playerDriverIds: playerDriverIds,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Dedicated Broadcast Race Control Ticker (Clean Lower-Third position)
                                    if (latestBattle != null || latestIncident != null) ...[
                                      BattleCardWidget(
                                        battle: latestBattle,
                                        latestIncident: latestIncident,
                                      ),
                                      const SizedBox(height: 6),
                                    ],

                                    // Undercut Predictor
                                    UndercutWidget(prediction: undercutPred),
                                    const SizedBox(height: 6),

                                    // Pit Wall Controls
                                    DriverCommandDockWidget(
                                      driver1: controller.playerDriver1,
                                      car1: controller.playerCar1,
                                      driver2: controller.playerDriver2,
                                      car2: controller.playerCar2,
                                      strategy1: controller.getDriverStrategy(playerDriverIds[0]),
                                      strategy2: controller.getDriverStrategy(playerDriverIds[1]),
                                      onPaceChanged: (id, mode) => controller.setDriverPace(id, mode),
                                      onFuelChanged: (id, mix) => controller.setDriverFuel(id, mix),
                                      onErsChanged: (id, mode) => controller.setDriverErs(id, mode),
                                      onPitOrder: (id, tire) => controller.orderPitStop(id, tire),
                                      onToggleAutoStrategy: (id, auto) => controller.toggleAutoStrategy(id, auto),
                                      onOpenStrategyPlanner: () => _showLiveStrategySheet(context, controller),
                                    ),
                                  ],
                                ),
                              ),

                              // TAB 2: Full Screen Timing Tower (P1-P20)
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: TimingTowerWidget(
                                  cars: controller.cars,
                                  playerDriverIds: playerDriverIds,
                                  width: double.infinity,
                                ),
                              ),

                              // TAB 3: Team Radio & Race Events Feed
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildRadioAndEventsFeed(controller),
                              ),
                            ],
                          )
                        : // DESKTOP SIDE-BY-SIDE LAYOUT
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // LEFT: Timing Tower (P1 - P20)
                                TimingTowerWidget(
                                  cars: controller.cars,
                                  playerDriverIds: playerDriverIds,
                                  width: 290,
                                ),
                                const SizedBox(width: 8),

                                // RIGHT: 2D Track, Broadcast Ticker, Undercut, & Driver Commands
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Clean Unobstructed 2D Track
                                      Expanded(
                                        flex: 5,
                                        child: CircuitCanvasWidget(
                                          circuit: controller.circuit,
                                          cars: controller.cars,
                                          playerDriverIds: playerDriverIds,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Broadcast Lower-Third Ticker
                                      if (latestBattle != null || latestIncident != null) ...[
                                        BattleCardWidget(
                                          battle: latestBattle,
                                          latestIncident: latestIncident,
                                        ),
                                        const SizedBox(height: 6),
                                      ],

                                      UndercutWidget(prediction: undercutPred),
                                      const SizedBox(height: 6),

                                      DriverCommandDockWidget(
                                        driver1: controller.playerDriver1,
                                        car1: controller.playerCar1,
                                        driver2: controller.playerDriver2,
                                        car2: controller.playerCar2,
                                        strategy1: controller.getDriverStrategy(playerDriverIds[0]),
                                        strategy2: controller.getDriverStrategy(playerDriverIds[1]),
                                        onPaceChanged: (id, mode) => controller.setDriverPace(id, mode),
                                        onFuelChanged: (id, mix) => controller.setDriverFuel(id, mix),
                                        onErsChanged: (id, mode) => controller.setDriverErs(id, mode),
                                        onPitOrder: (id, tire) => controller.orderPitStop(id, tire),
                                        onToggleAutoStrategy: (id, auto) => controller.toggleAutoStrategy(id, auto),
                                        onOpenStrategyPlanner: () => _showLiveStrategySheet(context, controller),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlagBanner(SafetyCarStatus status, bool isMobile) {
    if (status == SafetyCarStatus.clear) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          border: Border.all(color: Colors.greenAccent),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag, color: Colors.greenAccent, size: 12),
            if (!isMobile) ...[
              const SizedBox(width: 4),
              Text('TRACK CLEAR', style: F1Theme.f1Display(fontSize: 9, color: Colors.greenAccent)),
            ],
          ],
        ),
      );
    } else {
      String label = status == SafetyCarStatus.virtualSafetyCar ? 'VSC' : 'SAFETY CAR';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.3),
          border: Border.all(color: Colors.amber, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.amber, size: 12),
            const SizedBox(width: 4),
            Text(label, style: F1Theme.f1Display(fontSize: 9, color: Colors.amber)),
          ],
        ),
      );
    }
  }

  Widget _buildSpeedControls(RaceController controller, bool isMobile) {
    final speeds = [0, 1, 2, 5, 10, 30];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: speeds.map((speed) {
        final isSelected = controller.simSpeed == speed;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: InkWell(
            onTap: () => controller.setSimSpeed(speed),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? F1Theme.f1Red : F1Theme.surfaceBorder,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                speed == 0 ? 'II' : '${speed}X',
                style: F1Theme.f1Display(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.white70,
                  italic: false,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadioAndEventsFeed(RaceController controller) {
    return Container(
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEAM RADIO & RACE EVENTS', style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.bold)),
          const Divider(height: 16, color: F1Theme.surfaceBorder),
          Expanded(
            child: controller.eventsHistory.isEmpty && controller.radioHistory.isEmpty
                ? Center(
                    child: Text('No active incidents. Race running smoothly.',
                        style: F1Theme.f1Body(fontSize: 12, color: Colors.grey)),
                  )
                : ListView(
                    children: [
                      ...controller.radioHistory.map((msg) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: F1Theme.carbonBlack,
                            borderRadius: BorderRadius.circular(4),
                            border: const Border(left: BorderSide(color: Colors.lightBlueAccent, width: 3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.radio, size: 14, color: Colors.lightBlueAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'LAP ${msg.lap} [${msg.driverShortName}]: "${msg.text}"',
                                  style: F1Theme.f1Body(fontSize: 11, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      ...controller.eventsHistory.reversed.map((evt) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: F1Theme.carbonBlack,
                            borderRadius: BorderRadius.circular(4),
                            border: Border(
                              left: BorderSide(
                                color: evt.severity == EventSeverity.critical ? F1Theme.f1Red : Colors.amber,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LAP ${evt.lap} • ${evt.title}',
                                style: F1Theme.f1Display(fontSize: 11, color: Colors.amber),
                              ),
                              Text(evt.description, style: F1Theme.f1Body(fontSize: 10, color: Colors.white70)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showPodiumAndPressModal(BuildContext context, RaceController controller) {
    final cars = controller.cars;
    final p1 = cars.isNotEmpty ? DriversData.getDriverById(cars[0].driverId) : null;
    final p2 = cars.length > 1 ? DriversData.getDriverById(cars[1].driverId) : null;
    final p3 = cars.length > 2 ? DriversData.getDriverById(cars[2].driverId) : null;

    final bestPos = controller.playerCar1?.position ?? 10;
    final questions = PaddockPoliticsEngine.generatePostRaceQuestions(
      teamName: controller.playerTeam.name,
      driver1LastName: controller.playerDriver1?.lastName ?? 'Driver',
      bestFinishPosition: bestPos,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: F1Theme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.88,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PODIUM CEREMONY & PRESS DESK',
                        style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: F1Theme.surfaceBorder),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PODIUM STEPS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // P2
                              _buildPodiumStep('P2 🥈', p2?.fullName ?? 'P2', 18, 70, Colors.grey[400]!),
                              // P1 (Tallest)
                              _buildPodiumStep('P1 🏆', p1?.fullName ?? 'WINNER', 25, 100, Colors.amber),
                              // P3
                              _buildPodiumStep('P3 🥉', p3?.fullName ?? 'P3', 15, 55, const Color(0xFFCD7F32)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: F1Theme.surfaceBorder),

                          // POST-RACE PRESS CONFERENCE
                          Text('POST-RACE PRESS CONFERENCE (DRIVE TO SURVIVE)',
                              style: F1Theme.f1Display(fontSize: 11, color: F1Theme.f1Red)),
                          const SizedBox(height: 10),

                          ...questions.map((q) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: F1Theme.carbonBlack,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: F1Theme.surfaceBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.mic, size: 14, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Text('${q.journalistName} (${q.mediaOutlet})',
                                          style: F1Theme.f1Display(fontSize: 10, color: Colors.amber)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(q.questionText, style: F1Theme.f1Body(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ...q.options.map((opt) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: F1Theme.surfaceBorder),
                                          padding: const EdgeInsets.all(8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(opt.consequenceSummary, style: F1Theme.f1Body()),
                                              backgroundColor: Colors.green[800],
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                opt.text,
                                                style: F1Theme.f1Body(fontSize: 10, color: Colors.white70),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Return to Season Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: F1Theme.f1Red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        _finishRaceAndReturnToCareer(context, ctx, controller);
                      },
                      child: Text('RETURN TO FACTORY & ADVANCE SEASON →',
                          style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPodiumStep(String stepLabel, String driverName, int points, double height, Color color) {
    return Column(
      children: [
        Text(driverName, style: F1Theme.f1Display(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
        Text('+$points PTS', style: F1Theme.f1Mono(fontSize: 9, color: Colors.amber)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            border: Border.all(color: color, width: 2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          alignment: Alignment.center,
          child: Text(
            stepLabel,
            style: F1Theme.f1Display(fontSize: 14, color: color, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
