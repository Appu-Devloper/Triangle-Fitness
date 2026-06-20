import 'package:flutter/material.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';

abstract final class AdminWorkspaceColors {
  static const background = Color(0xFF080A0D);
  static const sidebar = Color(0xFF0D1014);
  static const surface = Color(0xFF12161B);
  static const surfaceRaised = Color(0xFF171C22);
  static const field = Color(0xFF0D1116);
  static const border = Color(0xFF262D35);
  static const borderStrong = Color(0xFF343D47);
  static const text = Color(0xFFF4F5F7);
  static const muted = Color(0xFF929AA5);
  static const subtle = Color(0xFF606A75);
  static const success = Color(0xFF4FD18B);
  static const warning = Color(0xFFFFB454);
  static const info = Color(0xFF6C9CFF);
  static const danger = Color(0xFFFF656B);
  static const accent = AppColors.red;
}

enum AdminWorkspaceSection {
  overview,
  members,
  addMember,
  payments,
  subscriptions,
  transformations,
  settings,
}

extension AdminWorkspaceSectionInfo on AdminWorkspaceSection {
  String get label => switch (this) {
    AdminWorkspaceSection.overview => 'Overview',
    AdminWorkspaceSection.members => 'Members',
    AdminWorkspaceSection.addMember => 'Add Member',
    AdminWorkspaceSection.payments => 'Payments',
    AdminWorkspaceSection.subscriptions => 'Subscriptions',
    AdminWorkspaceSection.transformations => 'Transformations',
    AdminWorkspaceSection.settings => 'Settings',
  };

  IconData get icon => switch (this) {
    AdminWorkspaceSection.overview => Icons.grid_view_rounded,
    AdminWorkspaceSection.members => Icons.groups_2_outlined,
    AdminWorkspaceSection.addMember => Icons.person_add_alt_1_rounded,
    AdminWorkspaceSection.payments => Icons.account_balance_wallet_outlined,
    AdminWorkspaceSection.subscriptions => Icons.card_membership_rounded,
    AdminWorkspaceSection.transformations => Icons.insights_rounded,
    AdminWorkspaceSection.settings => Icons.tune_rounded,
  };

  String get route => switch (this) {
    AdminWorkspaceSection.overview => '/admin',
    AdminWorkspaceSection.members => '/admin/members',
    AdminWorkspaceSection.addMember => '/admin/members/add',
    AdminWorkspaceSection.payments => '/admin/payments',
    AdminWorkspaceSection.subscriptions => '/admin/subscriptions',
    AdminWorkspaceSection.transformations => '/admin/transformations',
    AdminWorkspaceSection.settings => '/admin/settings',
  };
}

class AdminWorkspaceScaffold extends StatelessWidget {
  const AdminWorkspaceScaffold({
    super.key,
    required this.section,
    required this.title,
    required this.subtitle,
    required this.body,
    this.headerActions = const [],
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.adminName,
    this.onSignOut,
    this.signingOut = false,
    this.onDestinationSelected,
  });

  final AdminWorkspaceSection section;
  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget> headerActions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final String? adminName;
  final VoidCallback? onSignOut;
  final bool signingOut;
  final ValueChanged<AdminWorkspaceSection>? onDestinationSelected;

  void _navigate(BuildContext context, AdminWorkspaceSection destination) {
    if (destination == section) return;
    final callback = onDestinationSelected;
    if (callback != null) {
      callback(destination);
      return;
    }
    Navigator.of(context).pushReplacementNamed(destination.route);
  }

