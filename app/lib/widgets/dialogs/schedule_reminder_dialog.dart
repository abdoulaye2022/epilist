// widgets/dialogs/schedule_reminder_dialog.dart - VERSION REDESIGNÉE
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/shopping_reminder_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

class ScheduleReminderDialog extends StatefulWidget {
  final ShoppingList shoppingList;

  const ScheduleReminderDialog({super.key, required this.shoppingList});

  @override
  State<ScheduleReminderDialog> createState() => _ScheduleReminderDialogState();
}

class _ScheduleReminderDialogState extends State<ScheduleReminderDialog> {
  final _storeController = TextEditingController();
  final _customMessageController = TextEditingController();

  DateTime? _selectedDateTime;
  String _selectedQuickOption = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _storeController.dispose();
    _customMessageController.dispose();
    super.dispose();
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 20),
                    _buildTitle(l10n),
                    const SizedBox(height: 12),
                    _buildListInfo(l10n),
                    const SizedBox(height: 24),
                    _buildQuickOptions(l10n),
                    const SizedBox(height: 20),
                    _buildCustomDateTime(l10n),
                    const SizedBox(height: 20),
                    _buildOptionalFields(l10n),
                    const SizedBox(height: 24),
                    _buildButtons(l10n),
                  ],
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.schedule, size: 40, color: Colors.blue[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.scheduleReminder,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildListInfo(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.blue[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shoppingList.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.shoppingList.itemsCount} ${l10n.articles}',
                  style: TextStyle(color: Colors.blue[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOptions(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickOptions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickOptionsGrid(l10n),
      ],
    );
  }

  Widget _buildQuickOptionsGrid(AppLocalizations l10n) {
    final quickOptions = [
      {'key': 'in_2h', 'label': l10n.in2Hours, 'icon': Icons.access_time},
      {'key': 'tomorrow', 'label': l10n.tomorrow, 'icon': Icons.today},
      {'key': 'weekend', 'label': l10n.thisWeekend, 'icon': Icons.weekend},
      {
        'key': 'all',
        'label': l10n.allOfAbove,
        'icon': Icons.notifications_active,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: quickOptions.length,
      itemBuilder: (context, index) {
        final option = quickOptions[index];
        final isSelected = _selectedQuickOption == option['key'];

        return InkWell(
          onTap:
              _isLoading
                  ? null
                  : () => _selectQuickOption(option['key'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[100] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option['icon'] as IconData,
                  size: 24,
                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                ),
                const SizedBox(height: 4),
                Text(
                  option['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomDateTime(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customDateTime,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _isLoading ? null : _selectCustomDateTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDateTime != null
                        ? _formatDateTime(_selectedDateTime!)
                        : l10n.selectDateTime,
                    style: TextStyle(
                      color:
                          _selectedDateTime != null
                              ? Colors.black87
                              : Colors.grey[600],
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalFields(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.optionalFields ?? "Champs optionnels",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _storeController,
          label: l10n.storeName,
          hint: l10n.storeNameHint,
          icon: Icons.store,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _customMessageController,
          label: l10n.customMessage,
          hint: l10n.customMessageHint,
          icon: Icons.message,
          enabled: !_isLoading,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: enabled ? Colors.blue[600] : Colors.grey[400],
        ),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
      ),
      enabled: enabled,
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
          child: ElevatedButton.icon(
            onPressed:
                (_canSchedule() && !_isLoading) ? _scheduleReminder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.blue[300],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.schedule, size: 18),
            label: Flexible(
              child: Text(
                "Programmer", // ✅ Texte court et simple
                style: const TextStyle(
                  fontSize: 13, // ✅ Plus petit avec icône
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _selectQuickOption(String option) {
    setState(() {
      _selectedQuickOption = option;
      _selectedDateTime = null; // Reset custom selection
    });
  }

  Future<void> _selectCustomDateTime() async {
    final now = DateTime.now();

    // Sélection de la date
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null) return;

    // Sélection de l'heure
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _selectedQuickOption = ''; // Reset quick option
    });
  }

  bool _canSchedule() {
    return _selectedQuickOption.isNotEmpty || _selectedDateTime != null;
  }

  Future<void> _scheduleReminder() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
    });

    try {
      final storeName = _storeController.text.trim();
      final customMessage = _customMessageController.text.trim();

      if (_selectedQuickOption.isNotEmpty) {
        await _scheduleQuickOption(
          _selectedQuickOption,
          storeName,
          customMessage,
        );
      } else if (_selectedDateTime != null) {
        await ShoppingReminderService.scheduleShoppingReminder(
          shoppingList: widget.shoppingList,
          reminderTime: _selectedDateTime!,
          storeName: storeName.isNotEmpty ? storeName : null,
          customMessage: customMessage.isNotEmpty ? customMessage : null,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        SmartSnackBarManager.showSuccessSnackBar(
          context,
          l10n.reminderScheduled,
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la programmation du rappel: $e');
      if (mounted) {
        SmartSnackBarManager.showErrorSnackBar(
          context,
          l10n.errorSchedulingReminder,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _scheduleQuickOption(
    String option,
    String storeName,
    String customMessage,
  ) async {
    final now = DateTime.now();

    switch (option) {
      case 'in_2h':
        await ShoppingReminderService.scheduleShoppingReminder(
          shoppingList: widget.shoppingList,
          reminderTime: now.add(const Duration(hours: 2)),
          storeName: storeName.isNotEmpty ? storeName : null,
          customMessage: customMessage.isNotEmpty ? customMessage : null,
        );
        break;

      case 'tomorrow':
        final tomorrow = DateTime(now.year, now.month, now.day + 1, 10, 0);
        await ShoppingReminderService.scheduleShoppingReminder(
          shoppingList: widget.shoppingList,
          reminderTime: tomorrow,
          storeName: storeName.isNotEmpty ? storeName : null,
          customMessage: customMessage.isNotEmpty ? customMessage : null,
        );
        break;

      case 'weekend':
        final weekend = _getNextWeekend(now);
        await ShoppingReminderService.scheduleShoppingReminder(
          shoppingList: widget.shoppingList,
          reminderTime: weekend,
          storeName: storeName.isNotEmpty ? storeName : null,
          customMessage: customMessage.isNotEmpty ? customMessage : null,
        );
        break;

      case 'all':
        await ShoppingReminderService.schedulePopularReminders(
          shoppingList: widget.shoppingList,
          storeName: storeName.isNotEmpty ? storeName : null,
        );
        break;
    }
  }

  DateTime _getNextWeekend(DateTime from) {
    int daysUntilSaturday = (DateTime.saturday - from.weekday) % 7;
    if (daysUntilSaturday == 0) daysUntilSaturday = 7;

    final saturday = from.add(Duration(days: daysUntilSaturday));
    return DateTime(saturday.year, saturday.month, saturday.day, 9, 0);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} à ${_formatTime(dateTime)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Aujourd'hui";
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return "Demain";
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
