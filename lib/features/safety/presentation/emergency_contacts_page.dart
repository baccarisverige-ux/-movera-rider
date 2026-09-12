import 'package:flutter/material.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/domain/emergency_contact.dart';
import 'package:movera_rider/features/safety/domain/phone_e164.dart';
import 'package:movera_rider/features/safety/presentation/safety_marks.dart';
import 'package:movera_rider/features/safety/presentation/safety_ui.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key, required this.controller});
  final SafetyController controller;

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  SafetyController get _ctl => widget.controller;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(_onChange);
  }

  @override
  void dispose() {
    _ctl.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _edit([EmergencyContact? existing]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _ContactEditor(controller: _ctl, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _ctl.contacts;
    return SafetyScaffold(
      title: 'Emergency contacts',
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: items.length >= kMaxEmergencyContacts ? null : () => _edit(),
            style: ElevatedButton.styleFrom(
              backgroundColor: SafetyUi.ink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFD8DEE3),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              items.length >= kMaxEmergencyContacts ? 'Maximum 5 contacts' : 'Add contact',
              style: SafetyUi.text(15.5, weight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        children: [
          const Center(child: SafetyMark(SafetyMarks.contacts, size: 72)),
          const SizedBox(height: 16),
          Text(
            'Add people you trust so they can be reached quickly when you need help.',
            textAlign: TextAlign.center,
            style: SafetyUi.text(15, color: SafetyUi.muted, height: 1.45),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Container(
              decoration: SafetyUi.cardDecoration(),
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
              child: Text(
                'No emergency contacts yet. Add someone you trust.',
                textAlign: TextAlign.center,
                style: SafetyUi.text(14.5, color: SafetyUi.muted, height: 1.4),
              ),
            )
          else
            Container(
              decoration: SafetyUi.cardDecoration(),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++)
                    _ContactTile(
                      contact: items[i],
                      showDivider: i != items.length - 1,
                      onEdit: () => _edit(items[i]),
                      onDelete: () => _ctl.removeContact(items[i].id),
                      onPrimary: () => _ctl.makePrimary(items[i].id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.showDivider,
    required this.onEdit,
    required this.onDelete,
    required this.onPrimary,
  });

  final EmergencyContact contact;
  final bool showDivider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
          title: Text(contact.name, style: SafetyUi.text(16, weight: FontWeight.w500)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              [
                SwedishPhone.display(contact.phoneE164),
                contact.relationship,
                if (contact.isPrimary) 'Primary',
                if (contact.shareTrips) 'Trip sharing',
              ].join(' · '),
              style: SafetyUi.text(12.5, color: SafetyUi.muted),
            ),
          ),
          onTap: onEdit,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'primary') onPrimary();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (!contact.isPrimary)
                const PopupMenuItem(value: 'primary', child: Text('Make primary')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 18),
            child: Divider(height: 1, color: SafetyUi.line),
          ),
      ],
    );
  }
}

class _ContactEditor extends StatefulWidget {
  const _ContactEditor({required this.controller, this.existing});
  final SafetyController controller;
  final EmergencyContact? existing;

  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late String _relationship;
  late bool _share;
  late bool _enabled;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _phone = TextEditingController(text: existing?.phoneE164 ?? '');
    _relationship = existing?.relationship ?? 'Family';
    _share = existing?.shareTrips ?? false;
    _enabled = existing?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.existing == null) {
        await widget.controller.addContact(
          name: _name.text,
          phone: _phone.text,
          relationship: _relationship,
          shareTrips: _share,
        );
      } else {
        await widget.controller.editContact(
          widget.existing!.copyWith(
            name: _name.text,
            phoneE164: _phone.text,
            relationship: _relationship,
            shareTrips: _share,
            isEnabled: _enabled,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() {
        _error = widget.controller.error ?? 'Could not save contact.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SafetyUi.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing == null ? 'Add contact' : 'Edit contact',
              style: SafetyUi.text(20, weight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _relationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: [
                for (final label in kEmergencyContactRelationships)
                  DropdownMenuItem(value: label, child: Text(label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _relationship = value);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Share trips with this person', style: SafetyUi.text(14.5)),
              value: _share,
              activeColor: SafetyUi.accent,
              onChanged: (value) => setState(() => _share = value),
            ),
            if (widget.existing != null)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Enabled', style: SafetyUi.text(14.5)),
                value: _enabled,
                activeColor: SafetyUi.accent,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: SafetyUi.text(13, color: SafetyUi.danger)),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafetyUi.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_saving ? 'Saving…' : 'Save', style: SafetyUi.text(15.5, weight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
