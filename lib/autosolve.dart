library autosolve_client;

import 'dart:async';

import 'package:autosolve_client/autosolve_options.dart';
import 'package:autosolve_client/model/captcha_cancel_request.dart';
import 'package:autosolve_client/validation/autosolve_status.dart';
import 'package:autosolve_client/validation/autosolve_validate.dart';
import 'package:autosolve_client/validation/autosolve_validation_response.dart';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:eventify/eventify.dart';
import 'package:flutter/services.dart';

import 'autosolve_constants.dart';
import 'model/captcha_cancel_response.dart';
import 'model/captcha_token_request.dart';
import 'model/captcha_token_response.dart';

class AutoSolve {
  AutoSolveOptions options;
  String accountId;
  String routingKey;
  String solverName;
  String receiverQueueName;
  String cancelSolverQueueName;
  String receiverQueueRoute;
  String cancelReceiverRoute;
  String tokenSendRoute;
  String cancelSendRoute;
  String directExchangeName;
  String fanoutExchangeName;
  bool debug;
  Client client;
  ConnectionSettings settings;
  Channel directChannel;
  Channel fanoutChannel;
  Exchange directExchange;
  Exchange fanoutExchange;
  final EventEmitter ee;
  bool connected = false;
  int connectionAttempts = 0;
  List<CaptchaTokenRequest> backlog = [];
  Timer reconnectDelayTimer;

  AutoSolve(this.ee, bool debug) {
    this.debug = debug;
  }

  Future<AutoSolveValidationResponse> init(AutoSolveOptions options) async {
    this.options = options;
    AutoSolveValidationResponse validationResponse =
        await AutoSolveValidate.validate(options);
    if (validationResponse.autoSolveStatus ==
        AutoSolveStatus.ValidationSuccess) {
      try {
        initCredentials(validationResponse);
        this.client = new Client(settings: this.settings);
        AutoSolveStatus resultStatus = await _createChannels() &&
                await _declareExchanges() &&
                await _bindQueueConsumer()
            ? AutoSolveStatus.Connected
            : AutoSolveStatus.FailedConnection;
        connected = true;
        connectionAttempts = 0;
        _establishErrorListeners();
        return new AutoSolveValidationResponse(
            resultStatus, validationResponse.validationResponse);
      } catch (e) {
        log("Error in AutoSolve init :: " + e.toString(), true);
        return new AutoSolveValidationResponse(
            AutoSolveStatus.FailedConnection, null);
      }
    } else {
      connectionAttempts += 1;
      return validationResponse;
    }
  }

  Future<void> _establishErrorListeners() async {
    this.client.registerHeartbeatCallback(this._handleHeartbeatError);
    this.client.errorListener((error) {
      print("Error received");
      print(error);
    });
  }

  void _generateRoutingAndQueueNames() {
    this.receiverQueueName =
        _buildPrefixWithCredentials(AutoSolveConstants.RECEIVER_QUEUE_NAME);
    this.receiverQueueRoute =
        _buildPrefixWithCredentials(AutoSolveConstants.TOKEN_RECEIVE_ROUTE);
    this.cancelReceiverRoute =
        _buildPrefixWithCredentials(AutoSolveConstants.CANCEL_RECEIVE_ROUTE);
    this.directExchangeName =
        _getNameWithAccountId(AutoSolveConstants.DIRECT_EXCHANGE);
    this.fanoutExchangeName =
        _getNameWithAccountId(AutoSolveConstants.FANOUT_EXCHANGE);

    this.tokenSendRoute =
        _getRouteToOneClick(AutoSolveConstants.TOKEN_SEND_ROUTE);
    this.cancelSendRoute =
        _getRouteToOneClick(AutoSolveConstants.CANCEL_SEND_ROUTE);
  }

  void initCredentials(AutoSolveValidationResponse validationResponse) {
    this.routingKey = options.accessToken.replaceAll("-", "");
    this.accountId = _getAccountId();

    _generateRoutingAndQueueNames();

    this.settings = new ConnectionSettings(
        host: AutoSolveConstants.HOSTNAME,
        maxConnectionAttempts: 1,
        reconnectWaitTime:
            new Duration(milliseconds: AutoSolveConstants.RECONNECT_WAIT_TIME),
        virtualHost: AutoSolveConstants.VHOST,
        authProvider:
            new PlainAuthenticator(this.accountId, options.accessToken),
        heartbeat: AutoSolveConstants.HEARTBEAT);
  }

  Future<bool> _createChannels() async {
    this.directChannel = await this.client.channel();
    this.fanoutChannel = await this.client.channel();
    log("Created Channel", false);
    return true;
  }

  Future<bool> _declareExchanges() async {
    await this
        .directChannel
        .exchange(this.directExchangeName, ExchangeType.DIRECT,
            passive: true, durable: true)
        .then((Exchange exchange) => this.directExchange = exchange);
    await this
        .fanoutChannel
        .exchange(this.fanoutExchangeName, ExchangeType.FANOUT,
            passive: true, durable: true)
        .then((Exchange exchange) => this.fanoutExchange = exchange);
    log("Exchanges Declared", false);
    return true;
  }

