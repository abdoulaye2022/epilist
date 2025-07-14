import 'package:epilist/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      child: AlertDialog(
        title: _buildTitle(l10n),
        content: _buildContent(l10n),
        actions: _buildActions(l10n),
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Row(
      children: [
        Icon(Icons.warning_rounded, color: Colors.red[600], size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _showCodeStep ? l10n.confirmDeletion : l10n.deleteAccount,
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

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.processingInProgress),
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
            if (!_showCodeStep) ..._buildFirstStep(l10n),
            if (_showCodeStep) ..._buildSecondStep(l10n),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFirstStep(AppLocalizations l10n) {
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
              l10n.attention,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.actionDefinitiveIrreversible,
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
        l10n.whatWillBeDeleted,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
      ),
      const SizedBox(height: 8),

      _buildDeletionItem(l10n.profileAndPersonalInfo),
      _buildDeletionItem(l10n.allPrivateGroceryLists),
      _buildDeletionItem(l10n.preferencesAndSettings),
      _buildDeletionItem(l10n.purchaseHistory),

      const SizedBox(height: 16),

      Text(
        l10n.whatWillBePreserved,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
      ),
      const SizedBox(height: 8),

      Text(
        l10n.sharedListsAnonymized,
        style: TextStyle(color: Colors.green[600], fontSize: 14),
      ),

      const SizedBox(height: 20),

      TextFormField(
        controller: _reasonController,
        decoration: InputDecoration(
          labelText: l10n.reasonOptional,
          hintText: l10n.whyDeleteAccount,
          border: const OutlineInputBorder(),
        ),
        maxLines: 3,
        maxLength: 500,
      ),

      const SizedBox(height: 16),

      CheckboxListTile(
        value: _confirmDeletion,
        onChanged: (value) => setState(() => _confirmDeletion = value!),
        title: Text(l10n.understandIrreversible),
        subtitle: Text(l10n.allDataWillBeDeleted),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.red[600],
      ),
    ];
  }

  List<Widget> _buildSecondStep(AppLocalizations l10n) {
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
            Text(
              l10n.verificationCodeSent,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.verificationCodeSentToEmail(_userEmail ?? ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      TextFormField(
        controller: _codeController,
        decoration: InputDecoration(
          labelText: l10n.verificationCodeRequired,
          hintText: l10n.sixDigitCodeHint,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.security),
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.codeRequired;
          }
          if (value.length != 6) {
            return l10n.codeMustBeSixDigits;
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
                l10n.codeExpiresInTwoHours,
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

  List<Widget> _buildActions(AppLocalizations l10n) {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: Text(l10n.cancel),
      ),

      if (!_showCodeStep)
        ElevatedButton(
          onPressed: _confirmDeletion && !_isLoading ? _requestDeletion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.requestDeletion),
        ),

      if (_showCodeStep)
        ElevatedButton(
          onPressed: !_isLoading ? _confirmDeletionWithCode : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.confirmDeletionWithCode),
        ),
    ];
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = false);

    if (state is AccountDeletionCodeSent) {
      setState(() {
        _showCodeStep = true;
        _userEmail = state.email;
      });

      SmartSnackBarManager.showSuccessSnackBar(
        context,
        l10n.verificationCodeSentCheckEmail,
      );
    } else if (state is AccountDeletionConfirmed) {
      Navigator.pop(context);

      SmartSnackBarManager.showInfoSnackBar(
        context,
        l10n.accountWillBeDeletedOn(_formatDate(state.deletionEffectiveDate)),
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
        '${date.month.toString().padLeft(2, '0')}'
        '/${date.year}';
  }
}
