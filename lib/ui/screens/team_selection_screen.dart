import 'package:flutter/material.dart';
import '../../models/team.dart';
import '../../data/teams_data.dart';
import '../../data/drivers_data.dart';
import '../theme/f1_theme.dart';
import 'career_dashboard.dart';
import '../../services/save_game_service.dart';

class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  Team _selectedTeam = TeamsData.allTeams.first;
  CareerSaveData? _savedCareer;

  @override
  void initState() {
    super.initState();
    _loadSavedCareer();
  }

  Future<void> _loadSavedCareer() async {
    final save = await SaveGameService.loadSavedCareer();
    if (mounted) {
      setState(() => _savedCareer = save);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: F1Theme.carbonBlack,
          appBar: AppBar(
            backgroundColor: F1Theme.carbonBlack,
            elevation: 0,
            title: Row(
              children: [
                // F1 Angular Red Logo
                Transform(
                  transform: Matrix4.skewX(-0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: F1Theme.f1Red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'F1',
                      style: F1Theme.f1Display(fontSize: 16, fontWeight: FontWeight.w900, italic: true),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'MANAGER 2026',
                  style: F1Theme.f1Display(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        );
      },
    );
  }

  Widget _buildResumeCareerBanner() {
    if (_savedCareer == null) return const SizedBox.shrink();
    final team = TeamsData.getTeamById(_savedCareer!.teamId);
    if (team == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(team.primaryColorHex), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(team.primaryColorHex).withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(team.primaryColorHex).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_score, color: Colors.amber, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('SAVED CAREER FOUND', style: F1Theme.f1Display(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('• Round ${_savedCareer!.currentRaceIndex + 1}', style: F1Theme.f1Mono(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                Text(
                  team.name.toUpperCase(),
                  style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Budget: \$${_savedCareer!.budgetMillions}M',
                  style: F1Theme.f1Mono(fontSize: 9, color: Colors.white60),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(team.primaryColorHex),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CareerDashboardScreen(team: team, savedData: _savedCareer),
                ),
              );
            },
            child: Text('RESUME ▶', style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // MOBILE LAYOUT (Clean Vertical Scroll with Team Cards Carousel / List)
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildResumeCareerBanner(),
        // Title bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SELECT CONSTRUCTOR',
                style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              Text(
                '10 TEAMS',
                style: F1Theme.f1Mono(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),

        // Horizontal Team Selector Cards
        SizedBox(
          height: 84,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: TeamsData.allTeams.length,
            itemBuilder: (context, index) {
              final team = TeamsData.allTeams[index];
              final isSelected = team.id == _selectedTeam.id;

              return InkWell(
                onTap: () => setState(() => _selectedTeam = team),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? F1Theme.cardHighlight : F1Theme.surfaceDark,
                    border: Border.all(
                      color: isSelected ? Color(team.primaryColorHex) : F1Theme.surfaceBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(team.primaryColorHex),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              team.shortName.toUpperCase(),
                              style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CAR ${team.car.overallRating}', style: F1Theme.f1Mono(fontSize: 10, color: Colors.amber)),
                          Text('\$${team.budgetMillions}M', style: F1Theme.f1Mono(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 16, color: F1Theme.surfaceBorder),

        // Inspector for the Selected Team (Scrollable)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildTeamInspectorContent(),
          ),
        ),

        // Sticky Bottom CTA Button
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: F1Theme.surfaceDark,
            border: Border(top: BorderSide(color: F1Theme.surfaceBorder)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: F1Theme.f1Red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => CareerDashboardScreen(team: _selectedTeam)),
                );
              },
              child: Text(
                'SIGN WITH ${_selectedTeam.shortName.toUpperCase()}',
                style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // DESKTOP LAYOUT (2 Columns)
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumeCareerBanner(),
          Text(
            'SELECT YOUR CONSTRUCTOR',
            style: F1Theme.f1Display(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            'Take command of an official Formula 1 team. Set the strategy, develop the car, and lead your drivers to glory.',
            style: F1Theme.f1Body(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: Grid of 10 official teams
                Expanded(
                  flex: 5,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: TeamsData.allTeams.length,
                    itemBuilder: (context, index) {
                      final team = TeamsData.allTeams[index];
                      final isSelected = team.id == _selectedTeam.id;

                      return InkWell(
                        onTap: () => setState(() => _selectedTeam = team),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? F1Theme.cardHighlight : F1Theme.surfaceDark,
                            border: Border.all(
                              color: isSelected ? Color(team.primaryColorHex) : F1Theme.surfaceBorder,
                              width: isSelected ? 2.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Color(team.primaryColorHex),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      team.shortName.toUpperCase(),
                                      style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      team.name,
                                      style: F1Theme.f1Body(fontSize: 10, color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Budget: \$${team.budgetMillions}M • Car: ${team.car.overallRating}',
                                      style: F1Theme.f1Mono(fontSize: 10, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // RIGHT: Selected Team Inspector
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: F1Theme.surfaceDark,
                      border: Border.all(color: F1Theme.surfaceBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTeamInspectorContent(),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: F1Theme.f1Red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => CareerDashboardScreen(team: _selectedTeam)),
                                );
                              },
                              child: Text(
                                'SIGN AS PRINCIPAL FOR ${_selectedTeam.shortName.toUpperCase()}',
                                style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Content inside Team Inspector
  Widget _buildTeamInspectorContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(_selectedTeam.primaryColorHex),
              radius: 18,
              child: Text(
                _selectedTeam.shortName.substring(0, 2).toUpperCase(),
                style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTeam.name.toUpperCase(),
                    style: F1Theme.f1Display(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Principal: ${_selectedTeam.principalName} • PU: ${_selectedTeam.engineManufacturer}',
                    style: F1Theme.f1Body(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 20, color: F1Theme.surfaceBorder),

        // Specs
        Text(
          'CAR PERFORMANCE (R&D BASELINE)',
          style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        _buildSpecBar('Top Speed', _selectedTeam.car.topSpeed),
        _buildSpecBar('Acceleration', _selectedTeam.car.acceleration),
        _buildSpecBar('Low-Speed Downforce', _selectedTeam.car.lowSpeedDownforce),
        _buildSpecBar('High-Speed Downforce', _selectedTeam.car.highSpeedDownforce),
        _buildSpecBar('DRS Efficiency', _selectedTeam.car.drsEfficiency),
        _buildSpecBar('Tyre Preservation', _selectedTeam.car.tyrePreservation),

        const Divider(height: 20, color: F1Theme.surfaceBorder),

        // Drivers
        Text(
          'OFFICIAL DRIVER LINEUP',
          style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ..._selectedTeam.driverIds.map((driverId) {
          final driver = DriversData.getDriverById(driverId);
          if (driver == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: F1Theme.carbonBlack,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: F1Theme.surfaceBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(3)),
                      child: Text('${driver.number}', style: F1Theme.f1Mono(fontSize: 10, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      driver.fullName,
                      style: F1Theme.f1Body(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
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
    );
  }

  Widget _buildSpecBar(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 125,
            child: Text(label, style: F1Theme.f1Body(fontSize: 11, color: Colors.white70)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value / 100.0,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  value >= 95 ? F1Theme.drsGreen : (value >= 90 ? Colors.amber : Colors.blueAccent),
                ),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text('$value', textAlign: TextAlign.end, style: F1Theme.f1Mono(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
