import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:autosolve_client/autosolve_options.dart';
import 'package:autosolve_client/model/validation_response_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../autosolve_constants.dart';
import 'autosolve_status.dart';
import 'autosolve_validation_response.dart';

class AutoSolveValidate {
  static Future<AutoSolveValidationResponse> validate(
      AutoSolveOptions options) async {
    Timer timer =
        new Timer(Duration(seconds: AutoSolveConstants.VALIDATION_TIMEOUT), () {
      return validationError();
    });
    Response response =
        await http.get(Uri.parse(buildValidationUrl(options))).catchError((onError) {
      print("Error in validation");
    });
    timer.cancel();
    if (response == null) {
      return validationError();
    } else {
      return parseValidationResponse(response);
    }
  }

  static AutoSolveValidationResponse parseValidationResponse(
      Response response) {
    AutoSolveStatus status = response.statusCode ==
            AutoSolveConstants.SUCCESS_STATUS_CODE
        ? AutoSolveStatus.ValidationSuccess
        : response.statusCode ==
                AutoSolveConstants.INVALID_API_KEY_OR_ACCESS_TOKEN
            ? AutoSolveStatus.InvalidApiKeyOrAccessToken
            : response.statusCode == AutoSolveConstants.INVALID_CLIENT_KEY
                ? AutoSolveStatus.InvalidClientKey
                : response.statusCode == AutoSolveConstants.TOO_MANY_REQUESTS
                    ? AutoSolveStatus.TooManyRequests
                    : AutoSolveStatus.ValidationError;
    String resString = response.body != "" ? response.body : "{}";
    return new AutoSolveValidationResponse(
        status, ValidationResponse.fromJson(json.decode(resString)));
  }

  static AutoSolveValidationResponse validationError() {
    return new AutoSolveValidationResponse(
        AutoSolveStatus.ValidationError, null);
  }

  static String buildValidationUrl(AutoSolveOptions options) {
    return "https://dashboard.autosolve.io/rest/${options.accessToken}/verify/${options.apiKey}?clientId=${options.clientKey}";
  }
}
