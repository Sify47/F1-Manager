import 'package:flutter/material.dart';
import '../../data/teams_data.dart';
import '../../data/circuits_data.dart';
import '../../models/team.dart';
import '../../models/circuit.dart';
import '../../services/save_game_service.dart';
import '../../services/audio_service.dart';
import '../theme/f1_theme.dart';
import 'team_selection_screen.dart';
import 'career_dashboard.dart';
import 'weekend_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CareerSaveData? _savedCareer;
  bool _isMuted = AudioService.instance.isMuted;

  @override
  void initState() {
    super.initState();
    _loadSaveData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSaveData() async {
    final save = await SaveGameService.loadSavedCareer();
    if (mounted) {
      setState(() {
        _savedCareer = save;
      });
    }
  }

  void _toggleAudio() {
    setState(() {
      AudioService.instance.toggleMute();
      _isMuted = AudioService.instance.isMuted;
    });
    if (!_isMuted) {
      AudioService.instance.playRadioBeep();
    }
  }

  void _resumeCareer() async {
    if (_savedCareer == null) return;
    final team = TeamsData.getTeamById(_savedCareer!.teamId);
    if (team == null) return;

    AudioService.instance.playRadioBeep();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareerDashboardScreen(
          team: team,
          savedData: _savedCareer,
        ),
      ),
    );
    // Refresh save state when coming back to home
    _loadSaveData();
  }

  void _startNewCareer() {
    AudioService.instance.playRadioBeep();
    if (_savedCareer != null) {
      final team = TeamsData.getTeamById(_savedCareer!.teamId);
      final teamName = team?.name ?? 'Your current team';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: F1Theme.surfaceDark,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'EXISTING CAREER FOUND',
                style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'You currently have a saved career with $teamName (Round ${_savedCareer!.currentRaceIndex + 1}).\n\nStarting a new career will allow you to select a new team and start a fresh season. Continue to Team Selection?',
            style: F1Theme.f1Body(fontSize: 12, color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'CANCEL',
                style: F1Theme.f1Display(fontSize: 12, color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: F1Theme.f1Red),
              onPressed: () {
                Navigator.pop(ctx);
                _navigateToTeamSelection();
              },
              child: Text(
                'START NEW CAREER',
                style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      _navigateToTeamSelection();
    }
  }

  void _navigateToTeamSelection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeamSelectionScreen()),
    );
    _loadSaveData();
  }

  void _confirmDeleteSave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: F1Theme.surfaceDark,
        title: Text(
          'DELETE CAREER SAVE?',
          style: F1Theme.f1Display(fontSize: 14, color: F1Theme.f1Red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete your saved career? All championship standings, car upgrades, and season progress will be wiped.',
          style: F1Theme.f1Body(fontSize: 12, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: F1Theme.f1Display(fontSize: 12, color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: F1Theme.f1Red),
            onPressed: () async {
              Navigator.pop(ctx);
              await SaveGameService.clearSave();
              AudioService.instance.playRadioBeep();
              _loadSaveData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: F1Theme.surfaceDark,
                    content: Text(
                      'Career save deleted successfully.',
                      style: F1Theme.f1Body(fontSize: 12, color: Colors.white),
                    ),
                  ),
                );
              }
            },
            child: Text('DELETE', style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRegulationsGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: F1Theme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: F1Theme.f1Red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'FIA',
                          style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'F1 REGULATIONS & PIT WALL GUIDE',
                        style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: F1Theme.surfaceBorder),
              Expanded(
                child: ListView(
                  children: [
                    _buildGuideItem(
                      icon: Icons.tune,
                      title: 'Free Practice 1, 2, 3 & Dual Car Setups',
                      body:
                          'Tune both drivers independently across FP1, FP2, and FP3. As track evolution rubbers in the circuit, refine wings, suspension, and gear ratios to maximize driver satisfaction and claim a pace bonus for Qualifying.',
                    ),
                    _buildGuideItem(
                      icon: Icons.timer,
                      title: 'Knockout Qualifying Shootout (Q1, Q2, Q3)',
                      body:
                          'All 20 cars battle in Q1 (bottom 5 eliminated to P16-P20). Q2 eliminates 5 more (P11-P15). The Top 10 shootout in Q3 decides Pole Position.',
                    ),
                    _buildGuideItem(
                      icon: Icons.alt_route,
                      title: 'Pit Stop Time Loss & Standings Drop',
                      body:
                          'Pit lane traversal costs ~20-25 seconds at pit-lane speed limits. Cars on track driving at 220+ km/h will overtake you while pitting, causing realistic position drops based on live track gaps.',
                    ),
                    _buildGuideItem(
                      icon: Icons.offline_bolt,
                      title: 'Tactical Undercut & Dirty Air',
                      body:
                          'Stuck behind a rival within 1.8 seconds? Box 2 laps early for fresh tyres to unleash superior pace and jump ahead when they pit.',
                    ),
                    _buildGuideItem(
                      icon: Icons.warning_rounded,
                      title: 'Safety Car & VSC "Cheap Stops"',
                      body:
                          'When a Safety Car or VSC is deployed, cars on track circulate at reduced delta speed. Pitting under SC cuts your effective pit loss by half!',
                    ),
                    _buildGuideItem(
                      icon: Icons.cloud,
                      title: 'Weather Crossover & Dynamic Rain',
                      body:
                          'Track wetness > 25% requires Intermediate tyres; > 65% triggers Full Wet. When rain stops, wait for the drying line before boxing for slicks.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideItem({required IconData icon, required String title, required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: F1Theme.carbonBlack,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: F1Theme.f1Red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: F1Theme.f1Red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: F1Theme.f1Body(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickExhibitionModal() {
    Team selectedExTeam = TeamsData.allTeams.first;
    Circuit selectedExCircuit = CircuitsData.allCircuits.first;

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
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flash_on, color: Colors.amber, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'QUICK GRAND PRIX WEEKEND',
                            style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Race any Grand Prix without altering your career save file.',
                    style: F1Theme.f1Body(fontSize: 11, color: Colors.grey),
                  ),
                  const Divider(color: F1Theme.surfaceBorder, height: 20),

                  // Circuit Selection
                  Text('1. SELECT CIRCUIT', style: F1Theme.f1Display(fontSize: 11, color: F1Theme.f1Red)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: F1Theme.carbonBlack,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: F1Theme.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Circuit>(
                        value: selectedExCircuit,
                        dropdownColor: F1Theme.surfaceDark,
                        isExpanded: true,
                        items: CircuitsData.allCircuits.map((c) {
                          return DropdownMenuItem<Circuit>(
                            value: c,
                            child: Row(
                              children: [
                                Text(c.flagEmoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${c.grandPrixName} (${c.totalLaps} Laps)',
                                    style: F1Theme.f1Body(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedExCircuit = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Team Selection
                  Text('2. SELECT CONSTRUCTOR', style: F1Theme.f1Display(fontSize: 11, color: F1Theme.f1Red)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: F1Theme.carbonBlack,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: F1Theme.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Team>(
                        value: selectedExTeam,
                        dropdownColor: F1Theme.surfaceDark,
                        isExpanded: true,
                        items: TeamsData.allTeams.map((t) {
                          return DropdownMenuItem<Team>(
                            value: t,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(t.primaryColorHex),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.name,
                                    style: F1Theme.f1Body(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedExTeam = val);
                        },
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Launch Exhibition Button
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
                        Navigator.pop(ctx);
                        AudioService.instance.playRadioBeep();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WeekendHubScreen(
                              circuit: selectedExCircuit,
                              playerTeam: selectedExTeam,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(
                        'START EXHIBITION WEEKEND →',
                        style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform(
                  transform: Matrix4.skewX(-0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: F1Theme.f1Red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'F1',
                      style: F1Theme.f1Display(fontSize: 15, fontWeight: FontWeight.w900, italic: true),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'MANAGER 2026',
                    style: F1Theme.f1Display(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: _isMuted ? 'Unmute Audio' : 'Mute Audio',
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: _isMuted ? Colors.grey : Colors.greenAccent,
                  size: 22,
                ),
                onPressed: _toggleAudio,
              ),
              IconButton(
                tooltip: 'F1 Regulations & Guide',
                icon: const Icon(Icons.help_outline, color: Colors.white70, size: 22),
                onPressed: _showRegulationsGuide,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HERO HEADER
                      _buildHeroHeader(isMobile),
                      const SizedBox(height: 24),

                      // RESUME CAREER CARD (Save Game)
                      _buildResumeCareerCard(isMobile),
                      const SizedBox(height: 16),

                      // NEW CAREER & QUICK EXHIBITION BUTTONS
                      _buildActionButtons(isMobile),
                      const SizedBox(height: 28),

                      // SEASON 2026 GRID SUMMARY
                      _buildGridSummary(isMobile),
                      const SizedBox(height: 20),

                      // FOOTER DISCLAIMER
                      Center(
                        child: Text(
                          'FIA Formula 1 World Championship™ Simulation • Season 2026',
                          style: F1Theme.f1Mono(fontSize: 10, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F1Theme.surfaceBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            F1Theme.surfaceDark,
            F1Theme.f1Red.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: F1Theme.f1Red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '2026 FIA FORMULA ONE WORLD CHAMPIONSHIP™',
                  style: F1Theme.f1Display(fontSize: isMobile ? 10 : 12, color: F1Theme.f1Red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PIT WALL STRATEGY & TEAM PRINCIPAL',
            style: F1Theme.f1Display(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Master race setups in FP1-FP3, orchestrate precision undercut pit stops, manage tire cliffs, and lead your constructor to the World Championship title.',
            style: F1Theme.f1Body(fontSize: isMobile ? 11 : 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeCareerCard(bool isMobile) {
    if (_savedCareer == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: F1Theme.surfaceDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: F1Theme.surfaceBorder, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_score, color: Colors.grey, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NO SAVED CAREER FOUND',
                    style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start a new career below to choose your constructor and launch your 2026 campaign.',
                    style: F1Theme.f1Body(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final team = TeamsData.getTeamById(_savedCareer!.teamId);
    if (team == null) return const SizedBox.shrink();

    final teamColor = Color(team.primaryColorHex);
    final circuitIndex = _savedCareer!.currentRaceIndex;
    final currentCircuit = circuitIndex < CircuitsData.allCircuits.length
        ? CircuitsData.allCircuits[circuitIndex]
        : CircuitsData.allCircuits.last;

    final constructorPts = _savedCareer!.constructorPoints[team.id] ?? 0;
    final savedDate = _formatSavedDate(_savedCareer!.savedAt);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: F1Theme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: teamColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: teamColor.withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge & Delete Save
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'SAVED CAREER',
                        style: F1Theme.f1Display(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Saved $savedDate',
                      style: F1Theme.f1Mono(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Delete Save',
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  onPressed: _confirmDeleteSave,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Team Header
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: teamColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    team.name.toUpperCase(),
                    style: F1Theme.f1Display(
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: teamColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: teamColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    team.shortName.toUpperCase(),
                    style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold, color: teamColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: F1Theme.surfaceBorder),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildSaveStatItem(
                    label: 'NEXT RACE',
                    value: '${currentCircuit.flagEmoji} Rd ${circuitIndex + 1}/${CircuitsData.allCircuits.length}',
                    subtext: currentCircuit.country.toUpperCase(),
                  ),
                ),
                Expanded(
                  child: _buildSaveStatItem(
                    label: 'POINTS',
                    value: '$constructorPts PTS',
                    subtext: 'Constructor Standing',
                  ),
                ),
                Expanded(
                  child: _buildSaveStatItem(
                    label: 'BUDGET',
                    value: '\$${_savedCareer!.budgetMillions}M',
                    subtext: 'R&D Available',
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Big Action Button: RESUME CAREER
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: teamColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 6,
                ),
                onPressed: _resumeCareer,
                icon: const Icon(Icons.sports_score, size: 22),
                label: Text(
                  'RESUME CAREER 🏁',
                  style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildSaveStatItem({
    required String label,
    required String value,
    required String subtext,
    Color color = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: F1Theme.f1Display(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: F1Theme.f1Mono(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtext,
          style: F1Theme.f1Body(fontSize: 9, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Column(
      children: [
        // START NEW CAREER BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _savedCareer == null ? F1Theme.f1Red : F1Theme.surfaceDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: _savedCareer != null ? const BorderSide(color: F1Theme.f1Red, width: 1.5) : BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _startNewCareer,
            icon: const Icon(Icons.sports_motorsports, size: 22),
            label: Text(
              _savedCareer == null ? 'START NEW CAREER 🏎️' : 'START NEW CAREER',
              style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // QUICK GRAND PRIX / EXHIBITION
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: F1Theme.surfaceBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _showQuickExhibitionModal,
            icon: const Icon(Icons.flash_on, size: 18, color: Colors.amber),
            label: Text(
              'QUICK GRAND PRIX (STANDALONE WEEKEND)',
              style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridSummary(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryPill('24', 'GRAND PRIX'),
          Container(width: 1, height: 24, color: F1Theme.surfaceBorder),
          _buildSummaryPill('10', 'CONSTRUCTORS'),
          Container(width: 1, height: 24, color: F1Theme.surfaceBorder),
          _buildSummaryPill('20', 'DRIVERS'),
          Container(width: 1, height: 24, color: F1Theme.surfaceBorder),
          _buildSummaryPill('FP1-3', 'PRACTICE'),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(String number, String label) {
    return Column(
      children: [
        Text(number, style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.w900, color: F1Theme.f1Red)),
        const SizedBox(height: 2),
        Text(label, style: F1Theme.f1Display(fontSize: 8, color: Colors.grey)),
      ],
    );
  }

  String _formatSavedDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
