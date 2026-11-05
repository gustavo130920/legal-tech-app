import 'package:flutter/material.dart';

const String testEnvironmentMessage =
    'Ambiente de testes: use apenas dados fictícios, nunca informações de clientes ou processos reais.';

/// Aviso exibido enquanto a plataforma estiver em avaliação.
class TestEnvironmentNotice extends StatelessWidget {
  const TestEnvironmentNotice({super.key});

  static const Color _color = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Icon(Icons.info_outline_rounded, color: _color, size: 18.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              testEnvironmentMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
