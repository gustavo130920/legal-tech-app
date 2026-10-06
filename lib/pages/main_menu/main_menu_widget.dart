import '/components/button/button_widget.dart';
import '/components/quick_action/quick_action_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_menu_model.dart';
export 'main_menu_model.dart';

import '../../app_state.dart';

class MainMenuWidget extends StatefulWidget {
  const MainMenuWidget({super.key});

  static String routeName = 'MainMenu';
  static String routePath = '/mainMenu';

  @override
  State<MainMenuWidget> createState() => _MainMenuWidgetState();
}

class _MainMenuWidgetState extends State<MainMenuWidget> {
  late MainMenuModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  late Set<String> _selectedAreas;
  late Set<String> _savedAreas;

  String _userName = 'Usuário';
  String _userInitials = 'US';
  bool _isLoading = true;
  bool _isSavingConfig = false;

  final Map<String, Map<String, dynamic>> _areaData = {
    'Trabalhista': {'icon': Icons.work_rounded},
    'Civil': {'icon': Icons.gavel_rounded},
    'Penal': {'icon': Icons.balance_rounded},
    'Previdenciário': {'icon': Icons.account_balance_rounded},
    'Tributário': {'icon': Icons.attach_money_rounded},
    'Empresarial': {'icon': Icons.corporate_fare_rounded},
    'Contratos': {'icon': Icons.description_rounded},
  };

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainMenuModel());

    _savedAreas = Set.from(globalSavedAreas);
    _selectedAreas = Set.from(globalSavedAreas);

    _initializeDashboard();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final fullName = user.userMetadata?['full_name'] as String? ?? 'Dr. Advogado';
      
      final names = fullName.trim().split(' ');
      String initials = '';
      if (names.isNotEmpty) initials += names.first[0].toUpperCase();
      if (names.length > 1) initials += names.last[0].toUpperCase();

      try {
        final response = await Supabase.instance.client
            .from('user_areas')
            .select('areas')
            .eq('user_id', user.id)
            .maybeSingle();

        if (response != null && response['areas'] != null) {
          final List<dynamic> dbAreas = response['areas'];
          final Set<String> loadedAreas = dbAreas.map((e) => e.toString()).toSet();
          
          globalSavedAreas = loadedAreas;
          _savedAreas = Set.from(loadedAreas);
          _selectedAreas = Set.from(loadedAreas);
        } else {
          // CORREÇÃO: Limpa a tela caso o usuário logado não tenha nenhuma área salva
          globalSavedAreas.clear();
          _savedAreas.clear();
          _selectedAreas.clear();
        }
      } catch (e) {
        print('Erro ao carregar áreas do Supabase: $e');
      }

      safeSetState(() {
        _userName = fullName;
        _userInitials = initials.isNotEmpty ? initials : 'US';
        _isLoading = false;
      });
    } else {
      safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      
      // CORREÇÃO: Limpeza profunda de RAM ao fazer logout para evitar vazamento de dados entre contas
      globalSavedAreas.clear();
      _savedAreas.clear();
      _selectedAreas.clear();
      globalCurrentArea = '';
      
      globalAreaDatabase.forEach((key, value) {
        value['pecas'] = <String>[];
        value['topics'] = <Map<String, dynamic>>[];
      });

      if (mounted) {
        context.goNamed(LoginWidget.routeName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sair da conta: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _toggleArea(String areaName) {
    safeSetState(() {
      if (_selectedAreas.contains(areaName)) {
        _selectedAreas.remove(areaName);
      } else {
        _selectedAreas.add(areaName);
      }
    });
  }

  Future<void> _saveAreasToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    safeSetState(() => _isSavingConfig = true);

    try {
      final areaList = _selectedAreas.toList();

      await Supabase.instance.client.from('user_areas').upsert(
        {
          'user_id': user.id,
          'areas': areaList,
        },
        onConflict: 'user_id',
      );

      safeSetState(() {
        _savedAreas = Set.from(_selectedAreas);
        globalSavedAreas = Set.from(_selectedAreas);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar configurações: $e'), backgroundColor: Colors.red),
      );
    } finally {
      safeSetState(() => _isSavingConfig = false);
    }
  }

  Widget _buildAreaConfigCard({
    required String name,
    required IconData icon,
  }) {
    final isSelected = _selectedAreas.contains(name);

    return InkWell(
      onTap: () => _toggleArea(name),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).alternate,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 20.0,
                height: 20.0,
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
              const SizedBox(width: 16.0),
              Icon(
                icon,
                color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondaryText,
                size: 24.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).labelMedium.override(
                        font: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                        color: isSelected ? FlutterFlowTheme.of(context).primaryText : FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveModuleCard({
    required String name,
    required IconData icon,
    required int topicCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48.0, height: 48.0,
                decoration: BoxDecoration(
                  color: const Color(0x1A14B8A6),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: FlutterFlowTheme.of(context).primary, size: 24.0),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: FlutterFlowTheme.of(context).titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                    ),
                    if (topicCount > 0) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        topicCount == 1 ? '1 Tópico Disponível' : '$topicCount Tópicos Disponíveis',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(),
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá, $_userName',
                                style: FlutterFlowTheme.of(context).titleLarge.override(
                                      font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                      color: FlutterFlowTheme.of(context).primaryText,
                                    ),
                              ),
                              Text(
                                'Bem-vindo ao LegalTech',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                              ),
                            ].divide(const SizedBox(height: 4.0)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44.0, height: 44.0,
                                decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary, shape: BoxShape.circle),
                                alignment: const AlignmentDirectional(0.0, 0.0),
                                child: Text(
                                  _userInitials,
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context).labelMedium.override(
                                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                        color: FlutterFlowTheme.of(context).onPrimary,
                                        fontSize: 16.72,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              IconButton(
                                tooltip: 'Sair da conta',
                                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22.0),
                                onPressed: _signOut,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Configurações da Prática',
                            style: FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).secondaryBackground,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Container(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Selecione suas áreas de atuação para personalizar sua criação de documentos',
                                      style: FlutterFlowTheme.of(context).bodySmall.override(
                                            font: GoogleFonts.inter(),
                                            color: FlutterFlowTheme.of(context).secondaryText,
                                          ),
                                    ),
                                    GridView(
                                      padding: EdgeInsets.zero,
                                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 350.0,
                                        crossAxisSpacing: 16.0, mainAxisSpacing: 16.0, mainAxisExtent: 64.0,
                                      ),
                                      primary: false, shrinkWrap: true, scrollDirection: Axis.vertical,
                                      children: [
                                        _buildAreaConfigCard(name: 'Trabalhista', icon: Icons.work_rounded),
                                        _buildAreaConfigCard(name: 'Civil', icon: Icons.gavel_rounded),
                                        _buildAreaConfigCard(name: 'Penal', icon: Icons.balance_rounded),
                                        _buildAreaConfigCard(name: 'Previdenciário', icon: Icons.account_balance_rounded),
                                        _buildAreaConfigCard(name: 'Tributário', icon: Icons.attach_money_rounded),
                                        _buildAreaConfigCard(name: 'Empresarial', icon: Icons.corporate_fare_rounded),
                                        _buildAreaConfigCard(name: 'Contratos', icon: Icons.description_rounded),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    InkWell(
                                      onTap: _isSavingConfig ? null : _saveAreasToSupabase,
                                      child: wrapWithModel(
                                        model: _model.buttonModel,
                                        updateCallback: () => safeSetState(() {}),
                                        child: ButtonWidget(
                                          icon: Icon(Icons.save_rounded, color: FlutterFlowTheme.of(context).primaryText, size: 24.0),
                                          iconPresent: true, iconEndPresent: false,
                                          content: _isSavingConfig ? 'Salvando...' : 'Salvar Configuração',
                                          variant: 'primary', size: 'medium', fullWidth: true, loading: false, disabled: _isSavingConfig,
                                        ),
                                      ),
                                    ),
                                  ].divide(const SizedBox(height: 16.0)),
                                ),
                              ),
                            ),
                          ),
                        ].divide(const SizedBox(height: 16.0)),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Ações Rápidas',
                            style: FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () async => context.pushNamed(AddTopicModalWidget.routeName),
                                  child: wrapWithModel(
                                    model: _model.quickActionModel1,
                                    updateCallback: () => safeSetState(() {}),
                                    child: QuickActionWidget(
                                      icon: Icon(Icons.add_box_rounded, color: FlutterFlowTheme.of(context).primary, size: 20.0),
                                      label: 'Adicionar Tópico',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ].divide(const SizedBox(height: 16.0)),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Módulos Ativos',
                                style: FlutterFlowTheme.of(context).titleMedium.override(
                                      font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                      color: FlutterFlowTheme.of(context).primaryText,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_savedAreas.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                                  child: Text(
                                    'Nenhum módulo ativo no momento.\nSelecione as áreas acima e clique em "Salvar".',
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                          font: GoogleFonts.inter(),
                                          color: FlutterFlowTheme.of(context).secondaryText,
                                        ),
                                  ),
                                )
                              else
                                ..._savedAreas.map((area) {
                                  final icon = _areaData[area]?['icon'] as IconData? ?? Icons.folder_rounded;
                                  final topicsList = globalAreaDatabase[area]?['topics'] as List?;
                                  final int topicCount = topicsList?.length ?? 0;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _buildActiveModuleCard(
                                      name: area == 'Contratos' ? area : 'Direito $area',
                                      icon: icon,
                                      topicCount: topicCount,
                                      onTap: () {
                                        globalCurrentArea = area;
                                        context.pushNamed(AreaWorkspaceWidget.routeName);
                                      },
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ].divide(const SizedBox(height: 16.0)),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 32.0, 0.0, 32.0),
                        child: Container(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Text(
                            'LegalTech v1.0.5',
                            style: FlutterFlowTheme.of(context).labelSmall.override(
                                  font: GoogleFonts.inter(),
                                  color: FlutterFlowTheme.of(context).onSurface,
                                ),
                          ),
                        ),
                      ),
                    ].divide(const SizedBox(height: 32.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}