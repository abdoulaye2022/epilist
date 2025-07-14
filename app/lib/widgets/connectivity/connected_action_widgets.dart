// widgets/connectivity/connected_action_widgets.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/connectivity/connectivity_wrapper.dart';
import 'package:epilist/widgets/dialogs/no_internet_dialog.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

/// Bouton qui nécessite une connexion internet pour fonctionner
class ConnectedElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool showOfflineMessage;

  const ConnectedElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.showOfflineMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = context.isConnected;

    return ElevatedButton(
      onPressed:
          onPressed == null
              ? null
              : () {
                if (isConnected) {
                  onPressed?.call();
                } else {
                  _handleOfflineAction(context);
                }
              },
      style:
          style?.copyWith(
            backgroundColor:
                isConnected
                    ? style?.backgroundColor
                    : MaterialStateProperty.all(Colors.grey[400]),
          ) ??
          ElevatedButton.styleFrom(
            backgroundColor: isConnected ? null : Colors.grey[400],
          ),
      child: child,
    );
  }

  void _handleOfflineAction(BuildContext context) {
    if (showOfflineMessage) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => NoInternetDialog(onRetry: () => onPressed?.call()),
      );
    }
  }
}

/// FloatingActionButton qui nécessite une connexion internet
class ConnectedFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? tooltip;
  final Color? backgroundColor;
  final bool showOfflineMessage;

  const ConnectedFloatingActionButton({
    super.key,
    required this.onPressed,
    this.child,
    this.tooltip,
    this.backgroundColor,
    this.showOfflineMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = context.isConnected;
    final l10n = AppLocalizations.of(context)!;

    return FloatingActionButton(
      onPressed:
          onPressed == null
              ? null
              : () {
                if (isConnected) {
                  onPressed?.call();
                } else {
                  _handleOfflineAction(context);
                }
              },
      backgroundColor:
          isConnected
              ? (backgroundColor ?? Colors.green[600])
              : Colors.grey[400],
      tooltip:
          isConnected
              ? tooltip
              : (l10n.connectionRequired ?? 'Connexion requise'),
      child:
          isConnected ? child : const Icon(Icons.wifi_off, color: Colors.white),
    );
  }

  void _handleOfflineAction(BuildContext context) {
    if (showOfflineMessage) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => NoInternetDialog(onRetry: () => onPressed?.call()),
      );
    }
  }
}

/// ListTile qui nécessite une connexion internet
class ConnectedListTile extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool showOfflineMessage;

  const ConnectedListTile({
    super.key,
    this.onTap,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.showOfflineMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = context.isConnected;

    return ListTile(
      onTap:
          onTap == null
              ? null
              : () {
                if (isConnected) {
                  onTap?.call();
                } else {
                  _handleOfflineAction(context);
                }
              },
      leading:
          isConnected
              ? leading
              : const Icon(Icons.wifi_off, color: Colors.grey),
      title: title,
      subtitle: subtitle,
      trailing:
          isConnected
              ? trailing
              : const Icon(Icons.warning, color: Colors.orange),
      enabled: isConnected,
    );
  }

  void _handleOfflineAction(BuildContext context) {
    if (showOfflineMessage) {
      final l10n = AppLocalizations.of(context)!;
      SmartSnackBarManager.showWarningSnackBar(
        context,
        l10n.connectionRequired ?? 'Connexion Internet requise',
      );
    }
  }
}

/// RefreshIndicator qui nécessite une connexion internet
class ConnectedRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final bool showOfflineMessage;

  const ConnectedRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.showOfflineMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = context.isConnected;

    return RefreshIndicator(
      onRefresh: () async {
        if (isConnected) {
          return await onRefresh();
        } else {
          _handleOfflineAction(context);
        }
      },
      child: child,
    );
  }

  void _handleOfflineAction(BuildContext context) {
    if (showOfflineMessage) {
      final l10n = AppLocalizations.of(context)!;
      SmartSnackBarManager.showWarningSnackBar(
        context,
        l10n.connectionRequired ?? 'Connexion Internet requise pour actualiser',
      );
    }
  }
}

/// IconButton qui nécessite une connexion internet
class ConnectedIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final bool showOfflineMessage;

  const ConnectedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.showOfflineMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = context.isConnected;
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      onPressed:
          onPressed == null
              ? null
              : () {
                if (isConnected) {
                  onPressed?.call();
                } else {
                  _handleOfflineAction(context);
                }
              },
      icon: isConnected ? icon : const Icon(Icons.wifi_off),
      tooltip:
          isConnected
              ? tooltip
              : (l10n.connectionRequired ?? 'Connexion requise'),
      color: isConnected ? null : Colors.grey,
    );
  }

  void _handleOfflineAction(BuildContext context) {
    if (showOfflineMessage) {
      final l10n = AppLocalizations.of(context)!;
      SmartSnackBarManager.showWarningSnackBar(
        context,
        l10n.connectionRequired ?? 'Connexion Internet requise',
      );
    }
  }
}

/// TextButton qui nécessite une connexion internet
class ConnectedTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool showOfflineMessage;

  const ConnectedTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.showOfflineMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = context.isConnected;

    return TextButton(
      onPressed:
          onPressed == null
              ? null
              : () {
                if (isConnected) {
                  onPressed?.call();
                } else {
                  _handleOfflineAction(context);
                }
              },
      style:
          style?.copyWith(
            foregroundColor:
                isConnected
                    ? style?.foregroundColor
                    : MaterialStateProperty.all(Colors.grey),
          ) ??
          TextButton.styleFrom(
            foregroundColor: isConnected ? null : Colors.grey,
          ),
      child: child,
    );
  }

  void _handleOfflineAction(BuildContext context) {
    if (showOfflineMessage) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => NoInternetDialog(onRetry: () => onPressed?.call()),
      );
    }
  }
}
