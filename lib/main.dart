import 'package:flutter/material.dart';

void main() {
  runApp(const MQTTProjectApp());
}

class MQTTProjectApp extends StatelessWidget {
  const MQTTProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MQTTProjectAppScreen(),
    );
  }
}

class MQTTProjectAppScreen extends StatefulWidget {
  const MQTTProjectAppScreen({super.key});

  @override
  State<MQTTProjectAppScreen> createState() => _MQTTProjectAppScreenState();
}

class _MQTTProjectAppScreenState extends State<MQTTProjectAppScreen> {
  bool isRunning = false;
  Duration duration = const Duration();
  late Stopwatch stopwatch;

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
  }

  void start() {
    setState(() {
      isRunning = true;
      stopwatch.start();
      updateDuration();
    });
  }

  void stop() {
    setState(() {
      isRunning = false;
      stopwatch.stop();
    });
  }

  void reset() {
    setState(() {
      isRunning = false;
      stopwatch.reset();
      duration = const Duration();
    });
  }

  void updateDuration() {
    if (isRunning) {
      Future.delayed(const Duration(milliseconds: 30), () {
        if (isRunning) {
          setState(() {
            duration = stopwatch.elapsed;
            updateDuration();
          });
        }
      });
    }
  }

  String durationToString(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitMilliseconds =
        twoDigits(duration.inMilliseconds.remainder(1000) ~/ 10);

    return '$twoDigitMinutes:$twoDigitSeconds.$twoDigitMilliseconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF272727),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              durationToString(duration),
              style: const TextStyle(
                  fontSize: 72.0, color: Color.fromARGB(255, 255, 255, 255)),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF03DAC5),
                  child: IconButton(
                    icon: isRunning
                        ? const Icon(Icons.pause)
                        : const Icon(Icons.play_arrow),
                    onPressed: isRunning ? stop : start,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 20.0),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF03DAC5),
                  child: IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: reset,
                    color: Colors.black,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
