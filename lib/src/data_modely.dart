// ============================================================================
// --- DATA A MODELY ---
// ============================================================================

class KartaData {
  final String slovo;
  final bool jeHlavni;
  final int kategorieId;

  KartaData(this.slovo, this.jeHlavni, this.kategorieId);

  Map<String, dynamic> toJson() => {
        's': slovo,
        'h': jeHlavni,
        'k': kategorieId,
      };

  factory KartaData.fromJson(Map<String, dynamic> json) => KartaData(
        json['s'],
        json['h'],
        json['k'],
      );
}

class SkakajiciKarta {
  KartaData data;
  double x, y, vx, vy;
  SkakajiciKarta(this.data, this.x, this.y, this.vx, this.vy);
}

class Level {
  final List<KartaData> karty;
  final int pocetSloupcu;

  Level({required this.karty, this.pocetSloupcu = 4});
}
