import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data_modely.dart';
import 'seznam_levelu.dart';
import 'globalni_nastaveni.dart';
import 'vykreslovani.dart';

// ============================================================================
// --- HRA (SlovniSolitare) ---
// ============================================================================

class SlovniSolitare extends StatefulWidget {
  final bool nacistUlozenou;
  const SlovniSolitare({super.key, this.nacistUlozenou = false});
  @override
  State<SlovniSolitare> createState() => _SlovniSolitareState();
}

class _SlovniSolitareState extends State<SlovniSolitare>

    with TickerProviderStateMixin {

  // --- Responzivní velikosti ---

  double sirkaKarty = 60;

  double vyskaKarty = 85;

  double sirkaSloupce = 72;

  double posunOdpadu = 26;

  double posunSkrytych = 15;

  double posunOdkrytych = 35;



  int aktualniLevelIndex = 0;

  int pocetSloupcu = 4;



  List<KartaData> balicek = [];

  List<KartaData> odpad = [];

  List<List<KartaData>> cile = List.generate(4, (_) => []);

  List<List<KartaData>> sloupce = List.generate(4, (_) => []);

  List<KartaData> archiv = [];

  List<List<KartaData>> skryteBalicky = List.generate(4, (_) => []);

  List<int> idsKategoriiProCile = [];



  final Random _rnd = Random();

  List<Widget> efekty = [];

  List<SkakajiciKarta> kaskada = [];

  Ticker? _kaskadaTicker;

  AnimationController? _lizaciController;

  KartaData? _leticiKarta;

  AnimationController? _rozdavaciController;

  KartaData? _leticiRozdavanaKarta;

  int _cilovySloupecProRozdavani = 0;

  bool _leticiJeRub = false;



  int pocetTahu = 0;



  int get limitTahu {

    int pocetKaret = seznamLevelu[aktualniLevelIndex].karty.length;

    double obtiznost = 2.2;

    return (pocetKaret * obtiznost).toInt();

  }



  int skore = 0;

  int ulozenyZacatekSkore = 0;



  bool jeKonecHryProhra = false;

  bool rozdavam = false;

  Map<String, int>? _tahanaPozice;

  bool _tahamZOdpadu = false;



  @override

  void initState() {

    super.initState();

    _lizaciController = AnimationController(

        vsync: this, duration: const Duration(milliseconds: 400));

    _rozdavaciController = AnimationController(

        vsync: this, duration: const Duration(milliseconds: 300));

    _lizaciController!.addStatusListener((status) {

      if (status == AnimationStatus.completed) {

        setState(() {

          if (_leticiKarta != null) odpad.add(_leticiKarta!);

          _leticiKarta = null;

          _lizaciController!.reset();

        });

      }

    });



    if (widget.nacistUlozenou) {

      nactiRozehranouHru();

    } else {

      restartHry(novyLevel: false);

    }

  }



  @override

  void dispose() {

    _lizaciController?.dispose();

    _kaskadaTicker?.dispose();

    super.dispose();

  }



  int celkemVKategorii(int id) {

    return seznamLevelu[aktualniLevelIndex]

        .karty

        .where((k) => k.kategorieId == id)

        .length;

  }



  void ulozHru() async {

    final prefs = await SharedPreferences.getInstance();

    String zabalKarty(List<KartaData> list) =>

        jsonEncode(list.map((k) => k.toJson()).toList());

    String zabalSloupce(List<List<KartaData>> list) => jsonEncode(

        list.map((l) => l.map((k) => k.toJson()).toList()).toList());



    await prefs.setString('balicek', zabalKarty(balicek));

    await prefs.setString('odpad', zabalKarty(odpad));

    await prefs.setString('archiv', zabalKarty(archiv));

    await prefs.setString('cile', zabalSloupce(cile));

    await prefs.setString('sloupce', zabalSloupce(sloupce));

    await prefs.setString('skryteBalicky', zabalSloupce(skryteBalicky));

    await prefs.setInt('skore', skore);

    await prefs.setInt('ulozeneSkore', ulozenyZacatekSkore);

    await prefs.setInt('tahy', pocetTahu);

    await prefs.setInt('level', aktualniLevelIndex);

    await prefs.setBool('existujeUlozeni', true);

    await prefs.setInt('pocetSloupcu', pocetSloupcu);

  }



  void nactiRozehranouHru() async {

    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('existujeUlozeni')) {

      restartHry(novyLevel: false);

      return;

    }

    List<KartaData> rozbalKarty(String json) =>

        (jsonDecode(json) as List).map((i) => KartaData.fromJson(i)).toList();



    setState(() {

      aktualniLevelIndex = prefs.getInt('level') ?? 0;

      pocetSloupcu = prefs.getInt('pocetSloupcu') ?? 4;

      balicek = rozbalKarty(prefs.getString('balicek') ?? "[]");

      odpad = rozbalKarty(prefs.getString('odpad') ?? "[]");

      archiv = rozbalKarty(prefs.getString('archiv') ?? "[]");

      var cileRaw = jsonDecode(prefs.getString('cile') ?? "[]") as List;

      cile = cileRaw

          .map((l) => (l as List).map((i) => KartaData.fromJson(i)).toList())

          .toList();

      var sloupceRaw = jsonDecode(prefs.getString('sloupce') ?? "[]") as List;

      sloupce = sloupceRaw

          .map((l) => (l as List).map((i) => KartaData.fromJson(i)).toList())

          .toList();

      var skryteRaw =

          jsonDecode(prefs.getString('skryteBalicky') ?? "[]") as List;

      skryteBalicky = skryteRaw

          .map((l) => (l as List).map((i) => KartaData.fromJson(i)).toList())

          .toList();

      if (skryteBalicky.length < pocetSloupcu) {

        skryteBalicky = List.generate(pocetSloupcu, (_) => []);

      }

      skore = prefs.getInt('skore') ?? 0;

      ulozenyZacatekSkore = prefs.getInt('ulozeneSkore') ?? 0;

      pocetTahu = prefs.getInt('tahy') ?? 0;

    });

  }



  void restartHry({bool novyLevel = false}) async {

    _kaskadaTicker?.stop();



    setState(() {

      rozdavam = true;



      if (novyLevel) {

        ulozenyZacatekSkore = skore;

        if (aktualniLevelIndex < seznamLevelu.length - 1) {

          aktualniLevelIndex++;

        } else {

          aktualniLevelIndex = 0;

          ulozenyZacatekSkore = 0;

        }

      }

      

      final level = seznamLevelu[aktualniLevelIndex];

      pocetSloupcu = level.pocetSloupcu;



      skore = ulozenyZacatekSkore;

      balicek = List.from(level.karty);

      balicek.shuffle();



      odpad = [];



      var unikatniIds = balicek.map((e) => e.kategorieId).toSet().toList();

      idsKategoriiProCile = unikatniIds;



      cile = List.generate(unikatniIds.length, (_) => <KartaData>[]);

      sloupce = List.generate(pocetSloupcu, (_) => []);

      skryteBalicky = List.generate(pocetSloupcu, (_) => []);



      archiv = [];

      kaskada = [];

      pocetTahu = 0;

      jeKonecHryProhra = false;

      _tahanaPozice = null;

    });



    List<int> ciloveSkryte = List.generate(pocetSloupcu, (_) => _rnd.nextInt(3));

    ciloveSkryte.shuffle();



    List<Map<String, dynamic>> akceRozdavani = [];

    int maxSkrytych = ciloveSkryte.reduce(max);



    for (int radek = 0; radek < maxSkrytych + 1; radek++) {

      for (int s = 0; s < pocetSloupcu; s++) {

        if (radek < ciloveSkryte[s]) {

          akceRozdavani.add({'col': s, 'rub': true});

        } else if (radek == ciloveSkryte[s]) {

          akceRozdavani.add({'col': s, 'rub': false});

        }

      }

    }



    for (var akce in akceRozdavani) {

      if (balicek.isEmpty) break;



      int cilovySloupec = akce['col'];

      bool jeRub = akce['rub'];



      setState(() {

        if (jeRub) {

          _leticiRozdavanaKarta = KartaData("", false, 0);

        } else {

          _leticiRozdavanaKarta = balicek[0];

        }



        _cilovySloupecProRozdavani = cilovySloupec;

        _leticiJeRub = jeRub;



        _rozdavaciController!.reset();

        _rozdavaciController!.forward();



        if (vibraceZapnute) HapticFeedback.selectionClick();

      });



      await Future.delayed(const Duration(milliseconds: 200));



      setState(() {

        if (balicek.isNotEmpty) {

          KartaData skutecnaKarta = balicek.removeAt(0);



          if (jeRub) {

            skryteBalicky[cilovySloupec].add(skutecnaKarta);

          } else {

            sloupce[cilovySloupec].add(skutecnaKarta);

          }

        }

        _leticiRozdavanaKarta = null;

      });

    }



    setState(() {

      rozdavam = false;

    });



    ulozHru();

  }



  void zkontrolujProhru() {

    if (pocetTahu >= limitTahu) {

      setState(() => jeKonecHryProhra = true);

    }

  }



  void _startKaskada() {

    int zbyvajiciTahy = limitTahu - pocetTahu;

    if (zbyvajiciTahy > 0) setState(() => skore += zbyvajiciTahy * 1);



    List<KartaData> vsechnyHotove = List.from(archiv);

    for (var seznam in cile) {

      vsechnyHotove.addAll(seznam);

    }



    for (int i = 0; i < vsechnyHotove.length; i++) {

      kaskada.add(SkakajiciKarta(

          vsechnyHotove[i],

          150.0 + (i % pocetSloupcu) * 60,

          80.0,

          (_rnd.nextDouble() - 0.5) * 12,

          -5.0 - _rnd.nextDouble() * 8));

    }

    _kaskadaTicker = createTicker((elapsed) {

      setState(() {

        for (var k in kaskada) {

          k.x += k.vx;

          k.y += k.vy;

          k.vy += 0.6;

          if (k.y > MediaQuery.of(context).size.height - 100) {

            k.y = MediaQuery.of(context).size.height - 100;

            k.vy *= -0.7;

          }

        }

      });

    });

    _kaskadaTicker!.start();

  }



  void vybuchni(Offset pozice) {

    for (int i = 0; i < 35; i++) {

      final double angle = _rnd.nextDouble() * 2 * pi;

      final double dist = 80.0 + _rnd.nextDouble() * 120.0;

      final color = [

        Colors.amber[100],

        Colors.white,

        Colors.orange[300],

        Colors.amber[400]

      ][_rnd.nextInt(4)];

      setState(() {

        efekty.add(Positioned(

            left: pozice.dx,

            top: pozice.dy,

            child: TweenAnimationBuilder(

                tween: Tween(begin: 0.0, end: 1.0),

                duration: const Duration(milliseconds: 900),

                builder: (c, double v, child) => Opacity(

                    opacity: 1.0 - (v * v),

                    child: Transform.translate(

                        offset:

                            Offset(cos(angle) * dist * v, sin(angle) * dist * v),

                        child: Transform.rotate(angle: v * 4, child: child))),

                child: Container(

                    width: 8,

                    height: 8,

                    decoration: BoxDecoration(

                        color: color,

                        borderRadius: BorderRadius.circular(2))))));

      });

    }

    Future.delayed(const Duration(milliseconds: 1000),

        () => setState(() => efekty.clear()));

  }



  void lizni() {

    if (rozdavam) return;

    if (jeKonecHryProhra) return;

    if (balicek.isEmpty && odpad.isEmpty) return;

    if (_lizaciController!.isAnimating) return;

    if (vibraceZapnute) HapticFeedback.lightImpact();



    setState(() {

      pocetTahu++;

      if (balicek.isNotEmpty) {

        _leticiKarta = balicek.removeAt(0);

        _lizaciController!.forward();

      } else {

        balicek.addAll(odpad.reversed);

        odpad.clear();

      }

    });

    ulozHru();

    zkontrolujProhru();

  }



  void presun(Map data, String kam, int ci, BuildContext context) async {

    if (rozdavam) return;

    if (jeKonecHryProhra) return;

    setState(() => _tahanaPozice = null);



    if (data['t'] == kam && data['i'] == ci) return;

    List<KartaData> tahaneKarty = List<KartaData>.from(data['karty']);

    KartaData prvni = tahaneKarty.first;



    bool muze = (kam == "cil")

        ? (cile[ci].isEmpty

            ? prvni.jeHlavni

            : (prvni.kategorieId == cile[ci].first.kategorieId &&

                !prvni.jeHlavni))

        : (sloupce[ci].isEmpty ||

            (prvni.kategorieId == sloupce[ci].last.kategorieId &&

                !sloupce[ci].last.jeHlavni));



    if (!muze) {

      setState(() => skore = max(0, skore - 5));

      if (vibraceZapnute) HapticFeedback.heavyImpact();

      return;

    }



    setState(() {

      pocetTahu++;

      if (kam != "cil" || !prvni.jeHlavni) skore += 10;



      if (data['t'] == "odpad") {

        odpad.removeLast();

      } else if (data['t'] == "sloupec") {

        int odkudIdx = data['i'];

        sloupce[odkudIdx].removeRange(

            sloupce[odkudIdx].length - tahaneKarty.length,

            sloupce[odkudIdx].length);

        if (sloupce[odkudIdx].isEmpty && skryteBalicky[odkudIdx].isNotEmpty) {

          sloupce[odkudIdx].add(skryteBalicky[odkudIdx].removeLast());

        }

      }



      if (kam == "sloupec") sloupce[ci].addAll(tahaneKarty);

      if (kam == "cil") {

        cile[ci].addAll(tahaneKarty);

        if (cile[ci].length == celkemVKategorii(prvni.kategorieId)) {

          final RenderBox box = context.findRenderObject() as RenderBox;

          vybuchni(box.localToGlobal(Offset.zero) + const Offset(30, 40));



          Future.delayed(const Duration(milliseconds: 500), () {

            if (mounted) {

              setState(() {

                archiv.addAll(cile[ci]);

                cile[ci].clear();

                if (archiv.length ==

                    seznamLevelu[aktualniLevelIndex].karty.length) {

                  _startKaskada();

                }

              });

            }

          });

        }

      }

    });

    ulozHru();

    zkontrolujProhru();

  }

  void zobrazitHerniMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Center(
          child: Text(
            "HERNÍ MENU",
            style: TextStyle(
              color: Color(0xFF3E2723),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("POKRAČOVAT"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(220, 45)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("RESTARTOVAT"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(220, 45)),
                  onPressed: () {
                    restartHry(novyLevel: false);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text("CHEAT: VYBRAT LEVEL"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(220, 45)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFFFFF8E1),
                        title: const Text("Kam chceš skočit?",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        content: SizedBox(
                          width: double.maxFinite,
                          height: 300,
                          child: ListView.builder(
                            itemCount: seznamLevelu.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text("Level ${index + 1}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                leading: const Icon(Icons.play_circle_filled,
                                    color: Colors.purple),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  aktualniLevelIndex = index;
                                  ulozenyZacatekSkore = 0;
                                  skore = 0;
                                  restartHry(novyLevel: false);
                                },
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("ZRUŠIT"),
                          )
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text("UKONČIT HRU"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(220, 45)),
                  onPressed: () {
                    ulozHru();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  child: Divider(color: Color(0xFFD7CCC8), thickness: 1.5),
                ),
                SwitchListTile(
                  title: const Text("Zvuky", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
                  secondary: Icon(zvukyZapnute ? Icons.volume_up : Icons.volume_off, color: const Color(0xFF4E342E)),
                  value: zvukyZapnute,
                  activeColor: Colors.green,
                  onChanged: (bool value) {
                    setState(() {
                      zvukyZapnute = value;
                    });
                    ulozNastaveni();
                  },
                ),
                SwitchListTile(
                  title: const Text("Vibrace", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
                  secondary: Icon(vibraceZapnute ? Icons.vibration : Icons.phone_android, color: const Color(0xFF4E342E)),
                  value: vibraceZapnute,
                  activeColor: Colors.green,
                  onChanged: (bool value) {
                    setState(() {
                      vibraceZapnute = value;
                    });
                    ulozNastaveni();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

    @override

    Widget build(BuildContext context) {

      // --- VÝPOČET VELIKOSTÍ ---

      final double sirkaObrazovky = MediaQuery.of(context).size.width;

      // Cílem je, aby sloupce zabraly cca 92% šířky.

      final double hraciPlocha = sirkaObrazovky * 0.92;

      sirkaSloupce = (hraciPlocha / pocetSloupcu).floorToDouble();

      const double hPadding = 5.0; // Mezera vedle karty

      sirkaKarty = (sirkaSloupce - hPadding * 2).floorToDouble();

      vyskaKarty = (sirkaKarty * 1.45).floorToDouble(); // Lehce upravený poměr

            posunOdpadu = sirkaKarty * 0.4;

            posunSkrytych = vyskaKarty * 0.20;

            posunOdkrytych = vyskaKarty * 0.20;

  

      int zbyvaTahu = limitTahu - pocetTahu;

  

      List<Widget> topRowItems = [];

      // Balíček

      topRowItems.add(Padding(

        padding: const EdgeInsets.symmetric(horizontal: 5),

        child: SizedBox(

          width: sirkaKarty,

          height: vyskaKarty,

          child: GestureDetector(

            onTap: lizni,

            child: Center(

              child: Container(

                width: sirkaKarty,

                height: vyskaKarty,

                decoration: BoxDecoration(

                  borderRadius: BorderRadius.circular(sirkaKarty * 0.13),

                  border: Border.all(color: Colors.white24, width: 2),

                  color: balicek.isNotEmpty

                      ? const Color(0xFFB71C1C)

                      : Colors.black26,

                ),

                child: balicek.isNotEmpty

                    ? CustomPaint(painter: RubKartyPainter())

                    : const Icon(Icons.refresh, color: Colors.white38),

              ),

            ),

          ),

        ),

      ));

  

      // Odpad

      if (pocetSloupcu > 1) {

        double odpadWidth = sirkaSloupce * (pocetSloupcu > 2 ? 2 : 1);

        topRowItems.add(SizedBox(

          width: odpadWidth,

          height: vyskaKarty,

          child: Stack(

            clipBehavior: Clip.none,

            children: [

              Positioned(

                left: (sirkaSloupce - sirkaKarty) / 2,

                child: Container(

                  width: sirkaKarty,

                  height: vyskaKarty,

                  decoration: BoxDecoration(

                    borderRadius: BorderRadius.circular(sirkaKarty * 0.13),

                    border: Border.all(color: Colors.white10, width: 2),

                    color: Colors.black12,

                  ),

                  child: odpad.isEmpty

                      ? Center(

                          child: Icon(Icons.layers_clear,

                              color: Colors.white12, size: sirkaKarty * 0.4))

                      : null,

                ),

              ),

              for (int i = 0; i < odpad.length; i++)

                if (i >= odpad.length - 3)

                  Positioned(

                    left: (sirkaSloupce - sirkaKarty) / 2 +

                        (i - max(0, odpad.length - 3)) * posunOdpadu,

                                                                                child: (i == odpad.length - 1)

                                                                                    ? tahatelna([odpad[i]], "odpad", 0)

                                                                                    : vzhledKarty(odpad[i], true,

                                                                                        otocitText:

                                                                                            !(i == odpad.length - 2 && _tahamZOdpadu)),

                  ),

              if (_leticiKarta != null)

                AnimatedBuilder(

                  animation: _lizaciController!,

                  builder: (context, child) {

                    double v = CurvedAnimation(

                            parent: _lizaciController!,

                            curve: Curves.easeInOutCubic)

                        .value;

                    double startLeft = -sirkaSloupce;

                    double cilLeft = (sirkaSloupce - sirkaKarty) / 2 +

                        (min(2, odpad.length) * (posunOdpadu * 0.85));

                    return Positioned(

                      left: startLeft + ((cilLeft - startLeft) * v),

                      top: 0,

                      child: Transform.rotate(

                        angle: v * 0.2,

                        child: Transform.scale(

                          scale: 1.1,

                          child: vzhledKarty(_leticiKarta!, true, leti: true),

                        ),

                      ),

                    );

                  },

                )

            ],

          ),

        ));

      }

      // Zbytek horní řady jako prázdná místa

      int zabranoNahore = 1 + (pocetSloupcu > 1 ? (pocetSloupcu > 2 ? 2 : 1) : 0);

      for (int i = 0; i < pocetSloupcu - zabranoNahore; i++) {

         topRowItems.add(Padding(

          padding: const EdgeInsets.symmetric(horizontal: 5),

          child: SizedBox(width: sirkaKarty, height: vyskaKarty),

        ));

      }

  

  

      return Scaffold(

        body: Stack(

          children: [

            // --- 1. POZADÍ ---

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

  

            // --- 2. HLAVNÍ HERNÍ PLOCHA ---

            SafeArea(

              child: Column(

                children: [

                  // LEVEL

                  const SizedBox(height: 30),

                  Container(

                    padding:

                        const EdgeInsets.symmetric(horizontal: 25, vertical: 8),

                    decoration: BoxDecoration(

                      color: const Color.fromARGB(51, 0, 0, 0),

                      borderRadius: BorderRadius.circular(30),

                      border: Border.all(

                          color: const Color.fromARGB(153, 255, 193, 7),

                          width: 1.5),

                      boxShadow: [

                        BoxShadow(

                          color: const Color.fromARGB(26, 0, 0, 0),

                          blurRadius: 8,

                          offset: const Offset(0, 4),

                        )

                      ],

                    ),

                    child: Row(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        const Icon(Icons.star, size: 16, color: Colors.amber),

                        const SizedBox(width: 8),

                        Text(

                          "LEVEL ${aktualniLevelIndex + 1}",

                          style: const TextStyle(

                            fontSize: 16,

                            color: Colors.white,

                            fontWeight: FontWeight.w900,

                            letterSpacing: 2.0,

                            decoration: TextDecoration.none,

                          ),

                        ),

                      ],

                    ),

                  ),

  

                  // BALÍČEK A ODPAD

                  Container(

                    margin: const EdgeInsets.only(top: 15, bottom: 20),

                    child: Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: topRowItems,

                    ),

                  ),

  

                  // SLOUPCE (Cíle a Herní pole)

                  Expanded(

                    child: Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: List.generate(

                        pocetSloupcu,

                        (idx) => Padding(

                          padding: const EdgeInsets.symmetric(horizontal: 5),

                          child: Builder(builder: (context) {

                            bool cilExistuje = idx < cile.length;

  

                            return Column(

                              children: [

                                // Horní CÍLE

                                SizedBox(

                                  height: vyskaKarty * 0.3, // 26/85

                                  child: !cilExistuje || cile[idx].isEmpty

                                      ? null

                                      : Container(

                                          width: sirkaKarty,

                                          margin:

                                              const EdgeInsets.only(bottom: 2),

                                          decoration: BoxDecoration(

                                              color: const Color.fromARGB(

                                                  77, 0, 0, 0),

                                              borderRadius:

                                                  BorderRadius.circular(6),

                                              border: Border.all(

                                                  color: Colors.amber,

                                                  width: 1)),

                                                                                  alignment: Alignment.center,

                                                                                  child: Padding(

                                                                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),

                                                                                    child: FittedBox(

                                                                                      fit: BoxFit.scaleDown,

                                                                                      child: Text(

                                                                                        cile[idx].first.slovo,

                                                                                        style: const TextStyle(

                                                                                            color: Colors.amber,

                                                                                            fontWeight: FontWeight.bold),

                                                                                      ),

                                                                                    ),

                                                                                  ),

                                                                                ),

                                                                        ),

                                DragTarget<Map>(

                                  onAcceptWithDetails: (details) =>

                                      presun(details.data, "cil", idx, context),

                                                                    builder: (c, _, __) => Stack(

                                                                      alignment: Alignment.center,

                                                                      children: [

                                                                        // The Frame

                                                                        Container(

                                                                          width: sirkaKarty,

                                                                          height: vyskaKarty,

                                                                                                                  decoration: BoxDecoration(

                                                                                                                    color: const Color.fromARGB(51, 0, 0, 0),

                                                                                                                                                              borderRadius: BorderRadius.circular(sirkaKarty * 0.16),

                                                                                                                                                                                                        border: cilExistuje && cile[idx].isEmpty

                                                                                                                                                                                                            ? Border.all(

                                                                                                                                                                                                                color: Colors.amber.withOpacity(0.5),

                                                                                                                                                                                                                width: 2,

                                                                                                                                                                                                                strokeAlign: BorderSide.strokeAlignOutside,

                                                                                                                                                                                                              )

                                                                                                                                                                                                            : null,

                                                                                                                                                            ),

                                                                        ),

                                                                        // The Content

                                                                        if (!cilExistuje || cile[idx].isEmpty)

                                                                          Icon(

                                                                            Icons.star,

                                                                            color: const Color.fromARGB(77, 255, 193, 7),

                                                                            size: sirkaKarty * 0.5,

                                                                          )

                                                                        else

                                                                          Stack(

                                                                            alignment: Alignment.center,

                                                                                                                      children: cile[idx]

                                                                                                                          .map((karta) => vzhledKarty(

                                                                                                                                karta,

                                                                                                                                true,

                                                                                                                                pocitadlo: (cile[idx].indexOf(karta) > 0)

                                                                                                                                    ? "${cile[idx].indexOf(karta)}/${celkemVKategorii(karta.kategorieId) - 1}"

                                                                                                                                    : null,

                                                                                                                                zobrazIkonu: cile[idx].last == karta,

                                                                                                                                jeVCili: true,

                                                                                                                              ))

                                                                                                                          .toList(),

                                                                          ),

                                                                      ],

                                                                    ),

                                ),

                                const SizedBox(height: 5),

  

                                // Spodní SLOUPCE (Opravené centrování karet)

                                Expanded(

                                  child: DragTarget<Map>(

                                    onAcceptWithDetails: (details) => presun(

                                        details.data, "sloupec", idx, context),

                                    builder: (c, _, __) => Container(

                                      width:

                                          sirkaKarty, // Sjednoceno na šířku karty

                                      color: Colors

                                          .transparent, // Zajišťuje, že oblast reaguje na dotyk

                                      child: Stack(

                                        clipBehavior: Clip.none,

                                        alignment: Alignment

                                            .topCenter, // <--- TATO ŘÁDKA CENTRUJE KARTY VE SLOUPCI

                                        children: [

                                          // 1. VIZUÁLNÍ RÁMEČEK (Hnízdo)

                                          Positioned(

                                            top: 0,

                                            child: Container(

                                              width:

                                                  sirkaKarty, // Musí být stejné jako karta

                                              height:

                                                  vyskaKarty * 2.1, // 180/85

                                              decoration: BoxDecoration(

                                                borderRadius:

                                                    BorderRadius.circular(

                                                        sirkaKarty * 0.16),

                                                color: const Color.fromARGB(

                                                    26, 0, 0, 0),

                                                border: Border.all(

                                                    color: Colors.white

                                                        .withAlpha(13),

                                                    width: 1.5),

                                              ),

                                            ),

                                          ),

  

                                          // 2. Rubové (skryté) karty

                                          for (int k = 0;

                                              k < skryteBalicky[idx].length;

                                              k++)

                                            Positioned(

                                              top: k * posunSkrytych,

                                              child: vzhledKarty(

                                                  KartaData("", false, 0),

                                                  false),

                                            ),

  

                                          // 3. Viditelné karty

                                          for (int j = 0;

                                              j < sloupce[idx].length;

                                              j++)

                                            if (!(_tahanaPozice != null &&

                                                _tahanaPozice!['col'] == idx &&

                                                j >= _tahanaPozice!['idx']!))

                                              Positioned(

                                                top: (skryteBalicky[idx].length *

                                                        posunSkrytych) +

                                                    (j * posunOdkrytych),

                                                child: tahatelna(

                                                  sloupce[idx].sublist(j),

                                                  "sloupec",

                                                  idx,

                                                  indexVPuvodnimSloupci: j,

                                                  jeZakryta: j <

                                                      sloupce[idx].length - 1,

                                                ),

                                              )

                                        ],

                                      ),

                                    ),

                                  ),

                                ),

                              ],

                            );

                          }),

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

  

            // --- 3. PRAVÝ PANEL (SUPER SLIM verze pro mobil) ---

            if (!kaskada.isNotEmpty)

              Positioned(

                right: 0, // Úplně vpravo

                top: 80,

                child: Container(

                  // Padding (vycpávka) zmenšena na minimum (jen 4 px)

                  padding:

                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),

                  decoration: BoxDecoration(

                    gradient: LinearGradient(

                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,

                      colors: [

                        Colors.black.withAlpha(26),

                        Colors.black.withAlpha(3)

                      ],

                    ),

                    // Zaoblení jen vlevo

                    borderRadius: const BorderRadius.only(

                      topLeft: Radius.circular(12),

                      bottomLeft: Radius.circular(12),

                    ),

                    border:

                        Border.all(color: Colors.white.withAlpha(26), width: 1),

                    boxShadow: [

                      BoxShadow(

                        color: Colors.black.withAlpha(77),

                        blurRadius: 10,

                        offset: const Offset(4, 4),

                      )

                    ],

                  ),

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [

                      // MENU IKONA

                      IconButton(

                        icon: const Icon(Icons.settings,

                            color: Colors.amber,

                            size: 18), // Ještě menší ikona

                        onPressed: zobrazitHerniMenu,

                        padding: EdgeInsets.zero,

                        constraints: const BoxConstraints(),

                        tooltip: "Menu",

                      ),

  

                      Container(

                          margin: const EdgeInsets.symmetric(vertical: 4),

                          width: 15,

                          height: 1,

                          color: Colors.white12),

  

                      // TAHY

                      Column(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Icon(Icons.directions_walk,

                              size: 10,

                              color: zbyvaTahu <= 5

                                  ? Colors.redAccent

                                  : Colors.amber),

                          Text("$zbyvaTahu",

                              style: TextStyle(

                                  fontSize: 13, // Menší číslo (bylo 15)

                                  color: zbyvaTahu <= 5

                                      ? Colors.redAccent

                                      : Colors.white,

                                  fontWeight: FontWeight.w900,

                                  fontFamily: 'monospace')),

                        ],

                      ),

  

                      Container(

                          margin: const EdgeInsets.symmetric(vertical: 4),

                          width: 15,

                          height: 1,

                          color: Colors.white12),

  

                      // SKÓRE

                      Column(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          const Icon(Icons.emoji_events,

                              size: 10, color: Colors.amber),

                          Text("$skore",

                              style: const TextStyle(

                                  fontSize: 13, // Menší číslo (bylo 15)

                                  color: Colors.amber,

                                  fontWeight: FontWeight.w900,

                                  fontFamily: 'monospace')),

                        ],

                      ),

                    ],

                  ),

                ),

              ),

  

            // --- 4. EFEKTY A ANIMACE ---

            ...efekty,

            for (var k in kaskada)

              Positioned(left: k.x, top: k.y, child: vzhledKarty(k.data, true)),

  

            // Animace rozdávání

            if (_leticiRozdavanaKarta != null)

              AnimatedBuilder(

                animation: _rozdavaciController!,

                builder: (context, child) {

                  double sirka = MediaQuery.of(context).size.width;

                  double startX = sirkaSloupce;

                  double startY = 100;

                  

                  double cilX = (_cilovySloupecProRozdavani * sirkaSloupce) + (sirkaSloupce - sirkaKarty) / 2;

                  double cilY = vyskaKarty * 2.5;

  

                  double t = CurvedAnimation(

                          parent: _rozdavaciController!,

                          curve: Curves.easeInOutCubic)

                      .value;

                  double aktualniX = startX + (cilX - startX) * t;

                  double aktualniY = startY + (cilY - startY) * t;

                  return Positioned(

                    left: aktualniX,

                    top: aktualniY,

                    child: Transform.scale(

                      scale: 1.0 + (sin(t * 3.14) * 0.2),

                      child: vzhledKarty(_leticiRozdavanaKarta!, !_leticiJeRub,

                          leti: true),

                    ),

                  );

                },

              ),

  

            // --- 5. OVERLAY (Prohra / Výhra) ---

            if (jeKonecHryProhra)

              Container(

                color: Colors.black54,

                child: Center(

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      const Text(

                        "PROHRA",

                        style: TextStyle(

                            fontSize: 50,

                            color: Colors.red,

                            fontWeight: FontWeight.bold,

                            decoration: TextDecoration.none,

                            shadows: [

                              Shadow(blurRadius: 10, color: Colors.black)

                            ]),

                      ),

                      const SizedBox(height: 10),

                      Text(

                        "Získané skóre: $skore",

                        style: const TextStyle(

                            color: Colors.white,

                            fontSize: 24,

                            fontWeight: FontWeight.bold,

                            decoration: TextDecoration.none),

                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(

                        style: ElevatedButton.styleFrom(

                            backgroundColor: Colors.amber,

                            padding: const EdgeInsets.symmetric(

                                horizontal: 30, vertical: 15)),

                        onPressed: () => restartHry(novyLevel: false),

                        child: const Text("ZKUSIT ZNOVU",

                            style: TextStyle(

                                color: Colors.black,

                                fontWeight: FontWeight.bold)),

                      )

                    ],

                  ),

                ),

              ),

  

            if (kaskada.isNotEmpty)

              Positioned(

                bottom: 50,

                left: 0,

                right: 0,

                child: Center(

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Text(

                        "VÍTĚZSTVÍ! SKÓRE: $skore",

                        style: const TextStyle(

                          fontSize: 24,

                          fontWeight: FontWeight.w900,

                          color: Colors.amber,

                          decoration: TextDecoration.none,

                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],

                        ),

                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(

                        onPressed: () => restartHry(novyLevel: true),

                        style: ElevatedButton.styleFrom(

                            backgroundColor: Colors.amber,

                            foregroundColor: Colors.black),

                        child: Text(

                          aktualniLevelIndex < seznamLevelu.length - 1

                              ? "DALŠÍ LEVEL >>"

                              : "HOTOVO! ZNOVU OD 1.",

                          style: const TextStyle(

                              fontSize: 20, fontWeight: FontWeight.bold),

                        ),

                      )

                    ],

                  ),

                ),

              )

          ],

        ),

      );

    }

  // ==========================================================================
  // --- POMOCNÉ WIDGETY (Draggable, Vzhled karty) ---
  // ==========================================================================

  Widget tahatelna(List<KartaData> k, String t, int i,
      {bool jeZakryta = false, int indexVPuvodnimSloupci = 0}) {
    if (jeKonecHryProhra) return vzhledKarty(k.first, true, isGray: true);

    return Draggable<Map>(
      data: {'karty': k, 't': t, 'i': i},
      onDragStarted: () {
        if (vibraceZapnute) HapticFeedback.selectionClick();
        setState(() {
          if (t == "sloupec") {
            _tahanaPozice = {'col': i, 'idx': indexVPuvodnimSloupci};
          } else if (t == "odpad") {
            _tahamZOdpadu = true;
          }
        });
      },
      onDraggableCanceled: (_, __) => setState(() {
        _tahanaPozice = null;
        _tahamZOdpadu = false;
      }),
      onDragEnd: (_) => setState(() {
        _tahanaPozice = null;
        _tahamZOdpadu = false;
      }),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.1,
          child: SizedBox(
            width: sirkaKarty,
            height: vyskaKarty + (k.length - 1) * posunOdkrytych,
            child: Stack(
              children: k.asMap().entries.map((entry) {
                int idx = entry.key;
                KartaData karta = entry.value;
                return Positioned(
                  top: idx * posunOdkrytych,
                  child: vzhledKarty(karta, true,
                      leti: true, jeZakryta: idx < k.length - 1),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
          opacity: 0.0,
          child: vzhledKarty(k.first, true, jeZakryta: jeZakryta)),
      child: vzhledKarty(k.first, true, jeZakryta: jeZakryta),
    );
  }

  Widget vzhledKarty(KartaData k, bool odhalena,
      {bool leti = false,
      String? pocitadlo,
      bool zobrazIkonu = false,
      bool otocitText = false,
      bool isGray = false,
      bool jeZakryta = false,
      bool jeVCili = false}) {
    // --- NOVÁ LOGIKA PRO VZHLED STARÉ KARTY ---
    final bool pouzitVzhledStareKarty = odhalena && !k.jeHlavni && !leti && !isGray;

    // Původní definice barev a stylů (zůstávají pro ostatní stavy karet)
    final Gradient pozadiGradient = odhalena
        ? (k.jeHlavni
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange[200]!, Colors.amber[400]!])
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.3, 1.0],
                colors: [
                    const Color(0xFFFFFFFF),
                    const Color(0xFFF8F8F0),
                    const Color(0xFFE0E0E0)
                  ]))
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red[800]!, Colors.red[900]!]);

    final Color barvaRamecku = odhalena
        ? (k.jeHlavni
            ? Colors.orange[700]!.withAlpha(128)
            : Colors.grey[400]!)
        : Colors.white;

    final Color barvaVnitrniLinky = jeVCili
        ? Colors.amber
        : (k.jeHlavni
            ? const Color.fromARGB(77, 121, 85, 72)
            : const Color.fromARGB(77, 158, 158, 158));

    final TextStyle stylPisma = GoogleFonts.raleway(
      fontWeight: FontWeight.w700,
      fontSize: sirkaKarty * 0.18,
      color: isGray ? Colors.grey[700] : const Color(0xFF3E2723),
      decoration: TextDecoration.none,
    );

    // Pomocné funkce (zůstávají beze změny)
    IconData? getIkona() {
      switch (k.kategorieId) {
        case 1: return Icons.pets;
        case 2: return Icons.eco;
        case 3: return Icons.location_city;
        case 4: return Icons.palette;
        case 5: return Icons.checkroom;
        case 6: return Icons.directions_car;
        case 7: return Icons.wb_sunny;
        case 8: return Icons.family_restroom;
        case 9: return Icons.category;
        case 10: return Icons.school;
        case 11: return Icons.restaurant;
        case 12: return Icons.music_note;
        default: return null;
      }
    }

    Widget getObsahKarty() {
      if (k.kategorieId == 9 && k.jeHlavni) {
        return Icon(Icons.category, size: sirkaKarty * 0.8, color: Colors.white);
      }
      if (k.kategorieId == 9 && !k.jeHlavni) {
        IconData ikonaTvaru;
        Color barvaTvaru;
        if (k.slovo == "Srdce") {
          ikonaTvaru = Icons.favorite; barvaTvaru = Colors.red;
        } else if (k.slovo == "Hvězda") {
          ikonaTvaru = Icons.star; barvaTvaru = Colors.amber;
        } else if (k.slovo == "Čtverec") {
          ikonaTvaru = Icons.square; barvaTvaru = Colors.blue;
        } else if (k.slovo == "Kruh") {
          ikonaTvaru = Icons.circle; barvaTvaru = Colors.green;
        } else {
          ikonaTvaru = Icons.help; barvaTvaru = Colors.grey;
        }
        return Icon(ikonaTvaru, size: sirkaKarty * 0.66, color: barvaTvaru);
      }
      return Text(k.slovo, textAlign: TextAlign.center, style: stylPisma);
    }

    // Vykreslení
    return Container(
      width: sirkaKarty,
      height: vyskaKarty,
      decoration: pouzitVzhledStareKarty
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(sirkaKarty * 0.13),
              border: Border.all(color: Colors.black.withOpacity(0.4), width: 1),
              image: const DecorationImage(
                image: AssetImage('assets/images/stary_papir.png.png'),
                fit: BoxFit.cover,
colorFilter: ColorFilter.mode(
                  const Color.fromARGB(255, 255, 250, 240),
                  BlendMode.softLight,
                ),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color.fromARGB(51, 0, 0, 0),
                    blurRadius: 6,
                    offset: Offset(2, 3))
              ],
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(sirkaKarty * 0.13), // 8/60
              gradient: isGray ? null : pozadiGradient,
              color: isGray ? Colors.grey[300] : null,
              border: Border.all(
                  color: isGray ? Colors.grey : barvaRamecku,
                  width: odhalena ? 1 : 0),
              boxShadow: leti
                  ? [
                      BoxShadow(
                          color: const Color.fromARGB(102, 0, 0, 0),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 10))
                    ]
                  : [
                      BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 6,
                          offset: const Offset(2, 3))
                    ],
            ),
      child: odhalena
          ? ClipRRect(
              borderRadius: BorderRadius.circular(sirkaKarty * 0.11), // 7/60
              child: Stack(
                children: [
                  // --- EFEKT VINĚTY (ZTMAVENÍ OKRAJŮ) ---
                  if (pouzitVzhledStareKarty)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(sirkaKarty * 0.11),
                        gradient: RadialGradient(
                          radius: 0.9,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  
                  // Původní obsah karty
                  if (!isGray)
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(sirkaKarty * 0.1), // 6/60
                        border: Border.all(color: barvaVnitrniLinky, width: 2),
                      ),
                    ),
                  if (k.jeHlavni && !isGray)
                    Positioned(
                      top: -vyskaKarty * 0.23, // -20/85
                      left: -sirkaKarty * 0.33, // -20/60
                      child: Container(
                        width: sirkaKarty * 0.83, // 50/60
                        height: sirkaKarty * 0.83, // 50/60
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(77, 255, 255, 255),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  if (otocitText)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: sirkaKarty * 0.06), // 4.0
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(k.slovo, style: stylPisma),
                          ),
                        ),
                      ),
                    )
                  else if (jeZakryta)
                    Padding(
                      padding: EdgeInsets.only(top: vyskaKarty * 0.05, left: 2.0, right: 2.0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (k.jeHlavni && getIkona() != null)
                                Icon(getIkona(), size: sirkaKarty * 0.23, color: Colors.brown[700]),
                              
                              // Zde je už upravený text s vlastní velikostí
                              Text(
                                k.slovo,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.raleway(
                                  fontWeight: FontWeight.w700,
                                  fontSize: sirkaKarty * 0.15, // <-- ZDE SI UPRAVTE VELIKOST
                                  color: const Color(0xFF3E2723),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: sirkaKarty * 0.1), // 6
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (k.jeHlavni && getIkona() != null)
                                Icon(getIkona(), size: sirkaKarty * 0.26, color: Colors.brown[700]),
                              getObsahKarty()
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (zobrazIkonu && getIkona() != null && otocitText == false && !k.jeHlavni)
                    Positioned(
                      left: sirkaKarty * 0.1, // 6
                      top: sirkaKarty * 0.1, // 6
                      child: Icon(getIkona(), size: sirkaKarty * 0.23, color: isGray ? Colors.grey : Colors.black38),
                    ),
                  if (pocitadlo != null)
                    Positioned(
                      right: sirkaKarty * 0.1, // 6
                      bottom: sirkaKarty * 0.1, // 6
                      child: Text(
                        pocitadlo,
                        style: GoogleFonts.rubik(
                          fontSize: sirkaKarty * 0.13, // 8.5/60
                          fontWeight: FontWeight.w600,
                          color: isGray
                              ? Colors.grey[700]
                              : const Color(0xFF3E2723),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : CustomPaint(painter: RubKartyPainter()),
    );
  }
}
