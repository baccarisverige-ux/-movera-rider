import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/saved_places/application/saved_places_controller.dart';
import 'package:movera_rider/features/saved_places/domain/saved_place.dart';
import 'package:movera_rider/features/saved_places/presentation/pickup_location.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class AddPlace extends StatefulWidget {
  const AddPlace({
    super.key,
    this.controller,
    this.initial,
    this.kind,
  });

  final SavedPlacesController? controller;
  final PlaceShortcut? initial;
  final String? kind;

  @override
  State<AddPlace> createState() => _AddPlaceState();
}

class _AddPlaceState extends State<AddPlace> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final SavedPlacesController _places;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _places = widget.controller ?? SavedPlacesController();
    _nameController = TextEditingController(text: widget.initial?.title ?? '');
    _locationController =
        TextEditingController(text: widget.initial?.subtitle ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final selected = await Navigator.push<String>(
      context,
      BottomToTopTransition(
        const RiderSearchPickupLocation(allowCreateShortcut: false),
      ),
    );
    if (!mounted || selected == null || selected.trim().isEmpty) return;
    setState(() {
      _locationController.text = selected.trim();
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    if (name.isEmpty || location.isEmpty) {
      setState(() => _error = 'Add both a name and a location.');
      return;
    }

    final place = PlaceShortcut(
      title: name,
      subtitle: location,
      kind: _kindFor(name),
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _places.save(place);
      if (!mounted) return;
      Navigator.pop(context, place);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Couldn’t save this place. Try again.';
      });
    }
  }

  String _kindFor(String name) {
    final existing = widget.initial?.kind.trim();
    final requested = widget.kind?.trim();
    final raw = requested?.isNotEmpty == true
        ? requested!
        : existing?.isNotEmpty == true
            ? existing!
            : name;
    final lower = raw.toLowerCase();
    if (lower == 'work') return 'office';
    final slug = lower
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'other' : slug;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: ResSize.h * 30,
                width: ResSize.w * 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff999999).withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppColor.title,
                    size: ResSize.h * 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: TextWidget(
          text: widget.initial == null ? 'Add new address' : 'Edit saved place',
          color: AppColor.title,
          fontSize: 16,
          fontWeight: fwSemiBold,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            TextField(
              controller: _nameController,
              style: GoogleFonts.poppins(
                color: AppColor.title,
                fontSize: 16,
                fontWeight: fwNormal,
              ),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: GoogleFonts.poppins(
                  color: AppColor.subtitle,
                  fontSize: 14,
                  fontWeight: fwNormal,
                ),
              ),
            ),
            16.height,
            InkWell(
              onTap: _pickLocation,
              child: IgnorePointer(
                child: TextField(
                  controller: _locationController,
                  style: GoogleFonts.poppins(
                    color: AppColor.title,
                    fontSize: 16,
                    fontWeight: fwNormal,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Add location',
                    labelStyle: GoogleFonts.poppins(
                      color: AppColor.subtitle,
                      fontSize: 12,
                      fontWeight: fwNormal,
                    ),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              12.height,
              Text(
                _error!,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: fwMedium,
                ),
              ),
            ],
            const Spacer(),
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ),
            ),
            16.height,
          ],
        ),
      ),
    );
  }
}