  @override
  Widget build(BuildContext context) {
    final workspaceTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: AdminWorkspaceColors.background,
      cardColor: AdminWorkspaceColors.surface,
      dividerColor: AdminWorkspaceColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminWorkspaceColors.field,
        labelStyle: const TextStyle(
          color: AdminWorkspaceColors.muted,
          fontSize: 12,
        ),
        hintStyle: const TextStyle(
          color: AdminWorkspaceColors.subtle,
          fontSize: 12,
        ),
        prefixIconColor: AdminWorkspaceColors.muted,
        suffixIconColor: AdminWorkspaceColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminWorkspaceColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminWorkspaceColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AdminWorkspaceColors.accent,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AdminWorkspaceColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminWorkspaceColors.text,
          side: const BorderSide(color: AdminWorkspaceColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AdminWorkspaceColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );

    return Theme(
      data: workspaceTheme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1050;
          return Scaffold(
            backgroundColor: AdminWorkspaceColors.background,
            drawer: desktop
                ? null
                : Drawer(
                    backgroundColor: AdminWorkspaceColors.sidebar,
                    child: _WorkspaceNavigation(
                      selected: section,
                      onSelected: (destination) {
                        Navigator.of(context).pop();
                        _navigate(context, destination);
                      },
                      adminName: adminName,
                      onSignOut: onSignOut,
                      signingOut: signingOut,
                    ),
                  ),
            floatingActionButton: floatingActionButton,
            body: Row(
              children: [
                if (desktop)
                  SizedBox(
                    width: 264,
                    child: _WorkspaceNavigation(
                      selected: section,
                      onSelected: (destination) =>
                          _navigate(context, destination),
                      adminName: adminName,
                      onSignOut: onSignOut,
                      signingOut: signingOut,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _WorkspaceHeader(
                        title: title,
                        subtitle: subtitle,
                        section: section,
                        desktop: desktop,
                        actions: headerActions,
                        adminName: adminName,
                        onSignOut: onSignOut,
                        signingOut: signingOut,
                      ),
                      if (!desktop)
                        _MobileWorkspaceTabs(
                          selected: section,
                          onSelected: (destination) =>
                              _navigate(context, destination),
                        ),
                      Expanded(child: body),
                      if (bottomNavigationBar != null) bottomNavigationBar!,
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MobileWorkspaceTabs extends StatelessWidget {
  const _MobileWorkspaceTabs({
    required this.selected,
    required this.onSelected,
  });

  final AdminWorkspaceSection selected;
  final ValueChanged<AdminWorkspaceSection> onSelected;

  @override
  Widget build(BuildContext context) {
    const sections = [
      AdminWorkspaceSection.overview,
      AdminWorkspaceSection.members,
      AdminWorkspaceSection.addMember,
      AdminWorkspaceSection.payments,
      AdminWorkspaceSection.subscriptions,
      AdminWorkspaceSection.settings,
    ];
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: AdminWorkspaceColors.surface,
        border: Border(bottom: BorderSide(color: AdminWorkspaceColors.border)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final destination = sections[index];
          final active = destination == selected;
          return ChoiceChip(
            key: ValueKey('admin-mobile-tab-${destination.name}'),
            avatar: Icon(
              destination.icon,
              size: 16,
              color: active
                  ? Colors.white
                  : AdminWorkspaceColors.muted,
            ),
            label: Text(destination.label.toUpperCase()),
            selected: active,
            onSelected: (_) => onSelected(destination),
            selectedColor: AdminWorkspaceColors.accent,
            backgroundColor: AdminWorkspaceColors.field,
            side: BorderSide(
              color: active
                  ? AdminWorkspaceColors.accent
                  : AdminWorkspaceColors.border,
            ),
            labelStyle: TextStyle(
              color: active ? Colors.white : AdminWorkspaceColors.text,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.45,
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: sections.length,
      ),
    );
  }
}

class _WorkspaceNavigation extends StatelessWidget {
  const _WorkspaceNavigation({
    required this.selected,
    required this.onSelected,
    required this.adminName,
    required this.onSignOut,
    required this.signingOut,
  });

  final AdminWorkspaceSection selected;
  final ValueChanged<AdminWorkspaceSection> onSelected;
  final String? adminName;
  final VoidCallback? onSignOut;
  final bool signingOut;

  @override
  Widget build(BuildContext context) {
    const navigationSections = [
      AdminWorkspaceSection.overview,
      AdminWorkspaceSection.members,
      AdminWorkspaceSection.addMember,
      AdminWorkspaceSection.payments,
      AdminWorkspaceSection.subscriptions,
      AdminWorkspaceSection.settings,
    ];
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AdminWorkspaceColors.sidebar,
          border: Border(right: BorderSide(color: AdminWorkspaceColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AdminWorkspaceColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.change_history_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRIANGLE',
                        style: TextStyle(
                          color: AdminWorkspaceColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'FITNESS ADMIN',
                        style: TextStyle(
                          color: AdminWorkspaceColors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 10),
              child: Text(
                'MANAGEMENT',
                style: TextStyle(
                  color: AdminWorkspaceColors.subtle,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            for (final destination in navigationSections)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _NavigationItem(
                  destination: destination,
                  selected: destination == selected,
                  onTap: () => onSelected(destination),
                ),
              ),
            const Spacer(),
            if (adminName != null && adminName!.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminWorkspaceColors.surface,
                  border: Border.all(color: AdminWorkspaceColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 17,
                      backgroundColor: Color(0xFF2A171A),
                      child: Icon(
                        Icons.admin_panel_settings_outlined,
                        color: AdminWorkspaceColors.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminWorkspaceColors.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Administrator',
                            style: TextStyle(
                              color: AdminWorkspaceColors.muted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (onSignOut != null)
              TextButton.icon(
                onPressed: signingOut ? null : onSignOut,
                style: TextButton.styleFrom(
                  foregroundColor: AdminWorkspaceColors.danger,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                ),
                icon: signingOut
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded, size: 19),
                label: Text(signingOut ? 'SIGNING OUT...' : 'LOG OUT'),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AdminWorkspaceSection destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AdminWorkspaceColors.accent.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: selected
                ? Border.all(
                    color: AdminWorkspaceColors.accent.withValues(alpha: 0.34),
                  )
                : null,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(
                destination.icon,
                size: 19,
                color: selected
                    ? AdminWorkspaceColors.accent
                    : AdminWorkspaceColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label.toUpperCase(),
                  style: TextStyle(
                    color: selected
                        ? AdminWorkspaceColors.text
                        : AdminWorkspaceColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.65,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AdminWorkspaceColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.title,
    required this.subtitle,
    required this.section,
    required this.desktop,
    required this.actions,
    required this.adminName,
    required this.onSignOut,
    required this.signingOut,
  });

  final String title;
  final String subtitle;
  final AdminWorkspaceSection section;
  final bool desktop;
  final List<Widget> actions;
  final String? adminName;
  final VoidCallback? onSignOut;
  final bool signingOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: desktop ? 88 : 76,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 12),
      decoration: const BoxDecoration(
        color: AdminWorkspaceColors.surface,
        border: Border(bottom: BorderSide(color: AdminWorkspaceColors.border)),
      ),
      child: Row(
        children: [
          if (!desktop)
            Builder(
              builder: (context) => IconButton(
                onPressed: Scaffold.of(context).openDrawer,
                tooltip: 'Open admin navigation',
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
          if (!desktop) const SizedBox(width: 2),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AdminWorkspaceColors.accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              section.icon,
              color: AdminWorkspaceColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminWorkspaceColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminWorkspaceColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          ...actions.expand((action) => [const SizedBox(width: 8), action]),
          if (!desktop && onSignOut != null) ...[
            const SizedBox(width: 6),
            if (MediaQuery.sizeOf(context).width < 520)
              IconButton(
                onPressed: signingOut ? null : onSignOut,
                tooltip: 'Log out',
                icon: signingOut
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded, size: 20),
              )
            else
              TextButton.icon(
                onPressed: signingOut ? null : onSignOut,
                icon: signingOut
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded, size: 18),
                label: Text(signingOut ? 'SIGNING OUT...' : 'LOG OUT'),
              ),
          ],
        ],
      ),
    );
  }
}

class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AdminWorkspaceColors.surface,
        border: Border.all(color: AdminWorkspaceColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
