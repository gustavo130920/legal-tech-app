import '/components/button/button_widget.dart';
import '/components/social_button/social_button_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'register_widget.dart' show RegisterWidget;
import 'package:flutter/material.dart';

class RegisterModel extends FlutterFlowModel<RegisterWidget> {
  late ButtonModel buttonModel1;
  late SocialButtonModel socialButtonModel;
  late ButtonModel buttonModel3;

  @override
  void initState(BuildContext context) {
    buttonModel1 = createModel(context, () => ButtonModel());
    socialButtonModel = createModel(context, () => SocialButtonModel());
    buttonModel3 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    buttonModel1.dispose();
    socialButtonModel.dispose();
    buttonModel3.dispose();
  }
}