  Future<bool> _bindQueueConsumer() async {
    List<String> tokenReceiverList = new List<String>();
    tokenReceiverList.add(this.receiverQueueRoute);
    tokenReceiverList.add(this.cancelReceiverRoute);
    this
        .directExchange
        .bindQueueConsumer(this.receiverQueueName, tokenReceiverList)
        .then((consumer) {
      consumer.listen((AmqpMessage message) => _receiveMessage(message));
    });
    log("Listening for tokens at " + this.receiverQueueRoute, false);
    log("Bound consumer to routing keys", false);
    return true;
  }

  Future<dynamic> closeConnection() async {
    this.connected = false;
    if (this.client != null) {
      await this.client.close();
      return new Timer(
          Duration(milliseconds: AutoSolveConstants.MAX_WAIT_CONNECTION_CLOSE),
          () {
        return;
      });
    }

    return;
  }

  void send(CaptchaTokenRequest request) {
    request.apiKey = this.options.apiKey;
    request.createdAt = _currentTimeInSeconds();
    this._sendCaptchaRequest(request);
  }

  void sendCancel(String taskId) {
    CaptchaCancelRequest cancelRequest = CaptchaCancelRequest(
        taskId, this.options.apiKey, this.options.cancelResponseRequired);
    String json = cancelRequest.toJsonString();
    this.fanoutExchange.publish(json, this.cancelSendRoute);
    log("Sending Cancel", false);
  }

  void sendCancelAll() {
    CaptchaCancelRequest cancelRequest =
        CaptchaCancelRequest(null, this.options.apiKey, null);
    String json = cancelRequest.toJsonStringCancelAll();
    this.fanoutExchange.publish(json, this.cancelSendRoute);
    log("Sending Cancel All", false);
  }

  void _sendCaptchaRequest(CaptchaTokenRequest request) {
    if (this.connected) {
      log("Sending token to :: " + this.tokenSendRoute, false);
      String json = request.toJsonString();
      log(json, false);
      this.directExchange.publish(json, this.tokenSendRoute);
    } else {
      this.log("Not connected. Pushing to backlog", true);
      this._pushToBacklog(request);
    }
  }

  void _receiveMessage(AmqpMessage message) {
    if (message.routingKey == this.receiverQueueRoute) {
      _receiveTokenMessage(message);
    } else {
      _receiveCancelMessage(message);
    }
  }

  void _receiveTokenMessage(AmqpMessage message) {
    log("Received Token Response : ${message.payloadAsJson}", false);
    CaptchaTokenResponse response =
        CaptchaTokenResponse.fromJson(message.payloadAsJson);
    this.ee.emit(AutoSolveConstants.TOKEN_RESPONSE_EVENT, this, response);
  }

  void _receiveCancelMessage(AmqpMessage message) {
    log("Received Token Cancel Request : ${message.payloadAsJson}", false);
    CaptchaCancelResponse response =
        CaptchaCancelResponse.fromJson(message.payloadAsJson);
    this.ee.emit(AutoSolveConstants.TOKEN_CANCEL_EVENT, this, response);
  }

  void _handleHeartbeatError() {
    if (this.connected) {
      this.log("Connection lost. Attempting reconnect.", true);
      this.connected = false;
      _handleReconnect();
    }
  }

  void _handleReconnect() {
    this.init(options).then((response) {
      if (response.autoSolveStatus != AutoSolveStatus.Connected) {
        this.log(
            "Connection attempt #" +
                this.connectionAttempts.toString() +
                " failed. Re-attempting",
            true);
        _delayReconnect();
      } else {
        this.log("Successfully reconnected. Clearing backlog", false);
        if (this.reconnectDelayTimer != null) {
          this.reconnectDelayTimer.cancel();
        }
        this._clearMessageBacklog();
      }
    }).catchError((error) {
      log(error.toString(), true);
      _delayReconnect();
    });
  }

  void _delayReconnect() {
    reconnectDelayTimer = new Timer(new Duration(seconds: _getDelay()), () {
      _handleReconnect();
    });
  }

  void _pushToBacklog(CaptchaTokenRequest request) {
    this.backlog.add(request);
  }

  void _clearMessageBacklog() {
    for (int i = 0; i < this.backlog.length; i++) {
      this._sendCaptchaRequest(this.backlog[i]);
    }
    this.backlog.clear();
  }

  int _getDelay() {
    int index =
        this.connectionAttempts >= AutoSolveConstants.DELAY_SEQUENCE.length
            ? AutoSolveConstants.DELAY_SEQUENCE.length - 1
            : this.connectionAttempts;
    return AutoSolveConstants.DELAY_SEQUENCE[index];
  }

  void log(String message, isError) {
    if (this.debug) {
      isError
          ? print("[AUTOSOLVE][x] :: " + message)
          : print("[AUTOSOLVE][✓] :: " + message);
    }
  }

  String _getAccountId() {
    return this.options.accessToken.split("-")[0];
  }

  String _buildPrefixWithCredentials(String prefix) {
    return prefix +
        "." +
        this.accountId +
        "." +
        this.options.apiKey.replaceAll("-", "");
    ;
  }

  String _getRouteToOneClick(String route) {
    return route + "." + this.routingKey;
  }

  String _getNameWithAccountId(String prefix) {
    return prefix + "." + this.accountId;
  }

  static int _currentTimeInSeconds() {
    var ms = (new DateTime.now()).millisecondsSinceEpoch;
    return (ms / 1000).round();
  }

  static const MethodChannel _channel = const MethodChannel('flutterautosolve');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
