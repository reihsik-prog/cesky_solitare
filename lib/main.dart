import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app_providers.dart';
import 'src/vykreslovani.dart';
import 'src/hra.dart';
import 'src/pomocne_widgety.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // `nactiNastaveni()` je nyní nahrazeno Riverpod providery.
  // runApp je obalen v ProviderScope, aby byly providery dostupné v celé aplikaci.
  runApp(const ProviderScope(
    child: MaterialApp(
      title: 'Slovní Solitér',
      debugShowCheckedModeBanner: false,
      home: HlavniMenu(),
    ),
  ));
}

// ============================================================================
// --- HLAVNÍ MENU ---
// ============================================================================

// Převedeno na ConsumerWidget pro integraci s Riverpodem.
class HlavniMenu extends ConsumerWidget {
  const HlavniMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sledujeme stav provideru, který nám říká, zda existuje uložená hra.
    final existujeUlozeniAsync = ref.watch(existujeUlozeniProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Pozadí
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.6,
                colors: [
                  Color(0xFF43A047),
                  Color(0xFF1B5E20),
                  Color(0xFF072008)
                ],
                stops: [0.05, 0.6, 1.0],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: PozadiTexturePainter())),

          // Obsah menu
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Nadpis
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(77),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.amber.withAlpha(128), width: 2),
                  ),
                  child: const Column(children: [
                    Icon(Icons.style, size: 60, color: Colors.amber),
                    SizedBox(height: 10),
                    Text(
                      "SLOVNÍ\nSOLITÉR",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                        letterSpacing: 2.0,
                        height: 0.9,
                        shadows: [
                          Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                              offset: Offset(2, 2))
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 40),

                const SizedBox(height: 30),

                // Tlačítka
                // Pomocí .when處理ujeme všechny stavy FutureProvideru
                existujeUlozeniAsync.when(
                  // Data úspěšně načtena
                  data: (existujeUlozeni) {
                    if (existujeUlozeni) {
                      return MenuTlacitko(
                        text: "POKRAČOVAT",
                        ikona: Icons.fast_forward,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SlovniSolitare(nacistUlozenou: true),
                            ),
                            // Po návratu z hry znovu zkontrolujeme stav
                          ).then((_) => ref.invalidate(existujeUlozeniProvider));
                        },
                      );
                    }
                    // Pokud neexistuje uložení, vrátíme prázdný widget
                    return const SizedBox.shrink();
                  },
                  // Během načítání zobrazíme prázdný widget, aby se layout nerozpadl
                  loading: () => const SizedBox(height: 70), // Výška odpovídá tlačítku
                  // V případě chyby nezobrazíme nic
                  error: (err, stack) => const SizedBox.shrink(),
                ),
                if (existujeUlozeniAsync.valueOrNull == true)
                  const SizedBox(height: 20),

                MenuTlacitko(
                  text: "NOVÁ HRA",
                  ikona: Icons.play_arrow_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SlovniSolitare(nacistUlozenou: false),
                      ),
                       // Po návratu z hry znovu zkontrolujeme stav
                    ).then((_) => ref.invalidate(existujeUlozeniProvider));
                  },
                ),
                const SizedBox(height: 20),
                MenuTlacitko(
                  text: "PRAVIDLA",
                  ikona: Icons.help_outline,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFFFFF8E1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        title: const Text("Jak hrát?",
                            style: TextStyle(
                                color: Color(0xFF3E2723),
                                fontWeight: FontWeight.bold)),
                        content: const SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("1. CÍL HRY",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  "Setřiď karty do 4 horních přihrádek podle kategorií.\n"),
                              Text("2. PRAVIDLA",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  "• Do prázdné horní přihrádky patří jen HLAVNÍ KARTA."),
                              Text("• Na ni skládej karty stejné kategorie."),
                              Text(
                                  "• Ve spodních sloupcích skládej karty na sebe, pokud mají stejnou kategorii."),
                              Text(
                                  "• Do prázdného sloupce můžeš dát cokoliv."),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("ROZUMÍM",
                                style: TextStyle(
                                    color: Color(0xFF3E2723),
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text("Verze 2.1 - Tvary",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 10)))
        ],
      ),
    );
  }
}
