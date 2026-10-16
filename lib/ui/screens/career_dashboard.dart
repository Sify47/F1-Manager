import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team.dart';
import '../../models/circuit.dart';
import '../../data/circuits_data.dart';
import '../../data/drivers_data.dart';
import '../../state/career_controller.dart';
import '../theme/f1_theme.dart';
import 'weekend_hub_screen.dart';
import '../widgets/rd_factory_view.dart';
import '../widgets/board_objectives_card.dart';
import '../../services/save_game_service.dart';

class CareerDashboardScreen extends StatelessWidget {
  final Team team;
  final CareerSaveData? savedData;

  const CareerDashboardScreen({super.key, required this.team, this.savedData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CareerController(initialTeam: team, savedData: savedData),
      child: const _CareerDashboardContent(),
    );
  }
}

class _CareerDashboardContent extends StatelessWidget {
  const _CareerDashboardContent();

  @override
  Widget build(BuildContext context) {
    final career = context.watch<CareerController>();
    final team = career.playerTeam;
    final currentCircuit = career.currentCircuit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: F1Theme.carbonBlack,
          appBar: AppBar(
            backgroundColor: F1Theme.carbonBlack,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Save & Return to Main Menu',
              icon: const Icon(Icons.home_outlined, color: Colors.white70, size: 22),
              onPressed: () {
                career.manualSave();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: F1Theme.surfaceDark,
                    duration: const Duration(seconds: 1),
                    content: Text(
                      'Career progress saved! 💾',
                      style: F1Theme.f1Body(fontSize: 12, color: Colors.greenAccent),
                    ),
                  ),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            title: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(team.primaryColorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  team.name.toUpperCase(),
                  style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: F1Theme.surfaceDark,
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.greenAccent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '\$${team.budgetMillions}M',
                      style: F1Theme.f1Mono(fontSize: 11, color: Colors.greenAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: isMobile
                  ? Column(
                      children: [
                        _buildNextRaceCard(context, currentCircuit, team, career),
                        const SizedBox(height: 12),
                        BoardObjectivesCard(career: career),
                        const SizedBox(height: 12),
                        _buildDriversCard(team),
                        const SizedBox(height: 12),
                        _buildRdDepartmentCard(context, career, team),
                        const SizedBox(height: 12),
                        _buildChampionshipStandingsCard(career),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT COLUMN
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildNextRaceCard(context, currentCircuit, team, career),
                              const SizedBox(height: 14),
                              BoardObjectivesCard(career: career),
                              const SizedBox(height: 14),
                              _buildDriversCard(team),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // RIGHT COLUMN
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _buildRdDepartmentCard(context, career, team),
                              const SizedBox(height: 14),
                              _buildChampionshipStandingsCard(career),
                            ],
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

  Widget _buildNextRaceCard(BuildContext context, Circuit circuit, Team team, CareerController career) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                'UPCOMING GRAND PRIX',
                style: F1Theme.f1Display(fontSize: 10, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: F1Theme.f1Red,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'ROUND ${career.currentRaceIndex + 1} / ${CircuitsData.allCircuits.length}',
                  style: F1Theme.f1Display(fontSize: 9, italic: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(circuit.flagEmoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      circuit.grandPrixName.toUpperCase(),
                      style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${circuit.name} (${circuit.city}, ${circuit.country})',
                      style: F1Theme.f1Body(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: F1Theme.surfaceBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRaceSpecItem('LAPS', '${circuit.totalLaps}'),
              _buildRaceSpecItem('LENGTH', '${circuit.lengthKm} km'),
              _buildRaceSpecItem('ABRASION', '${(circuit.asphaltAbrasiveness * 100).toInt()}%'),
              _buildRaceSpecItem('RAIN RISK', '${(circuit.baseRainProbability * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: F1Theme.f1Red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeekendHubScreen(circuit: circuit, playerTeam: team, careerController: career),
                  ),
                );
              },
              icon: const Icon(Icons.sports_motorsports, size: 18),
              label: Text(
                'ENTER RACE WEEKEND',
                style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceSpecItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: F1Theme.f1Display(fontSize: 8, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: F1Theme.f1Mono(fontSize: 12)),
      ],
    );
  }

  Widget _buildDriversCard(Team team) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE DRIVERS',
            style: F1Theme.f1Display(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...team.driverIds.map((driverId) {
            final driver = DriversData.getDriverById(driverId);
            if (driver == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: F1Theme.carbonBlack,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: F1Theme.surfaceBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white12,
                    child: Text('${driver.number}', style: F1Theme.f1Mono(fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.fullName, style: F1Theme.f1Body(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Braking: ${driver.stats.braking} • Tyre: ${driver.stats.tyreManagement}',
                            style: F1Theme.f1Body(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    'OVR ${driver.stats.overallRating}',
                    style: F1Theme.f1Mono(fontSize: 11, color: Colors.amber),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRdDepartmentCard(BuildContext context, CareerController career, Team team) {
    return RdFactoryView(career: career);
  }

  Widget _buildChampionshipStandingsCard(CareerController career) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONSTRUCTORS CHAMPIONSHIP',
            style: F1Theme.f1Display(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          ...career.sortedConstructorStandings.take(5).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final standing = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('P${idx + 1}', style: F1Theme.f1Mono(fontSize: 10)),
                  ),
                  Expanded(
                    child: Text(standing.shortCode, style: F1Theme.f1Display(fontSize: 11, italic: false)),
                  ),
                  Text('${standing.points} PTS', style: F1Theme.f1Mono(fontSize: 10)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
