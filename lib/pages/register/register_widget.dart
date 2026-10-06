import '/components/social_button/social_button_widget.dart';
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
import 'register_model.dart';
export 'register_model.dart';

class RegisterWidget extends StatefulWidget {
  const RegisterWidget({super.key});

  static String routeName = 'Register';
  static String routePath = '/register';

  @override
  State<RegisterWidget> createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  late RegisterModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _acceptTerms = false;
  bool _passwordVisibility = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegisterModel());
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _model.dispose();
    super.dispose();
  }

  Widget _buildCustomInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
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
          obscureText: isPassword && !_passwordVisibility,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                  font: GoogleFonts.inter(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
            prefixIcon: Icon(icon, color: FlutterFlowTheme.of(context).secondaryText, size: 20.0),
            suffixIcon: isPassword
                ? InkWell(
                    onTap: () => safeSetState(() => _passwordVisibility = !_passwordVisibility),
                    focusNode: FocusNode(skipTraversal: true),
                    child: Icon(
                      _passwordVisibility ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 20.0,
                    ),
                  )
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
            contentPadding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(),
                color: FlutterFlowTheme.of(context).primaryText,
              ),
        ),
      ],
    );
  }

  // AUDITORIA E SEGURANÇA: Validação forte de senha mitigando OWASP A07
  Future<void> _fazerCadastro() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    // Regras de Complexidade de Senha
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segurança: A senha deve ter pelo menos 8 caracteres.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segurança: A senha deve conter pelo menos 1 letra maiúscula.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segurança: A senha deve conter pelo menos 1 letra minúscula.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segurança: A senha deve conter pelo menos 1 número.'), backgroundColor: Colors.orange),
      );
      return;
    }
    // Verifica se há pelo menos um caractere que NÃO seja letra ou número
    if (!password.contains(RegExp(r'[^a-zA-Z0-9]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Segurança: A senha deve conter pelo menos 1 caractere especial (ex: @, #, !, &, etc).'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos para continuar.')),
      );
      return;
    }

    safeSetState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso! Faça login para continuar.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pushNamed(LoginWidget.routeName);
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no Supabase: ${error.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e'), backgroundColor: Colors.red),
      );
    } finally {
      safeSetState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24.0, top: 16.0, right: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 8.0,
                      buttonSize: 40.0,
                      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                      onPressed: () async => context.safePop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 450.0),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Criar Conta',
                                      style: FlutterFlowTheme.of(context).headlineMedium.override(
                                            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                            color: FlutterFlowTheme.of(context).primaryText,
                                          ),
                                    ),
                                    Text(
                                      'Junte-se à plataforma líder em automação jurídica.',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            font: GoogleFonts.inter(),
                                            color: FlutterFlowTheme.of(context).secondaryText,
                                          ),
                                    ),
                                    const SizedBox(height: 24.0),
                                    _buildCustomInput(
                                      label: 'Nome Completo',
                                      hint: 'Ex: João Silva',
                                      icon: Icons.person_outline_rounded,
                                      controller: _nameController,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 16.0),
                                    _buildCustomInput(
                                      label: 'E-mail Profissional',
                                      hint: 'seu@email.com',
                                      icon: Icons.mail_outline_rounded,
                                      controller: _emailController,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 16.0),
                                    _buildCustomInput(
                                      label: 'Senha',
                                      hint: 'Forte (Mín. 8 chars, 1A, 1a, 1@)',
                                      icon: Icons.lock_outline_rounded,
                                      controller: _passwordController,
                                      isPassword: true,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _fazerCadastro(),
                                    ),
                                    const SizedBox(height: 16.0),
                                    InkWell(
                                      onTap: () => safeSetState(() => _acceptTerms = !_acceptTerms),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20.0, height: 20.0,
                                            decoration: BoxDecoration(
                                              color: _acceptTerms ? FlutterFlowTheme.of(context).primary : Colors.transparent,
                                              borderRadius: BorderRadius.circular(4.0),
                                              border: Border.all(
                                                color: _acceptTerms ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).alternate,
                                                width: 1.5,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: _acceptTerms ? const Icon(Icons.check_rounded, color: Colors.white, size: 14.0) : null,
                                          ),
                                          const SizedBox(width: 12.0),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(text: 'Li e concordo com os ', style: FlutterFlowTheme.of(context).bodySmall),
                                                  TextSpan(text: 'Termos de Uso', style: FlutterFlowTheme.of(context).bodySmall.override(font: GoogleFonts.inter(fontWeight: FontWeight.bold), color: FlutterFlowTheme.of(context).primary)),
                                                  TextSpan(text: ' e a ', style: FlutterFlowTheme.of(context).bodySmall),
                                                  TextSpan(text: 'Política de Privacidade', style: FlutterFlowTheme.of(context).bodySmall.override(font: GoogleFonts.inter(fontWeight: FontWeight.bold), color: FlutterFlowTheme.of(context).primary)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24.0),
                                    FFButtonWidget(
                                      onPressed: _isLoading ? null : _fazerCadastro,
                                      text: _isLoading ? 'Carregando...' : 'Cadastrar',
                                      options: FFButtonOptions(
                                        width: double.infinity,
                                        height: 48.0,
                                        color: FlutterFlowTheme.of(context).primary,
                                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                              color: Colors.white,
                                            ),
                                        elevation: 0.0,
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: FlutterFlowTheme.of(context).alternate)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: Text('OU', style: FlutterFlowTheme.of(context).labelSmall),
                                        ),
                                        Expanded(child: Divider(color: FlutterFlowTheme.of(context).alternate)),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),
                                    wrapWithModel(
                                      model: _model.socialButtonModel,
                                      updateCallback: () => safeSetState(() {}),
                                      child: const SocialButtonWidget(
                                        icon: 'https://cdn.simpleicons.org/google/111827.svg',
                                        label: 'Cadastrar com Google',
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Já possui uma conta?',
                                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                                  font: GoogleFonts.inter(),
                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                ),
                                          ),
                                          FFButtonWidget(
                                            onPressed: () async => context.pushNamed(LoginWidget.routeName),
                                            text: 'Entrar',
                                            options: FFButtonOptions(
                                              color: Colors.transparent,
                                              textStyle: FlutterFlowTheme.of(context).bodySmall.override(
                                                    font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                    color: FlutterFlowTheme.of(context).primary,
                                                  ),
                                              elevation: 0.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}