import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Krok 1: Definice stavového objektu
// Uchovává všechny hodnoty, které chceme sledovat a vykreslovat v UI.
class ScoreState {
  final int score;
  final int coins;
  final int undoTokens;
  final bool firstUndoUsed; // Sledujeme, zda bylo v této hře už použito Undo

  ScoreState({
    this.score = 0,
    this.coins = 0,
    this.undoTokens = 0,
    this.firstUndoUsed = false,
  });

  ScoreState copyWith({
    int? score,
    int? coins,
    int? undoTokens,
    bool? firstUndoUsed,
  }) {
    return ScoreState(
      score: score ?? this.score,
      coins: coins ?? this.coins,
      undoTokens: undoTokens ?? this.undoTokens,
      firstUndoUsed: firstUndoUsed ?? this.firstUndoUsed,
    );
  }
}

// Krok 2: Vytvoření Notifieru (správce stavu)
// Obsahuje veškerou logiku pro úpravu stavu.
class ScoreManager extends Notifier<ScoreState> {
  late SharedPreferences _prefs;

  @override
  ScoreState build() {
    // Na začátku se pokusíme načíst uložené hodnoty
    _init();
    return ScoreState();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedCoins = _prefs.getInt('coins') ?? 0;
    final savedUndoTokens = _prefs.getInt('undoTokens') ?? 3; // Výchozí hodnota pro prvního hráče
    state = state.copyWith(coins: savedCoins, undoTokens: savedUndoTokens);
  }

  // --- Metody pro ukládání a načítání ---

  Future<void> _saveData() async {
    await _prefs.setInt('coins', state.coins);
    await _prefs.setInt('undoTokens', state.undoTokens);
  }

  // --- Metody pro bodování akcí ---

  void cardToTableau() {
    state = state.copyWith(score: state.score + 5);
  }

  void cardToFoundation({int cardCount = 1}) {
    state = state.copyWith(score: state.score + (15 * cardCount));
  }

  // --- Logika pro tlačítko Zpět (Undo) ---

  bool canUseUndo() {
    if (!state.firstUndoUsed) {
      return state.score >= 50;
    }
    return state.undoTokens > 0;
  }

  void useUndo() {
    if (!state.firstUndoUsed) {
      // První použití v této hře stojí 50 bodů
      if (state.score >= 50) {
        state = state.copyWith(
          score: state.score - 50,
          firstUndoUsed: true,
        );
      }
    } else {
      // Další použití vyžaduje token
      if (state.undoTokens > 0) {
        state = state.copyWith(undoTokens: state.undoTokens - 1);
        _saveData(); // Uložíme změnu počtu tokenů
      }
    }
  }

  // --- Konec hry a bonusy ---

  void calculateWinBonus(int remainingMoves) {
    final bonus = remainingMoves * 50;
    state = state.copyWith(score: state.score + bonus);
  }

  void endGame() {
    // Převod bodů na mince
    final newCoins = state.score ~/ 100;
    state = state.copyWith(coins: state.coins + newCoins);
    
    // Uložení a reset bodů pro další hru
    _saveData();
    resetForNewGame();
  }

  // --- Resetování pro novou hru ---

  void resetForNewGame() {
    state = state.copyWith(
      score: 0,
      firstUndoUsed: false,
    );
  }
}

// Krok 3: Vytvoření globálního Provideru
// Tímto providerem budeme přistupovat k ScoreManageru z celé aplikace.
final scoreManagerProvider = NotifierProvider<ScoreManager, ScoreState>(ScoreManager.new);
