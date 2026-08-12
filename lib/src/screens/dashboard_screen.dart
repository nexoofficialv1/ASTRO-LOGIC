import 'package:flutter/material.dart';

import '../localization/app_copy.dart';
import '../data/client_store.dart';
import '../models/astro_module.dart';
import 'clients_screen.dart';
import 'numerology_workspace_screen.dart';
import 'kp_workspace_screen.dart';
import 'settings_screen.dart';
import 'signed_report_verification_screen.dart';
import 'western_workspace_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.clientStore,
    required this.onToggleLanguage,
    super.key,
  });

  final ClientStore clientStore;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASTRO LOGIC'),
        actions: [
          IconButton(
            tooltip: AppCopy.of(context, 'verifySignedReport'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SignedReportVerificationScreen(
                  clientStore: clientStore,
                ),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner),
          ),
          TextButton.icon(
            onPressed: onToggleLanguage,
            icon: const Icon(Icons.translate),
            label: Text(Localizations.localeOf(context).languageCode == 'bn'
                ? 'English'
                : 'বাংলা'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050
                ? 4
                : constraints.maxWidth >= 650
                    ? 3
                    : 2;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(onStart: () => _openClients(context)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  sliver: SliverGrid.builder(
                    itemCount: astroModules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.12,
                    ),
                    itemBuilder: (context, index) =>
                        _ModuleCard(
                          module: astroModules[index],
                          onTap: () => _openModule(context, astroModules[index]),
                        ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openModule(BuildContext context, AstroModule module) {
    if (module.availability == AstroModuleAvailability.comingSoon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context, 'comingSoon'))),
      );
      return;
    }
    if (module.copyKey == 'clients' ||
        module.copyKey == 'vedic' ||
        module.copyKey == 'gemstoneRemedies' ||
        module.copyKey == 'reports') {
      _openClients(context);
      return;
    }
    if (module.copyKey == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SettingsScreen(clientStore: clientStore),
        ),
      );
      return;
    }
    if (module.copyKey == 'numerology') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const NumerologyWorkspaceScreen(),
        ),
      );
      return;
    }
    if (module.copyKey == 'kp') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => KpWorkspaceScreen(clientStore: clientStore),
        ),
      );
      return;
    }
    if (module.copyKey == 'western') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WesternWorkspaceScreen(clientStore: clientStore),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppCopy.of(context, 'comingSoon'))),
    );
  }

  void _openClients(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClientsScreen(clientStore: clientStore),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF37216D), Color(0xFF161A36)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x45D9B65D)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 20,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppCopy.of(context, 'welcome'),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.lock_outline, size: 17),
                    const SizedBox(width: 7),
                    Text(AppCopy.of(context, 'offline')),
                  ]),
                ],
              ),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.add),
                label: Text(AppCopy.of(context, 'newConsultation')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onTap});

  final AstroModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: module.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(module.icon, color: module.color, size: 30),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppCopy.of(context, module.copyKey),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (module.availability == AstroModuleAvailability.comingSoon) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppCopy.of(context, 'comingSoon'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
