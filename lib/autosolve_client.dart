import 'package:autosolve_client/autosolve_options.dart';
import 'package:autosolve_client/lifecycle/lifecycle_manager.dart';
import 'package:autosolve_client/model/captcha_token_request.dart';
import 'package:autosolve_client/validation/autosolve_status.dart';
import 'package:autosolve_client/validation/autosolve_validation_response.dart';
import 'package:eventify/eventify.dart';
import 'package:flutter/cupertino.dart';

import 'autosolve.dart';

class AutoSolveClient with WidgetsBindingObserver {
  AutoSolve _autoSolve;
  AutoSolveOptions autoSolveOptions;
  LifecycleManager _lifecycleManager;
  final EventEmitter ee = new EventEmitter();
  bool enabled = false;

  AutoSolveClient(AutoSolveOptions options) {
    autoSolveOptions = options;
    _autoSolve = new AutoSolve(ee, true);
    _lifecycleManager = new LifecycleManager(this);
  }

  Future<AutoSolveStatus> updateParameters(AutoSolveOptions options) {
    this.autoSolveOptions = options;
    return initialize();
  }

  Future<AutoSolveStatus> initialize() async {
    print("Initializing rabbit");
    addLifecycleObserver();
    AutoSolveValidationResponse autoSolveValidationResponse =
        await _autoSolve.init(autoSolveOptions);

    enabled = autoSolveValidationResponse.autoSolveStatus == AutoSolveStatus.Connected;

    print("Validation status received rabbit initialized");
    return autoSolveValidationResponse.autoSolveStatus;
  }

  void send(CaptchaTokenRequest request) {
    _autoSolve.send(request);
  }

  void cancel(String taskId) {
    _autoSolve.sendCancel(taskId);
  }

  void cancelAll() {
    _autoSolve.sendCancelAll();
  }

  void addLifecycleObserver() {
    if(!enabled) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  void removeLifecycleObserver() {
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> close() async {
    removeLifecycleObserver();
    return closeInternal(true);
  }

  Future<void> closeInternal(bool clientTriggered) async {
    print("Closing rabbit");
    enabled = !clientTriggered;
    await _autoSolve.closeConnection();
  }

  void log(String message, isError) {
    if (this.autoSolveOptions.debug) {
      isError
          ? print("[AUTOSOLVE][x] :: " + message)
          : print("[AUTOSOLVE][✓] :: " + message);
    }
  }

  void info(String message) {
    if(this.autoSolveOptions.debug) {
      print("[AUTOSOLVE][!] :: " + message);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleManager.handleLifecycleChange(state);
  }
}
