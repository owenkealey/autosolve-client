class AutoSolveOptions {
  String accessToken;
  String apiKey;
  String clientKey;
  bool cancelResponseRequired = true;
  bool useLifecycleHandling = true;
  bool debug = false;

  AutoSolveOptions(this.accessToken, this.apiKey, this.clientKey,
      {bool cancelResponseRequired, bool useLifecycleHandling, bool debug}) {
    this.cancelResponseRequired = cancelResponseRequired == null
        ? this.cancelResponseRequired
        : cancelResponseRequired;
    this.useLifecycleHandling = useLifecycleHandling == null
        ? this.useLifecycleHandling
        : useLifecycleHandling;
    this.debug = debug == null
        ? this.debug
        : debug;
  }
}
