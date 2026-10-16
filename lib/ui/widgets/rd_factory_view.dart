import 'package:flutter/material.dart';
import '../../models/car_part_rd.dart';
import '../../state/career_controller.dart';
import '../theme/f1_theme.dart';

class RdFactoryView extends StatefulWidget {
  final CareerController career;

  const RdFactoryView({super.key, required this.career});

  @override
  State<RdFactoryView> createState() => _RdFactoryViewState();
}

class _RdFactoryViewState extends State<RdFactoryView> {
  CarPartType _selectedPart = CarPartType.frontWing;

  @override
  Widget build(BuildContext context) {
    final team = widget.career.playerTeam;
    final car = team.car;
    final activeProjects = widget.career.activeProjects;

    return Container(
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Factory Title & ATR Restrictions
          Row(
            children: [
              const Icon(Icons.precision_manufacturing, color: F1Theme.f1Red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'R&D ENGINEERING OPERATIONS',
                      style: F1Theme.f1Display(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Factory Upgrades, Aero ATR Testing & Performance Trade-offs',
                      style: F1Theme.f1Body(fontSize: 10, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              // ATR Testing Hours Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: F1Theme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.air, size: 12, color: Colors.lightBlueAccent),
                    const SizedBox(width: 4),
                    Text(
                      'WT: ${widget.career.windTunnelHours}h | CFD: ${widget.career.cfdPoints}p',
                      style: F1Theme.f1Mono(fontSize: 10, color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Car Overall Performance Matrix
          _buildPerformanceGauges(car),
          const SizedBox(height: 14),

          // Active Factory Projects Queue
          if (activeProjects.isNotEmpty) ...[
            Text('ACTIVE FACTORY PRODUCTION QUEUE',
                style: F1Theme.f1Display(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...activeProjects.map((p) => _buildActiveProjectCard(p)),
            const SizedBox(height: 12),
          ],

          // Part Selection Tabs
          Text('SELECT CAR ASSEMBLY TO UPGRADE',
              style: F1Theme.f1Display(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CarPartType.values.map((part) {
                final isSel = _selectedPart == part;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPart = part),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? F1Theme.f1Red.withValues(alpha: 0.25) : F1Theme.carbonBlack,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSel ? F1Theme.f1Red : F1Theme.surfaceBorder,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        part.displayName,
                        style: F1Theme.f1Display(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Available Specifications with Trade-offs
          ...CarPartRdCatalog.getSpecsForPart(_selectedPart).map((spec) {
            return _buildSpecCard(spec, _selectedPart);
          }),

          // Engineering Feed Bulletin
          if (widget.career.engineeringFeed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('FACTORY BULLETIN LOG', style: F1Theme.f1Display(fontSize: 9, color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: F1Theme.carbonBlack,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: F1Theme.surfaceBorder),
              ),
              child: Text(
                widget.career.engineeringFeed.first,
                style: F1Theme.f1Body(fontSize: 10, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceGauges(dynamic car) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: F1Theme.carbonBlack,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CAR SPECIFICATION INDEX', style: F1Theme.f1Display(fontSize: 9, color: Colors.grey)),
              Text('OVR RATING: ${car.overallRating}',
                  style: F1Theme.f1Mono(fontSize: 11, color: F1Theme.drsGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMiniStat('TOP SPEED', car.topSpeed, Colors.redAccent)),
              const SizedBox(width: 6),
              Expanded(child: _buildMiniStat('ACCELERATION', car.acceleration, Colors.amberAccent)),
              const SizedBox(width: 6),
              Expanded(child: _buildMiniStat('HIGH DOWNFORCE', car.highSpeedDownforce, Colors.lightBlueAccent)),
              const SizedBox(width: 6),
              Expanded(child: _buildMiniStat('TYRE CARE', car.tyrePreservation, Colors.greenAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: F1Theme.f1Display(fontSize: 7, color: Colors.white60)),
            Text('$value', style: F1Theme.f1Mono(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (value / 100.0).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveProjectCard(RdProject project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: F1Theme.carbonBlack,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.build_circle, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(project.specPhilosophy.name,
                        style: F1Theme.f1Display(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (project.isRushDevelopment) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(2)),
                        child: Text('RUSH',
                            style: F1Theme.f1Display(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Manufacturing: Ready in ${project.racesRemaining} ${project.racesRemaining == 1 ? "Grand Prix" : "Grands Prix"}',
                  style: F1Theme.f1Body(fontSize: 9, color: Colors.amberAccent),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(RdSpecPhilosophy spec, CarPartType partType) {
    final team = widget.career.playerTeam;
    final canAfford = team.budgetMillions >= spec.baseCostMillions;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
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
              Expanded(
                child: Text(
                  spec.name,
                  style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: canAfford ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: canAfford ? Colors.greenAccent : Colors.redAccent),
                ),
                child: Text(
                  '\$${spec.baseCostMillions}M • ${spec.baseRacesToDeliver} GP',
                  style: F1Theme.f1Mono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: canAfford ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(spec.description, style: F1Theme.f1Body(fontSize: 10, color: Colors.white60)),
          const SizedBox(height: 8),

          // Pros (Stat Gains)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle, color: Colors.greenAccent, size: 10),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    spec.prosText,
                    style: F1Theme.f1Body(fontSize: 9, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Cons (Trade-Offs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove_circle, color: Colors.redAccent, size: 10),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    spec.consText,
                    style: F1Theme.f1Body(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Action Buttons: Standard vs Rush
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: canAfford ? () => _commissionUpgrade(partType, spec, isRush: true) : null,
                child: Text('RUSH ORDER (-1 GP / +40% \$)', style: F1Theme.f1Display(fontSize: 8)),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? F1Theme.f1Red : Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: canAfford ? () => _commissionUpgrade(partType, spec, isRush: false) : null,
                child: Text('COMMISSION PART', style: F1Theme.f1Display(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _commissionUpgrade(CarPartType partType, RdSpecPhilosophy spec, {required bool isRush}) {
    bool ok = widget.career.commissionRdProject(
      partType: partType,
      spec: spec,
      isRush: isRush,
    );

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: F1Theme.surfaceDark,
          content: Text(
            '${spec.name} sent to factory floor! ⚙️',
            style: F1Theme.f1Display(fontSize: 11, color: Colors.greenAccent),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: F1Theme.surfaceDark,
          content: Text(
            'Insufficient funds or factory capacity! ❌',
            style: F1Theme.f1Display(fontSize: 11, color: Colors.redAccent),
          ),
        ),
      );
    }
  }
}

