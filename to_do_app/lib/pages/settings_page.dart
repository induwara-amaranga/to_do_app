import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/components/task_page_bottom_nav_bar.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/providers/auth_provider.dart';
import 'package:to_do_app/themes/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  final ToDoDataBase db;
  const SettingsPage({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0.5,
        shadowColor: cs.onSurface.withAlpha(30),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: cs.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: const TaskBottomNavBar(current: 1),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _ProfileCard(cs: cs, auth: auth),
          const SizedBox(height: 32),

          _SectionHeader(label: 'Preferences', color: cs.primary),
          const SizedBox(height: 8),
          _SettingsGroup(cs: cs, items: [
            _SettingsTile(
              cs: cs,
              icon: Icons.palette_outlined,
              label: 'Appearance',
              subtitle: 'Theme, colors, and layout',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                activeColor: cs.primary,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
            _SettingsTile(
              cs: cs,
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              subtitle: 'Reminders and alerts',
              onTap: () {},
            ),
            _SettingsTile(
              cs: cs,
              icon: Icons.check_circle_outline,
              label: 'Task Defaults',
              subtitle: 'Priority and category settings',
              onTap: () => Navigator.pushNamed(context, '/manageCategories'),
            ),
          ]),
          const SizedBox(height: 32),

          _SectionHeader(label: 'Connectivity', color: cs.primary),
          const SizedBox(height: 8),
          _SettingsGroup(cs: cs, items: [
            _SettingsTile(
              cs: cs,
              icon: Icons.sync,
              label: 'Calendar & Sync',
              subtitle: 'Google and Outlook integration',
              onTap: () => Navigator.pushNamed(context, '/calendarSync'),
            ),
            _SettingsTile(
              cs: cs,
              icon: Icons.person_outline,
              label: 'Account',
              subtitle: auth.isGoogleSignedIn
                  ? auth.displayName
                  : 'Not signed in',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),

          _SectionHeader(label: 'System', color: cs.error),
          const SizedBox(height: 8),
          _DangerCard(cs: cs, db: db),
          const SizedBox(height: 48),

          Text(
            'TaskFocus v2.4.0',
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withAlpha(120),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Made with optimism for productivity',
            style: TextStyle(fontSize: 10, color: cs.onSurface.withAlpha(80)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ColorScheme cs;
  final AuthProvider auth;
  const _ProfileCard({required this.cs, required this.auth});

  @override
  Widget build(BuildContext context) {
    final name =
        auth.displayName.isNotEmpty ? auth.displayName : 'Guest User';
    final initial = name[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: cs.primary.withAlpha(40),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.isGoogleSignedIn ? 'Google Account' : 'Local Account',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: cs.onSurface.withAlpha(130)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final ColorScheme cs;
  final List<Widget> items;
  const _SettingsGroup({required this.cs, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withAlpha(30)),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              items[i],
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 72,
                  color: cs.onSurface.withAlpha(25),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.cs,
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurface.withAlpha(100),
                ),
          ],
        ),
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  final ColorScheme cs;
  final ToDoDataBase db;
  const _DangerCard({required this.cs, required this.db});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.error.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withAlpha(50)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _confirmReset(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.error.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_outline, color: cs.error, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset App Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.error,
                      ),
                    ),
                    Text(
                      'Clear all tasks, settings, and local cache',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.error.withAlpha(165),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reset App Data?'),
            content: const Text(
              'This will permanently delete all tasks and calendar data. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await db.clearToDoList();
                  await db.clearAllCalTasks();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (_) => false,
                    );
                  }
                },
                child: Text(
                  'Reset',
                  style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }
}
