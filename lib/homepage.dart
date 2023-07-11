import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutterprojects/barriers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bird.dart';
import 'cloud.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final player = AudioPlayer();

  static double birdYaxis = 0;
  int score = 0;
  int highscore = 0;
  double time = 0;
  double height = 0;
  double initialheight = birdYaxis;
  bool gamehasstartted = false;
  double barrierXtwo = barrierXone + 1.7;
  double barrierYone = 1.1;
  double barrierYtwo = 1.2;
  static double barrierXone = 1;


  void jump() {
    setState(() {
      time = 0;
      initialheight = birdYaxis;
    });
  }

  void resetGame() {
    Navigator.pop(context);
    setState(() {
      birdYaxis = 0;
      gamehasstartted = false;
      time = 0;
      initialheight = birdYaxis;
    });
  }

  void showdialog(String score) {
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
            actions: [
              Text("SCORE : $score",style: GoogleFonts.play(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),),
              SizedBox(width: 30,),
              InkWell(
                onTap: resetGame,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    padding: EdgeInsets.all(10),
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
    gamehasstartted = true;
    Timer.periodic(Duration(milliseconds: 60), (timer) {
      time = time + 0.05;
      height = -4.9 * time * time + 2.8 * time;
      setState(() {
        birdYaxis = initialheight - height;
      });

      setState(() {
        if (barrierXone < -2) {
          barrierXone += 4;
        } else {
          barrierXone -= 0.05;
        }
      });
      setState(() {
        if (barrierXtwo < -2) {
          barrierXtwo += 6;
        } else {
          barrierXtwo -= 0.05;
        }
      });

      if (birdYaxis < -1 || birdYaxis > 1) {
        timer.cancel();
        gamehasstartted = false;
        showdialog(score.toString());
        score = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        player.play(AssetSource('sounds/flap.mp3'));
        score++;
        if (score > highscore) {
          highscore = score;
        }
        if (gamehasstartted) {
          jump();
        } else {
          startGame();
        }
      },
      child: Scaffold(

        body:

        Column(
          children: [

            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  AnimatedContainer(
                    alignment: Alignment(0, birdYaxis),
                    color: Colors.blue,
                    duration: Duration(milliseconds: 0),
                    child: Bird(),
                  ),
                  Container(
                    alignment: Alignment(0, -0.26),
                    child: gamehasstartted
                        ? Text(" ")
                        : Text(
                            " T A P  T O  P L A Y !",
                            style: GoogleFonts.play(
                                fontSize: 30,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold),
                          ),

                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 0),
                    alignment: Alignment(barrierXone, barrierYone),
                    child: MyBarrier(
                      size: 300.0,
                    ),
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 0),
                    alignment: Alignment(barrierXone, -barrierYone),
                    child: cloud(),
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 0),
                    alignment: Alignment(barrierXtwo, barrierYtwo),
                    child: MyBarrier(
                      size: 220.0,
                    ),
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 0),
                    alignment: Alignment(barrierXtwo, -barrierYtwo),
                    child: cloud(),
                  )
                ],
              ),
            ),
            Container(
              height: 15,
              color: Colors.green,
            ),
            Expanded(
              child: Container(
                color: Colors.brown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "SCORE",
                          style: GoogleFonts.play(
                              fontSize: 30,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          score.toString(),
                          style: GoogleFonts.play(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "BEST ",
                          style: GoogleFonts.play(
                              fontSize: 30,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          highscore.toString(),
                          style: GoogleFonts.play(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            ),
            Container(
              width: double.infinity,
              color: Colors.brown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0,5,0,5),
                    child: Text("©Coded by Shuvam",style: GoogleFonts.poppins(fontWeight: FontWeight.bold,color: Colors.brown.shade800),),
                  ),
                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}
