// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTHandler {
  final ValueNotifier<String> valueNotifier = ValueNotifier<String>("");
  final String isRunningTopic = 'soapBox/isRunning';
  final String lightTopic = 'soapBox/light';
  final String _host;

  late MqttServerClient client;

  MQTTHandler(String host) : _host = host;

  Future<void> connect() async {
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
    } else {
      print(
          'SOAPBOX::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      exit(-1);
    }

    client.subscribe(isRunningTopic, MqttQos.atMostOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      valueNotifier.value = pt;
      // notifyListeners();

      print(
          'SOAPBOX::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });

    // client.published!.listen((MqttPublishMessage message) {
    //   print(
    //       'SOAPBOX::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    // });
  }

  void publishMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.publishMessage(lightTopic, MqttQos.atMostOnce, builder.payload!);
    }
  }

  void disconnect() {
    client.unsubscribe(isRunningTopic);
    client.unsubscribe(lightTopic);
    client.disconnect();
  }

  void onSubscribed(String topic) {
    print('SOAPBOX::Subscription confirmed for topic $topic');
  }

  void onDisconnected() {
    print('SOAPBOX::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('SOAPBOX::OnDisconnected callback is solicited, this is correct');
    } else {
      print(
          'SOAPBOX::OnDisconnected callback is unsolicited or none, this is incorrect - exiting');
      exit(-1);
    }
  }

  void onConnected() {
    print(
        'SOAPBOX::OnConnected client callback - Client connection was successful');
  }

  void pong() {
    print('SOAPBOX::Ping response client callback invoked');
  }
}
