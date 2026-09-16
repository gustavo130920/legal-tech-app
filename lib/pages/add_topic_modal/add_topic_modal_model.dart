import '/components/button/button_widget.dart';
import '/components/form_label/form_label_widget.dart';
import '/components/placeholder_chip/placeholder_chip_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'add_topic_modal_widget.dart' show AddTopicModalWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddTopicModalModel extends FlutterFlowModel<AddTopicModalWidget> {
  
  late FormLabelModel formLabelModel1;
  
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;
  
  late FormLabelModel formLabelModel2;
  late TextFieldModel textFieldModel1;
  late FormLabelModel formLabelModel3;
  late TextFieldModel textFieldModel2;
  late PlaceholderChipModel placeholderChipModel1;
  late PlaceholderChipModel placeholderChipModel2;
  late PlaceholderChipModel placeholderChipModel3;
  late PlaceholderChipModel placeholderChipModel4;
  late FormLabelModel formLabelModel4;
  late TextFieldModel textFieldModel3;
  late ButtonModel buttonModel1;
  late ButtonModel buttonModel2;

  @override
  void initState(BuildContext context) {
    formLabelModel1 = createModel(context, () => FormLabelModel());
    formLabelModel2 = createModel(context, () => FormLabelModel());
    textFieldModel1 = createModel(context, () => TextFieldModel());
    formLabelModel3 = createModel(context, () => FormLabelModel());
    textFieldModel2 = createModel(context, () => TextFieldModel());
    placeholderChipModel1 = createModel(context, () => PlaceholderChipModel());
    placeholderChipModel2 = createModel(context, () => PlaceholderChipModel());
    placeholderChipModel3 = createModel(context, () => PlaceholderChipModel());
    placeholderChipModel4 = createModel(context, () => PlaceholderChipModel());
    formLabelModel4 = createModel(context, () => FormLabelModel());
    textFieldModel3 = createModel(context, () => TextFieldModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    formLabelModel1.dispose();
    formLabelModel2.dispose();
    textFieldModel1.dispose();
    formLabelModel3.dispose();
    textFieldModel2.dispose();
    placeholderChipModel1.dispose();
    placeholderChipModel2.dispose();
    placeholderChipModel3.dispose();
    placeholderChipModel4.dispose();
    formLabelModel4.dispose();
    textFieldModel3.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
