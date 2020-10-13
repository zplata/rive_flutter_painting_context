import 'package:rive_flutter_text/rive_custom_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// We track if the animation is playing by whether or not the controller is
  /// running.
  bool get isPlaying => _controller?.isActive ?? false;

  Artboard _riveArtboard;
  RiveAnimationController _controller;
  Matrix4 _transform = Matrix4.identity();

  Future<void> _load() async {
    var data = await rootBundle.load('assets/distinctly_rive_animation.riv');
    var file = RiveFile();
    var success = file.import(data);
    if (success) {
      var artboard = file.mainArtboard;
      artboard.addController(_controller = SimpleAnimation('Untitled 1'));
      setState(() => _riveArtboard = artboard);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _riveArtboard == null
            ? const SizedBox()
            :
            // Draw Rive in a stack so that you can draw things after it in the
            // same transform space.
            Stack(
                children: [
                  Positioned.fill(
                    // Use a RivePaintContext instead of a Rive widget. This
                    // will let you provide a set of painting context objects
                    // that can register for callbacks when the transform of the
                    // referenced component changes or whenever Rive paints. The
                    // paint callback will be pre-transformed to the transform
                    // space of the component.
                    child: RiveCustomPainter(
                      artboard: _riveArtboard,
                      components: [
                        // Provide a RivePaintContext for any object you want to
                        // track the transformation of.
                        RivePaintContext(
                          componentName: 'ball',
                          transformChanged: (matrix) {
                            // If you want the text to scale, rotate, and
                            // translate with the object, just set the matrix
                            // directly.
                            // setState(
                            //   () {
                            //     _transform = matrix;
                            //   },
                            // );

                            // If you want it to only translate, extract the
                            // transformed translation and create a new matrix
                            // with only the translation.
                            setState(
                              () {
                                _transform = Matrix4.translation(
                                    matrix.transform3(Vector3.zero()));
                              },
                            );
                          },

                          // If you want to paint something directly in context
                          // of the component, you can do that by adding a
                          // 'paint' callback.

                          // paint: (canvas) {
                          //   canvas.drawRect(
                          //     Rect.fromCenter(
                          //       center: Offset.zero,
                          //       width: 100,
                          //       height: 100,
                          //     ),
                          //     Paint()..color = Colors.red,
                          //   );
                          // },
                        )
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Transform(
                      transform: _transform,
                      child: const Text(
                        'this is a ball',
                        style: TextStyle(
                          fontSize: 40,
                          color: Color(0xFFFF4477),
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
