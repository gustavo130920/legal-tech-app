import '/components/quick_action_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'area_workspace_widget.dart' show AreaWorkspaceWidget;
import 'package:flutter/material.dart';

class AreaWorkspaceModel extends FlutterFlowModel<AreaWorkspaceWidget> {
  late QuickActionCardModel quickActionCardModel1;
  late QuickActionCardModel quickActionCardModel2;

  @override
  void initState(BuildContext context) {
    quickActionCardModel1 = createModel(context, () => QuickActionCardModel());
    quickActionCardModel2 = createModel(context, () => QuickActionCardModel());
  }

  @override
  void dispose() {
    quickActionCardModel1.dispose();
    quickActionCardModel2.dispose();
  }
}