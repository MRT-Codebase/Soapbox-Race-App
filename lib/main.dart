import 'dart:async';
import 'package:flutter/material.dart';
import 'mqtt_handler.dart';

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
  bool isGreenOn = false;
  bool isOrangeOn = false;
  bool isRedOn = false;

  bool raceStarted = false;

  Duration duration = const Duration();
  late Stopwatch stopwatch;
  bool isStopwatchRunning = false;

  late MQTTHandler mqttHandler;
  bool connectionStatus = false;

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
    mqttHandler = MQTTHandler();
    mqttHandler.receiveMsgNotifier.addListener(_mqttMsgChanged);
    mqttHandler.hostStatusNotifier.addListener(_hostConChanged);
  }

  void startRace() {
    // TODO: Improve this: Create better way to create interval function calls
    for (int i = 0; i < 3000; i += 500) {
      // Use Timer to create a delay
      Timer(Duration(milliseconds: i), () {
        if (i % 1000 == 0) {
          mqttHandler.publishMessage("GORB");
          setState(() {
            isGreenOn = true;
            isOrangeOn = true;
            isRedOn = true;
          });
        } else {
          mqttHandler.publishMessage("OFF");
          setState(() {
            isGreenOn = false;
            isOrangeOn = false;
            isRedOn = false;
          });
        }
      });
    }
    raceStarted = true;
  }

  void _mqttMsgChanged() {
    if (mqttHandler.receiveMsgNotifier.value == "Start" &&
        raceStarted == true) {
      startStopwatch();
    } else if (mqttHandler.receiveMsgNotifier.value == "Stop") {
      stopStopwatch();
      raceStarted = false;
    }
  }

  void _hostConChanged() {
    setState(() {
      connectionStatus = mqttHandler.hostStatusNotifier.value;
    });
  }

  void connectHost() {
    mqttHandler.connect('192.168.43.53');
  }

  void startStopwatch() {
    setState(() {
      isStopwatchRunning = true;
      stopwatch.start();
      updateDuration();
    });
  }

  void stopStopwatch() {
    setState(() {
      isStopwatchRunning = false;
      stopwatch.stop();
    });
  }

  void resetStopwatch() {
    setState(() {
      isStopwatchRunning = false;
      raceStarted = false;
      stopwatch.reset();
      duration = const Duration();
    });
  }

  void updateDuration() {
    if (isStopwatchRunning) {
      Future.delayed(const Duration(milliseconds: 30), () {
        if (isStopwatchRunning) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isGreenOn
                          ? const Color.fromARGB(255, 0, 255, 8)
                          : const Color.fromARGB(255, 50, 97, 0)),
                ),
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOrangeOn
                          ? const Color.fromARGB(255, 255, 165, 0)
                          : const Color.fromARGB(255, 145, 99, 15)),
                ),
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRedOn
                          ? const Color.fromARGB(255, 255, 0, 0)
                          : const Color.fromARGB(255, 134, 46, 46)),
                ),
              ],
            ),
            const SizedBox(height: 100.0),
            Text(
              durationToString(duration),
              style: const TextStyle(
                  fontSize: 72.0, color: Color.fromARGB(255, 255, 255, 255)),
            ),
            const SizedBox(height: 100.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF03DAC5),
                  child: IconButton(
                    icon: raceStarted
                        ? const Icon(Icons.pause)
                        : const Icon(Icons.play_arrow),
                    onPressed: raceStarted ? stopStopwatch : startRace,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 20.0),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF03DAC5),
                  child: IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: resetStopwatch,
                    color: Colors.black,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: connectHost,
        backgroundColor: connectionStatus
            ? const Color.fromARGB(255, 54, 121, 45)
            : const Color.fromARGB(255, 168, 51, 51),
        foregroundColor: Colors.black,
        child: const Icon(Icons.wifi),
      ),
    );
  }
}
