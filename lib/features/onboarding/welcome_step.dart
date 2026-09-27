import 'package:flutter/material.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bem-vinda ao VaiViver', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'O VaiViver bloqueia a aba Reels do Instagram e limita quanto tempo '
            'você rola o Feed. Para isso, ele precisa de algumas permissões — '
            'vamos te guiar por cada uma.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onNext, child: const Text('Próximo')),
        ],
      ),
    );
  }
}
