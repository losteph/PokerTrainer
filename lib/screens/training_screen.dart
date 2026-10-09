import 'dart:math';
import 'package:flutter/material.dart' hide Card;

import '../core/controllers/game_controller.dart';
import '../core/models/card.dart';
import '../core/models/player_position.dart';
import '../core/models/player_position_scheme.dart';
import '../core/rules/strategic_ranges.dart';
import '../widgets/training_action_bar.dart';

enum RangeCategory {
  early('Early (UTG)'),
  middle('Middle (MP/LJ/HJ)'),
  late('Late (CO/BTN)'),
  blinds('Blinds (SB/BB)');

  final String label;
  const RangeCategory(this.label);
}

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late final GameController controller;
  final Random _random = Random();

  int? _selectedPlayerCount; // null = Casuale (2-10)
  RangeCategory? _selectedRange; // null = Casuale

  @override
  void initState() {
    super.initState();
    controller = GameController();
    _dealNextHand();
  }

  // Restituisce le posizioni valide a tavolo per un dato player count
  List<PlayerPosition> _getTablePositions(int playerCount) {
    if (playerCount == 2) return const [PlayerPosition.sb, PlayerPosition.bb];
    if (playerCount == 3) return const [PlayerPosition.btn, PlayerPosition.sb, PlayerPosition.bb];
    return PlayerPositionScheme.getForPlayerCount(playerCount);
  }

  // Mappa quali posizioni appartengono a quale categoria
  List<PlayerPosition> _positionsForCategory(RangeCategory cat) {
    return switch (cat) {
      RangeCategory.early => const [PlayerPosition.utg, PlayerPosition.utg1, PlayerPosition.utg2],
      RangeCategory.middle => const [PlayerPosition.mp, PlayerPosition.lj, PlayerPosition.hj],
      RangeCategory.late => const [PlayerPosition.co, PlayerPosition.btn],
      RangeCategory.blinds => const [PlayerPosition.sb, PlayerPosition.bb],
    };
  }

  // Range disponibili dato un numero di giocatori specifico
  Set<RangeCategory> _getAvailableRanges(int? playerCount) {
    if (playerCount == null) {
      return RangeCategory.values.toSet();
    }
    final tablePositions = _getTablePositions(playerCount).toSet();
    final available = <RangeCategory>{};

    for (final cat in RangeCategory.values) {
      final catPositions = _positionsForCategory(cat);
      if (catPositions.any((pos) => tablePositions.contains(pos))) {
        available.add(cat);
      }
    }
    return available;
  }

  void _dealNextHand() {
    int playerCount;
    RangeCategory category;

    // 1. Risolvi il numero di giocatori
    if (_selectedPlayerCount != null) {
      playerCount = _selectedPlayerCount!;
    } else if (_selectedRange != null) {
      // Se abbiamo un range scelto ma player count casuale, scegliamo un tavolo compatibile
      final compatibleCounts = <int>[];
      for (int count = 2; count <= 10; count++) {
        if (_getAvailableRanges(count).contains(_selectedRange)) {
          compatibleCounts.add(count);
        }
      }
      playerCount = compatibleCounts[_random.nextInt(compatibleCounts.length)];
    } else {
      playerCount = 2 + _random.nextInt(9);
    }

    // 2. Risolvi la categoria del range
    final availableRangesAtTable = _getAvailableRanges(playerCount).toList();
    if (_selectedRange != null && availableRangesAtTable.contains(_selectedRange)) {
      category = _selectedRange!;
    } else {
      category = availableRangesAtTable[_random.nextInt(availableRangesAtTable.length)];
    }

    // 3. Estrai una posizione casuale valida per quella categoria a quel tavolo
    final tablePositions = _getTablePositions(playerCount);
    final validPositions = _positionsForCategory(category)
        .where((pos) => tablePositions.contains(pos))
        .toList();

    final position = validPositions[_random.nextInt(validPositions.length)];

    controller.configureTable(
      playerCount: playerCount,
      playerPosition: position,
    );
    controller.startNewHand();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Color _getFeedbackColor(TrainingFeedbackType type) {
    return switch (type) {
      TrainingFeedbackType.correct => Colors.green.shade700,
      TrainingFeedbackType.mistake => Colors.red.shade700,
    };
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Guida Completa ai Range di Apertura',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // SPIEGAZIONE RANGE DINAMICI
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Text(
                      'I Range Dinamici:\n'
                      'Al ridursi dei giocatori al tavolo le posizioni scalano: da 10 a 7 giocatori esistono le Early Position (UTG). '
                      'Da 6 giocatori in giù i primi a parlare assumono direttamente i range di Middle Position (MP/LJ/HJ), eliminando '
                      'la necessità di memorizzare tabelle ridondanti.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FASCIA 1: TAVOLI 10-4 GIOCATORI
                  const Text(
                    '1. Tavoli da 10 a 4 Giocatori',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  _buildRangeSection('Early Position (UTG, UTG+1, UTG+2)', StrategicRanges.early),
                  _buildRangeSection(
                    'Middle Position (MP, LJ, HJ)',
                    StrategicRanges.middle,
                    extraNote: 'Stack Effettivo (> 15 BB): Lo stack effettivo è lo stack più basso tra il tuo e quello dell\'avversario con cui sei in contesa. '
                        'Se entrambi avete più di 15 Grandi Bui, puoi chiamare anche con 22-44 cercando il tris (set mining). Sotto i 15 BB si foldano.',
                  ),
                  _buildRangeSection('Late Position (CO, BTN)', StrategicRanges.late),
                  _buildRangeSection('Small Blind (SB)', StrategicRanges.smallBlind),
                  _buildRangeSection(
                    'Big Blind (BB)',
                    const ['Tutte le coppie (22+)', 'Tutti gli Assi (Ax)', 'Tutte le suited (qualsiasi carta con lo stesso seme, es. 32s, T4s...)'],
                  ),

                  const SizedBox(height: 20),

                  // FASCIA 2: 3 GIOCATORI
                  const Text(
                    '2. Tavolo a 3 Giocatori',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  _buildRangeSection('Button (BTN)', StrategicRanges.threePlayerButton),
                  _buildRangeSection('Small Blind (SB)', StrategicRanges.threePlayerSmallBlind),
                  _buildRangeSection('Big Blind (BB) - Call', StrategicRanges.threePlayerBigBlindCall),
                  _buildRangeSection('Big Blind (BB) - Raise', StrategicRanges.threePlayerBigBlindRaise),

                  const SizedBox(height: 20),

                  // FASCIA 3: 2 GIOCATORI (HEADS-UP)
                  const Text(
                    '3. Heads-Up (2 Giocatori)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  _buildRangeSection(
                    'Small Blind / Button (SB)',
                    StrategicRanges.headsUpSmallBlind,
                    extraNote: 'In Heads-Up il giocatore sullo Small Blind ha anche il Bottone e parla per primo preflop.',
                  ),
                  _buildRangeSection('Big Blind (BB)', StrategicRanges.headsUpBigBlind),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRangeSection(String title, List<String> hands, {String? extraNote}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            hands.join(', '),
            style: TextStyle(color: Colors.grey.shade800, fontSize: 12, height: 1.3),
          ),
          if (extraNote != null) ...[
            const SizedBox(height: 6),
            Text(
              extraNote,
              style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontStyle: FontStyle.italic, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableRanges = _getAvailableRanges(_selectedPlayerCount);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final feedback = controller.feedback;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Opening Range Trainer'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Vedi Tabelle',
                onPressed: _showInfoSheet,
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // SELETTORE 1: GIOCATORI AL TAVOLO
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _selectedPlayerCount,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Tavolo',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Casuale')),
                            for (int count = 10; count >= 2; count--)
                              DropdownMenuItem(value: count, child: Text('$count Giocatori')),
                          ],
                          onChanged: (count) {
                            setState(() {
                              _selectedPlayerCount = count;
                              // Se il range precedentemente scelto non esiste con questi giocatori, resettalo
                              if (_selectedRange != null && !_getAvailableRanges(count).contains(_selectedRange)) {
                                _selectedRange = null;
                              }
                            });
                            _dealNextHand();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // SELETTORE 2: RANGE (Abilitato/disabilitato dinamicamente)
                      Expanded(
                        child: DropdownButtonFormField<RangeCategory?>(
                          initialValue: _selectedRange,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Range',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Casuale')),
                            ...RangeCategory.values.map(
                              (cat) {
                                final isAvailable = availableRanges.contains(cat);
                                return DropdownMenuItem(
                                  value: isAvailable ? cat : null,
                                  enabled: isAvailable,
                                  child: Text(
                                    cat.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isAvailable ? null : Colors.grey.shade400,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          onChanged: (cat) {
                            setState(() {
                              _selectedRange = cat;
                            });
                            _dealNextHand();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info Tavolo Attuale
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tavolo: ${controller.playerCount ?? '-'} Giocatori', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Ruolo: ${controller.playerPosition?.label ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Carte coperte/servite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: controller.holeCards.map((card) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _PlayingCardWidget(card: card),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Feedback
                  if (feedback != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _getFeedbackColor(feedback.type).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getFeedbackColor(feedback.type)),
                      ),
                      child: Text(
                        feedback.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _getFeedbackColor(feedback.type),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 40),

                  const Spacer(),

                  // Pulsanti FOLD / CALL
                  TrainingActionBar(
                    onAction: (action) {
                      if (controller.feedback == null) {
                        controller.chooseAction(action);
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Tasto Prossima Mano
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _dealNextHand,
                      child: const Text('PROSSIMA MANO'),
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
}

class _PlayingCardWidget extends StatelessWidget {
  final Card card;

  const _PlayingCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final isRed = card.suit == CardSuit.hearts || card.suit == CardSuit.diamonds;
    final color = isRed ? Colors.red.shade700 : Colors.black87;

    return Container(
      width: 85,
      height: 125,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.symbol,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}