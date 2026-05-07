import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';

/// A thin AppBar + body wrapper reused across every screen.
///
/// Usage:
/// ```dart
/// return MainScaffold(
///   title: 'My Screen',
///   actions: [IconButton(...)],
///   child: MyContent(),
/// );
/// ```
class MainScaffold extends StatelessWidget {
  /// Text shown in the AppBar.
  final String title;

  /// The primary content rendered below the AppBar.
  final Widget child;

  /// Optional action widgets placed in the AppBar trailing area.
  final List<Widget>? actions;

  /// Replaces the default back button. Pass [SizedBox.shrink()] to hide it.
  final Widget? leading;

  /// When `true` a [FloatingActionButton] slot is available via [fab].
  final Widget? fab;

  /// Controls [Scaffold.resizeToAvoidBottomInset] (default `true`).
  final bool resizeToAvoidBottomInset;

  /// Optional bottom navigation bar.
  final Widget? bottomNavigationBar;

  const MainScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.leading,
    this.fab,
    this.resizeToAvoidBottomInset = true,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: fab,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
        centerTitle: false,
        leading: leading,
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: theme.colorScheme.errorContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 16,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Offline — changes saved locally',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
