import '/components/quick_action_card_widget.dart';
import '/core/errors/user_messages.dart';
import '/core/legal/cnj_number.dart';
import '/features/drafting/domain/document_composer.dart';
import '/features/drafting/ui/workspace_view_model.dart';
import '/features/library/data/library_repository.dart';
import '/features/library/domain/library_models.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/platform/document_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'area_workspace_model.dart';
import '../add_topic_modal/add_topic_modal_widget.dart';
import '../main_menu/main_menu_widget.dart';
export 'area_workspace_model.dart';

import '../../app_state.dart';

const Color _pendingColor = Color(0xFFF59E0B);
const double _twoColumnWidth = 1000.0;

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

  WorkspaceViewModel? _viewModel;

  late final Map<ClientField, TextEditingController> _fieldControllers;
  final Map<String, TextEditingController> _customControllers = {};
  final TextEditingController _searchController = TextEditingController();

  WorkspaceViewModel get _vm => _viewModel!;
  TextEditingController get _processoController => _fieldControllers[ClientField.processo]!;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AreaWorkspaceModel());

    _fieldControllers = {
      for (final field in ClientField.values) field: TextEditingController(),
    };

    final area = widget.area;
    if (area != null && globalAreaDatabase.containsKey(area)) {
      globalCurrentArea = area;
    }

    if (!globalAreaDatabase.containsKey(globalCurrentArea)) {
      // Sem área definida não há como saber o que abrir: nunca assumir uma.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(MainMenuWidget.routeName);
      });
      return;
    }

    _viewModel = WorkspaceViewModel(
      repository: SupabaseLibraryRepository(Supabase.instance.client),
      area: globalCurrentArea,
      currentUserId: () => Supabase.instance.client.auth.currentUser?.id,
    )..addListener(_onViewModelChanged);

    _fieldControllers.forEach((field, controller) {
      controller.addListener(() => _viewModel?.setField(field, controller.text));
    });
    _searchController.addListener(() => _viewModel?.setSearchQuery(_searchController.text));

    _initialize();
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    _viewModel?.dispose();
    _fieldControllers.values.forEach((controller) => controller.dispose());
    _customControllers.values.forEach((controller) => controller.dispose());
    _searchController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _vm.load();
    } catch (e) {
      _showError('Erro ao carregar seus dados', e);
    }
    if (!mounted) return;

    final restored = _vm.restoreDraft();
    _syncControllersFromViewModel();
    if (restored) {
      _showMessage('Recuperamos o que você estava preenchendo nesta sessão.');
    }
  }

  void _onViewModelChanged() {
    _syncCustomControllers();
    if (_searchController.text != _vm.searchQuery) {
      _searchController.text = _vm.searchQuery;
    }
    safeSetState(() {});
  }

  void _syncCustomControllers() {
    final names = _vm.customVariableNames.toSet();

    for (final name in names) {
      _customControllers.putIfAbsent(name, () {
        final controller = TextEditingController(text: _vm.customValue(name));
        controller.addListener(() => _viewModel?.setCustomValue(name, controller.text));
        return controller;
      });
    }

    final removed = _customControllers.keys.where((name) => !names.contains(name)).toList();
    for (final name in removed) {
      final controller = _customControllers.remove(name)!;
      // O campo ainda está na tela até a próxima reconstrução.
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    }
  }

  void _syncControllersFromViewModel() {
    _fieldControllers.forEach((field, controller) {
      final value = _vm.fieldValue(field);
      if (controller.text != value) controller.text = value;
    });
    _syncCustomControllers();
    _customControllers.forEach((name, controller) {
      final value = _vm.customValue(name);
      if (controller.text != value) controller.text = value;
    });
  }

  void _showMessage(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showError(String action, Object error) {
    _showMessage('$action. ${friendlyError(error)}', color: Colors.red);
  }

  Future<void> _openNewTopic() async {
    await context.pushNamed(AddTopicModalWidget.routeName);
    if (!mounted) return;
    try {
      await _vm.load();
    } catch (e) {
      _showError('Erro ao carregar seus dados', e);
    }
  }

  InputDecoration _dialogFieldDecoration({String? hint, String? label, String? helper}) {
    final theme = FlutterFlowTheme.of(context);
    return InputDecoration(
      hintText: hint,
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
      alignLabelWithHint: true,
      labelStyle: TextStyle(color: theme.secondaryText),
      hintStyle: TextStyle(color: theme.secondaryText),
      helperStyle: TextStyle(color: theme.secondaryText),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.alternate, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.primary, width: 1.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: theme.primaryBackground,
    );
  }

  TextStyle get _dialogFieldStyle => FlutterFlowTheme.of(context).bodyMedium.override(
        font: GoogleFonts.inter(),
        color: FlutterFlowTheme.of(context).primaryText,
      );

  Widget _dialogTitle(String text) => Text(
        text,
        style: FlutterFlowTheme.of(context).titleMedium.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              color: FlutterFlowTheme.of(context).primaryText,
            ),
      );

  List<Widget> _dialogActions(BuildContext dialogContext, String confirmLabel, VoidCallback onConfirm) => [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('Cancelar', style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: FlutterFlowTheme.of(context).primary),
          child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
        ),
      ];

  Future<bool> _confirm({required String title, required String message, required String confirmLabel, Color? color}) async {
    final theme = FlutterFlowTheme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        title: Text(title, style: TextStyle(color: theme.primaryText, fontWeight: FontWeight.bold)),
        content: Text(message, style: TextStyle(color: theme.secondaryText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color ?? theme.primary),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result == true && mounted;
  }

  void _showAddPecaDialog() {
    final controller = TextEditingController();

    Future<void> submit(BuildContext dialogContext) async {
      if (controller.text.trim().isEmpty) return;
      try {
        await _vm.createPeca(controller.text);
        if (dialogContext.mounted) Navigator.pop(dialogContext);
        _showMessage('Peça criada com sucesso!', color: Colors.green);
      } catch (e) {
        _showError('Erro ao salvar peça', e);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: _dialogTitle('Nova Peça'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (_) => submit(dialogContext),
          decoration: _dialogFieldDecoration(hint: 'Ex: Réplica, Procuração, Recurso...'),
          style: _dialogFieldStyle,
        ),
        actions: _dialogActions(dialogContext, 'Criar', () => submit(dialogContext)),
      ),
    );
  }

  void _showEditPecaDialog(PecaItem peca) {
    final nameController = TextEditingController(text: peca.name);
    final headerController = TextEditingController(text: _vm.headerTemplateFor(peca.name));

    Future<void> submit(BuildContext dialogContext) async {
      try {
        await _vm.updatePeca(
          oldName: peca.name,
          rawName: nameController.text,
          rawHeader: headerController.text,
        );
        if (dialogContext.mounted) Navigator.pop(dialogContext);
        _showMessage('Peça atualizada com sucesso!', color: Colors.green);
      } catch (e) {
        _showError('Erro ao atualizar peça', e);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: _dialogTitle('Editar Peça'),
        content: SizedBox(
          width: 560.0,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: _dialogFieldDecoration(label: 'Nome da peça'),
                  style: _dialogFieldStyle,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: headerController,
                  minLines: 6,
                  maxLines: 12,
                  decoration: _dialogFieldDecoration(
                    label: 'Cabeçalho da peça',
                    helper: 'Separe os parágrafos com uma linha em branco. Use variáveis como {{ENDEREÇAMENTO}}, {{PROCESSO}}, {{NOME_CLIENTE}}, {{REU}} e {{CPF}}.',
                  ),
                  style: _dialogFieldStyle,
                ),
              ],
            ),
          ),
        ),
        actions: _dialogActions(dialogContext, 'Salvar', () => submit(dialogContext)),
      ),
    );
  }

  Future<void> _deletePeca(PecaItem peca) async {
    final confirmed = await _confirm(
      title: 'Excluir Peça',
      message: 'Tem certeza que deseja excluir "${peca.name}"? Todos os tópicos desta peça também serão apagados.',
      confirmLabel: 'Excluir',
      color: Colors.red,
    );
    if (!confirmed) return;

    try {
      await _vm.deletePeca(peca.name);
      _showMessage('Peça excluída com sucesso!', color: Colors.green);
    } catch (e) {
      _showError('Erro ao excluir peça', e);
    }
  }

  void _showEditTopicDialog(TopicItem topic) {
    final titleController = TextEditingController(text: topic.title);
    final contentController = TextEditingController(text: topic.content);

    Future<void> submit(BuildContext dialogContext) async {
      if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
      try {
        await _vm.updateTopic(
          id: topic.id,
          rawTitle: titleController.text,
          rawContent: contentController.text,
        );
        if (dialogContext.mounted) Navigator.pop(dialogContext);
        _showMessage('Tópico atualizado com sucesso!', color: Colors.green);
      } catch (e) {
        _showError('Erro ao atualizar tópico', e);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: _dialogTitle('Editar Tópico'),
        content: SizedBox(
          width: 560.0,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: _dialogFieldDecoration(label: 'Título do Tópico'),
                  style: _dialogFieldStyle,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: contentController,
                  maxLines: 6,
                  decoration: _dialogFieldDecoration(label: 'Conteúdo do Modelo'),
                  style: _dialogFieldStyle,
                ),
              ],
            ),
          ),
        ),
        actions: _dialogActions(dialogContext, 'Salvar', () => submit(dialogContext)),
      ),
    );
  }

  Future<void> _deleteTopic(TopicItem topic) async {
    final confirmed = await _confirm(
      title: 'Excluir Tópico',
      message: 'Tem certeza que deseja excluir "${topic.title}"?',
      confirmLabel: 'Excluir',
      color: Colors.red,
    );
    if (!confirmed) return;

    try {
      await _vm.deleteTopic(topic.id);
      _showMessage('Tópico excluído com sucesso!', color: Colors.green);
    } catch (e) {
      _showError('Erro ao excluir tópico', e);
    }
  }

  void _applyKit(TopicKit kit) {
    final missing = _vm.applyKit(kit);
    _showMessage(missing == 0
        ? 'Kit "${kit.name}" aplicado.'
        : 'Kit "${kit.name}" aplicado. ${missing == 1 ? '1 tópico não existe mais' : '$missing tópicos não existem mais'}.');
  }

  void _showSaveKitDialog() {
    final controller = TextEditingController();

    Future<void> submit(BuildContext dialogContext) async {
      if (controller.text.trim().isEmpty) return;
      try {
        await _vm.saveSelectionAsKit(controller.text);
        if (dialogContext.mounted) Navigator.pop(dialogContext);
        _showMessage('Kit salvo com sucesso!', color: Colors.green);
      } catch (e) {
        _showError('Erro ao salvar kit', e);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: _dialogTitle('Salvar seleção como kit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (_) => submit(dialogContext),
          decoration: _dialogFieldDecoration(hint: 'Ex: Contestação Banco X'),
          style: _dialogFieldStyle,
        ),
        actions: _dialogActions(dialogContext, 'Salvar', () => submit(dialogContext)),
      ),
    );
  }

  Future<void> _deleteKit(TopicKit kit) async {
    final confirmed = await _confirm(
      title: 'Excluir Kit',
      message: 'Excluir o kit "${kit.name}"? Os tópicos não serão apagados.',
      confirmLabel: 'Excluir',
      color: Colors.red,
    );
    if (!confirmed) return;

    try {
      await _vm.deleteKit(kit.id);
      _showMessage('Kit excluído.');
    } catch (e) {
      _showError('Erro ao excluir kit', e);
    }
  }

  Future<void> _clearClientData() async {
    final confirmed = await _confirm(
      title: 'Limpar dados',
      message: 'Os dados do cliente e os tópicos selecionados serão removidos para iniciar uma nova peça. As peças e os tópicos salvos não são apagados.',
      confirmLabel: 'Limpar',
    );
    if (!confirmed) return;

    _vm.clearClientData();
    _syncControllersFromViewModel();
  }

  void _copyToClipboardAsHtml() {
    if (_vm.selectedTopics.isEmpty) {
      _showMessage('Selecione tópicos antes de copiar.');
      return;
    }
    _runAfterReview('Copiar mesmo assim', _copyDocument);
  }

  void _downloadAsDoc() {
    if (_vm.selectedTopics.isEmpty) {
      _showMessage('Selecione tópicos antes de gerar o documento.');
      return;
    }
    _runAfterReview('Gerar mesmo assim', _generateFile);
  }

  // A ação roda dentro do clique, porque o navegador só libera a área de
  // transferência durante um gesto do usuário.
  void _runAfterReview(String proceedLabel, VoidCallback action) {
    // A conferência do número CNJ é só informativa: qualquer número pode ser usado.
    final pending = _vm.pendingFields;
    if (pending.isEmpty) {
      action();
      return;
    }

    final theme = FlutterFlowTheme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        title: Text('Documento com pendências', style: TextStyle(color: theme.primaryText, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confira antes de usar este documento:', style: TextStyle(color: theme.secondaryText)),
            const SizedBox(height: 12.0),
            ...pending.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('• $field: não preenchido', style: TextStyle(color: theme.primaryText)),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              action();
            },
            child: Text(proceedLabel, style: TextStyle(color: theme.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Voltar e preencher', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _copyDocument() {
    final input = _vm.documentInput;
    final plainText = composePlainText(input);

    if (copyRichTextToClipboard(html: composeHtml(input), plainText: plainText)) {
      _showMessage('Documento copiado. Cole no Word ou no Google Docs.');
    } else {
      Clipboard.setData(ClipboardData(text: plainText));
      _showMessage('Copiado em formato simples (navegador bloqueou formatação).');
    }
  }

  void _generateFile() {
    final downloaded = downloadWordDocument(
      fileName: '${_vm.selectedPeca?.replaceAll(' ', '_')}.doc',
      content: composeWordDocument(_vm.documentInput),
    );
    if (downloaded) {
      _showMessage('Arquivo gerado. Confira a pasta de downloads.');
    } else {
      _showMessage('Não foi possível gerar o arquivo. Tente copiar o documento.', color: Colors.red);
    }
  }

  String get _enderecamentoHint {
    switch (_vm.area) {
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

  Widget _sectionTitle(String text) => Text(
        text,
        style: FlutterFlowTheme.of(context).titleMedium.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              color: FlutterFlowTheme.of(context).primaryText,
            ),
      );

  Widget _checkMark({required bool selected, int? position, double size = 22.0}) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? theme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: selected ? theme.primary : theme.alternate, width: 1.5),
      ),
      alignment: Alignment.center,
      child: !selected
          ? null
          : position != null
              ? Text('$position', style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold))
              : const Icon(Icons.check_rounded, color: Colors.white, size: 14.0),
    );
  }

  Widget _buildPecaCard(PecaItem peca) {
    final theme = FlutterFlowTheme.of(context);
    final isSelected = _vm.selectedPeca == peca.name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: isSelected ? theme.primary : theme.alternate, width: isSelected ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _vm.selectPeca(peca.name),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _checkMark(selected: isSelected, size: 20.0),
                  const SizedBox(width: 8.0),
                  Text(
                    peca.name,
                    style: theme.labelMedium.override(
                      font: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                      color: isSelected ? theme.primaryText : theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            InkWell(
              onTap: () => _showEditPecaDialog(peca),
              child: Icon(Icons.edit_outlined, size: 16.0, color: theme.secondaryText),
            ),
            const SizedBox(width: 6.0),
            InkWell(
              onTap: () => _deletePeca(peca),
              child: const Icon(Icons.delete_outline_rounded, size: 16.0, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(TopicItem topic) {
    final theme = FlutterFlowTheme.of(context);
    final position = _vm.selectedTopicIds.indexOf(topic.id);
    final isSelected = position >= 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: isSelected ? theme.primary : theme.alternate, width: isSelected ? 1.5 : 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            InkWell(
              onTap: () => _vm.toggleTopic(topic.id),
              child: _checkMark(selected: isSelected, position: isSelected ? position + 1 : null),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: InkWell(
                onTap: () => _vm.toggleTopic(topic.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: theme.titleSmall.override(
                        font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      topic.preview,
                      style: theme.bodySmall.override(font: GoogleFonts.inter(), color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Editar tópico',
              icon: const Icon(Icons.edit_outlined, size: 18.0),
              color: theme.secondaryText,
              onPressed: () => _showEditTopicDialog(topic),
            ),
            IconButton(
              tooltip: 'Excluir tópico',
              icon: const Icon(Icons.delete_outline_rounded, size: 18.0),
              color: Colors.redAccent,
              onPressed: () => _deleteTopic(topic),
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
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.labelSmall.override(
            font: GoogleFonts.inter(fontWeight: FontWeight.bold),
            color: theme.secondaryText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.labelMedium.override(font: GoogleFonts.inter(), color: theme.secondaryText),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.alternate, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: theme.primaryBackground,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 12.0),
          ),
          style: theme.bodyMedium.override(font: GoogleFonts.inter(), color: theme.primaryText),
        ),
      ],
    );
  }

  Widget _buildProcessoStatus() {
    final theme = FlutterFlowTheme.of(context);
    final check = checkCnjNumber(_processoController.text);
    final (String message, Color color) = switch (check.status) {
      CnjStatus.empty => ('', Colors.transparent),
      CnjStatus.incomplete => ('Número incompleto', theme.secondaryText),
      CnjStatus.invalid => ('Fora do padrão CNJ. Confira se houve erro de digitação.', _pendingColor),
      CnjStatus.valid => (check.description ?? 'Número válido', theme.success),
    };
    if (message.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Text(message, style: theme.labelSmall.override(font: GoogleFonts.inter(), color: color)),
    );
  }

  Widget _buildQuickActions() => Row(
        children: [
          Expanded(
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
            child: InkWell(
              onTap: _openNewTopic,
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
      );

  Widget _buildPecasSection() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Selecionar Peça'),
          if (_vm.isLoading && _vm.pecas.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: _vm.pecas.map(_buildPecaCard).toList(),
            ),
        ].divide(const SizedBox(height: 16.0)),
      );

  Widget _buildClientSection() {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Dados do Cliente'),
            TextButton.icon(
              onPressed: _clearClientData,
              icon: Icon(Icons.restart_alt_rounded, size: 18.0, color: theme.secondaryText),
              label: Text('Limpar dados', style: TextStyle(color: theme.secondaryText)),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(
                  label: 'ENDEREÇAMENTO',
                  hint: _enderecamentoHint,
                  controller: _fieldControllers[ClientField.enderecamento]!,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'NOME DO CLIENTE',
                        hint: 'Ex: João Silva',
                        controller: _fieldControllers[ClientField.nomeCliente]!,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: _buildInputField(
                        label: 'CPF',
                        hint: '000.000.000-00',
                        controller: _fieldControllers[ClientField.cpf]!,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()],
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'RÉU / DESTINATÁRIO',
                        hint: 'Nome da Empresa ou Nome Contrário',
                        controller: _fieldControllers[ClientField.reu]!,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(
                            label: 'NÚMERO DO PROCESSO',
                            hint: '0000000-00.0000.0.00.0000',
                            controller: _processoController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, ProcessoInputFormatter()],
                          ),
                          _buildProcessoStatus(),
                        ],
                      ),
                    ),
                  ],
                ),
                ..._customControllers.entries.map((entry) => KeyedSubtree(
                      key: ValueKey('variable-${entry.key}'),
                      child: _buildInputField(
                        label: variableLabel(entry.key).toUpperCase(),
                        hint: 'Digite aqui',
                        controller: entry.value,
                      ),
                    )),
              ].divide(const SizedBox(height: 16.0)),
            ),
          ),
        ),
      ].divide(const SizedBox(height: 16.0)),
    );
  }

  Widget _emptyMessage(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
      );

  Widget _buildKitChip(TopicKit kit) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(9999.0),
        border: Border.all(color: theme.primary),
      ),
      padding: const EdgeInsets.only(left: 14.0, right: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _applyKit(kit),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '${kit.name} (${_vm.availableTopicsInKit(kit)})',
                style: theme.labelMedium.override(font: GoogleFonts.inter(fontWeight: FontWeight.w600), color: theme.primaryText),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Excluir kit',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 16.0, color: theme.secondaryText),
            onPressed: () => _deleteKit(kit),
          ),
        ],
      ),
    );
  }

  Widget _buildKitsSection() {
    if (_vm.selectedPeca == null || _vm.topicsOfSelectedPeca.isEmpty) return const SizedBox.shrink();

    final theme = FlutterFlowTheme.of(context);
    final kits = _vm.kitsOfSelectedPeca;
    final canSave = _vm.selectedTopicIds.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Kits de Tópicos'),
            TextButton.icon(
              onPressed: canSave ? _showSaveKitDialog : null,
              icon: Icon(Icons.bookmark_add_outlined, size: 18.0, color: canSave ? theme.primary : theme.secondaryText),
              label: Text('Salvar seleção', style: TextStyle(color: canSave ? theme.primary : theme.secondaryText)),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        if (kits.isEmpty)
          Text(
            'Selecione os tópicos que costuma usar juntos e salve como kit para marcá-los com um clique.',
            style: theme.bodySmall.override(font: GoogleFonts.inter(), color: theme.secondaryText),
          )
        else
          Wrap(spacing: 8.0, runSpacing: 8.0, children: kits.map(_buildKitChip).toList()),
      ],
    );
  }

  Widget _buildTopicsSection() {
    final theme = FlutterFlowTheme.of(context);
    final allTopics = _vm.topicsOfSelectedPeca;
    final visibleTopics = _vm.visibleTopics;
    final selectedCount = _vm.selectedTopicIds.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Selecionar Tópicos'),
            Container(
              decoration: BoxDecoration(color: const Color(0x1A10B981), borderRadius: BorderRadius.circular(9999.0)),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                selectedCount == 1 ? '1 selecionado' : '$selectedCount selecionados',
                style: theme.labelSmall.override(font: GoogleFonts.inter(fontWeight: FontWeight.bold), color: theme.success),
              ),
            ),
          ],
        ),
        if (allTopics.isNotEmpty)
          TextField(
            controller: _searchController,
            decoration: _dialogFieldDecoration(hint: 'Buscar por título ou conteúdo').copyWith(
              prefixIcon: Icon(Icons.search_rounded, color: theme.secondaryText, size: 20.0),
              suffixIcon: _vm.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: Icon(Icons.close_rounded, color: theme.secondaryText, size: 18.0),
                      onPressed: _searchController.clear,
                    ),
            ),
            style: _dialogFieldStyle,
          ),
        if (_vm.isLoading)
          const SizedBox.shrink()
        else if (_vm.selectedPeca == null)
          _emptyMessage('Nenhuma peça criada nesta área.\nClique em "Nova Peça" para começar.')
        else if (allTopics.isEmpty)
          _emptyMessage('Nenhum tópico criado para a peça "${_vm.selectedPeca}".\nClique em "Novo Tópico" para começar.')
        else if (visibleTopics.isEmpty)
          _emptyMessage('Nenhum tópico encontrado para "${_vm.searchQuery}".')
        else
          ...visibleTopics.map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildTopicCard(topic),
              )),
      ].divide(const SizedBox(height: 16.0)),
    );
  }

  Widget _buildOrderSection() {
    final theme = FlutterFlowTheme.of(context);
    final selected = _vm.selectedTopics;
    if (selected.length < 2) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Ordem no Documento'),
        const SizedBox(height: 12.0),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: selected.length,
          onReorder: _vm.moveSelectedTopic,
          itemBuilder: (context, index) {
            final topic = selected[index];
            return Container(
              key: ValueKey('order-${topic.id}'),
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: theme.alternate),
              ),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_indicator_rounded, color: theme.secondaryText, size: 20.0),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '${index + 1}.',
                    style: theme.labelMedium.override(font: GoogleFonts.inter(fontWeight: FontWeight.bold), color: theme.primary),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      topic.title,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.override(font: GoogleFonts.inter(), color: theme.primaryText),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mover para cima',
                    icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20.0),
                    color: theme.secondaryText,
                    onPressed: index == 0 ? null : () => _vm.moveSelectedTopic(index, index - 1),
                  ),
                  IconButton(
                    tooltip: 'Mover para baixo',
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20.0),
                    color: theme.secondaryText,
                    onPressed: index == selected.length - 1 ? null : () => _vm.moveSelectedTopic(index, index + 2),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPendingBanner() {
    if (_vm.selectedTopics.isEmpty) return const SizedBox.shrink();

    final pending = _vm.pendingFields;
    if (pending.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: _pendingColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: _pendingColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${pending.length == 1 ? 'Falta 1 campo' : 'Faltam ${pending.length} campos'}: ${pending.join(', ')}',
        style: FlutterFlowTheme.of(context).bodySmall.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              color: _pendingColor,
            ),
      ),
    );
  }

  /// Folha branca parecida com o documento final. Carlito tem as mesmas medidas
  /// da Calibri, que não está disponível para o navegador desenhar a prévia.
  Widget _buildDocumentSheet() {
    final baseStyle = GoogleFonts.carlito(fontSize: 14.67, height: 1.15, color: Colors.black);
    final titleStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
    final pendingStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: const Color(0xFF92400E),
      backgroundColor: const Color(0xFFFEF3C7),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.0)),
      child: RichText(
        text: TextSpan(
          children: composeSpans(_vm.documentInput).map((span) {
            final style = span.isPending ? pendingStyle : (span.isTitle ? titleStyle : baseStyle);
            return TextSpan(text: span.text, style: style);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Visualização do Documento')),
            InkWell(
              onTap: _copyToClipboardAsHtml,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: theme.alternate),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.content_copy_rounded, color: theme.primaryText, size: 16.0),
                    const SizedBox(width: 6.0),
                    Text(
                      'Copiar',
                      style: theme.bodyMedium.override(font: GoogleFonts.inter(fontWeight: FontWeight.w600), color: theme.primaryText),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          _vm.selectedPeca ?? '',
          style: theme.labelMedium.override(font: GoogleFonts.inter(fontWeight: FontWeight.bold), color: theme.primary),
        ),
        const SizedBox(height: 16.0),
        _buildPendingBanner(),
        _buildDocumentSheet(),
      ],
    );
  }

  Widget _buildFormColumn() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuickActions(),
          _buildPecasSection(),
          _buildClientSection(),
          _buildKitsSection(),
          _buildTopicsSection(),
          _buildOrderSection(),
        ].divide(const SizedBox(height: 24.0)),
      );

  Widget _buildBody() => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _twoColumnWidth) {
            return SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildFormColumn(), const SizedBox(height: 24.0), _buildPreviewSection()],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  primary: false,
                  padding: const EdgeInsets.all(24.0),
                  child: _buildFormColumn(),
                ),
              ),
              Container(width: 1.0, color: FlutterFlowTheme.of(context).alternate),
              Expanded(
                child: SingleChildScrollView(
                  primary: false,
                  padding: const EdgeInsets.all(24.0),
                  child: _buildPreviewSection(),
                ),
              ),
            ],
          );
        },
      );

  Widget _buildFooter() {
    final theme = FlutterFlowTheme.of(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          border: Border(top: BorderSide(color: theme.alternate)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Arquivo Word', style: theme.bodyMedium.override(font: GoogleFonts.inter(), color: theme.secondaryText)),
            Row(
              children: [
                Icon(Icons.description_rounded, color: theme.primary, size: 20.0),
                const SizedBox(width: 4.0),
                Text('.doc', style: theme.bodyMedium.override(font: GoogleFonts.inter(fontWeight: FontWeight.bold), color: theme.primaryText)),
                const SizedBox(width: 24.0),
                InkWell(
                  onTap: _downloadAsDoc,
                  child: Container(
                    decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(8.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Row(
                      children: [
                        const Icon(Icons.download_rounded, color: Colors.white, size: 20.0),
                        const SizedBox(width: 8.0),
                        Text('Gerar Arquivo', style: theme.titleSmall.override(font: GoogleFonts.inter(fontWeight: FontWeight.w600), color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_viewModel == null) {
      return Scaffold(key: scaffoldKey, backgroundColor: theme.primaryBackground);
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.secondaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText, size: 24.0),
            onPressed: () async => context.goNamed(MainMenuWidget.routeName),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                globalAreaDatabase[_vm.area]['title'],
                style: theme.titleMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  color: theme.primaryText,
                ),
              ),
              Text(
                'Montador de Peças',
                style: theme.labelSmall.override(font: GoogleFonts.inter(), color: theme.secondaryText),
              ),
            ],
          ),
          centerTitle: false,
          elevation: 0.0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: theme.alternate, height: 1.0),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }
}
