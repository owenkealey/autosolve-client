class AutoSolveConstants {
  static const String HOSTNAME = "rabbit.autosolve.io";
  static const String VHOST = "oneclick";
  static const String DIRECT_EXCHANGE = "exchanges.direct";
  static const String FANOUT_EXCHANGE = "exchanges.fanout";
  static const String TOKEN_SEND_ROUTE = "routes.request.token";
  static const String CANCEL_SEND_ROUTE = "routes.request.token.cancel";
  static const String TOKEN_RECEIVE_ROUTE = "routes.response.token";
  static const String CANCEL_RECEIVE_ROUTE = "routes.response.token.cancel";

  static const String RECEIVER_QUEUE_NAME = "queues.response.direct";

  static const String TOKEN_RESPONSE_EVENT = "token_response";
  static const String TOKEN_CANCEL_EVENT = "token_cancel_request";

  static const int MAX_CONNECTION_ATTEMPTS = 10;
  static const int RECONNECT_WAIT_TIME = 1500;
  static const int MAX_WAIT_CONNECTION_CLOSE = 5000;

  static const int SUCCESS_STATUS_CODE = 200;
  static const int INVALID_CLIENT_KEY = 400;
  static const int TOO_MANY_REQUESTS = 429;
  static const int INVALID_API_KEY_OR_ACCESS_TOKEN = 401;
  static const int RABBIT_CONNECT_TIMEOUT = 10000;
  static const int VALIDATION_TIMEOUT = 10000;
  static const Duration HEARTBEAT = Duration(seconds: 10);
  static const List DELAY_SEQUENCE = [2, 3, 5, 8, 13, 21, 34];
}
