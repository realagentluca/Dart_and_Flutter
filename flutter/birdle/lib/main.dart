import 'package:flutter/material.dart';
import 'game.dart';

const AppLanguage kGameLanguage = AppLanguage.en;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WordRepository.setLanguage(kGameLanguage);
  await WordRepository.ensureLoaded();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Align(
            alignment: Alignment.center,
            child: Text("Birdle (${kGameLanguage.name})", style: Theme.of(context).textTheme.headlineLarge),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: const GamePage(),
            ),
          ),
        ),
      ),
    );
  }
}

class Tile extends StatelessWidget {
  const Tile(this.letter, this.hitType, {super.key});

  final String letter;
  final HitType hitType;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 60.0,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        color: switch (hitType) {
          HitType.hit => Colors.green.shade300,
          HitType.partial => Colors.amber.shade300,
          HitType.miss => Colors.grey.shade400,
          _ => Colors.white,
        },
        borderRadius: BorderRadius.all(const Radius.circular(15)),
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Game _game = Game();
  String? _errorMessage;
  bool _endDialogShown = false;

  bool _isWinningGuess(Word guess) {
    for (final letter in guess) {
      if (letter.type != HitType.hit) return false;
    }
    return true;
  }

  void _showEndDialog({required bool won}) {
    if (_endDialogShown) return;
    _endDialogShown = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(won ? 'Gewonnen' : 'Verloren'),
        content: Text(
          won
              ? 'Glückwunsch, du hast das Wort erraten.'
              : 'Leider verloren. Keine Versuche mehr übrig.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _checkGameEnd() {
    if (_game.didWin) {
      _showEndDialog(won: true);
      return;
    }
    if (_game.didLose) {
      _showEndDialog(won: false);
      return;
    }


    if (_game.guesses.isNotEmpty && _isWinningGuess(_game.previousGuess)) {
      _showEndDialog(won: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 5.0,
        children: [
          for (var guess in _game.guesses)
            Row(
              spacing: 5.0,
              children: [
                for (var letter in guess) Tile(letter.char, letter.type)
              ],
            ),
          GuessInput(
            onSubmitGuess: (String guess) {
              if (_game.isLegalGuess(guess)) {
                setState(() {
                  _game.guess(guess);
                  _errorMessage = null;
                  print('Solution: ${_game.hiddenWord}');
                });
                _checkGameEnd();
              } else {
                setState(() {
                  _errorMessage = 'Not a word';
                });
              }
            },
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class GuessInput extends StatefulWidget {
  const GuessInput({super.key, required this.onSubmitGuess});

  final void Function(String) onSubmitGuess;

  @override
  State<GuessInput> createState() => _GuessInputState();
}

class _GuessInputState extends State<GuessInput> {
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final text = _textEditingController.text;
    widget.onSubmitGuess(text);
    _textEditingController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              focusNode: _focusNode,
              maxLength: 5,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
              controller: _textEditingController,
              onSubmitted: (_) => _onSubmit(),
              autofocus: true,
            ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.send),
          onPressed: _onSubmit,
        )
      ],
    );
  }
}