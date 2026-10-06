import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterprojects/features/game/data/firebase_leaderboard.dart';
import 'package:flutterprojects/features/game/data/game_audio.dart';
import 'package:flutterprojects/features/game/domain/game_collision.dart';
import 'package:flutterprojects/features/game/presentation/widgets/bird.dart';
import 'package:flutterprojects/features/game/presentation/widgets/cloud.dart';
import 'package:flutterprojects/features/game/presentation/widgets/crow.dart';
import 'package:flutterprojects/features/game/presentation/widgets/lawn.dart';
import 'package:flutterprojects/features/game/presentation/widgets/tree_obstacle.dart';
import 'package:flutterprojects/features/game/presentation/widgets/wind_animation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const _sceneScoreInterval = 30;
  static const _sceneSkyPalettes = <List<Color>>[
    [Color(0xFFFFD7A3), Color(0xFFFFB98C), Color(0xFFFFE3BD)], // Morning
    [Color(0xFF45B9F3), Color(0xFF91D9F5), Color(0xFFD8F1FF)], // Afternoon
    [Color(0xFFFFA45C), Color(0xFFE97967), Color(0xFF594C78)], // Sunset
    [Color(0xFF18223D), Color(0xFF303D60), Color(0xFF68718A)], // Night
    [Color(0xFF536A7D), Color(0xFF8395A2), Color(0xFFC0C6C3)], // Rainy
  ];
  static const _sceneGroundPalettes = <List<Color>>[
    [Color(0xFF8CCF55), Color(0xFF55B844), Color(0xFF347F3E)],
    [Color(0xFF8CCF55), Color(0xFF55B844), Color(0xFF347F3E)],
    [Color(0xFF7FAE4C), Color(0xFF507E48), Color(0xFF354E3E)],
    [Color(0xFF435344), Color(0xFF303D38), Color(0xFF202A2B)],
    [Color(0xFF687B65), Color(0xFF4C6252), Color(0xFF34463D)],
  ];
  static const _sceneReflectionTints = [
    Color(0xFFFFD98E),
    Color(0xFFFFF3C4),
    Color(0xFFFFA77E),
    Color(0xFFB7CCFF),
    Color(0xFFB9E5F5),
  ];
  static const _worldScrollSpeed = 0.05;
  static const _simulationStep = 0.5;
  static const _playerNameKey = 'player_name';
  static const _groundAssetCycle = [
    'rock.png',
    'bush.png',
    'plant.png',
    'mushroom_red.png',
    'rock.png',
    'plant_purple.png',
    'bush.png',
    'mushroom_brown.png',
  ];

  final GameAudio _gameAudio = GameAudio();
  bool _audioPrepared = false;
  final math.Random _random = math.Random();
  final List<_CloudState> _clouds = [];
  final List<_GroundPropState> _groundProps = [];
  final List<_CrowState> _crows = [];
  final TextEditingController _nameController = TextEditingController();
  String? _playerName;

  double birdYaxis = 0;
  int score = 0;
  int _sceneIndex = 0;
  bool _cityBackdrop = false;
  int highscore = 0;
  double time = 0;
  double height = 0;
  double initialheight = 0;
  bool gamehasstartted = false;
  bool _isGameOver = false;
  double treeXone = 1;
  double treeXtwo = 2.7;
  double treeYone = 1.1;
  double treeYtwo = 1.2;
  int _firstTreeSize = 2;
  int _secondTreeSize = 4;
  int _firstTreeVariant = 0;
  int _secondTreeVariant = 1;
  double _lawnOffset = 0;
  final List<_RainDrop> _rainDrops = [];
  double _rainWind = 0;
  double _rainWindTarget = 0;
  int _rainWindChangeIn = 0;
  Size _playfieldSize = Size.zero;
  double _birdSize = 60;
  double _treeWidth = 60;
  Timer? _gameTimer;
  bool _isDying = false;
  double _deathVelocity = 0;
  double _birdRotation = 0;
  double _somersaultRemaining = 0;
  double _somersaultVelocity = 0;
  int _deathRestTicks = 0;

  double get _firstTreeHeight =>
      _playfieldSize.height * TreeObstacle.heightFactors[_firstTreeSize];

  double get _secondTreeHeight =>
      _playfieldSize.height * TreeObstacle.heightFactors[_secondTreeSize];

  Offset get _birdHitboxAlignment {
    if (_playfieldSize.height <= 0) return Offset(0, birdYaxis);
    final hitboxHeight = _birdSize * Bird.hitboxHeightFactor;
    final artworkOffset = Bird.visibleCenterOffsetFactor *
        _birdSize *
        2 /
        math.max(1, _playfieldSize.height - hitboxHeight);
    return Offset(0, birdYaxis - artworkOffset);
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) unawaited(BrowserContextMenu.disableContextMenu());
    unawaited(
      Future<void>.microtask(() {
        if (!mounted) return;
        setState(() => _audioPrepared = true);
      }),
    );
    _randomizeTrees();
    _resetClouds();
    _resetGroundProps();
    _resetRainDrops();
    _cityBackdrop = _random.nextInt(3) == 0;
  }

  void _resetRainDrops() {
    _rainDrops
      ..clear()
      ..addAll(List.generate(90, (_) => _randomRainDrop(randomY: true)));
  }

  _RainDrop _randomRainDrop({bool randomY = false}) => _RainDrop(
        x: _random.nextDouble(),
        y: randomY ? _random.nextDouble() : -_random.nextDouble() * 0.08,
        vx: (_random.nextDouble() - 0.5) * 0.001,
        vy: 0.0024 + _random.nextDouble() * 0.0035,
        gravity: 0.000018 + _random.nextDouble() * 0.000035,
        length: 5 + _random.nextDouble() * 15,
        opacity: 0.12 + _random.nextDouble() * 0.36,
        thickness: 0.45 + _random.nextDouble() * 0.8,
        depth: 0.25 + _random.nextDouble() * 0.75,
      );

  void _advanceRain() {
    if (_sceneIndex != 4) return;
    if (_rainWindChangeIn-- <= 0) {
      _rainWindTarget = (_random.nextDouble() - 0.5) * 0.0014;
      _rainWindChangeIn = 28 + _random.nextInt(54);
    }
    _rainWind += (_rainWindTarget - _rainWind) * 0.035;
    for (var index = 0; index < _rainDrops.length; index++) {
      final drop = _rainDrops[index];
      drop
        // Shared slow gusts, per-drop turbulence, and drag vary the paths.
        ..vx += (_rainWind * drop.depth - drop.vx) * 0.025 +
            (_random.nextDouble() - 0.5) * 0.000012
        ..vy += drop.gravity
        ..x += drop.vx
        ..y += drop.vy;
      if (drop.y > 1.04 || drop.x < -0.04 || drop.x > 1.04) {
        _rainDrops[index] = _randomRainDrop();
      }
    }
  }

  void _advanceScenesBetween(int previousScore, int newScore) {
    final firstMilestone = previousScore ~/ _sceneScoreInterval + 1;
    final lastMilestone = newScore ~/ _sceneScoreInterval;
    for (var milestone = firstMilestone;
        milestone <= lastMilestone;
        milestone++) {
      var nextScene = _random.nextInt(_sceneSkyPalettes.length - 1);
      if (nextScene >= _sceneIndex) nextScene++;
      _sceneIndex = nextScene;
      _cityBackdrop = _random.nextInt(3) == 0;
    }
  }

  void _advanceSomersault() {
    if (_somersaultRemaining <= 0) return;
    // Canvas coordinates grow downward, so negative angles spin anticlockwise.
    // Accelerate into the flip, then brake early enough to land upright.
    const angularAcceleration = 0.028;
    const maximumAngularSpeed = 0.42;
    final brakingSpeed = math.sqrt(
      2 * angularAcceleration * _somersaultRemaining,
    );
    final targetSpeed = math.min(maximumAngularSpeed, brakingSpeed);
    _somersaultVelocity += (targetSpeed - _somersaultVelocity) * 0.18;
    final angleStep = math.min(_somersaultRemaining, _somersaultVelocity);
    _somersaultRemaining -= angleStep;
    // Flutter's positive canvas rotation is clockwise, so subtract for a
    // counterclockwise somersault.
    _birdRotation -= angleStep;
    if (_somersaultRemaining < 0.01) {
      _somersaultRemaining = 0;
      _somersaultVelocity = 0;
      _birdRotation = 0;
    }
  }

  Future<void> _onRightClick() async {
    if (!_audioPrepared || _isDying || _isGameOver) return;
    _gameAudio.playTap();
    if (_playerName == null && !await _ensurePlayerName()) return;
    if (!mounted || _isDying || _isGameOver) return;
    setState(() {
      final previousScore = score;
      score += 3;
      _advanceScenesBetween(previousScore, score);
      if (score > highscore) highscore = score;
      _somersaultRemaining += math.pi * 2;
    });
    if (gamehasstartted) {
      jump();
    } else {
      startGame();
    }
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
            assetName: _groundAssetCycle[index],
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
      alignmentY: 0.28 + _random.nextDouble() * 0.68,
      sizeFactor: switch (assetName) {
        'bush.png' => 1.0 + _random.nextDouble() * 0.45,
        'mushroom_red.png' ||
        'mushroom_brown.png' =>
          0.65 + _random.nextDouble() * 0.3,
        'plant.png' || 'plant_purple.png' => 0.85 + _random.nextDouble() * 0.35,
        _ => 0.7 + _random.nextDouble() * 0.6,
      },
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
      _somersaultRemaining = 0;
      _somersaultVelocity = 0;
      _deathRestTicks = 0;
      gamehasstartted = false;
      _isGameOver = false;
      time = 0;
      initialheight = birdYaxis;
      treeXone = 1;
      treeXtwo = 2.7;
      _randomizeTrees();
      _resetClouds();
      _resetGroundProps();
      _sceneIndex = 0;
      _cityBackdrop = false;
      _resetRainDrops();
      _crows.clear();
    });
  }

  bool _hitsTree(double treeX, double treeY, double treeHeight) {
    if (_playfieldSize.isEmpty) return false;

    return overlapsTreeAtAlignment(
      playfieldSize: _playfieldSize,
      birdAlignment: _birdHitboxAlignment,
      // The animated bird artwork has transparent padding around its body.
      // Keep the collision box inside the sprite so contact follows the
      // visible bird more closely.
      birdSize: Size(
        _birdSize * Bird.hitboxWidthFactor,
        _birdSize * Bird.hitboxHeightFactor,
      ),
      treeAlignment: Offset(treeX, treeY),
      treeSize: Size(_treeWidth, treeHeight),
      canopyHeight: treeHeight * 0.34,
    );
  }

  void _onWindGustComplete() {
    if (!mounted || !gamehasstartted || _isDying || _isGameOver) return;

    final availableSlots = 3 - _crows.length;
    if (availableSlots <= 0) return;
    final count = math.min(availableSlots, 1 + _random.nextInt(2));
    for (var index = 0; index < count; index++) {
      _crows.add(
        _CrowState(
          alignmentX: -1.25 - index * 0.62,
          alignmentY: -0.78 + _random.nextDouble() * 1.56,
          wingPhase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _endGame(Timer timer) {
    timer.cancel();
    gamehasstartted = false;
    _isGameOver = true;
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
    _isGameOver = true;
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, _nameController.text.trim()),
            child: Text(
              'PLAY',
              style: GoogleFonts.play(fontWeight: FontWeight.bold),
            ),
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
    final leaderboard = ValueNotifier<_LeaderboardState>(
      const _LeaderboardState(loading: true),
    );
    _gameAudio.playGameOver();
    var dialogIsOpen = true;
    var requestIsComplete = false;
    unawaited(showdialog(finalScore, leaderboard).whenComplete(() {
      dialogIsOpen = false;
      if (requestIsComplete) leaderboard.dispose();
    }));

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
    if (mounted && dialogIsOpen) {
      leaderboard.value = _LeaderboardState(
        entries: topFive,
        error: leaderboardError,
      );
    }
    requestIsComplete = true;
    if (!dialogIsOpen) leaderboard.dispose();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    if (kIsWeb) unawaited(BrowserContextMenu.enableContextMenu());
    _nameController.dispose();
    unawaited(_gameAudio.dispose());
    super.dispose();
  }

  Future<void> showdialog(
    int finalScore,
    ValueNotifier<_LeaderboardState> leaderboard,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => PopScope<void>(
        canPop: false,
        child: ValueListenableBuilder<_LeaderboardState>(
          valueListenable: leaderboard,
          builder: (context, state, _) => AlertDialog(
            backgroundColor: Colors.brown.shade700,
            title: Center(
              child: Text(
                'GAME OVER',
                style: GoogleFonts.play(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'SCORE  $finalScore',
                      style: GoogleFonts.play(
                        fontSize: 21,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x29000000),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LEADERBOARD',
                          style: GoogleFonts.play(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (state.loading)
                          const _LeaderboardLoading()
                        else if (state.error != null)
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.play(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (state.entries.isEmpty)
                          Text(
                            'No scores yet. Be the first!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.play(color: Colors.white70),
                          )
                        else
                          for (var index = 0;
                              index < state.entries.length;
                              index++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${index + 1}.',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${state.entries[index]['name']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.play(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${state.entries[index]['score']}',
                                    style: GoogleFonts.play(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              OutlinedButton.icon(
                onPressed: () => _shareScore(finalScore),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('SHARE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
              ElevatedButton.icon(
                onPressed: resetGame,
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('PLAY AGAIN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.brown.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareScore(int finalScore) async {
    final playerName = _playerName ?? 'Player';
    final shareText =
        '$playerName scored $finalScore in Flappy Bird! Can you beat my score? '
        'Play here: https://fbirdsb.netlify.app/';
    final whatsappUrl = Uri.https('wa.me', '/', {'text': shareText});
    try {
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp to share.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp to share.')),
      );
    }
  }

  void startGame() {
    if (gamehasstartted) return;
    gamehasstartted = true;
    setState(() {});
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _advanceRain();
      if (_isDying) {
        if (birdYaxis < 0.88) {
          _deathVelocity += 0.018 * _simulationStep;
          birdYaxis =
              (birdYaxis + _deathVelocity * _simulationStep).clamp(-1.0, 0.88);
          _birdRotation =
              (_birdRotation + 0.14 * _simulationStep).clamp(0.0, 1.35);
        } else if (++_deathRestTicks >= 10) {
          birdYaxis = 0.88;
          setState(() {});
          _finishDying(timer);
          return;
        }
        setState(() {});
        return;
      }

      time = time + 0.05 * _simulationStep;
      _advanceSomersault();
      height = -4.9 * time * time + 2.8 * time;
      birdYaxis = initialheight - height;

      if (treeXone < -2) {
        treeXone += 4;
        _firstTreeSize = _random.nextInt(TreeObstacle.heightFactors.length);
        _firstTreeVariant = _random.nextInt(TreeObstacle.variantCount);
      } else {
        treeXone -= _worldScrollSpeed * _simulationStep;
      }
      if (treeXtwo < -2) {
        treeXtwo += 6;
        _secondTreeSize = _random.nextInt(TreeObstacle.heightFactors.length);
        _secondTreeVariant = _random.nextInt(TreeObstacle.variantCount);
      } else {
        treeXtwo -= _worldScrollSpeed * _simulationStep;
      }

      for (final cloud in _clouds) {
        cloud.alignmentX -= 0.008 * _simulationStep;
        if (cloud.alignmentX < -1.4) {
          final replacement = _randomCloud(1.35 + _random.nextDouble() * 0.2);
          cloud
            ..alignmentX = replacement.alignmentX
            ..alignmentY = replacement.alignmentY
            ..sizeFactor = replacement.sizeFactor;
        }
      }

      _lawnOffset = (_lawnOffset + _worldScrollSpeed / 2 * _simulationStep) % 1;
      for (final prop in _groundProps) {
        prop.alignmentX -= _worldScrollSpeed * _simulationStep;
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

      for (final crow in _crows) {
        crow
          ..alignmentX += _worldScrollSpeed * _simulationStep
          ..wingPhase =
              (crow.wingPhase + 0.25 * _simulationStep) % (math.pi * 2);
      }
      _crows.removeWhere((crow) => crow.alignmentX > 1.3);

      final hitTree = _hitsTree(treeXone, treeYone, _firstTreeHeight) ||
          _hitsTree(treeXtwo, treeYtwo, _secondTreeHeight);
      final crowSize = Size(_birdSize * 1.25, _birdSize * 0.8);
      final hitCrow = _crows.any(
        (crow) => overlapsAtAlignment(
          playfieldSize: _playfieldSize,
          firstAlignment: _birdHitboxAlignment,
          firstSize: Size(
            _birdSize * Bird.hitboxWidthFactor,
            _birdSize * Bird.hitboxHeightFactor,
          ),
          secondAlignment: Offset(crow.alignmentX, crow.alignmentY),
          secondSize: Size(crowSize.width * 0.96, crowSize.height * 0.88),
        ),
      );
      if (hitTree || hitCrow) {
        _startDying(timer);
        setState(() {});
        return;
      }
      // Alignment -1 puts the bird's top edge at the playfield edge. Let it
      // pass 60% of its height above the screen before ending the game.
      final topDeathAlignment = _playfieldSize.height <= 0
          ? -1.0
          : -1 - (_birdSize * 0.2 / _playfieldSize.height);
      if (birdYaxis < topDeathAlignment || birdYaxis > 1) {
        _endGame(timer);
        return;
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: _onRightClick,
      onTap: () async {
        if (!_audioPrepared) return;
        if (_isDying || _isGameOver) return;
        // Start playback in the tap's synchronous call stack for Safari.
        _gameAudio.playTap();
        if (_playerName == null && !await _ensurePlayerName()) return;
        if (!mounted) return;
        setState(() {
          final previousScore = score;
          score++;
          _advanceScenesBetween(previousScore, score);
          if (score > highscore) highscore = score;
        });
        if (gamehasstartted) {
          jump();
        } else {
          startGame();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact =
                      constraints.maxHeight < 520 || constraints.maxWidth < 360;
                  final labelFontSize = (constraints.maxWidth * 0.07)
                      .clamp(15.0, 30.0)
                      .toDouble();
                  final scoreFontSize = (constraints.maxWidth * 0.05)
                      .clamp(14.0, 22.0)
                      .toDouble();

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
                            _birdSize = (shortestSide * 0.16)
                                .clamp(40.0, 76.0)
                                .toDouble();
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
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 1800),
                                  curve: Curves.easeInOutCubic,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: _sceneSkyPalettes[_sceneIndex],
                                      stops: const [0, 0.62, 1],
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 1600),
                                      child: CustomPaint(
                                        key: ValueKey(
                                            'distant-scenery-$_sceneIndex-$_cityBackdrop'),
                                        painter: _SceneryPainter(
                                          scene: _sceneIndex,
                                          city: _cityBackdrop,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: WindAnimation(
                                    onGustComplete: _onWindGustComplete,
                                  ),
                                ),
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
                                    child: Bird(
                                      size: _birdSize,
                                      dying: _isDying,
                                      reflectionTint:
                                          _sceneReflectionTints[_sceneIndex],
                                    ),
                                  ),
                                ),
                                ..._crows.map(
                                  (crow) => Align(
                                    alignment: Alignment(
                                      crow.alignmentX,
                                      crow.alignmentY,
                                    ),
                                    child: Crow(
                                      width: _birdSize * 1.25,
                                      height: _birdSize * 0.8,
                                      wingPhase: crow.wingPhase,
                                    ),
                                  ),
                                ),
                                if (_sceneIndex == 4)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter:
                                            _RainPainter(drops: _rainDrops),
                                      ),
                                    ),
                                  ),
                                if (!gamehasstartted && !_isGameOver)
                                  Align(
                                    alignment: const Alignment(0, -0.26),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _audioPrepared
                                              ? 'T A P  T O  P L A Y !'
                                              : 'L O A D I N G  S O U N D ...',
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
                            final propBaseSize = (terrainWidth * 0.055)
                                .clamp(22.0, 70.0)
                                .toDouble();
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
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 1800),
                                  curve: Curves.easeInOutCubic,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: _sceneGroundPalettes[_sceneIndex],
                                      stops: const [0, 0.56, 1],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: terrainHeight * 0.82,
                                  child: CustomPaint(
                                    painter: LawnPainter(offset: _lawnOffset),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: math.min(58.0, terrainHeight * 0.34),
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/nature/grass_tile.png',
                                        ),
                                        repeat: ImageRepeat.repeat,
                                      ),
                                    ),
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
                                  final sizeMultiplier =
                                      switch (prop.assetName) {
                                    'bush.png' => 1.25,
                                    'mushroom_red.png' ||
                                    'mushroom_brown.png' =>
                                      0.62,
                                    'rock.png' => 0.75,
                                    _ => 0.9,
                                  };
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
                                          sizeMultiplier,
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
            const Positioned(
              right: 8,
              bottom: 4,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.48,
                  child: Text(
                    'Build with love - Shuvam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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

class _RainDrop {
  double x;
  double y;
  double vx;
  double vy;
  final double gravity;
  final double length;
  final double opacity;
  final double thickness;
  final double depth;

  _RainDrop({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.length,
    required this.opacity,
    required this.thickness,
    required this.depth,
  });
}

class _RainPainter extends CustomPainter {
  final List<_RainDrop> drops;

  const _RainPainter({required this.drops});

  @override
  void paint(Canvas canvas, Size size) {
    for (final drop in drops) {
      final paint = Paint()
        ..color = Color.fromRGBO(190, 215, 235, drop.opacity * drop.depth)
        ..strokeWidth = drop.thickness * (0.55 + drop.depth * 0.65)
        ..strokeCap = StrokeCap.round;
      final head = Offset(drop.x * size.width, drop.y * size.height);
      final velocity = Offset(drop.vx * size.width, drop.vy * size.height);
      final velocityLength = math.max(0.001, velocity.distance).toDouble();
      final tail = head - velocity / velocityLength * drop.length;
      canvas.drawLine(tail, head, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
}

class _SceneryPainter extends CustomPainter {
  final int scene;
  final bool city;

  const _SceneryPainter({required this.scene, required this.city});

  static const _mountainColors = [
    Color(0xAA8E716B),
    Color(0xAA507888),
    Color(0xAA8F5962),
    Color(0xCC131D38),
    Color(0xAA72828B),
  ];
  static const _treeColors = [
    Color(0xCC775D36),
    Color(0xCC528239),
    Color(0xCC774649),
    Color(0xCC17251F),
    Color(0xCC3E5448),
  ];
  static const _cityColors = [
    Color(0xCC72594E),
    Color(0xCC365B70),
    Color(0xCC70464F),
    Color(0xEE111A31),
    Color(0xCC475761),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final bandHeight = size.height * 0.72;
    canvas.save();
    canvas.translate(0, size.height - bandHeight);
    final scenerySize = Size(size.width, bandHeight);
    if (city) {
      _paintCity(canvas, scenerySize);
    } else {
      _paintMountains(canvas, scenerySize);
      _paintTrees(canvas, scenerySize);
    }
    canvas.restore();
  }

  void _paintMountains(Canvas canvas, Size size) {
    final distant = Path()
      ..moveTo(0, size.height * 0.78)
      ..lineTo(size.width * 0.18, size.height * 0.30)
      ..lineTo(size.width * 0.35, size.height * 0.73)
      ..lineTo(size.width * 0.56, size.height * 0.2)
      ..lineTo(size.width * 0.77, size.height * 0.76)
      ..lineTo(size.width * 0.91, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.67)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(distant, Paint()..color = _mountainColors[scene]);

    final nearer = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.13, size.height * 0.53)
      ..lineTo(size.width * 0.27, size.height * 0.77)
      ..lineTo(size.width * 0.45, size.height * 0.44)
      ..lineTo(size.width * 0.64, size.height * 0.83)
      ..lineTo(size.width * 0.82, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.8)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      nearer,
      Paint()..color = _treeColors[scene].withValues(alpha: 0.76),
    );
  }

  void _paintTrees(Canvas canvas, Size size) {
    final treePaint = Paint()..color = _treeColors[scene];
    for (var index = 0; index < 9; index++) {
      final x = size.width * (index / 8);
      final base = size.height;
      final trunkWidth = size.width * 0.012;
      final treeHeight = size.height * (0.48 + (index % 3) * 0.13);
      canvas.drawRect(
        Rect.fromLTWH(x - trunkWidth / 2, base - treeHeight * 0.45, trunkWidth,
            treeHeight * 0.45),
        treePaint,
      );
      final crown = Path()
        ..moveTo(x, base - treeHeight)
        ..lineTo(x + treeHeight * 0.24, base - treeHeight * 0.31)
        ..lineTo(x - treeHeight * 0.24, base - treeHeight * 0.31)
        ..close();
      canvas.drawPath(crown, treePaint);
      canvas.drawCircle(
          Offset(x, base - treeHeight * 0.53), treeHeight * 0.2, treePaint);
    }
  }

  void _paintCity(Canvas canvas, Size size) {
    final buildingPaint = Paint()..color = _cityColors[scene];
    final windowPaint = Paint()
      ..color = scene == 3 ? const Color(0xFFFFD987) : const Color(0x88FFF2C2);
    const buildingCount = 13;
    final buildingWidth = size.width / buildingCount;
    for (var index = 0; index < buildingCount; index++) {
      final x = index * buildingWidth;
      final heightFactor = [
        0.52,
        0.72,
        0.61,
        0.86,
        0.57,
        0.76,
        0.48,
        0.82,
        0.63,
        0.9,
        0.54,
        0.74,
        0.59
      ][index];
      final buildingHeight = size.height * heightFactor;
      final left = x + buildingWidth * 0.06;
      final width = buildingWidth * 0.88;
      final top = size.height - buildingHeight;
      canvas.drawRect(
        Rect.fromLTWH(left, top, width, buildingHeight),
        buildingPaint,
      );
      if (index % 4 == 1) {
        canvas.drawRect(
          Rect.fromLTWH(left + width * 0.32, top - size.height * 0.12,
              width * 0.36, size.height * 0.12),
          buildingPaint,
        );
      }
      for (var row = 0; row < 5; row++) {
        final windowY = top + size.height * (0.09 + row * 0.13);
        if (windowY > size.height - size.height * 0.06) break;
        for (var column = 0; column < 2; column++) {
          if ((index + row + column) % 3 == 0) continue;
          canvas.drawRect(
            Rect.fromLTWH(
              left + width * (0.2 + column * 0.42),
              windowY,
              width * 0.16,
              size.height * 0.045,
            ),
            windowPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SceneryPainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.city != city;
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

class _CrowState {
  double alignmentX;
  final double alignmentY;
  double wingPhase;

  _CrowState({
    required this.alignmentX,
    required this.alignmentY,
    required this.wingPhase,
  });
}

class _LeaderboardState {
  final bool loading;
  final List<Map<String, dynamic>> entries;
  final String? error;

  const _LeaderboardState({
    this.loading = false,
    this.entries = const [],
    this.error,
  });
}

class _LeaderboardLoading extends StatefulWidget {
  const _LeaderboardLoading();

  @override
  State<_LeaderboardLoading> createState() => _LeaderboardLoadingState();
}

class _LeaderboardLoadingState extends State<_LeaderboardLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: 0.9 + _controller.value * 0.2,
              child: child,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFFFFD166),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait, fetching leaderboard...',
            textAlign: TextAlign.center,
            style: GoogleFonts.play(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
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
