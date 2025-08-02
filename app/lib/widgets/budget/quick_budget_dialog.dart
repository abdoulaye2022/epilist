// widgets/budget/quick_budget_dialog.dart - VERSION COMPLETE AVEC FormattedAmount
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart'; // ✅ IMPORT AJOUTÉ

class QuickBudgetDialog extends StatefulWidget {
  final List<ShoppingList>? availableLists;
  final Function(String type, double amount, String? name, int? listId)
  onCreateBudget;

  const QuickBudgetDialog({
    super.key,
    this.availableLists,
    required this.onCreateBudget,
  });

  @override
  State<QuickBudgetDialog> createState() => _QuickBudgetDialogState();
}

class _QuickBudgetDialogState extends State<QuickBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedType = 'monthly';
  int? _selectedListId;
  bool _isLoading = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _updateBudgetName();
      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _updateBudgetName() {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    String periodName;
    switch (_selectedType) {
      case 'weekly':
        periodName = l10n.weekly;
        break;
      case 'yearly':
        periodName = l10n.yearly;
        break;
      default:
        periodName = l10n.monthly;
    }

    String scopeName = l10n.general;
    if (_selectedListId != null && widget.availableLists != null) {
      final selectedList = widget.availableLists!.firstWhere(
        (list) => list.id == _selectedListId,
        orElse:
            () => ShoppingList(
              id: 0,
              name: l10n.unknownList,
              userId: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              items: [],
            ),
      );
      scopeName = selectedList.name;
    }

    _nameController.text = '$periodName $scopeName ${l10n.budget}';
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
                child: Form(
                  key: _formKey,
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
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.flash_on_rounded, size: 40, color: Colors.orange[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.quickBudget,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.quickBudgetDescription,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPeriodSelector(l10n),
        const SizedBox(height: 16),
        _buildAmountField(l10n),
        const SizedBox(height: 16),
        _buildScopeSelector(l10n),
        const SizedBox(height: 16),
        _buildNameField(l10n),
        const SizedBox(height: 20),
        _buildPreview(l10n),
      ],
    );
  }

  Widget _buildPeriodSelector(AppLocalizations l10n) {
    final periods = [
      {
        'value': 'weekly',
        'label': l10n.weekly,
        'icon': Icons.view_week,
        'color': Colors.blue,
      },
      {
        'value': 'monthly',
        'label': l10n.monthly,
        'icon': Icons.calendar_month,
        'color': Colors.green,
      },
      {
        'value': 'yearly',
        'label': l10n.yearly,
        'icon': Icons.calendar_today,
        'color': Colors.purple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budgetPeriod,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children:
                periods.map((period) {
                  final isSelected = _selectedType == period['value'];
                  final color = period['color'] as MaterialColor;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedType = period['value'] as String;
                        _updateBudgetName();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? color[50] : null,
                        borderRadius:
                            periods.indexOf(period) == 0
                                ? const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                )
                                : periods.indexOf(period) == periods.length - 1
                                ? const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                )
                                : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            period['icon'] as IconData,
                            color: isSelected ? color[600] : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              period['label'] as String,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color: isSelected ? color[600] : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: color[600],
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budgetAmount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.monetization_on, color: Colors.amber[700]),
            hintText: l10n.enterAmount,
            // ✅ SUPPRESSION DU suffixText car FormattedAmount gère la devise
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.amber[700]!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) {
            // ✅ DÉCLENCHER UN REBUILD POUR LE PREVIEW
            setState(() {});
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.pleaseEnterAmount;
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return l10n.pleaseEnterValidAmount;
            }
            if (amount > 999999.99) {
              return l10n.amountTooHigh;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildScopeSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budgetScope,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // Option général
        InkWell(
          onTap: () {
            setState(() {
              _selectedListId = null;
              _updateBudgetName();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color:
                  _selectedListId == null ? Colors.indigo[50] : Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.public,
                  color:
                      _selectedListId == null
                          ? Colors.indigo[600]
                          : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.generalBudget,
                        style: TextStyle(
                          fontWeight:
                              _selectedListId == null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          color:
                              _selectedListId == null
                                  ? Colors.indigo[600]
                                  : Colors.black87,
                        ),
                      ),
                      Text(
                        l10n.generalBudgetDescription,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (_selectedListId == null)
                  Icon(Icons.check_circle, color: Colors.indigo[600], size: 20),
              ],
            ),
          ),
        ),

        // Options de listes spécifiques
        if (widget.availableLists != null &&
            widget.availableLists!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.orSelectSpecificList,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.availableLists!.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final list = widget.availableLists![index];
                final isSelected = _selectedListId == list.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedListId = list.id;
                      _updateBudgetName();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo[50] : null,
                      borderRadius:
                          index == 0
                              ? const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              )
                              : index == widget.availableLists!.length - 1
                              ? const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              )
                              : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.list,
                          color:
                              isSelected
                                  ? Colors.indigo[600]
                                  : Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            list.name,
                            style: TextStyle(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? Colors.indigo[600]
                                      : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Colors.indigo[600],
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budgetName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.label, color: Colors.green[600]),
            hintText: l10n.enterBudgetName,
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
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.pleaseEnterBudgetName;
            }
            if (value.trim().length < 3) {
              return l10n.budgetNameTooShort;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPreview(AppLocalizations l10n) {
    final amountText = _amountController.text;
    final amount = double.tryParse(amountText);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.preview,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPreviewItem(l10n.type, _getPeriodLabel(_selectedType, l10n)),
          _buildPreviewItem(
            l10n.amount,
            amount != null && amount > 0
                ? null
                : '0.00', // ✅ UTILISER FormattedAmount AU LIEU DU STRING
            amount: amount,
          ),
          _buildPreviewItem(l10n.scope, _getScopeLabel(l10n)),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String? value, {double? amount}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          // ✅ UTILISATION CONDITIONNELLE DE FormattedAmount
          if (amount != null && amount > 0)
            FormattedAmount(
              amount: amount,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              showCode: true, // ✅ AFFICHER LE CODE DE DEVISE DANS LE PREVIEW
            )
          else
            Text(
              value ?? '0.00',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
            onPressed: _isLoading ? null : _createBudget,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.orange[300],
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
                        const Icon(Icons.flash_on, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          l10n.createBudget,
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

  String _getPeriodLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'weekly':
        return l10n.weekly;
      case 'yearly':
        return l10n.yearly;
      default:
        return l10n.monthly;
    }
  }

  String _getScopeLabel(AppLocalizations l10n) {
    if (_selectedListId == null) {
      return l10n.general;
    }
    if (widget.availableLists != null) {
      final list = widget.availableLists!.firstWhere(
        (list) => list.id == _selectedListId,
        orElse:
            () => ShoppingList(
              id: 0,
              name: l10n.unknownList,
              userId: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              items: [],
            ),
      );
      return list.name;
    }
    return l10n.specificList;
  }

  void _createBudget() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final name = _nameController.text.trim();

    widget.onCreateBudget(
      _selectedType,
      amount,
      name.isNotEmpty ? name : null,
      _selectedListId,
    );

    Navigator.of(context).pop();
  }
}
