import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// --- GLOBÁLNÍ NASTAVENÍ ---
// ============================================================================
bool zvukyZapnute = true;
bool vibraceZapnute = true;

Future<void> nactiNastaveni() async {
  final prefs = await SharedPreferences.getInstance();
  zvukyZapnute = prefs.getBool('zvukyZapnute') ?? true;
  vibraceZapnute = prefs.getBool('vibraceZapnute') ?? true;
}

Future<void> ulozNastaveni() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('zvukyZapnute', zvukyZapnute);
  await prefs.setBool('vibraceZapnute', vibraceZapnute);
}