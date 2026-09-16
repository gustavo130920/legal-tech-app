import '/components/back_button/back_button_widget.dart';
import '/components/button/button_widget.dart';
import '/components/step_indicator/step_indicator_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'recover_password_widget.dart' show RecoverPasswordWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
