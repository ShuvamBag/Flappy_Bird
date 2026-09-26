import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterprojects/features/game/data/firebase_leaderboard.dart';
import 'package:flutterprojects/features/game/domain/game_collision.dart';
import 'package:flutterprojects/features/game/presentation/widgets/bird.dart';
import 'package:flutterprojects/features/game/presentation/widgets/cloud.dart';
import 'package:flutterprojects/features/game/presentation/widgets/lawn.dart';
import 'package:flutterprojects/features/game/presentation/widgets/tree_obstacle.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const _worldScrollSpeed = 0.05;
  static const _playerNameKey = 'player_name';

  final player = AudioPlayer();
  final math.Random _random = math.Random();
  final List<_CloudState> _clouds = [];
  final List<_GroundPropState> _groundProps = [];
  final TextEditingController _nameController = TextEditingController();
  String? _playerName;

  double birdYaxis = 0;
  int score = 0;
  int highscore = 0;
  double time = 0;
  double height = 0;
  double initialheight = 0;
  bool gamehasstartted = false;
  double treeXone = 1;
  double treeXtwo = 2.7;
  double treeYone = 1.1;
  double treeYtwo = 1.2;
  int _firstTreeSize = 2;
  int _secondTreeSize = 4;
  int _firstTreeVariant = 0;
  int _secondTreeVariant = 1;
  double _lawnOffset = 0;
  Size _playfieldSize = Size.zero;
  double _birdSize = 60;
  double _treeWidth = 60;
  Timer? _gameTimer;
  bool _isDying = false;
  double _deathVelocity = 0;
  double _birdRotation = 0;
  int _deathRestTicks = 0;

  double get _firstTreeHeight =>
      _playfieldSize.height * TreeObstacle.heightFactors[_firstTreeSize];

  double get _secondTreeHeight =>
      _playfieldSize.height * TreeObstacle.heightFactors[_secondTreeSize];

  @override
  void initState() {
    super.initState();
    _randomizeTrees();
    _resetClouds();
    _resetGroundProps();
  }

  void _randomizeTrees() {
    _firstTreeSize = _random.nextInt(TreeObstacle.heightFactors.length);
    _secondTreeSize = _random.nextInt(TreeObstacle.heightFactors.length);
    _firstTreeVariant = _random.nextInt(TreeObstacle.variantCount);
    _secondTreeVariant = _random.nextInt(TreeObstacle.variantCount);
  }

  void _resetClouds() {
    _clouds
      ..clear()
      ..addAll(
        List.generate(
          3,
          (index) => _randomCloud(-1.2 + index * 1.2),
        ),
      );
  }

  _CloudState _randomCloud(double startX) {
    return _CloudState(
      alignmentX: startX + _random.nextDouble() * 0.4 - 0.2,
      alignmentY: -0.9 + _random.nextDouble() * 0.55,
      sizeFactor: 0.13 + _random.nextDouble() * 0.11,
    );
  }

  void _resetGroundProps() {
    _groundProps
      ..clear()
      ..addAll(
        List.generate(
          8,
          (index) => _randomGroundProp(
            -1.1 + index * 0.32,
            assetName: index.isEven ? 'rock.png' : 'bush.png',
          ),
        ),
      );
  }

  _GroundPropState _randomGroundProp(
    double startX, {
    required String assetName,
  }) {
    return _GroundPropState(
      alignmentX: startX + _random.nextDouble() * 0.2 - 0.1,
      alignmentY: -0.85 + _random.nextDouble() * 1.7,
      sizeFactor: assetName == 'bush.png'
          ? 1.0 + _random.nextDouble() * 0.45
          : 0.7 + _random.nextDouble() * 0.6,
      assetName: assetName,
    );
  }

  void jump() {
    setState(() {
      time = 0;
      initialheight = birdYaxis;
    });
  }

  void resetGame() {
    Navigator.pop(context);
    _gameTimer?.cancel();
    setState(() {
      birdYaxis = 0;
      _isDying = false;
      _deathVelocity = 0;
      _birdRotation = 0;
      _deathRestTicks = 0;
      gamehasstartted = false;
      time = 0;
      initialheight = birdYaxis;
      treeXone = 1;
      treeXtwo = 2.7;
      _randomizeTrees();
      _resetClouds();
      _resetGroundProps();
    });
  }

  bool _hitsTree(double treeX, double treeY, double treeHeight) {
    if (_playfieldSize.isEmpty) return false;

    return overlapsTreeAtAlignment(
      playfieldSize: _playfieldSize,
      birdAlignment: Offset(0, birdYaxis),
      birdSize: Size.square(_birdSize),
      treeAlignment: Offset(treeX, treeY),
      treeSize: Size(_treeWidth, treeHeight),
      canopyHeight: treeHeight * 0.34,
    );
  }

  void _endGame(Timer timer) {
    timer.cancel();
    gamehasstartted = false;
    final finalScore = score;
    setState(() {
      score = 0;
    });
    unawaited(_presentGameOver(finalScore));
  }

  void _startDying(Timer timer) {
    _isDying = true;
    _deathVelocity = 0.025;
    _deathRestTicks = 0;
  }

  void _finishDying(Timer timer) {
    timer.cancel();
    _isDying = false;
    gamehasstartted = false;
    final finalScore = score;
    setState(() {
      score = 0;
    });
    unawaited(_presentGameOver(finalScore));
  }

  Future<bool> _ensurePlayerName() async {
    final preferences = await SharedPreferences.getInstance();
    final savedName = preferences.getString(_playerNameKey)?.trim();
    if (savedName != null && savedName.isNotEmpty) {
      _playerName = savedName;
      return true;
    }
    if (!mounted) return false;

    final enteredName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.brown.shade700,
        title: Text(
          'ENTER YOUR NAME',
          style: GoogleFonts.play(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          maxLength: 16,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Player name',
            hintStyle: TextStyle(color: Colors.white70),
            counterStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _nameController.text.trim()),
            child: const Text('PLAY'),
          ),
        ],
      ),
    );

    final name = enteredName?.trim();
    if (name == null || !mounted) return false;
    _playerName = name.isEmpty ? 'Player' : name;
    await preferences.setString(_playerNameKey, _playerName!);
    return true;
  }

  Future<void> _presentGameOver(int finalScore) async {
    var topFive = <Map<String, dynamic>>[];
    String? leaderboardError;
    try {
      await FirebaseLeaderboard.instance.submitScore(
        name: _playerName ?? 'Player',
        score: finalScore,
      );
      topFive = await FirebaseLeaderboard.instance.getTopFive();
    } catch (_) {
      leaderboardError = 'ONLINE LEADERBOARD UNAVAILABLE';
    }
    if (!mounted) return;
    showdialog(finalScore, topFive, leaderboardError: leaderboardError);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _nameController.dispose();
    unawaited(player.dispose());
    super.dispose();
  }

  void showdialog(
    int finalScore,
    List<Map<String, dynamic>> leaderboard, {
    String? leaderboardError,
  }) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          player.play(AssetSource('sounds/negative_beeps-6008.mp3'));
          return AlertDialog(
            backgroundColor: Colors.brown.shade700,
            title: Center(
              child: Text(
                "G A M E  O V E R ",
                style: GoogleFonts.play(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCORE : $finalScore',
                  style: GoogleFonts.play(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'TOP 5',
                  style: GoogleFonts.play(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (leaderboardError != null)
                  Text(
                    leaderboardError,
                    style: GoogleFonts.play(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  for (var index = 0; index < leaderboard.length; index++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${index + 1}. ${leaderboard[index]['name']}  ${leaderboard[index]['score']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.play(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ],
            ),
            actions: [
              InkWell(
                onTap: resetGame,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: Text(
                      "PLAY AGAIN",
                      style: GoogleFonts.play(
                          fontSize: 10,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          );
        });
  }

  void startGame() {
    if (gamehasstartted) return;
    gamehasstartted = true;
    setState(() {});
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isDying) {
        if (birdYaxis < 0.88) {
          _deathVelocity += 0.018;
          birdYaxis = (birdYaxis + _deathVelocity).clamp(-1.0, 0.88);
          _birdRotation = (_birdRotation + 0.14).clamp(0.0, 1.35);
        } else if (++_deathRestTicks >= 5) {
          birdYaxis = 0.88;
          setState(() {});
          _finishDying(timer);
          return;
        }
        setState(() {});
        return;
      }

      time = time + 0.05;
      height = -4.9 * time * time + 2.8 * time;
      birdYaxis = initialheight - height;

      if (treeXone < -2) {
        treeXone += 4;
        _firstTreeSize = _random.nextInt(TreeObstacle.heightFactors.length);
        _firstTreeVariant = _random.nextInt(TreeObstacle.variantCount);
      } else {
        treeXone -= _worldScrollSpeed;
      }
      if (treeXtwo < -2) {
        treeXtwo += 6;
        _secondTreeSize = _random.nextInt(TreeObstacle.heightFactors.length);
        _secondTreeVariant = _random.nextInt(TreeObstacle.variantCount);
      } else {
        treeXtwo -= _worldScrollSpeed;
      }

      for (final cloud in _clouds) {
        cloud.alignmentX -= 0.008;
        if (cloud.alignmentX < -1.4) {
          final replacement = _randomCloud(1.35 + _random.nextDouble() * 0.2);
          cloud
            ..alignmentX = replacement.alignmentX
            ..alignmentY = replacement.alignmentY
            ..sizeFactor = replacement.sizeFactor;
        }
      }

      _lawnOffset = (_lawnOffset + _worldScrollSpeed / 2) % 1;
      for (final prop in _groundProps) {
        prop.alignmentX -= _worldScrollSpeed;
        if (prop.alignmentX < -1.2) {
          final replacement = _randomGroundProp(
            1.08 + _random.nextDouble() * 0.12,
            assetName: prop.assetName,
          );
          prop
            ..alignmentX = replacement.alignmentX
            ..alignmentY = replacement.alignmentY
            ..sizeFactor = replacement.sizeFactor;
        }
      }

      final hitTree = _hitsTree(treeXone, treeYone, _firstTreeHeight) ||
          _hitsTree(treeXtwo, treeYtwo, _secondTreeHeight);
      if (hitTree) {
        _startDying(timer);
        setState(() {});
        return;
      }
      if (birdYaxis < -1 || birdYaxis > 1) {
        _endGame(timer);
        return;
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isDying) return;
        if (_playerName == null && !await _ensurePlayerName()) return;
        if (!mounted) return;
        player.play(AssetSource('sounds/flap.mp3'));
        setState(() {
          score++;
          if (score > highscore) highscore = score;
        });
        if (gamehasstartted) {
          jump();
        } else {
          startGame();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxHeight < 520 || constraints.maxWidth < 360;
              final labelFontSize =
                  (constraints.maxWidth * 0.07).clamp(15.0, 30.0).toDouble();
              final scoreFontSize =
                  (constraints.maxWidth * 0.05).clamp(14.0, 22.0).toDouble();

              return Column(
                children: [
                  Expanded(
                    flex: isCompact ? 5 : 4,
                    child: LayoutBuilder(
                      builder: (context, fieldConstraints) {
                        _playfieldSize = Size(
                          fieldConstraints.maxWidth,
                          fieldConstraints.maxHeight,
                        );
                        final shortestSide = math.min(
                          fieldConstraints.maxWidth,
                          fieldConstraints.maxHeight,
                        );
                        _birdSize =
                            (shortestSide * 0.16).clamp(40.0, 76.0).toDouble();
                        _treeWidth = (fieldConstraints.maxWidth * 0.17)
                            .clamp(52.0, 92.0)
                            .toDouble();
                        final promptFontSize =
                            (fieldConstraints.maxWidth * 0.075)
                                .clamp(16.0, 30.0)
                                .toDouble();

                        return Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.none,
                          children: [
                            const ColoredBox(color: Colors.blue),
                            ..._clouds.map(
                              (cloud) => Align(
                                alignment: Alignment(
                                  cloud.alignmentX,
                                  cloud.alignmentY,
                                ),
                                child: Cloud(
                                  size: (shortestSide * cloud.sizeFactor)
                                      .clamp(40.0, 112.0)
                                      .toDouble(),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment(treeXone, treeYone),
                              child: TreeObstacle(
                                width: _treeWidth,
                                height: _firstTreeHeight,
                                variant: _firstTreeVariant,
                              ),
                            ),
                            Align(
                              alignment: Alignment(treeXtwo, treeYtwo),
                              child: TreeObstacle(
                                width: _treeWidth,
                                height: _secondTreeHeight,
                                variant: _secondTreeVariant,
                              ),
                            ),
                            Align(
                              alignment: Alignment(0, birdYaxis),
                              child: Transform.rotate(
                                angle: _birdRotation,
                                child: Bird(size: _birdSize, dying: _isDying),
                              ),
                            ),
                            if (!gamehasstartted)
                              Align(
                                alignment: const Alignment(0, -0.26),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'T A P  T O  P L A Y !',
                                      style: GoogleFonts.play(
                                        fontSize: promptFontSize,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: isCompact ? 2 : 3,
                    child: LayoutBuilder(
                      builder: (context, terrainConstraints) {
                        final terrainWidth = terrainConstraints.maxWidth;
                        final terrainHeight = terrainConstraints.maxHeight;
                        final propBaseSize =
                            (terrainWidth * 0.055).clamp(22.0, 70.0).toDouble();
                        final terrainLabelFontSize = math
                            .min(labelFontSize, terrainHeight * 0.21)
                            .clamp(12.0, 30.0)
                            .toDouble();
                        final terrainScoreFontSize = math
                            .min(scoreFontSize, terrainHeight * 0.15)
                            .clamp(12.0, 22.0)
                            .toDouble();

                        return Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.none,
                          children: [
                            const ColoredBox(color: Color(0xFF49B83F)),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: LawnPainter(offset: _lawnOffset),
                              ),
                            ),
                            Positioned(
                              key: const ValueKey('grass-fringe'),
                              top: -16,
                              left: 0,
                              right: 0,
                              height: 44,
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: GrassFringePainter(
                                    offset: _lawnOffset,
                                  ),
                                ),
                              ),
                            ),
                            ..._groundProps.asMap().entries.map((entry) {
                              final prop = entry.value;
                              final isBush = prop.assetName == 'bush.png';
                              return Align(
                                key: ValueKey(
                                  'ground-prop-${entry.key}-${prop.assetName}',
                                ),
                                alignment: Alignment(
                                  prop.alignmentX,
                                  prop.alignmentY,
                                ),
                                child: Image.asset(
                                  'assets/images/nature/${prop.assetName}',
                                  width: propBaseSize *
                                      prop.sizeFactor *
                                      (isBush ? 1.25 : 0.75),
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                ),
                              );
                            }),
                            Positioned(
                              top: terrainHeight * 0.12,
                              left: terrainWidth * 0.27,
                              right: terrainWidth * 0.27,
                              bottom: terrainHeight * 0.1,
                              child: Row(
                                children: [
                                  _ScoreDisplay(
                                    label: 'SCORE',
                                    value: score,
                                    labelFontSize: terrainLabelFontSize,
                                    scoreFontSize: terrainScoreFontSize,
                                  ),
                                  _ScoreDisplay(
                                    label: 'BEST',
                                    value: highscore,
                                    labelFontSize: terrainLabelFontSize,
                                    scoreFontSize: terrainScoreFontSize,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CloudState {
  double alignmentX;
  double alignmentY;
  double sizeFactor;

  _CloudState({
    required this.alignmentX,
    required this.alignmentY,
    required this.sizeFactor,
  });
}

class _GroundPropState {
  double alignmentX;
  double alignmentY;
  double sizeFactor;
  String assetName;

  _GroundPropState({
    required this.alignmentX,
    required this.alignmentY,
    required this.sizeFactor,
    required this.assetName,
  });
}

class _ScoreDisplay extends StatelessWidget {
  final String label;
  final int value;
  final double labelFontSize;
  final double scoreFontSize;

  const _ScoreDisplay({
    required this.label,
    required this.value,
    required this.labelFontSize,
    required this.scoreFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.play(
                  fontSize: labelFontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                        color: Colors.black87,
                        blurRadius: 4,
                        offset: Offset(1, 2)),
                  ],
                ),
              ),
              SizedBox(height: (labelFontSize * 0.4).clamp(4.0, 12.0)),
              Text(
                value.toString(),
                style: GoogleFonts.play(
                  fontSize: scoreFontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                        color: Colors.black87,
                        blurRadius: 4,
                        offset: Offset(1, 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
