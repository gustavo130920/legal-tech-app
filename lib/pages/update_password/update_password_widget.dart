import '/core/errors/user_messages.dart';
import '/core/auth/password_policy.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePasswordWidget extends StatefulWidget {
  const UpdatePasswordWidget({super.key});

  static String routeName = 'UpdatePassword';
  static String routePath = '/updatePassword';

  @override
  State<UpdatePasswordWidget> createState() => _UpdatePasswordWidgetState();
}

class _UpdatePasswordWidgetState extends State<UpdatePasswordWidget> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text;

    final problem = validatePassword(password);
    if (problem != null) {
      _showMessage(problem, Colors.orange);
      return;
    }
    if (password != _confirmationController.text) {
      _showMessage('As senhas informadas não são iguais.', Colors.orange);
      return;
    }

    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      _showMessage('Link inválido ou expirado. Solicite a recuperação de senha novamente.', Colors.red);
      return;
    }

    safeSetState(() => _isSaving = true);

    try {
      await auth.updateUser(UserAttributes(password: password));
      AppStateNotifier.instance.finishPasswordRecovery();
      if (!mounted) return;
      _showMessage('Senha alterada com sucesso!', Colors.green);
      context.goNamed(MainMenuWidget.routeName);
    } on AuthException catch (error) {
      _showMessage('Erro ao alterar a senha. ${friendlyError(error)}', Colors.red);
    } catch (e) {
      _showMessage(friendlyError(e), Colors.red);
    } finally {
      safeSetState(() => _isSaving = false);
    }
  }

  Widget _buildPasswordInput({
    required String label,
    required TextEditingController controller,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 20.0),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450.0),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: FlutterFlowTheme.of(context).alternate, width: 1.0),
              ),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Definir nova senha',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).titleLarge.override(
                          font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                  ),
                  _buildPasswordInput(
                    label: 'Nova senha',
                    controller: _passwordController,
                    textInputAction: TextInputAction.next,
                  ),
                  _buildPasswordInput(
                    label: 'Confirme a nova senha',
                    controller: _confirmationController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _savePassword(),
                  ),
                  FFButtonWidget(
                    onPressed: _isSaving ? null : _savePassword,
                    text: _isSaving ? 'Salvando...' : 'Salvar nova senha',
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
                ].divide(const SizedBox(height: 16.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
