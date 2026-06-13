import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/presentation/widgets/admin_workspace.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    for (final field in _fields) field.key: TextEditingController(),
  };
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw StateError('Your admin session has expired. Please login again.');
      }
      final document = await FirebaseFirestore.instance
          .collection('settings')
          .doc('gymProfile')
          .get();
      final data = document.data() ?? const <String, dynamic>{};
      for (final field in _fields) {
        _controllers[field.key]!.text =
            data[field.key]?.toString().trim() ?? '';
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load settings: $error';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw StateError('Your admin session has expired. Please login again.');
      }
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('gymProfile')
          .set({
            for (final field in _fields)
              field.key: _controllers[field.key]!.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated successfully')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Unable to save settings: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminWorkspaceScaffold(
      section: AdminWorkspaceSection.settings,
      title: 'Settings',
      subtitle: 'Manage public gym identity, contact details and hours',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : _error != null && _controllers['gymName']!.text.isEmpty
          ? _SettingsError(message: _error!, onRetry: _load)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 50),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: AdminSurface(
                    padding: const EdgeInsets.all(26),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'GYM PROFILE',
                            style: TextStyle(
                              color: AppColors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Public contact and business details',
                            style: TextStyle(
                              color: AppColors.paper,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 22),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth >= 650
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth;
                              return Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: [
                                  for (final field in _fields)
                                    SizedBox(
                                      width: field.key == 'address'
                                          ? constraints.maxWidth
                                          : width,
                                      child: TextFormField(
                                        key: ValueKey('settings-${field.key}'),
                                        controller: _controllers[field.key],
                                        keyboardType: field.keyboardType,
                                        maxLines: field.key == 'address'
                                            ? 3
                                            : 1,
                                        decoration: InputDecoration(
                                          labelText: field.label,
                                        ),
                                        validator: field.key == 'gymName'
                                            ? (value) =>
                                                  value == null ||
                                                      value.trim().isEmpty
                                                  ? 'Gym Name is required.'
                                                  : null
                                            : null,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.red),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              key: const Key('save-settings'),
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _saving ? 'SAVING...' : 'SAVE SETTINGS',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.red,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingField {
  const _SettingField(this.key, this.label, [this.keyboardType]);

  final String key;
  final String label;
  final TextInputType? keyboardType;
}

const _fields = [
  _SettingField('gymName', 'Gym Name'),
  _SettingField('ownerName', 'Owner Name'),
  _SettingField('phone', 'Phone', TextInputType.phone),
  _SettingField('email', 'Email', TextInputType.emailAddress),
  _SettingField('address', 'Address'),
  _SettingField('openingTime', 'Opening Time'),
  _SettingField('closingTime', 'Closing Time'),
  _SettingField('instagramUrl', 'Instagram URL', TextInputType.url),
  _SettingField('facebookUrl', 'Facebook URL', TextInputType.url),
  _SettingField('whatsappNumber', 'WhatsApp Number', TextInputType.phone),
];
