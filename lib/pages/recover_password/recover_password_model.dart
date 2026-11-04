import '/components/back_button/back_button_widget.dart';
import '/components/button/button_widget.dart';
import '/components/step_indicator/step_indicator_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'recover_password_widget.dart' show RecoverPasswordWidget;
import 'package:flutter/material.dart';

class RecoverPasswordModel extends FlutterFlowModel<RecoverPasswordWidget> {
  late BackButtonModel backButtonModel;
  late StepIndicatorModel stepIndicatorModel;
  late TextFieldModel textFieldModel;
  late ButtonModel buttonModel1;
  late ButtonModel buttonModel2;

  @override
  void initState(BuildContext context) {
    backButtonModel = createModel(context, () => BackButtonModel());
    stepIndicatorModel = createModel(context, () => StepIndicatorModel());
    textFieldModel = createModel(context, () => TextFieldModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    backButtonModel.dispose();
    stepIndicatorModel.dispose();
    textFieldModel.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
