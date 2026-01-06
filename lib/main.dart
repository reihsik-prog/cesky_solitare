import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/globalni_nastaveni.dart';
import 'src/vykreslovani.dart';
import 'src/hra.dart';
import 'src/pomocne_widgety.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await nactiNastaveni();
  runApp(const MaterialApp(
    title: 'Slovní Solitér',
    debugShowCheckedModeBanner: false,
    home: HlavniMenu(),
  ));
}

// ============================================================================ 
// --- HLAVNÍ MENU --- 
// ============================================================================ 

class HlavniMenu extends StatefulWidget {
  const HlavniMenu({super.key});
  @override
  State<HlavniMenu> createState() => _HlavniMenuState();
}

class _HlavniMenuState extends State<HlavniMenu> {
  bool existujeUlozeni = false;

  @override
  void initState() {
    super.initState();
    zkontrolujUlozeni();
  }

  void zkontrolujUlozeni() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      existujeUlozeni = prefs.getBool('existujeUlozeni') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                if (existujeUlozeni) ...[
                  MenuTlacitko(
                    text: "POKRAČOVAT",
                    ikona: Icons.fast_forward,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SlovniSolitare(nacistUlozenou: true),
                        ),
                      ).then((_) => zkontrolujUlozeni());
                    },
                  ),
                  const SizedBox(height: 20),
                ],
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
                    ).then((_) => zkontrolujUlozeni());
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
