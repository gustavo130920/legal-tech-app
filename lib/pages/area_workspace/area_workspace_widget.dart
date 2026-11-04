import '/components/quick_action_card_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/features/drafting/domain/document_composer.dart';
import '/platform/document_actions.dart';
import 'area_workspace_model.dart';
import '../add_topic_modal/add_topic_modal_widget.dart';
import '../main_menu/main_menu_widget.dart';
export 'area_workspace_model.dart';

import '../../app_state.dart';

class AreaWorkspaceWidget extends StatefulWidget {
  const AreaWorkspaceWidget({super.key, this.area});

  static String routeName = 'AreaWorkspace';
  static String routePath = '/areaWorkspace';

  /// Vem da URL, para que recarregar a página mantenha a mesma área.
  final String? area;

  @override
  State<AreaWorkspaceWidget> createState() => _AreaWorkspaceWidgetState();
}

class _AreaWorkspaceWidgetState extends State<AreaWorkspaceWidget> {
  late AreaWorkspaceModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late TextEditingController _enderecamentoController;
  late TextEditingController _nomeController;
  late TextEditingController _cpfController;
  late TextEditingController _reuController;
  late TextEditingController _processoController;

  Set<int>? _selectedTopics;
  Set<int> get selectedTopics => _selectedTopics ??= {};

  Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, String> _pecaHeaders = {};

