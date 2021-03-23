import '../model/validation_response_model.dart';
import 'autosolve_status.dart';

class AutoSolveValidationResponse {
  AutoSolveStatus autoSolveStatus;
  ValidationResponse validationResponse;

  AutoSolveValidationResponse(this.autoSolveStatus, this.validationResponse);
}
