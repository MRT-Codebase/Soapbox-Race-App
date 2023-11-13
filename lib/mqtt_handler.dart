// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTHandler {
  final ValueNotifier<String> receiveMsgNotifier = ValueNotifier<String>("");
  final ValueNotifier<bool> hostStatusNotifier = ValueNotifier<bool>(false);
  final String raceStateTopic = 'raceState';
  final String lightStateTopic = 'lightState';

  late String _host;
  late MqttServerClient client;

  Future<void> connect(String host) async {
    _host = host;
    client = MqttServerClient(_host, '');
    client.setProtocolV311();
    // client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 2000; // milliseconds
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      print('SOAPBOX::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      print('SOAPBOX::socket exception - $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('SOAPBOX::Mosquitto client connected');
      client.subscribe(raceStateTopic, MqttQos.atMostOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        // TODO: Improve this: value notifier doesnt callback function if value remains same but in fact it got a new msg
        receiveMsgNotifier.value = pt;
        receiveMsgNotifier.value = "";

        // notifyListeners();

        print(
            'SOAPBOX::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      });

      // client.published!.listen((MqttPublishMessage message) {
      //   print(
      //       'SOAPBOX::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
      // });
    } else {
      print(
          'SOAPBOX::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
    }
  }

  void publishMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.publishMessage(
          lightStateTopic, MqttQos.atMostOnce, builder.payload!);
    }
  }

  void disconnect() {
    client.unsubscribe(raceStateTopic);
    client.unsubscribe(lightStateTopic);
    client.disconnect();
  }

  void onSubscribed(String topic) {
    print('SOAPBOX::Subscription confirmed for topic $topic');
  }

  void onDisconnected() {
    hostStatusNotifier.value = false;
    print('SOAPBOX::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('SOAPBOX::OnDisconnected callback is solicited, this is correct');
    } else {
      print(
          'SOAPBOX::OnDisconnected callback is unsolicited or none, this is incorrect - exiting');
    }
  }

  void onConnected() {
    hostStatusNotifier.value = true;
    print(
        'SOAPBOX::OnConnected client callback - Client connection was successful');
  }

  void pong() {
    print('SOAPBOX::Ping response client callback invoked');
  }
}
