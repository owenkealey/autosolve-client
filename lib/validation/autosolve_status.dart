enum AutoSolveStatus {
  Connected,
  ValidationSuccess,
  InvalidApiKeyOrAccessToken,
  ValidationError,
  FailedConnection,
  NoInternetConnection,
  InvalidClientKey,
  TooManyRequests
}

class AutoSolveStatusConverter {
  static getValue(AutoSolveStatus status) {
    return status == AutoSolveStatus.Connected
        ? "Connected"
        : status == AutoSolveStatus.ValidationSuccess
            ? "Validation Success"
            : status == AutoSolveStatus.ValidationError
                ? "Validation Error"
                : status == AutoSolveStatus.InvalidClientKey
                    ? "Invalid Client Key"
                    : status == AutoSolveStatus.TooManyRequests
                        ? "Too Many Requests"
                        : status == AutoSolveStatus.FailedConnection
                            ? "Connection Failed"
                            : status ==
                                    AutoSolveStatus.InvalidApiKeyOrAccessToken
                                ? "Invalid Companion Key"
                                : status == AutoSolveStatus.NoInternetConnection
                                    ? "No Internet Connection"
                                    : "Unknown Error";
  }
}
