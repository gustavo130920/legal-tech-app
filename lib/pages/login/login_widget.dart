import '/components/social_button/social_button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _rememberMe = false;
  bool _passwordVisibility = false;
  bool _isLoading = false;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
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

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha E-mail e Senha.')),
      );
      return;
    }

    safeSetState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        context.pushNamed(MainMenuWidget.routeName);
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de Login: ${error.message}'), backgroundColor: Colors.red),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64.0, height: 64.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context).primary,
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    alignment: const AlignmentDirectional(0.0, 0.0),
                                    child: Icon(Icons.balance_rounded, color: FlutterFlowTheme.of(context).onPrimary, size: 32.0),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'LEGALTECH',
                                        style: FlutterFlowTheme.of(context).headlineMedium.override(
                                              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                                              color: FlutterFlowTheme.of(context).primaryText,
                                              lineHeight: 1.35,
                                            ),
                                      ),
                                      Text(
                                        'Documentos Inteligentes',
                                        style: FlutterFlowTheme.of(context).bodySmall.override(
                                              font: GoogleFonts.inter(),
                                              color: FlutterFlowTheme.of(context).secondaryText,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ].divide(const SizedBox(height: 4.0)),
                                  ),
                                ].divide(const SizedBox(height: 16.0)),
                              ),
                            ),
                            Container(
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
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Login',
                                          style: FlutterFlowTheme.of(context).titleLarge.override(
                                                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                                                color: FlutterFlowTheme.of(context).primaryText,
                                              ),
                                        ),
                                        Text('Bem-vindo de volta', style: FlutterFlowTheme.of(context).bodySmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).secondaryText)),
                                      ].divide(const SizedBox(height: 4.0)),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildCustomInput(
                                          label: 'E-mail Profissional',
                                          hint: 'seu@email.com',
                                          icon: Icons.mail_outline_rounded,
                                          controller: _emailController,
                                          textInputAction: TextInputAction.next,
                                        ),
                                        _buildCustomInput(
                                          label: 'Senha',
                                          hint: '••••••••',
                                          icon: Icons.lock_outline_rounded,
                                          controller: _passwordController,
                                          isPassword: true,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _fazerLogin(),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              onTap: () => safeSetState(() => _rememberMe = !_rememberMe),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 18.0, height: 18.0,
                                                    decoration: BoxDecoration(
                                                      color: _rememberMe ? FlutterFlowTheme.of(context).primary : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(4.0),
                                                      border: Border.all(
                                                        color: _rememberMe ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).alternate,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: _rememberMe ? const Icon(Icons.check_rounded, color: Colors.white, size: 12.0) : null,
                                                  ),
                                                  const SizedBox(width: 8.0),
                                                  Text('Lembrar de mim', style: FlutterFlowTheme.of(context).bodySmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).secondaryText)),
                                                ],
                                              ),
                                            ),
                                            FFButtonWidget(
                                              onPressed: () async => context.pushNamed(RecoverPasswordWidget.routeName),
                                              text: 'Esqueceu a senha?',
                                              options: FFButtonOptions(
                                                color: Colors.transparent,
                                                textStyle: FlutterFlowTheme.of(context).bodySmall.override(
                                                      font: GoogleFonts.inter(),
                                                      color: FlutterFlowTheme.of(context).primary,
                                                    ),
                                                elevation: 0.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ].divide(const SizedBox(height: 16.0)),
                                    ),
                                    FFButtonWidget(
                                      onPressed: _isLoading ? null : _fazerLogin,
                                      text: _isLoading ? 'Entrando...' : 'Entrar',
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
                                    wrapWithModel(
                                      model: _model.socialButtonModel,
                                      updateCallback: () => safeSetState(() {}),
                                      child: const SocialButtonWidget(icon: 'https://cdn.simpleicons.org/google/111827.svg', label: 'Entrar com Google'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Não possui uma conta?', style: FlutterFlowTheme.of(context).bodySmall),
                                          FFButtonWidget(
                                            onPressed: () async => context.pushNamed(RegisterWidget.routeName),
                                            text: 'Cadastre-se',
                                            options: FFButtonOptions(
                                              color: Colors.transparent,
                                              textStyle: FlutterFlowTheme.of(context).bodySmall.override(
                                                    font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                    color: FlutterFlowTheme.of(context).primary,
                                                  ),
                                              elevation: 0.0,
                                            ),
                                          ),
                                        ].divide(const SizedBox(width: 4.0)),
                                      ),
                                    ),
                                  ].divide(const SizedBox(height: 24.0)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}