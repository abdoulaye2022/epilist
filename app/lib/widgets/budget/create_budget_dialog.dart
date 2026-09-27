// widgets/budget/create_budget_dialog.dart - VERSION COMPLETE AVEC FormattedAmount
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/budget/budget_bloc.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart'; // ✅ IMPORT AJOUTÉ

class CreateBudgetDialog extends StatefulWidget {
  final Budget? budgetToEdit;
  final BudgetPeriodType? initialPeriodType;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int? initialListId;

  const CreateBudgetDialog({
    super.key,
    this.budgetToEdit,
    this.initialPeriodType,
    this.initialStartDate,
    this.initialEndDate,
    this.initialListId,
  });

  @override
  State<CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends State<CreateBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  BudgetPeriodType _selectedPeriodType = BudgetPeriodType.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  int _alertThreshold = 80;
  int? _selectedListId;

  List<ShoppingList> _availableLists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadShoppingLists();
  }

  void _initializeForm() {
    if (widget.budgetToEdit != null) {
      final budget = widget.budgetToEdit!;
      _nameController.text = budget.name;
      _amountController.text = budget.budgetAmount.toString();
      _selectedPeriodType = budget.periodType;
      _startDate = budget.startDate;
      _endDate = budget.endDate;
      _alertThreshold = budget.alertThreshold;
      _selectedListId = budget.listId;
    } else {
      _selectedPeriodType =
          widget.initialPeriodType ?? BudgetPeriodType.monthly;
      _startDate = widget.initialStartDate ?? DateTime.now();
      _endDate =
          widget.initialEndDate ??
          _calculateEndDate(_selectedPeriodType, _startDate);
      _selectedListId = widget.initialListId;
    }
  }

  void _loadShoppingLists() {
    final shoppingListBloc = context.read<ShoppingListBloc>();
    if (shoppingListBloc.state is ShoppingListLoaded) {
      final state = shoppingListBloc.state as ShoppingListLoaded;
      setState(() {
        _availableLists = state.lists;
      });
    } else {
      shoppingListBloc.add(const LoadShoppingLists());
    }
  }

  DateTime _calculateEndDate(BudgetPeriodType periodType, DateTime startDate) {
    switch (periodType) {
      case BudgetPeriodType.weekly:
        return startDate.add(const Duration(days: 6));
      case BudgetPeriodType.monthly:
        return DateTime(startDate.year, startDate.month + 1, 0);
      case BudgetPeriodType.yearly:
        return DateTime(startDate.year, 12, 31);
      case BudgetPeriodType.custom:
        return startDate.add(const Duration(days: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.budgetToEdit != null;

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
            BlocListener<BudgetBloc, BudgetState>(
              listener: (context, state) {
                if (state is BudgetOperationSuccess) {
                  Navigator.pop(context);
                } else if (state is BudgetError) {
                  // L'erreur sera gérée par le BlocListener principal
                }
              },
              child: Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppDialogHeader(
                          icon:
                              isEditing
                                  ? Icons.edit_outlined
                                  : Icons.savings_outlined,
                          title:
                              isEditing ? l10n.editBudget : l10n.createBudget,
                        ),
                        const SizedBox(height: 16),
                        _buildForm(l10n),
                        const SizedBox(height: 24),
                        _buildButtons(l10n, isEditing),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Column(
      children: [
        _buildNameField(l10n),
        const SizedBox(height: 16),
        _buildAmountField(l10n),
        const SizedBox(height: 16),
        _buildPeriodTypeField(l10n),
        const SizedBox(height: 16),
        _buildDatesRow(l10n),
        const SizedBox(height: 16),
        _buildListField(l10n),
        const SizedBox(height: 16),
        _buildAlertThresholdSlider(l10n),
        const SizedBox(height: 16),
        // ✅ AJOUT DU PREVIEW AVEC FormattedAmount
        _buildAmountPreview(l10n),
      ],
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: l10n.budgetName,
        hintText: l10n.budgetNameHint,
      ),
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.budgetNameRequired;
        }
        if (value.trim().length < 3) {
          return l10n.budgetNameTooShort;
        }
        return null;
      },
    );
  }

  Widget _buildAmountField(AppLocalizations l10n) {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: l10n.budgetAmount,
        hintText: '100.00',
        // ✅ SUPPRESSION DU suffixText car FormattedAmount gère la devise
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: (value) {
        // ✅ DÉCLENCHER UN REBUILD POUR LE PREVIEW
        setState(() {});
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.budgetAmountRequired;
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return l10n.budgetAmountInvalid;
        }
        if (amount > 999999) {
          return l10n.budgetAmountTooHigh;
        }
        return null;
      },
    );
  }

  // ✅ NOUVEAU WIDGET PREVIEW AVEC FormattedAmount
  Widget _buildAmountPreview(AppLocalizations l10n) {
    final amountText = _amountController.text;
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.preview,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.budgetAmount,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              FormattedAmount(
                // ✅ UTILISATION DE FormattedAmount POUR LE PREVIEW
                amount: amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
                showCode: true, // ✅ AFFICHER LE CODE DE DEVISE
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTypeField(AppLocalizations l10n) {
    return DropdownButtonFormField<BudgetPeriodType>(
      value: _selectedPeriodType,
      decoration: InputDecoration(labelText: l10n.periodType),
      items:
          BudgetPeriodType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getPeriodTypeDisplayName(type, l10n)),
            );
          }).toList(),
      onChanged: (BudgetPeriodType? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedPeriodType = newValue;
            if (newValue != BudgetPeriodType.custom) {
              _endDate = _calculateEndDate(newValue, _startDate);
            }
          });
        }
      },
    );
  }

  Widget _buildDatesRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _selectStartDate,
            child: InputDecorator(
              decoration: InputDecoration(labelText: l10n.startDate),
              child: Text(
                _formatDate(_startDate),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap:
                _selectedPeriodType == BudgetPeriodType.custom
                    ? _selectEndDate
                    : null,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.endDate,
                enabled: _selectedPeriodType == BudgetPeriodType.custom,
              ),
              child: Text(
                _formatDate(_endDate),
                style: TextStyle(
                  fontSize: 16,
                  color:
                      _selectedPeriodType == BudgetPeriodType.custom
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListField(AppLocalizations l10n) {
    return BlocListener<ShoppingListBloc, ShoppingListState>(
      listener: (context, state) {
        if (state is ShoppingListLoaded) {
          setState(() {
            _availableLists = state.lists;
          });
        }
      },
      child: DropdownButtonFormField<int?>(
        value: _selectedListId,
        decoration: InputDecoration(
          labelText: l10n.associatedList,
          hintText: l10n.generalBudget,
        ),
        items: [
          DropdownMenuItem<int?>(value: null, child: Text(l10n.generalBudget)),
          ..._availableLists.map((list) {
            return DropdownMenuItem<int?>(
              value: list.id,
              child: Text(list.name),
            );
          }),
        ],
        onChanged: (int? newValue) {
          setState(() {
            _selectedListId = newValue;
          });
        },
      ),
    );
  }

  Widget _buildAlertThresholdSlider(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Text(
              '${l10n.alertThreshold}: ${_alertThreshold}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            children: [
              Slider(
                value: _alertThreshold.toDouble(),
                min: 50,
                max: 95,
                divisions: 9,
                activeColor: AppColors.warning,
                inactiveColor: Colors.orange[200],
                onChanged: (double value) {
                  setState(() {
                    _alertThreshold = value.round();
                  });
                },
              ),
              Text(
                l10n.alertThresholdDescription,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(AppLocalizations l10n, bool isEditing) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder:
          (context, state) => AppDialogActions(
            cancelLabel: l10n.cancel,
            submitLabel: isEditing ? l10n.update : l10n.create,
            loading: _isLoading || state is BudgetOperationLoading,
            onSubmit: _submitForm,
          ),
    );
  }

  String _getPeriodTypeDisplayName(
    BudgetPeriodType type,
    AppLocalizations l10n,
  ) {
    switch (type) {
      case BudgetPeriodType.weekly:
        return l10n.weekly;
      case BudgetPeriodType.monthly:
        return l10n.monthly;
      case BudgetPeriodType.yearly:
        return l10n.yearly;
      case BudgetPeriodType.custom:
        return l10n.custom;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_selectedPeriodType != BudgetPeriodType.custom) {
          _endDate = _calculateEndDate(_selectedPeriodType, _startDate);
        } else if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);

      if (widget.budgetToEdit != null) {
        final request = UpdateBudgetRequest(
          name: _nameController.text.trim(),
          budgetAmount: amount,
          periodType: _selectedPeriodType,
          startDate: _startDate,
          endDate: _endDate,
          alertThreshold: _alertThreshold,
        );

        context.read<BudgetBloc>().add(
          UpdateBudget(widget.budgetToEdit!.id, request),
        );
      } else {
        final request = CreateBudgetRequest(
          name: _nameController.text.trim(),
          budgetAmount: amount,
          periodType: _selectedPeriodType,
          startDate: _startDate,
          endDate: _endDate,
          alertThreshold: _alertThreshold,
          listId: _selectedListId,
        );

        context.read<BudgetBloc>().add(CreateBudget(request));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
