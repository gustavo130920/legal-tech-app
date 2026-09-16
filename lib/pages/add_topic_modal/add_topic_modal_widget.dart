import '/components/button/button_widget.dart';
import '/components/form_label/form_label_widget.dart';
import '/components/placeholder_chip/placeholder_chip_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'add_topic_modal_model.dart';
export 'add_topic_modal_model.dart';

import '../../app_state.dart';

class AddTopicModalWidget extends StatefulWidget {
  const AddTopicModalWidget({super.key});

  static String routeName = 'AddTopicModal';
  static String routePath = '/addTopicModal';

  @override
  State<AddTopicModalWidget> createState() => _AddTopicModalWidgetState();
}

class _AddTopicModalWidgetState extends State<AddTopicModalWidget> {
  late AddTopicModalModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;

  String? _selectedArea;
  String? _selectedPeca;
  FormFieldController<String>? _areaController;
  FormFieldController<String>? _pecaController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddTopicModalModel());

    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _tagsController = TextEditingController();

    final availableAreas = globalSavedAreas.isNotEmpty
        ? globalSavedAreas.toList()
        : ['Trabalhista', 'Civil', 'Penal', 'Previdenciário', 'Tributário', 'Empresarial', 'Contratos'];

    _selectedArea = availableAreas.contains(globalCurrentArea) ? globalCurrentArea : availableAreas.first;
    _areaController = FormFieldController<String>(_selectedArea);

    final pecasForArea = (globalAreaDatabase[_selectedArea!]['pecas'] as List).cast<String>();
    _selectedPeca = pecasForArea.isNotEmpty ? pecasForArea.first : null;
    _pecaController = FormFieldController<String>(_selectedPeca);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _closeModal() {
    context.safePop(); 
  }

  Future<void> _saveTopicToSupabase() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua sessão expirou. Faça login novamente.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (title.isEmpty || content.isEmpty || _selectedPeca == null || _selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha título, conteúdo e selecione a Peça.')),
      );
      return;
    }

    safeSetState(() => _isSaving = true);

    try {
      final regex = RegExp(r'\{\{(.*?)\}\}');
      final matches = regex.allMatches(content);
      final extractedVars = matches.map((m) => m.group(1)!.trim()).toSet().toList();

      final previewText = content.length > 40 ? '${content.substring(0, 40)}...' : content;

      await Supabase.instance.client.from('topics').insert({
        'user_id': user.id,
        'area_name': _selectedArea,
        'peca_name': _selectedPeca,
        'title': title,
        'content': content,
        'preview': previewText,
        'variables': extractedVars,
      });

      final newTopic = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': title,
        'content': content, 
        'preview': previewText,
        'variables': extractedVars,
        'peca': _selectedPeca, 
      };
      globalAreaDatabase[_selectedArea!]['topics'].add(newTopic);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tópico "$title" salvo com sucesso na nuvem!'), backgroundColor: Colors.green),
      );

      safeSetState(() {
        _titleController.clear();
        _contentController.clear();
        _tagsController.clear();
      });
      
      
      _closeModal();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro do banco: $e'), backgroundColor: Colors.red),
      );
    } finally {
      safeSetState(() => _isSaving = false);
    }
  }

  Widget _buildTextInput({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    IconData? leadingIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
              font: GoogleFonts.inter(),
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
        prefixIcon: leadingIcon != null 
            ? Icon(leadingIcon, color: FlutterFlowTheme.of(context).primaryText) 
            : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 1.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: FlutterFlowTheme.of(context).primaryBackground,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 12.0),
      ),
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            font: GoogleFonts.inter(),
            color: FlutterFlowTheme.of(context).primaryText,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableAreas = globalSavedAreas.isNotEmpty
        ? globalSavedAreas.toList()
        : ['Trabalhista', 'Civil', 'Penal', 'Previdenciário', 'Tributário', 'Empresarial', 'Contratos'];

    final pecasForArea = (globalAreaDatabase[_selectedArea!]['pecas'] as List).cast<String>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SingleChildScrollView(
          primary: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(shape: BoxShape.rectangle),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Novo Tópico',
                                style: FlutterFlowTheme.of(context).headlineMedium.override(
                                      font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                      color: FlutterFlowTheme.of(context).primaryText,
                                    ),
                              ),
                              Text(
                                'Adicione regras e modelos à sua biblioteca',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                              ),
                            ].divide(const SizedBox(height: 4.0)),
                          ),
                          FlutterFlowIconButton(
                            borderRadius: 9999.0,
                            buttonSize: 40.0,
                            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                            icon: Icon(Icons.close_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
                            onPressed: () async => _closeModal(),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1.0, decoration: BoxDecoration(color: FlutterFlowTheme.of(context).alternate)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              wrapWithModel(
                                model: _model.formLabelModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: const FormLabelWidget(label: 'Área Profissional'),
                              ),
                              FlutterFlowDropDown<String>(
                                controller: _areaController,
                                options: availableAreas,
                                onChanged: (val) {
                                  if (val != null) {
                                    safeSetState(() {
                                      _selectedArea = val;
                                      final newPecasForArea = (globalAreaDatabase[_selectedArea!]['pecas'] as List).cast<String>();
                                      _selectedPeca = newPecasForArea.isNotEmpty ? newPecasForArea.first : null;
                                      _pecaController?.value = _selectedPeca; 
                                    });
                                  }
                                },
                                width: double.infinity, height: 40.0,
                                textStyle: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText),
                                hintText: _selectedArea ?? 'Selecione',
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: FlutterFlowTheme.of(context).primary, size: 24.0),
                                fillColor: FlutterFlowTheme.of(context).surfaceVariant, elevation: 2.0, borderColor: FlutterFlowTheme.of(context).alternate, borderWidth: 1.0, borderRadius: 12.0, margin: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0), hidesUnderline: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              wrapWithModel(
                                model: _model.formLabelModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: const FormLabelWidget(label: 'Qual a Peça do Tópico?'),
                              ),
                              FlutterFlowDropDown<String>(
                                controller: _pecaController,
                                options: pecasForArea,
                                onChanged: (val) {
                                  if (val != null) {
                                    safeSetState(() {
                                      _selectedPeca = val;
                                    });
                                  }
                                },
                                width: double.infinity, height: 40.0,
                                textStyle: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText),
                                hintText: _selectedPeca ?? 'Nenhuma Peça Encontrada',
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: FlutterFlowTheme.of(context).primary, size: 24.0),
                                fillColor: FlutterFlowTheme.of(context).surfaceVariant, elevation: 2.0, borderColor: FlutterFlowTheme.of(context).alternate, borderWidth: 1.0, borderRadius: 12.0, margin: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0), hidesUnderline: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        wrapWithModel(
                          model: _model.formLabelModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: const FormLabelWidget(label: 'Título do Tópico'),
                        ),
                        _buildTextInput(hint: 'Ex: Rescisão sem justa causa', controller: _titleController),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            wrapWithModel(
                              model: _model.formLabelModel3,
                              updateCallback: () => safeSetState(() {}),
                              child: const FormLabelWidget(label: 'Conteúdo do Modelo'),
                            ),
                            Text(
                              'Use {{CHAVES}} para variáveis',
                              style: FlutterFlowTheme.of(context).labelSmall.override(font: GoogleFonts.inter(fontWeight: FontWeight.bold), color: FlutterFlowTheme.of(context).primary),
                            ),
                          ],
                        ),
                        Container(
                          constraints: const BoxConstraints(minHeight: 300.0),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).surfaceVariant, borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTextInput(hint: 'Digite o texto jurídico aqui...', controller: _contentController, maxLines: 8),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 16.0),
                                  child: Divider(height: 16.0, thickness: 1.0, color: FlutterFlowTheme.of(context).alternate),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Variáveis disponíveis:', style: FlutterFlowTheme.of(context).labelSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).secondaryText)),
                                    Wrap(
                                      spacing: 8.0, runSpacing: 8.0,
                                      children: [
                                        wrapWithModel(
                                          model: _model.placeholderChipModel1, updateCallback: () => safeSetState(() {}),
                                          child: PlaceholderChipWidget(icon: Icon(Icons.person_rounded, color: FlutterFlowTheme.of(context).primary, size: 14.0), text: '{{NOME_CLIENTE}}'),
                                        ),
                                        wrapWithModel(
                                          model: _model.placeholderChipModel2, updateCallback: () => safeSetState(() {}),
                                          child: PlaceholderChipWidget(icon: Icon(Icons.fingerprint_rounded, color: FlutterFlowTheme.of(context).primary, size: 14.0), text: '{{CPF}}'),
                                        ),
                                        wrapWithModel(
                                          model: _model.placeholderChipModel3, updateCallback: () => safeSetState(() {}),
                                          child: PlaceholderChipWidget(icon: Icon(Icons.balance_rounded, color: FlutterFlowTheme.of(context).primary, size: 14.0), text: '{{REU}}'),
                                        ),
                                        PlaceholderChipWidget(icon: Icon(Icons.gavel_rounded, color: FlutterFlowTheme.of(context).primary, size: 14.0), text: '{{PROCESSO}}'),
                                      ],
                                    ),
                                  ].divide(const SizedBox(height: 8.0)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        wrapWithModel(
                          model: _model.formLabelModel4, updateCallback: () => safeSetState(() {}),
                          child: const FormLabelWidget(label: 'Tags de Organização'),
                        ),
                        _buildTextInput(hint: 'Adicione tags separadas por vírgula', controller: _tagsController, leadingIcon: Icons.label_rounded),
                      ],
                    ),
                  ].divide(const SizedBox(height: 32.0)),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: FlutterFlowTheme.of(context).secondaryBackground),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: 1.0, decoration: BoxDecoration(color: FlutterFlowTheme.of(context).alternate)),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () => _closeModal(),
                              child: wrapWithModel(
                                model: _model.buttonModel1, updateCallback: () => safeSetState(() {}),
                                child: ButtonWidget(
                                  iconPresent: false, iconEndPresent: false, content: 'Cancelar',
                                  variant: 'outline', size: 'small', fullWidth: false, loading: false, disabled: false,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: _isSaving ? null : _saveTopicToSupabase,
                              child: wrapWithModel(
                                model: _model.buttonModel2, updateCallback: () => safeSetState(() {}),
                                child: ButtonWidget(
                                  icon: Icon(Icons.save_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 24.0),
                                  iconPresent: true, iconEndPresent: false, content: _isSaving ? 'Salvando...' : 'Salvar Tópico',
                                  variant: 'primary', size: 'small', fullWidth: false, loading: false, disabled: _isSaving,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}