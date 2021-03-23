import 'dart:ui';

import 'package:autosolve_client/autosolve_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:synchronized/synchronized.dart';

class LifecycleManager {
  AutoSolveClient client;
  Lock lock = new Lock();
  int lastEvent = 0;

  LifecycleManager(this.client);

  void handleLifecycleChange(AppLifecycleState state) async {
    if(client.autoSolveOptions.useLifecycleHandling && client.enabled) {
      await lock.synchronized(() async {
        if (lastEvent != state.index) {
          this.lastEvent = state.index;
          switch (state.index) {
            case 0:
              this.handleAppResumed();
              break;
            case 1:
              this.handleAppInactive();
              break;
            case 2:
              this.handleAppPaused();
              break;
            default:
              break;
          }
        }
      });
    }
  }

  void handleAppInactive() {
    handleAppInBackground();
    client.info("App State :: Inactive");
  }

  void handleAppPaused() {
    handleAppInBackground();
    client.info("App State :: Paused");
  }

  void handleAppInBackground() {
    this.client.closeInternal(false);
  }

  void handleAppResumed() {
    client.info("App State :: Resuming");
    this.client.initialize();
  }
}
