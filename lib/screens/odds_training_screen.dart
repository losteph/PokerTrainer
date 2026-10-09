import 'package:flutter/material.dart' hide Card;

import '../core/controllers/odds_controller.dart';
import '../core/models/card.dart';
import '../core/models/odds_training_scenario.dart';

class OddsTrainingScreen extends StatefulWidget {
  const OddsTrainingScreen({super.key});

  @override
  State<OddsTrainingScreen> createState() => _OddsTrainingScreenState();
}

class _OddsTrainingScreenState extends State<OddsTrainingScreen> {
  late final OddsController controller;

  @override
  void initState() {
    super.initState();
    controller = OddsController();
    controller.startNewScenario();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 3,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.88,
            child: Column(
              children: [
                const SizedBox(height: 12),
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
                const TabBar(
                  labelColor: Colors.indigo,
                  indicatorColor: Colors.indigo,
                  tabs: [
                    Tab(text: 'Regola 4 e 2 & Outs'),
                    Tab(text: 'Punti & Kicker'),
                    Tab(text: 'Stack & BB'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: FORMULE, OUTS PULITI VS SPORCHI, TABELLA
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text(
                            'Regola del 4 e del 2',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• Regola del 4 (Flop → 2 carte da vedere): Outs × 4 (-1% se Outs ≥ 8)\n'
                            '• Regola del 2 (Turn → 1 carta da vedere): Outs × 2 (+1% se Outs ≥ 8)',
                            style: TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 14),

                          // BOX DIDATTICO SUGLI OUTS (COSA SONO, COME CONTARLI E OUTS SPORCHI)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cosa sono gli Outs e come si contano?',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Un "Out" è qualsiasi carta rimasta nel mazzo che, se scende sul tavolo, trasforma la tua mano in un punto vincente.\n\n'
                                  'Esempi Classici:\n'
                                  '• Colore (Flush Draw): 4 carte dello stesso seme già viste → 13 totali - 4 = 9 Outs.\n'
                                  '• Scala Bilaterale (OESD): es. 8-9 su board 6-7-2 → servono quattro 5 e quattro 10 = 8 Outs.\n'
                                  '• Scala a Incastro (Gutshot): es. 8-9 su board J-Q-2 → serve solo il 10 = 4 Outs.\n\n'
                                  'Attenzione agli "Outs Sporchi" (Discounted Outs):\n'
                                  'Non tutti gli out sono uguali! Se stai cercando una scala con 8-9 su board 6♥ 7♥ 2♠, i 10 e i 5 ti danno scala. '
                                  'Ma il 10♥ e il 5♥ sono di cuori: se scendono, regalano il Colore a chiunque abbia due cuori in mano! '
                                  'In quei casi si "scontano" gli out togliendo quelli pericolosi (da 8 out teorici scendi a 6 out puliti).',
                                  style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'Tabella Puntata → Equity Richiesta',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• Pot / 10 → 9%\n'
                            '• Pot / 5  → 14%\n'
                            '• Pot / 4  → 17%\n'
                            '• Pot / 3  → 20%\n'
                            '• Pot / 2  → 25%\n'
                            '• 2/3 Pot  → 29%\n'
                            '• 3/4 Pot  → 30%\n'
                            '• 1x Pot   → 39%\n'
                            '• 2x Pot   → 40%\n'
                            '• 3x Pot   → 43%\n'
                            '• 4x Pot   → 45%\n'
                            '• 5x Pot   → 49%\n'
                            '• All-in   → 51%',
                            style: TextStyle(height: 1.35),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sconto Multiway:\n'
                            'In 6 giocatori: -1% | In 7: -2% | In 8: -3% | In 9: -4% | In 10: -5%',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 14),

                          // BOX SUI CASI WET/DRY
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mani Chiuse vs Progetti (Quando ignorare le Odds):',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '1. Made Hand Dominante (Board Asciutto):\n'
                                  'Con un Tris su board slegato non calcoli le pot odds di un Full: stai dominando (~85%+). Si punta e si chiama sempre.\n\n'
                                  '2. Tris su Board Pericoloso (Wet Board):\n'
                                  'Se a terra ci sono 3 carte a colore o collegate a scala, il tris insegue: calcoli i 7 outs (flop) per fare Full contro il punto superiore.',
                                  style: TextStyle(fontSize: 12, height: 1.35, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // TAB 2: GERARCHIA CARTE, VALORI SINGOLI, KICKER E SPLIT POT
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text(
                            'Gerarchia dei Punti (dal più alto al più basso)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Scala Reale (Royal Flush) - A K Q J T dello stesso seme\n'
                            '2. Scala Colore (Straight Flush) - 5 carte in scala dello stesso seme\n'
                            '3. Poker (Four of a Kind) - 4 carte dello stesso valore\n'
                            '4. Full (Full House) - Tris + Coppia\n'
                            '5. Colore (Flush) - 5 carte qualsiasi dello stesso seme\n'
                            '6. Scala (Straight) - 5 carte consecutive di semi diversi\n'
                            '7. Tris (Three of a Kind) - 3 carte dello stesso valore\n'
                            '8. Doppia Coppia (Two Pair)\n'
                            '9. Coppia (One Pair)\n'
                            '10. Carta Alta (High Card)',
                            style: TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Valore delle Singole Carte:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'A (Asso) > K (Re) > Q (Donna) > J (Fante) > T (10) > 9 > 8 > 7 > 6 > 5 > 4 > 3 > 2.\n'
                            '(L\'Asso vale come 1 solo nella scala minima A-2-3-4-5).',
                            style: TextStyle(height: 1.35, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cos\'è il Kicker e come funzionano gli Spareggi?',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Nel Texas Hold\'em la mano finale è sempre formata dalle migliori 5 carte assolute tra le tue 2 e le 5 del board.\n\n'
                                  '• Il Kicker:\n'
                                  'È la carta d\'appoggio più alta che completa la combinazione. '
                                  'A parità di punto (es. entrambi Coppia d\'Assi), vince chi possiede il kicker più alto (A-K batte A-Q).\n\n'
                                  '• Spareggio e Divisione del Piatto (Split Pot):\n'
                                  'Se tutte e 5 le migliori carte sono identiche, il piatto si divide equamente tra i giocatori rimasti.',
                                  style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // TAB 3: BB, STACK, STRATEGIA & PROFILI GIOCATORI
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text('Cosa sono i BB e come contarli?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text(
                            'BB sta per Big Blind (Grande Buio). Per calcolare quanti BB hai, dividi il tuo stack totale per il valore del grande buio del livello attuale.\n'
                            'Es: Stack 3.000 chip con bui 100/200 → 3.000 / 200 = 15 BB.',
                            style: TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          const Text('Definizione degli Stack & Open Raise Standard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text(
                            '• Short Stack (< 15 BB):\n'
                            '  Strategia: rilancio aggressivo a 3x o push diretto All-In.\n\n'
                            '• Medium Stack (15 - 30 BB):\n'
                            '  Strategia: rilancio standard a 2.5x.\n\n'
                            '• Big Stack (> 30 BB):\n'
                            '  Strategia: rilancio standard a 2.2x (consente un gioco postflop più manovrato).',
                            style: TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 18),

                          // SEZIONE: PROFILI DEI GIOCATORI AL TAVOLO
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'I 5 Tipi di Giocatori di Poker (Profili al Tavolo):',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '1. The Nit (La Roccia / Passivo Estremo):\n'
                                  '• Chi è: Gioca pochissime mani (solo top pair e assi). Se rilancia, ha sempre il punto massimo (monster hand).\n'
                                  '• Contromisura: Ruba sempre i suoi bui. Se punta pesante o rilancia, folda senza rimpianti.\n\n'
                                  '2. TAG (Tight-Aggressive - Lo Squalo):\n'
                                  '• Chi è: Lo stile ottimale moderno. Seleziona le mani con cura preflop (proprio come questo trainer), ma quando entra nel piatto gioca aggressivo (bet/raise).\n'
                                  '• Contromisura: Gioca contro di lui solo in posizione e con mani forti. Evita di bluffargli piatti grossi.\n\n'
                                  '3. LAG (Loose-Aggressive):\n'
                                  '• Chi è: Gioca molte mani e connette rilanci frequenti e bluff. Difficile da decifrare perché allarga molto i range.\n'
                                  '• Contromisura: Allarga il tuo range di call se hai punti medi (bluff-catch) e lascialo sfogare con rilanci di valore.\n\n'
                                  '4. Calling Station (Il Limper / Il Pesce):\n'
                                  '• Chi è: Giocatore passivo che chiama quasi ogni puntata per "vedere le carte", ma quasi mai rilancia. Odia foldare.\n'
                                  '• Contromisura: REGOLA AUREA: MAI BLUFFARE una calling station! Punta per valore ("value bet") grosso con punti forti, perché pagherà sempre.\n\n'
                                  '5. Maniac (L\'Iper-Aggressivo):\n'
                                  '• Chi è: Rilancia costantemente, spinge all-in improvvisi e cerca di rubare ogni piatto con puntate sconsiderate.\n'
                                  '• Contromisura: Intrappolalo giocando passivo con mani ottime (slowplay) e inducilo a puntare tutte le sue fiches nei tuoi punti chiusi.',
                                  style: TextStyle(fontSize: 12.5, height: 1.45, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final scenario = controller.currentScenario;
        final feedback = controller.feedback;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Odds & Equity Trainer'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Guida & Regole',
                onPressed: _showInfoSheet,
              ),
            ],
          ),
          body: scenario == null
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        SegmentedButton<OddsRuleMode>(
                          segments: const [
                            ButtonSegment(value: OddsRuleMode.ruleOf4, label: Text('Regola 4 (Flop)')),
                            ButtonSegment(value: OddsRuleMode.ruleOf2, label: Text('Regola 2 (Turn)')),
                          ],
                          selected: {controller.mode},
                          onSelectionChanged: (selected) {
                            controller.setMode(selected.first);
                          },
                        ),
                        const SizedBox(height: 8),

                        // BANNER TAVOLO: Mostra Stack, Piatto e Bet reale (con trigger All-in)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Stack: \$${scenario.userStack.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Tavolo: ${scenario.playerCount}p', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const Divider(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Piatto: \$${scenario.pot.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(
                                    scenario.isAllIn
                                        ? 'Bet: All-in (\$${scenario.callAmount.toInt()})'
                                        : 'Bet: \$${scenario.callAmount.toInt()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: scenario.isAllIn ? Colors.red.shade700 : Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text('Board a Terra:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: scenario.boardCards.map((c) => _MiniCardWidget(card: c)).toList(),
                        ),
                        const SizedBox(height: 8),

                        const Text('Le tue Carte:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: scenario.holeCards.map((c) => _MiniCardWidget(card: c)).toList(),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: feedback != null
                              ? SingleChildScrollView(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: feedback.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: feedback.isCorrect ? Colors.green : Colors.red),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          feedback.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: feedback.isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          feedback.explanation,
                                          style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                                  onPressed: feedback == null ? () => controller.chooseAction(called: false) : null,
                                  child: const Text('FOLD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                                  onPressed: feedback == null ? () => controller.chooseAction(called: true) : null,
                                  child: const Text('CALL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: controller.startNewScenario,
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

class _MiniCardWidget extends StatelessWidget {
  final Card card;

  const _MiniCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final isRed = card.suit == CardSuit.hearts || card.suit == CardSuit.diamonds;
    final color = isRed ? Colors.red.shade700 : Colors.black87;

    return Container(
      width: 55,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2)),
        ],
      ),
      child: Center(
        child: Text(
          card.symbol,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}