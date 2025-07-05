// widgets/dialogs/delete_account_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _reasonController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showCodeStep = false;
  bool _confirmDeletion = false;
  bool _isLoading = false;
  String? _userEmail;

  @override
  void dispose() {
    _reasonController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      child: AlertDialog(
        title: _buildTitle(),
        content: _buildContent(),
        actions: _buildActions(),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(Icons.warning_rounded, color: Colors.red[600], size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _showCodeStep ? 'Confirmer la suppression' : 'Supprimer le compte',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Traitement en cours...'),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_showCodeStep) ..._buildFirstStep(),
            if (_showCodeStep) ..._buildSecondStep(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFirstStep() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ ATTENTION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette action est définitive et irréversible !',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      Text(
        'Ce qui sera supprimé :',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
      ),
      const SizedBox(height: 8),

      _buildDeletionItem('• Votre profil et informations personnelles'),
      _buildDeletionItem('• Toutes vos listes d\'épicerie privées'),
      _buildDeletionItem('• Vos préférences et paramètres'),
      _buildDeletionItem('• Votre historique d\'achats'),

      const SizedBox(height: 16),

      Text(
        'Ce qui sera préservé :',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
      ),
      const SizedBox(height: 8),

      Text(
        '• Les listes partagées avec d\'autres utilisateurs (anonymisées)',
        style: TextStyle(color: Colors.green[600], fontSize: 14),
      ),

      const SizedBox(height: 20),

      TextFormField(
        controller: _reasonController,
        decoration: const InputDecoration(
          labelText: 'Raison (optionnelle)',
          hintText: 'Pourquoi supprimez-vous votre compte ?',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        maxLength: 500,
      ),

      const SizedBox(height: 16),

      CheckboxListTile(
        value: _confirmDeletion,
        onChanged: (value) => setState(() => _confirmDeletion = value!),
        title: const Text('Je comprends que cette action est irréversible'),
        subtitle: const Text(
          'Toutes mes données seront définitivement supprimées',
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.red[600],
      ),
    ];
  }

  List<Widget> _buildSecondStep() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.mail_outline, size: 48, color: Colors.orange[600]),
            const SizedBox(height: 12),
            const Text(
              'Code de vérification envoyé',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Un code de vérification a été envoyé à $_userEmail',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      TextFormField(
        controller: _codeController,
        decoration: const InputDecoration(
          labelText: 'Code de vérification *',
          hintText: 'Entrez le code à 6 chiffres',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.security),
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Le code est requis';
          }
          if (value.length != 6) {
            return 'Le code doit contenir 6 chiffres';
          }
          return null;
        },
      ),

      const SizedBox(height: 16),

      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Le code expire dans 2 heures',
                style: TextStyle(color: Colors.blue[700], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildDeletionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(color: Colors.red[600], fontSize: 14)),
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),

      if (!_showCodeStep)
        ElevatedButton(
          onPressed: _confirmDeletion && !_isLoading ? _requestDeletion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Demander la suppression'),
        ),

      if (_showCodeStep)
        ElevatedButton(
          onPressed: !_isLoading ? _confirmDeletionWithCode : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmer la suppression'),
        ),
    ];
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    setState(() => _isLoading = false);

    if (state is AccountDeletionCodeSent) {
      setState(() {
        _showCodeStep = true;
        _userEmail = state.email;
      });

      SmartSnackBarManager.showSuccessSnackBar(
        context,
        'Code de vérification envoyé ! Vérifiez votre email.',
      );
    } else if (state is AccountDeletionConfirmed) {
      Navigator.pop(context);

      SmartSnackBarManager.showInfoSnackBar(
        context,
        'Votre compte sera supprimé le ${_formatDate(state.deletionEffectiveDate)}. '
        'Vous avez 30 jours pour annuler cette action.',
        duration: const Duration(seconds: 5),
      );
    } else if (state is AuthFailure) {
      SmartSnackBarManager.showErrorSnackBar(context, state.error);
    }
  }

  void _requestDeletion() {
    if (!_confirmDeletion) return;

    setState(() => _isLoading = true);

    context.read<AuthBloc>().add(
      RequestAccountDeletion(reason: _reasonController.text.trim()),
    );
  }

  void _confirmDeletionWithCode() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    context.read<AuthBloc>().add(
      ConfirmAccountDeletion(
        deletionCode: _codeController.text.trim(),
        reason: _reasonController.text.trim(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
