// widgets/dialogs/feedback_dialog.dart - VERSION AVEC TRADUCTIONS LOCALES
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/contact/contact_bloc.dart';
import 'package:epilist/blocs/contact/contact_event.dart';
import 'package:epilist/blocs/contact/contact_state.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

import '../../models/feedback_models.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String? _selectedFeedbackType;
  String? _selectedPriority;

  List<FeedbackType> _feedbackTypes = [];
  List<PriorityLevel> _priorities = [];
  bool _isLoading = false;
  bool _dataLoaded = false;

  // Sauvegarder le BLoC pour éviter les erreurs de contexte
  late ContactBloc _contactBloc;

  @override
  void initState() {
    super.initState();
    _contactBloc = context.read<ContactBloc>();

    // Charger les types de feedback au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contactBloc.add(LoadFeedbackTypes());
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ==================== TRADUCTIONS LOCALES ====================

  /// ✅ NOUVEAU: Traduit localement les types de feedback avec fallback
  String _translateFeedbackTypeLabel(
    String value,
    String? serverLabel,
    AppLocalizations l10n,
  ) {
    // Priorité : utiliser les traductions locales
    switch (value) {
      case 'bug':
        return l10n.bugReport;
      case 'feature':
        return l10n.newFeature;
      case 'improvement':
        return l10n.improvement;
      case 'question':
        return l10n.question;
      case 'other':
        return l10n.other;
      default:
        // Fallback : utiliser le label du serveur ou une valeur par défaut
        return serverLabel ?? value;
    }
  }

  /// ✅ NOUVEAU: Traduit localement les descriptions avec fallback
  String _translateFeedbackTypeDescription(
    String value,
    String? serverDescription,
    AppLocalizations l10n,
  ) {
    switch (value) {
      case 'bug':
        return l10n.bugReportDescription;
      case 'feature':
        return l10n.newFeatureDescription;
      case 'improvement':
        return l10n.improvementDescription;
      case 'question':
        return l10n.questionDescription;
      case 'other':
        return l10n.otherDescription;
      default:
        return serverDescription ?? '';
    }
  }

  /// ✅ NOUVEAU: Traduit localement les priorités avec fallback
  String _translatePriorityLabel(
    String value,
    String? serverLabel,
    AppLocalizations l10n,
  ) {
    switch (value) {
      case 'low':
        return l10n.priorityLow;
      case 'normal':
        return l10n.priorityNormal;
      case 'high':
        return l10n.priorityHigh;
      case 'urgent':
        return l10n.priorityUrgent;
      default:
        return serverLabel ?? value;
    }
  }

  /// ✅ NOUVEAU: Obtient l'icône locale pour chaque type
  String _getFeedbackTypeIcon(String value) {
    switch (value) {
      case 'bug':
        return '🐛';
      case 'feature':
        return '💡';
      case 'improvement':
        return '🚀';
      case 'question':
        return '❓';
      case 'other':
      default:
        return '💬';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocListener<ContactBloc, ContactState>(
              listener: (context, state) {
                print('🔄 ContactBloc State: ${state.runtimeType}');

                if (state is FeedbackSent) {
                  print('✅ Feedback envoyé avec succès');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.of(context).pop();
                      SmartSnackBarManager.showSuccessSnackBar(
                        context,
                        state.message,
                        duration: const Duration(seconds: 4),
                      );
                    }
                  });
                } else if (state is ContactFailure) {
                  print('❌ Erreur ContactFailure: ${state.error}');
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    SmartSnackBarManager.showErrorSnackBar(
                      context,
                      state.error,
                    );
                  }
                } else if (state is FeedbackTypesLoaded) {
                  print(
                    '📋 Types de feedback chargés: ${state.feedbackTypes.length} types',
                  );
                  if (mounted) {
                    setState(() {
                      _feedbackTypes = state.feedbackTypes;
                      _priorities = state.priorities;
                      _isLoading = false;

                      // Initialiser les valeurs par défaut
                      if (!_dataLoaded) {
                        if (_feedbackTypes.isNotEmpty &&
                            _selectedFeedbackType == null) {
                          _selectedFeedbackType = _feedbackTypes.first.value;
                          print('🎯 Type par défaut: $_selectedFeedbackType');
                        }
                        if (_priorities.isNotEmpty &&
                            _selectedPriority == null) {
                          _selectedPriority = _priorities.first.value;
                          print('🎯 Priorité par défaut: $_selectedPriority');
                        }
                        _dataLoaded = true;
                      }
                    });
                  }
                } else if (state is ContactLoading) {
                  print('⏳ ContactLoading...');
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                    });
                  }
                } else if (state is ContactInitial) {
                  print('🔄 ContactInitial');
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIcon(),
                      const SizedBox(height: 20),
                      _buildTitle(l10n),
                      const SizedBox(height: 12),
                      _buildDescription(l10n),
                      const SizedBox(height: 24),
                      _buildForm(l10n),
                      const SizedBox(height: 24),
                      _buildButtons(l10n),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.feedback_outlined, size: 40, color: Colors.green[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.sendFeedback,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.feedbackDescription,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Type et priorité en ligne
          if (_dataLoaded &&
              _feedbackTypes.isNotEmpty &&
              _priorities.isNotEmpty) ...[
            _buildTypeAndPriorityRow(l10n),
            const SizedBox(height: 16),
          ] else if (_isLoading || !_dataLoaded) ...[
            _buildLoadingIndicator(),
            const SizedBox(height: 16),
          ],

          _buildSubjectField(l10n),
          const SizedBox(height: 16),
          _buildMessageField(l10n),
          const SizedBox(height: 16),
          _buildPrivacyNote(l10n),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.loadingOptions,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeAndPriorityRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildFeedbackTypeField(l10n)),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: _buildPriorityField(l10n)),
      ],
    );
  }

  Widget _buildFeedbackTypeField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.feedbackType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFeedbackType,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              items:
                  _feedbackTypes.map((type) {
                    // ✅ CORRECTION: Utiliser les traductions locales
                    final localIcon = _getFeedbackTypeIcon(type.value);
                    final localLabel = _translateFeedbackTypeLabel(
                      type.value,
                      type.label,
                      l10n,
                    );

                    return DropdownMenuItem<String>(
                      value: type.value,
                      child: Row(
                        children: [
                          Text(localIcon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              localLabel,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged:
                  _isLoading
                      ? null
                      : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFeedbackType = value;
                          });
                        }
                      },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.priority,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPriority,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              items:
                  _priorities.map((priority) {
                    // ✅ CORRECTION: Utiliser les traductions locales
                    final localLabel = _translatePriorityLabel(
                      priority.value,
                      priority.label,
                      l10n,
                    );

                    return DropdownMenuItem<String>(
                      value: priority.value,
                      child: Text(
                        localLabel,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
              onChanged:
                  _isLoading
                      ? null
                      : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPriority = value;
                          });
                        }
                      },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectField(AppLocalizations l10n) {
    return TextFormField(
      controller: _subjectController,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: l10n.subject,
        hintText: l10n.subjectHint,
        prefixIcon: Icon(Icons.title, color: Colors.blue[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        counterText: '', // Masquer le compteur
      ),
      maxLength: 200,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.subjectRequired;
        }
        if (value.trim().length < 5) {
          return l10n.subjectTooShort;
        }
        return null;
      },
    );
  }

  Widget _buildMessageField(AppLocalizations l10n) {
    return TextFormField(
      controller: _messageController,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: l10n.message,
        hintText: l10n.messageHint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: Icon(Icons.message, color: Colors.green[600]),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[600]!, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        alignLabelWithHint: true,
        counterText: '', // Masquer le compteur
      ),
      maxLines: 6,
      minLines: 4,
      maxLength: 2000,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.messageRequired;
        }
        if (value.trim().length < 10) {
          return l10n.messageTooShort;
        }
        return null;
      },
    );
  }

  Widget _buildPrivacyNote(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.privacy_tip_outlined, color: Colors.blue[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.feedbackPrivacyNote,
              style: TextStyle(fontSize: 11, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green[300],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          l10n.send,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  void _sendFeedback() {
    if (_formKey.currentState?.validate() ?? false) {
      // Validation côté client pour s'assurer que les valeurs sont définies
      if (_selectedFeedbackType == null || _selectedPriority == null) {
        final l10n = AppLocalizations.of(context)!;
        SmartSnackBarManager.showWarningSnackBar(
          context,
          l10n.pleaseSelectFeedbackTypeAndPriority,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final feedbackType = _selectedFeedbackType!;
      final priority = _selectedPriority!;

      print('🚀 Envoi du feedback: $feedbackType - $priority');

      _contactBloc.add(
        SendFeedback(
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          feedbackType: feedbackType,
          priority: priority,
        ),
      );
    }
  }
}
