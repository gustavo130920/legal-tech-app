import '/components/area_card/area_card_widget.dart';
import '/components/button/button_widget.dart';
import '/components/checkbox/checkbox_widget.dart';
import '/components/quick_action/quick_action_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'main_menu_widget.dart' show MainMenuWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MainMenuModel extends FlutterFlowModel<MainMenuWidget> {
  
  late CheckboxModel checkboxModel1;
  late CheckboxModel checkboxModel2;
  late CheckboxModel checkboxModel3;
  late CheckboxModel checkboxModel4;
  late CheckboxModel checkboxModel5;
  late CheckboxModel checkboxModel6;
  late ButtonModel buttonModel;
  late QuickActionModel quickActionModel1;
  late QuickActionModel quickActionModel2;
  late AreaCardModel areaCardModel1;
  late AreaCardModel areaCardModel2;
  late AreaCardModel areaCardModel3;

  @override
  void initState(BuildContext context) {
    checkboxModel1 = createModel(context, () => CheckboxModel());
    checkboxModel2 = createModel(context, () => CheckboxModel());
    checkboxModel3 = createModel(context, () => CheckboxModel());
    checkboxModel4 = createModel(context, () => CheckboxModel());
    checkboxModel5 = createModel(context, () => CheckboxModel());
    checkboxModel6 = createModel(context, () => CheckboxModel());
    buttonModel = createModel(context, () => ButtonModel());
    quickActionModel1 = createModel(context, () => QuickActionModel());
    quickActionModel2 = createModel(context, () => QuickActionModel());
    areaCardModel1 = createModel(context, () => AreaCardModel());
    areaCardModel2 = createModel(context, () => AreaCardModel());
    areaCardModel3 = createModel(context, () => AreaCardModel());
  }

  @override
  void dispose() {
    checkboxModel1.dispose();
    checkboxModel2.dispose();
    checkboxModel3.dispose();
    checkboxModel4.dispose();
    checkboxModel5.dispose();
    checkboxModel6.dispose();
    buttonModel.dispose();
    quickActionModel1.dispose();
    quickActionModel2.dispose();
    areaCardModel1.dispose();
    areaCardModel2.dispose();
    areaCardModel3.dispose();
  }
}