  String? _selectedPeca;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AreaWorkspaceModel());

    _enderecamentoController = TextEditingController();
    _nomeController = TextEditingController();
    _cpfController = TextEditingController();
    _reuController = TextEditingController();
    _processoController = TextEditingController();

    _enderecamentoController.addListener(() => safeSetState(() {}));
    _nomeController.addListener(() => safeSetState(() {}));
    _cpfController.addListener(() => safeSetState(() {}));
    _reuController.addListener(() => safeSetState(() {}));
    _processoController.addListener(() => safeSetState(() {}));

    final area = widget.area;
    if (area != null && globalAreaDatabase.containsKey(area)) {
      globalCurrentArea = area;
    }

    if (globalAreaDatabase.containsKey(globalCurrentArea)) {
      _loadDataFromSupabase();
    } else {
      // Sem área definida não há como saber o que abrir: nunca assumir uma.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(MainMenuWidget.routeName);
      });
    }
  }

  String get _enderecamentoHint {
    switch (globalCurrentArea) {
      case 'Trabalhista':
        return 'Ex: Vara do Trabalho de São Paulo/SP';
      case 'Penal':
        return 'Ex: Vara Criminal de São Paulo/SP';
      case 'Previdenciário':
        return 'Ex: Vara Previdenciária de São Paulo/SP';
      case 'Tributário':
        return 'Ex: Vara da Fazenda Pública de São Paulo/SP';
      case 'Contratos':
        return 'Ex: Comarca de São Paulo/SP';
      default:
        return 'Ex: Vara Cível de São Paulo/SP';
    }
  }

  @override
  void dispose() {
    _enderecamentoController.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    _reuController.dispose();
    _processoController.dispose();
    _dynamicControllers.values.forEach((ctrl) => ctrl.dispose());
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadDataFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final area = globalCurrentArea;

    // Resposta de uma sessão ou área anterior nunca pode entrar na memória atual.
    bool isStale() =>
        !mounted ||
        globalCurrentArea != area ||
        Supabase.instance.client.auth.currentUser?.id != user.id;

    safeSetState(() {
      _isLoadingData = true;
    });

    try {
      final pecasResponse = await Supabase.instance.client
          .from('pecas')
          .select('peca_name, header_template')
          .eq('user_id', user.id)
          .eq('area_name', area)
          .order('id', ascending: true);

      final topicsResponse = await Supabase.instance.client
          .from('topics')
          .select()
          .eq('user_id', user.id)
          .eq('area_name', area)
          .order('id', ascending: true);

      if (isStale()) return;

      final List<String> loadedPecas = (pecasResponse as List)
          .map((item) => item['peca_name'].toString())
          .toList();

      _pecaHeaders
        ..clear()
        ..addEntries((pecasResponse as List)
            .where((item) => item['header_template'] != null)
            .map((item) => MapEntry(item['peca_name'].toString(), item['header_template'].toString())));

      final currentAreaMap = globalAreaDatabase[area];
      if (currentAreaMap != null) {
        currentAreaMap['pecas'] = <String>[];
        final List<String> currentPecas = (currentAreaMap['pecas'] as List).cast<String>();
        currentPecas.addAll(loadedPecas);
      }

      final List<Map<String, dynamic>> loadedTopics = (topicsResponse as List).map((item) {
        return {
          'id': item['id'],
          'title': item['title'],
          'content': item['content'],
          'preview': item['preview'],
          'variables': (item['variables'] as List).cast<String>(),
          'peca': item['peca_name'],
        };
      }).toList();

      if (globalAreaDatabase[area] != null) {
        globalAreaDatabase[area]['topics'] = loadedTopics;
      }

      if (currentAreaMap != null && (currentAreaMap['pecas'] as List).isNotEmpty) {
        if (!loadedPecas.contains(_selectedPeca)) {
          _selectedPeca = loadedPecas.first;
        }
      } else {
        _selectedPeca = null;
      }
      
      globalSelectedPeca = _selectedPeca;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sincronizar nuvem: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        safeSetState(() => _isLoadingData = false);
        _updateDynamicFields();
      }
    }
  }

  void _changePeca(String newPeca) {
    if (_selectedPeca == newPeca) return;
    safeSetState(() {
      _selectedPeca = newPeca;
      globalSelectedPeca = newPeca;
      selectedTopics.clear();
      _dynamicControllers.forEach((_, ctrl) => ctrl.dispose());
      _dynamicControllers.clear();
      _updateDynamicFields();
    });
  }

  void _showAddPecaDialog() {
    final TextEditingController pecaController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          title: Text(
            'Nova Peça',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          content: TextField(
            controller: pecaController,
            autofocus: true,
            onSubmitted: (_) => _submitAddPeca(pecaController.text),
            decoration: InputDecoration(
              hintText: 'Ex: Réplica, Procuração, Recurso...',
              hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
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
            ),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
            ),
            ElevatedButton(
              onPressed: () => _submitAddPeca(pecaController.text),
              style: ElevatedButton.styleFrom(backgroundColor: FlutterFlowTheme.of(context).primary),
              child: const Text('Criar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAddPeca(String nameRaw) async {
    if (nameRaw.trim().isEmpty) return;
    final newPecaName = nameRaw.trim().toUpperCase();
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        await Supabase.instance.client.from('pecas').insert({
          'user_id': user.id,
          'area_name': globalCurrentArea,
          'peca_name': newPecaName,
        });
        
        safeSetState(() {
          (globalAreaDatabase[globalCurrentArea]['pecas'] as List).add(newPecaName);
          _changePeca(newPecaName);
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peça criada com sucesso!'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar peça: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showEditPecaDialog(String oldName) {
    final TextEditingController pecaController = TextEditingController(text: oldName);
    final TextEditingController headerController = TextEditingController(
      text: _pecaHeaders[oldName] ?? defaultHeaderForArea(globalCurrentArea),
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          title: Text(
            'Editar Peça',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          content: SizedBox(
            width: 560.0,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pecaController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Nome da peça',
                      labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
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
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: headerController,
                    minLines: 6,
                    maxLines: 12,
                    decoration: InputDecoration(
                      labelText: 'Cabeçalho da peça',
                      alignLabelWithHint: true,
                      helperText: 'Separe os parágrafos com uma linha em branco. Use variáveis como {{ENDEREÇAMENTO}}, {{PROCESSO}}, {{NOME_CLIENTE}}, {{REU}} e {{CPF}}.',
                      helperMaxLines: 3,
                      labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                      helperStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
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
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
            ),
            ElevatedButton(
              onPressed: () => _submitEditPeca(oldName, pecaController.text, headerController.text),
              style: ElevatedButton.styleFrom(backgroundColor: FlutterFlowTheme.of(context).primary),
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitEditPeca(String oldName, String newNameRaw, String headerRaw) async {
    final newName = newNameRaw.trim().toUpperCase();
    final headerText = headerRaw.trim();
    // Guardar o texto padrão faria a peça não receber correções futuras dele.
    final newHeader = headerText.isEmpty || headerText == defaultHeaderForArea(globalCurrentArea) ? null : headerText;

    if (newName.isEmpty || (newName == oldName && newHeader == _pecaHeaders[oldName])) {
      Navigator.pop(context);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('pecas').update({'peca_name': newName, 'header_template': newHeader}).eq('user_id', user.id).eq('area_name', globalCurrentArea).eq('peca_name', oldName);
      if (newName != oldName) {
        await Supabase.instance.client.from('topics').update({'peca_name': newName}).eq('user_id', user.id).eq('area_name', globalCurrentArea).eq('peca_name', oldName);
      }

      safeSetState(() {
        _pecaHeaders.remove(oldName);
        if (newHeader != null) _pecaHeaders[newName] = newHeader;

        final pecasList = (globalAreaDatabase[globalCurrentArea]['pecas'] as List);
        final idx = pecasList.indexOf(oldName);
        if (idx != -1) pecasList[idx] = newName;

        final topicsList = (globalAreaDatabase[globalCurrentArea]['topics'] as List);
        for (var t in topicsList) {
          if (t['peca'] == oldName) t['peca'] = newName;
        }

        if (_selectedPeca == oldName) {
          _selectedPeca = newName;
          globalSelectedPeca = newName;
        }
        _updateDynamicFields();
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peça atualizada com sucesso!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar peça: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deletePeca(String pecaName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: Text('Excluir Peça', style: TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja excluir "$pecaName"? Todos os tópicos desta peça também serão apagados.', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('topics').delete().eq('user_id', user.id).eq('area_name', globalCurrentArea).eq('peca_name', pecaName);
      await Supabase.instance.client.from('pecas').delete().eq('user_id', user.id).eq('area_name', globalCurrentArea).eq('peca_name', pecaName);

      safeSetState(() {
        _pecaHeaders.remove(pecaName);
        (globalAreaDatabase[globalCurrentArea]['pecas'] as List).remove(pecaName);
        final topicsList = (globalAreaDatabase[globalCurrentArea]['topics'] as List);
        topicsList.removeWhere((t) => t['peca'] == pecaName);

        final remainingPecas = (globalAreaDatabase[globalCurrentArea]['pecas'] as List).cast<String>();
        if (_selectedPeca == pecaName) {
          _selectedPeca = remainingPecas.isNotEmpty ? remainingPecas.first : null;
          globalSelectedPeca = _selectedPeca;
          selectedTopics.clear();
          _dynamicControllers.forEach((_, ctrl) => ctrl.dispose());
          _dynamicControllers.clear();
        }
      });
      _updateDynamicFields();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peça excluída com sucesso!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir peça: $e'), backgroundColor: Colors.red));
    }
  }

  void _showEditTopicDialog(Map<String, dynamic> topic) {
    final titleCtrl = TextEditingController(text: topic['title']);
    final contentCtrl = TextEditingController(text: topic['content']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          title: Text(
            'Editar Tópico',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Título do Tópico',
                    labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary)),
                  ),
                  style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: contentCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Conteúdo do Modelo',
                    labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary)),
                  ),
                  style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
            ),
            ElevatedButton(
              onPressed: () => _submitEditTopic(topic['id'], titleCtrl.text, contentCtrl.text),
              style: ElevatedButton.styleFrom(backgroundColor: FlutterFlowTheme.of(context).primary),
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitEditTopic(int id, String titleRaw, String contentRaw) async {
    final title = titleRaw.trim();
    final content = contentRaw.trim();

    if (title.isEmpty || content.isEmpty) return;

    try {
      final extractedVars = extractVariables(content);
      final previewText = topicPreview(content);

      await Supabase.instance.client.from('topics').update({
        'title': title,
        'content': content,
        'preview': previewText,
        'variables': extractedVars,
      }).eq('id', id);

      safeSetState(() {
        final topicsList = (globalAreaDatabase[globalCurrentArea]['topics'] as List);
        final idx = topicsList.indexWhere((t) => t['id'] == id);
        if (idx != -1) {
          topicsList[idx]['title'] = title;
          topicsList[idx]['content'] = content;
          topicsList[idx]['preview'] = previewText;
          topicsList[idx]['variables'] = extractedVars;
        }
        _updateDynamicFields();
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tópico atualizado com sucesso!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar tópico: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteTopic(int topicId, String topicTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: Text('Excluir Tópico', style: TextStyle(color: FlutterFlowTheme.of(context).primaryText, fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja excluir "$topicTitle"?', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('topics').delete().eq('id', topicId);

      safeSetState(() {
        final topicsList = (globalAreaDatabase[globalCurrentArea]['topics'] as List);
        topicsList.removeWhere((t) => t['id'] == topicId);
        selectedTopics.remove(topicId);
        _updateDynamicFields();
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tópico excluído com sucesso!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir tópico: $e'), backgroundColor: Colors.red));
    }
  }

  void _updateDynamicFields() {
    final currentArea = globalAreaDatabase[globalCurrentArea] ?? globalAreaDatabase['Trabalhista'];
    final allTopics = currentArea['topics'] as List<Map<String, dynamic>>;
    final dynamicTopics = allTopics.where((t) => t['peca'] == _selectedPeca).toList();

    Set<String> neededVars = extractVariables(_currentHeaderTemplate).toSet();

    for (var topicId in selectedTopics) {
      final topic = dynamicTopics.firstWhere((t) => t['id'] == topicId, orElse: () => {});
      if (topic.isNotEmpty && topic['variables'] != null) {
        neededVars.addAll((topic['variables'] as List<dynamic>).map((e) => e.toString()));
      }
    }

    neededVars.removeWhere(standardVariableNames.contains);

    for (var v in neededVars) {
      if (!_dynamicControllers.containsKey(v)) {
        final ctrl = TextEditingController();
        ctrl.addListener(() => safeSetState(() {}));
        _dynamicControllers[v] = ctrl;
      }
    }

    _dynamicControllers.keys.toList().forEach((key) {
      if (!neededVars.contains(key)) {
        _dynamicControllers[key]?.dispose();
        _dynamicControllers.remove(key);
      }
    });
  }

  void _toggleTopic(int topicId) {
    safeSetState(() {
      if (selectedTopics.contains(topicId)) {
        selectedTopics.remove(topicId);
      } else {
        selectedTopics.add(topicId);
      }
      _updateDynamicFields();
    });
  }

  String get _currentHeaderTemplate {
    final saved = _pecaHeaders[_selectedPeca];
    return saved != null && saved.trim().isNotEmpty
        ? saved
        : defaultHeaderForArea(globalCurrentArea);
  }

  DocumentInput _buildDocumentInput() {
    final currentArea = globalAreaDatabase[globalCurrentArea] ?? globalAreaDatabase['Trabalhista'];
    final allTopics = currentArea['topics'] as List<Map<String, dynamic>>;
    final dynamicTopics = allTopics.where((t) => t['peca'] == _selectedPeca).toList();

    final topics = <DocumentTopic>[];
    for (var topicId in selectedTopics) {
      final topic = dynamicTopics.firstWhere((t) => t['id'] == topicId, orElse: () => {});
      if (topic.isNotEmpty && topic['content'] != null) {
        topics.add(DocumentTopic(title: topic['title'].toString(), content: topic['content']));
      }
    }

    return DocumentInput(
      headerTemplate: _currentHeaderTemplate,
      topics: topics,
      enderecamento: _enderecamentoController.text,
      nomeCliente: _nomeController.text,
      cpf: _cpfController.text,
      reu: _reuController.text,
      processo: _processoController.text,
      customVariables: _dynamicControllers.map((key, controller) => MapEntry(key, controller.text)),
    );
  }

  void _copyToClipboardAsHtml() {
    if (selectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione tópicos antes de copiar.')));
      return;
    }

    final input = _buildDocumentInput();
    final plainText = composePlainText(input);

    if (copyRichTextToClipboard(html: composeHtml(input), plainText: plainText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento copiado com formatação perfeita! Cole no Word ou Docs.')),
      );
    } else {
      Clipboard.setData(ClipboardData(text: plainText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copiado em formato simples (navegador bloqueou formatação).')),
      );
    }
  }

  Widget _buildRichDocumentPreview() {
    final baseStyle = FlutterFlowTheme.of(context).bodySmall.override(
      font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).secondaryText, lineHeight: 1.5,
    );
    final boldStyle = FlutterFlowTheme.of(context).bodySmall.override(
      font: GoogleFonts.inter(fontWeight: FontWeight.bold), color: FlutterFlowTheme.of(context).primaryText, lineHeight: 1.5,
    );

    return RichText(
      text: TextSpan(
        children: composeSpans(_buildDocumentInput())
            .map((span) => TextSpan(text: span.text, style: span.isTitle ? boldStyle : baseStyle))
            .toList(),
      ),
    );
  }

  void _downloadAsDoc() {
    if (selectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione tópicos antes de gerar o documento.')));
      return;
    }
    final downloaded = downloadWordDocument(
      fileName: '${_selectedPeca?.replaceAll(' ', '_')}.doc',
      content: composeWordDocument(_buildDocumentInput()),
    );
    if (!downloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar o arquivo. Tente copiar o documento.'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildPecaCard(String name) {
    final isSelected = _selectedPeca == name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).alternate,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => _changePeca(name),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20.0, height: 20.0,
                    decoration: BoxDecoration(
                      color: isSelected ? FlutterFlowTheme.of(context).primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).alternate,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14.0) : null,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    name,
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                          color: isSelected ? FlutterFlowTheme.of(context).primaryText : FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            InkWell(
              onTap: () => _showEditPecaDialog(name),
              child: Icon(Icons.edit_outlined, size: 16.0, color: FlutterFlowTheme.of(context).secondaryText),
            ),
            const SizedBox(width: 6.0),
            InkWell(
              onTap: () => _deletePeca(name),
              child: const Icon(Icons.delete_outline_rounded, size: 16.0, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    final id = topic['id'] as int;
    final title = topic['title'] as String;
    final preview = topic['preview'] as String;
    final isSelected = selectedTopics.contains(id);

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).alternate,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => _toggleTopic(id),
              child: Container(
                width: 22.0, height: 22.0,
                decoration: BoxDecoration(
                  color: isSelected ? FlutterFlowTheme.of(context).primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).alternate,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14.0) : null,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: InkWell(
                onTap: () => _toggleTopic(id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FlutterFlowTheme.of(context).titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      preview,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: GoogleFonts.inter(),
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18.0),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  onPressed: () => _showEditTopicDialog(topic),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18.0),
                  color: Colors.redAccent,
                  onPressed: () => _deleteTopic(id, title),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          controller: controller,
          obscureText: false,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                  font: GoogleFonts.inter(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary, width: 1.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: FlutterFlowTheme.of(context).error, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: FlutterFlowTheme.of(context).error, width: 1.5),
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentArea = globalAreaDatabase[globalCurrentArea] ?? globalAreaDatabase['Trabalhista'];
    final areaPecas = (currentArea['pecas'] as List).cast<String>();
    
    final allTopics = currentArea['topics'] as List<Map<String, dynamic>>;
    final dynamicTopics = allTopics.where((t) => t['peca'] == _selectedPeca).toList();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 24.0,
            ),
            onPressed: () async {
              context.goNamed(MainMenuWidget.routeName);
            },
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentArea['title'],
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              Text(
                'Montador de Peças',
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.inter(),
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ],
          ),
          centerTitle: false,
          elevation: 0.0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: FlutterFlowTheme.of(context).alternate,
              height: 1.0,
            ),
          ),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                child: SingleChildScrollView(
                  primary: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: _showAddPecaDialog,
                                child: wrapWithModel(
                                  model: _model.quickActionCardModel1, 
                                  updateCallback: () => safeSetState(() {}),
                                  child: QuickActionCardWidget(
                                    icon: Icon(Icons.note_add_rounded, color: FlutterFlowTheme.of(context).primary, size: 24.0),
                                    title: 'Nova Peça',
                                    subtitle: 'Criar documento',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: () async {
                                  await context.pushNamed(AddTopicModalWidget.routeName);
                                  await _loadDataFromSupabase();
                                },
                                child: wrapWithModel(
                                  model: _model.quickActionCardModel2, 
                                  updateCallback: () => safeSetState(() {}),
                                  child: QuickActionCardWidget(
                                    icon: Icon(Icons.add_box_rounded, color: FlutterFlowTheme.of(context).primary, size: 24.0),
                                    title: 'Novo Tópico',
                                    subtitle: 'Adicionar texto',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Selecionar Peça',
                              style: FlutterFlowTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                    color: FlutterFlowTheme.of(context).primaryText,
                                  ),
                            ),
                            if (_isLoadingData)
                              const Center(child: CircularProgressIndicator())
                            else
                              Wrap(
                                spacing: 12.0, runSpacing: 12.0,
                                children: areaPecas.map((peca) => _buildPecaCard(peca)).toList(),
                              ),
                          ].divide(const SizedBox(height: 16.0)),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Dados do Cliente',
                              style: FlutterFlowTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                    color: FlutterFlowTheme.of(context).primaryText,
                                  ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'ENDEREÇAMENTO', hint: _enderecamentoHint, controller: _enderecamentoController,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'NOME DO CLIENTE', hint: 'Ex: João Silva', controller: _nomeController,
                                          ),
                                        ),
                                        const SizedBox(width: 16.0),
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'CPF', hint: '000.000.000-00', controller: _cpfController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'RÉU / DESTINATÁRIO', hint: 'Nome da Empresa ou Nome Contrário', controller: _reuController,
                                          ),
                                        ),
                                        const SizedBox(width: 16.0),
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'NÚMERO DO PROCESSO', hint: '0000000-00.0000.0.00.0000', controller: _processoController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, ProcessoInputFormatter()],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_dynamicControllers.isNotEmpty)
                                      ..._dynamicControllers.entries.map((entry) {
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: _buildInputField(
                                                label: entry.key.toUpperCase(), hint: 'Insira o(a) ${entry.key}', controller: entry.value,
                                              ),
                                            ),
                                          ]
                                        );
                                      }).toList(),
                                  ].divide(const SizedBox(height: 16.0)),
                                ),
                              ),
                            ),
                          ].divide(const SizedBox(height: 16.0)),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Selecionar Tópicos',
                                  style: FlutterFlowTheme.of(context).titleMedium.override(
                                        font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                        color: FlutterFlowTheme.of(context).primaryText,
                                      ),
                                ),
                                Container(
                                  decoration: BoxDecoration(color: const Color(0x1A10B981), borderRadius: BorderRadius.circular(9999.0)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_rounded, color: FlutterFlowTheme.of(context).success, size: 14.0),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          '${selectedTopics.length} selecionados',
                                          style: FlutterFlowTheme.of(context).labelSmall.override(
                                                font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                color: FlutterFlowTheme.of(context).success,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_isLoadingData)
                                  const SizedBox.shrink()
                                else if (dynamicTopics.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                                    child: Text(
                                      _selectedPeca == null
                                          ? 'Nenhuma peça criada nesta área.\nClique em "Nova Peça" para começar.'
                                          : 'Nenhum tópico criado para a peça "$_selectedPeca".\nClique em "Novo Tópico" para começar.',
                                      textAlign: TextAlign.center,
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).secondaryText,
                                          ),
                                    ),
                                  )
                                else
                                  ...dynamicTopics.map((topic) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: _buildTopicCard(topic),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ].divide(const SizedBox(height: 16.0)),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Visualização do Documento',
                              style: FlutterFlowTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                    color: FlutterFlowTheme.of(context).primaryText,
                                  ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 180.0),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                  border: Border.all(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedPeca ?? '', 
                                              style: FlutterFlowTheme.of(context).labelLarge.override(
                                                    font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                    color: FlutterFlowTheme.of(context).primary,
                                                  ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _copyToClipboardAsHtml(),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: FlutterFlowTheme.of(context).primaryBackground,
                                                borderRadius: BorderRadius.circular(8.0),
                                                border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.content_copy_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 16.0),
                                                  const SizedBox(width: 6.0),
                                                  Text(
                                                    'Copiar',
                                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                                          color: FlutterFlowTheme.of(context).primaryText,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(height: 16.0, thickness: 1.0, color: FlutterFlowTheme.of(context).alternate),
                                      const SizedBox(height: 8.0),
                                      _buildRichDocumentPreview(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ].divide(const SizedBox(height: 16.0)),
                        ),
                      ].divide(const SizedBox(height: 24.0)),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Container(
                decoration: BoxDecoration(color: FlutterFlowTheme.of(context).secondaryBackground),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 1.0, color: FlutterFlowTheme.of(context).alternate),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Formato de Saída', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).secondaryText)),
                          Row(
                            children: [
                              Icon(Icons.description_rounded, color: FlutterFlowTheme.of(context).primary, size: 20.0),
                              const SizedBox(width: 4.0),
                              Text('.doc', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(fontWeight: FontWeight.bold), color: FlutterFlowTheme.of(context).primaryText)),
                              const SizedBox(width: 24.0),
                              InkWell(
                                onTap: () => _downloadAsDoc(),
                                child: Container(
                                  decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary, borderRadius: BorderRadius.circular(8.0)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.download_rounded, color: Colors.white, size: 20.0),
                                      const SizedBox(width: 8.0),
                                      Text('Gerar Arquivo', style: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(fontWeight: FontWeight.w600), color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}