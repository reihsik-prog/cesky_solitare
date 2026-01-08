import 'data_modely.dart';

// ============================================================================
// --- SEZNAM LEVELŮ ---
// ============================================================================

final List<Level> seznamLevelu = [
  // --- LEVEL 1 (ID 1-4) ---
  Level(karty: [
    KartaData("ZVÍŘE", true, 1), KartaData("Kočka", false, 1), 
    KartaData("OVOCE", true, 2), KartaData("Hruška", false, 2), 
    KartaData("MĚSTO", true, 3), KartaData("Praha", false, 3), 
    KartaData("BARVA", true, 4), KartaData("Modrá", false, 4), 
  ]),
  // --- LEVEL 2 (ID 5-8) ---
  Level(karty: [
    KartaData("OBLEČENÍ", true, 5), KartaData("Tričko", false, 5), KartaData("Kalhoty", false, 5), KartaData("Boty", false, 5), KartaData("Čepice", false, 5),
    KartaData("DOPRAVA", true, 6), KartaData("Auto", false, 6), KartaData("Kolo", false, 6), KartaData("Vlak", false, 6), KartaData("Letadlo", false, 6),
    KartaData("POČASÍ", true, 7), KartaData("Slunce", false, 7), KartaData("Déšť", false, 7), KartaData("Sníh", false, 7), KartaData("Vítr", false, 7),
    KartaData("RODINA", true, 8), KartaData("Máma", false, 8), KartaData("Táta", false, 8), KartaData("Bratr", false, 8), KartaData("Sestra", false, 8),
  ]),
  // --- LEVEL 3: BAREVNÉ TVARY (ID 9-12) ---
  Level(karty: [
    KartaData("TVARY", true, 9),
    KartaData("Srdce", false, 9),
    KartaData("Kruh", false, 9),
    KartaData("Čtverec", false, 9),
    KartaData("Trojúhelník", false, 9),


    // Další kategorie pro Level 3
    KartaData("ŠKOLA", true, 10), KartaData("Sešit", false, 10), KartaData("Tužka", false, 10), KartaData("Batoh", false, 10), KartaData("Kniha", false, 10),
    KartaData("JÍDLO", true, 11), KartaData("Pizza", false, 11), KartaData("Hamburger", false, 11), KartaData("Salát", false, 11), KartaData("Polévka", false, 11),
    KartaData("HUDBA", true, 12), KartaData("Kytara", false, 12), KartaData("Piano", false, 12), KartaData("Buben", false, 12), KartaData("Flétna", false, 12),
  ]),
  // --- LEVEL 4: VELKÝ MIX ---
  Level(karty: [
    KartaData("ZVÍŘATA", true, 1), KartaData("Pes", false, 1), KartaData("Kočka", false, 1), KartaData("Slon", false, 1), KartaData("Lev", false, 1), KartaData("Tygr", false, 1), KartaData("Medvěd", false, 1),
    KartaData("OVOCE", true, 2), KartaData("Jablko", false, 2), KartaData("Banán", false, 2), KartaData("Hrozny", false, 2),
    KartaData("NÁSTROJE", true, 3), KartaData("Kladivo", false, 3), KartaData("Šroubovák", false, 3), KartaData("Pila", false, 3),
    KartaData("BARVY", true, 4), KartaData("Červená", false, 4), KartaData("Modrá", false, 4), KartaData("Zelená", false, 4),
    KartaData("OBLEČENÍ", true, 5), KartaData("Tričko", false, 5), KartaData("Kalhoty", false, 5), KartaData("Boty", false, 5),
    KartaData("DOPRAVA", true, 6), KartaData("Auto", false, 6), KartaData("Kolo", false, 6), KartaData("Vlak", false, 6), KartaData("Letadlo", false, 6),
    KartaData("HUDBA", true, 12), KartaData("Kytara", false, 12), KartaData("Piano", false, 12), KartaData("Buben", false, 12), KartaData("Flétna", false, 12),
  ]),
  // Zde můžete v budoucnu přidat level s 5 sloupci, např.:
  // Level(pocetSloupcu: 5, karty: [ ... ]),

];