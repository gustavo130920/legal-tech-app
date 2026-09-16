import '/components/button/button_widget.dart';
import '/components/social_button/social_button_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'login_widget.dart' show LoginWidget;
import 'package:flutter/material.dart';

class LoginModel extends FlutterFlowModel<LoginWidget> {
  late ButtonModel buttonModel1;
  late ButtonModel buttonModel2;
  late ButtonModel buttonModel3;
  late SocialButtonModel socialButtonModel;

  @override
  void initState(BuildContext context) {
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    buttonModel3 = createModel(context, () => ButtonModel());
    socialButtonModel = createModel(context, () => SocialButtonModel());
  }

  @override
  void dispose() {
    buttonModel1.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
    socialButtonModel.dispose();
  }
}