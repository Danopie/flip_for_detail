import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme)
              .apply(bodyColor: Color(0xFF2C2C29))),
      home: ProductDetailPage(),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  double value = 0;

  @override
  void initState() {
    controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1));

    controller.addListener(() {
      setState(() {
        value = controller.value;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7bbbb7),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: handleDragUpdate,
        onVerticalDragEnd: handleDragEnd,
        onVerticalDragDown: handleDragStop,
        child: Builder(
          builder: (BuildContext context) {
            final mainAnimation = AlwaysStoppedAnimation(value);

            return Stack(
              children: [
                ProductOverview(
                  rotateAnimation: CurvedAnimation(
                      parent: mainAnimation, curve: Interval(0.0, 0.7)),
                ),
                ProductDescription(
                  rotateAnimation: CurvedAnimation(
                      parent: mainAnimation, curve: Interval(0.5, 0.7)),
                  borderAnimation: CurvedAnimation(
                      parent: mainAnimation, curve: Interval(0.5, 0.7)),
                  textAnimation: CurvedAnimation(
                    parent: mainAnimation,
                    curve: Interval(0.5, 1.0),
                  ),
                  shadowAnimation: CurvedAnimation(
                      parent: mainAnimation, curve: Interval(0.5, 0.7)),
                ),
                ProductTitle(
                    positionAnimation: CurvedAnimation(
                  parent: mainAnimation,
                  curve: Interval(0.4, 1.0),
                )),
                ViewDescriptionButton(
                  onPressed: () {
                    toggleDescription(true);
                  },
                  animation: CurvedAnimation(
                      parent: mainAnimation, curve: Interval(0.4, 0.6)),
                ),
                PageTitle(
                  animation: mainAnimation,
                  onBackPressed: () {
                    toggleDescription(false);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void handleDragStop(details) {
    if (controller.isAnimating) {
      controller.stop();
    }
  }

  void handleDragUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy / 500;
    setState(() {
      if (value - dy > 1) {
        value = 1;
      } else if (value - dy < 0) {
        value = 0;
      } else {
        value -= dy;
      }
    });
  }

  void handleDragEnd(DragEndDetails details) {
    final size = MediaQuery.of(context).size;
    // Calculate the velocity relative to the unit interval, [0,1],
    // used by the animation controller.
    final pixelsPerSecond = details.velocity.pixelsPerSecond;
    final unitsPerSecondX = pixelsPerSecond.dx / size.width;
    final unitsPerSecondY = pixelsPerSecond.dy / size.height;
    final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
    final unitVelocity = unitsPerSecond.distance;

    const spring = SpringDescription(
      mass: 10,
      stiffness: 1,
      damping: 1,
    );

    SpringSimulation simulation;

    if (unitsPerSecondY > 2) {
      print('_ProductDetailPageState.handlePanEnd: fling up');
      if (value != 0) {
        print(
            '_ProductDetailPageState.handlePanEnd: fling up -> show overview');
        simulation = SpringSimulation(spring, value, 0, -unitVelocity);
      }
    } else if (unitsPerSecondY < -2) {
      print('_ProductDetailPageState.handlePanEnd: fling down');
      if (value != 1) {
        print(
            '_ProductDetailPageState.handlePanEnd: fling down -> show detail');
        simulation = SpringSimulation(spring, value, 1, -unitVelocity);
      }
    } else {
      print('_ProductDetailPageState.handlePanEnd: freeze');
      if (value > 0.5 && value < 1) {
        print('_ProductDetailPageState.handlePanEnd: freeze -> show detail');
        simulation = SpringSimulation(spring, value, 1, -unitVelocity);
      } else if (value > 0 && value <= 0.5) {
        print('_ProductDetailPageState.handlePanEnd: freeze -> show overview');
        simulation = SpringSimulation(spring, value, 0, -unitVelocity);
      }
    }

    if (simulation != null) {
      controller.animateWith(simulation);
    }
  }

  void toggleDescription(bool open) {
    const spring = SpringDescription(
      mass: 10,
      stiffness: 1,
      damping: 2,
    );

    final double velocity = 5;

    SpringSimulation simulation;
    if (open) {
      simulation = SpringSimulation(spring, 0, 1, velocity);
    } else {
      simulation = SpringSimulation(spring, 1, 0, velocity);
    }

    controller.animateWith(simulation);
  }
}

class ViewDescriptionButton extends StatelessWidget {
  final Animation<double> animation;
  final Function onPressed;

  const ViewDescriptionButton({Key key, this.animation, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final margin = MediaQuery.of(context).size.height -
        Tween<double>(begin: 82, end: 120).evaluate(animation) +
        MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 23,
      top: margin,
      child: InkWell(
        onTap: () {
          if (animation.value < 0.1) {
            onPressed();
          }
        },
        child: FadeTransition(
          opacity: ReverseAnimation(animation),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Spec",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductOverview extends StatelessWidget {
  final Animation<double> rotateAnimation;

  const ProductOverview({Key key, this.rotateAnimation}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final guitarWidth = MediaQuery.of(context).size.width / 2;
    final guitarHeight = MediaQuery.of(context).size.height * 2 / 3;

    return Transform(
      alignment: Alignment(0, -0.2),
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(
            Tween<double>(begin: 0, end: -pi * 0.51).evaluate(rotateAnimation)),
      child: Container(
        child: Stack(
          children: [
            Container(
              color: Color(0xFFb6d4d2),
            ),
            Align(
              alignment: Alignment(0, 0),
              child: Container(
                width: guitarWidth - 120,
                height: guitarHeight,
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                      blurRadius: 60,
                      color: Colors.black26,
                      offset: Offset(0, 10))
                ]),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(-120, -30),
                child: Transform.rotate(
                  angle: pi / 2,
                  child: Text(
                    "FENDER",
                    style: TextStyle(
                      color: Color(0xFFd4d4b6),
                      shadows: [
                        Shadow(
                            color: Colors.black38,
                            blurRadius: 1,
                            offset: Offset(1, 1))
                      ],
                      fontSize: 90,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment(0, -0.3),
              child: Transform(
                transform: Matrix4.identity(),
                child: Image.asset(
                  "image/guit.png",
                  fit: BoxFit.contain,
                  width: guitarWidth,
                  height: guitarHeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final text = lorem(paragraphs: 1, words: 70);

class ProductDescription extends StatelessWidget {
  final Animation<double> shadowAnimation;
  final Animation<double> textAnimation;
  final Animation<double> rotateAnimation;
  final Animation<double> borderAnimation;

  const ProductDescription(
      {Key key,
      this.shadowAnimation,
      this.textAnimation,
      this.rotateAnimation,
      this.borderAnimation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 100 + MediaQuery.of(context).padding.top),
      child: Stack(
        children: [
          Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..scale(
                  1.0,
                  Tween<double>(begin: 0, end: 1.0).evaluate(rotateAnimation),
                  0.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(
                            Tween<double>(begin: 0.0, end: 0.5)
                                .evaluate(shadowAnimation)),
                        width: Tween<double>(begin: 100, end: 8)
                            .evaluate(borderAnimation))),
                color: Color(0xFFb6d4d2),
              ),
              child: Container(
                  color:
                      ColorTween(begin: Colors.black54, end: Colors.transparent)
                          .evaluate(shadowAnimation)),
            ),
          ),
          Transform.translate(
            offset: Tween<Offset>(begin: Offset(0, 500), end: Offset(0, 0))
                .evaluate(textAnimation),
            child: Container(
                padding: EdgeInsets.fromLTRB(36, 170, 36, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      text,
                      style: TextStyle(fontSize: 14),
                    ),
                    Container(
                      height: 18,
                    ),
                    Image.asset("image/playing_guit.jpg")
                  ],
                )),
          ),
        ],
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  final Animation<double> animation;
  final Function onBackPressed;

  const PageTitle({Key key, this.animation, this.onBackPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 12, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (animation.value > 0.9) {
                  onBackPressed();
                }
              },
              child: AnimatedIcon(
                size: 26,
                color: Color(0xFF2C2C29),
                icon: AnimatedIcons.menu_close,
                progress: animation,
              ),
            ),
          ),
          Text(
            "PRODUCT DETAIL",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF2C2C29),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}

class ProductTitle extends StatelessWidget {
  final Animation positionAnimation;

  const ProductTitle({Key key, this.positionAnimation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final margin = Tween<double>(
                begin: MediaQuery.of(context).size.height - 135,
                end: 100 + MediaQuery.of(context).padding.top + 50)
            .evaluate(positionAnimation) +
        MediaQuery.of(context).padding.bottom;
    return Positioned(
      top: margin,
      left: 35,
      child: Text(
        "Fender\nAmerican\nElite Strat",
        style: TextStyle(
          color: Color(0xFF2C2C29),
          fontSize: 26,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
