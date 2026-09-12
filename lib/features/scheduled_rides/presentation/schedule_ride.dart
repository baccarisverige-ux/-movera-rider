import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/scheduled_rides/application/scheduled_rides_controller.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/confirm_booking.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/add_note.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/select_date_time.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class ScheduleRide extends StatefulWidget {
  const ScheduleRide({super.key});

  @override
  State<ScheduleRide> createState() => _ScheduleRideState();
}

class _ScheduleRideState extends State<ScheduleRide> {
  static const Color _scheduleInk = Color(0xFF172127);
  static const Color _scheduleMuted = Color(0xFF7B858B);
  static const Color _scheduleSurface = Color(0xFFF5F6F6);
  static const Color _scheduleLine = Color(0xFFE4E7E8);
  static const Color _scheduleAccent = Color(0xFF356879);

  final TextEditingController _pickupController = TextEditingController(
    text: 'Current location',
  );
  final TextEditingController _dropoffController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final ScheduledRideSession _session = ScheduledRideSession();

  // Default location
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(59.3293, 18.0686), // neutral map fallback
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _pickupController.addListener(_syncRouteToSession);
    _dropoffController.addListener(_syncRouteToSession);
    _syncRouteToSession();
  }

  @override
  void dispose() {
    _pickupController.removeListener(_syncRouteToSession);
    _dropoffController.removeListener(_syncRouteToSession);
    _pickupController.dispose();
    _dropoffController.dispose();
    for (final controller in _stopControllers) {
      controller.removeListener(_syncRouteToSession);
      controller.dispose();
    }
    sc.dispose();
    AppScope.instance.maps.detach(owner: MapOwners.schedule);
    super.dispose();
  }

  void _loadMarkers() {
    // Add any initial markers if needed
    // Example: driver location marker
    _markers.add(
      Marker(
        markerId: MarkerId('driver_location'),
        position: LatLng(59.3293, 18.0686),
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
  }

  int currentStep = 0;

  void _syncRouteToSession() {
    _session.captureRoute(
      pickup: _pickupController.text,
      dropoff: _dropoffController.text,
      stops: _stopControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
    );
  }

  void goToNextStep() {
    FocusScope.of(context).unfocus();
    _syncRouteToSession();
    setState(() => currentStep += 1);
  }

  void goToPreviousStep() {
    FocusScope.of(context).unfocus();
    if (currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => currentStep -= 1);
  }

  void _editRoute() {
    FocusScope.of(context).unfocus();
    if (currentStep == 0) return;
    setState(() => currentStep = 0);
  }

  void _addStop() {
    if (_stopControllers.length >= 3) return;
    final controller = TextEditingController();
    controller.addListener(_syncRouteToSession);
    setState(() => _stopControllers.add(controller));
    _syncRouteToSession();
  }

  void _removeStop(int index) {
    final controller = _stopControllers.removeAt(index);
    controller.removeListener(_syncRouteToSession);
    controller.dispose();
    setState(() {});
    _syncRouteToSession();
  }

  ScrollController sc = ScrollController();

  Widget _buildPanelContent() {
    if (currentStep == 0) {
      return _buildAddressStep();
    } else if (currentStep == 1) {
      return ScheduleDateTimeSelector(
        onConfirm: goToNextStep,
        onBack: goToPreviousStep,
        body: body(),
        session: _session,
      );
    } else if (currentStep == 2) {
      return ScheduleAddNote(
        onConfirm: goToNextStep,
        body: body(),
        session: _session,
      );
    } else {
      return ScheduleConfirmBooking(body: body(), session: _session);
    }
  }

  Widget _buildAddressStep() {
    final canContinue = _dropoffController.text.trim().isNotEmpty;
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Material(
                          color: _scheduleSurface,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 23,
                                color: _scheduleInk,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'SCHEDULE',
                          style: GoogleFonts.poppins(
                            color: _scheduleMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Plan your ride',
                      style: GoogleFonts.poppins(
                        color: _scheduleInk,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Where should your Movera driver pick you up?',
                      style: GoogleFonts.poppins(
                        color: _scheduleMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _scheduleLine),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.045),
                            blurRadius: 22,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _scheduleAddressField(
                            controller: _pickupController,
                            label: 'Pickup',
                            hint: 'Enter pickup address',
                            icon: Icons.my_location_rounded,
                          ),
                          const Divider(height: 1, indent: 42),
                          for (
                            var index = 0;
                            index < _stopControllers.length;
                            index++
                          ) ...[
                            _scheduleAddressField(
                              controller: _stopControllers[index],
                              label: 'Stop ${index + 1}',
                              hint: 'Enter stop address',
                              icon: Icons.more_horiz_rounded,
                              onRemove: () => _removeStop(index),
                            ),
                            const Divider(height: 1, indent: 42),
                          ],
                          _scheduleAddressField(
                            controller: _dropoffController,
                            label: 'Drop-off',
                            hint: 'Where to?',
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    if (_stopControllers.length < 3)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addStop,
                          style: TextButton.styleFrom(
                            foregroundColor: _scheduleInk,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 19),
                          label: Text(
                            'Add a stop',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 25),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _scheduleSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: _scheduleAccent,
                            size: 21,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You will choose the date and time on the next screen.',
                              style: GoogleFonts.poppins(
                                color: _scheduleMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _scheduleLine)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: canContinue ? goToNextStep : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scheduleInk,
                      disabledBackgroundColor: _scheduleInk.withOpacity(0.18),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _scheduleAddressField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    VoidCallback? onRemove,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Icon(icon, color: _scheduleAccent, size: 20),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            textInputAction: label == 'Drop-off'
                ? TextInputAction.done
                : TextInputAction.next,
            style: GoogleFonts.poppins(
              color: _scheduleInk,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              labelStyle: GoogleFonts.poppins(
                color: _scheduleMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: GoogleFonts.poppins(
                color: _scheduleMuted.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        if (onRemove != null)
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: _scheduleMuted,
            iconSize: 18,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildPanelContent());
  }

  Widget verticleCircle({
    String? icon,
    bool isStop = false,
    String? stopText,
    bool removeDottedLine = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: ResSize.h * 32,
            width: ResSize.w * 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.liteBlue,
            ),
            child: Center(
              child: isStop
                  ? TextWidget(
                      text: stopText,
                      fontWeight: fwBold,
                      fontSize: 16,
                      color: AppColor.black,
                    )
                  : Image.asset(icon!, height: ResSize.h * 22),
            ),
          ),
          removeDottedLine
              ? 0.height
              : Expanded(
                  child: DottedLine(
                    dashLength: 3,
                    dashGapLength: 3,
                    lineThickness: 1.4,
                    dashColor: AppColor.black,
                    direction: Axis.vertical,
                  ),
                ),
        ],
      ),
    );
  }

  Widget horizentalLocation({String? title, location, bool isStop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          fontSize: 12,
          fontWeight: fwSemiBold,
          text: title,
          color: Color(0xffA3A3A3),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                location!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: fwSemiBold,
                  color: AppColor.black,
                ),
              ),
            ),
            isStop
                ? Row(
                    children: [
                      10.width,
                      Image.asset(AppAssets.removeStop, height: ResSize.h * 24),
                    ],
                  )
                : SizedBox(),
          ],
        ),
      ],
    );
  }

  Widget body() {
    return SizedBox(
      child: Stack(
        children: [
          CustomGoogleMap(
            initialPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              AppScope.instance.maps.attach(
                controller,
                owner: MapOwners.schedule,
              );
            },
            onTap: (LatLng position) {
              // Handle map tap events
            },
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                children: [
                  50.height,
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: ResSize.h * 24,
                          width: ResSize.w * 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.white,
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 4),
                                color: Color(
                                  0xff606060,
                                  // ignore: deprecated_member_use
                                ).withOpacity(0.12),
                                spreadRadius: 6,
                                blurRadius: 40,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: AppColor.black,
                              size: ResSize.h * 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  18.height,
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColor.white,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 16,
                        vertical: ResSize.h * 16,
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height:
                                    ResSize.h * 230, // more height to fit A & B
                                child: Column(
                                  children: [
                                    5.height,
                                    // Pickup Circle
                                    verticleCircle(icon: AppAssets.gps),

                                    2.height,
                                    verticleCircle(isStop: true, stopText: "A"),
                                    2.height,
                                    verticleCircle(isStop: true, stopText: "B"),
                                    2.height,
                                    verticleCircle(
                                      icon: AppAssets.location,
                                      removeDottedLine: true,
                                    ),
                                  ],
                                ),
                              ),
                              12.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: _editRoute,
                                      child: horizentalLocation(
                                        title: "Pick-Up",
                                        location:
                                            "Club Vista Mare - Dubai - Unit...",
                                      ),
                                    ),
                                    9.height,
                                    Divider(
                                      height: 0,
                                      thickness: 0.2,
                                      color: AppColor.border,
                                    ),
                                    9.height,

                                    horizentalLocation(
                                      title: "Stop Point A",
                                      isStop: true,
                                      location:
                                          "Ab - Dubai - United Arab Emi...",
                                    ),
                                    9.height,
                                    Divider(
                                      height: 0,
                                      thickness: 0.2,
                                      color: AppColor.border,
                                    ),
                                    9.height,

                                    horizentalLocation(
                                      isStop: true,
                                      title: "Stop Point B",
                                      location:
                                          "Club - Dubai - United Arab Emi...",
                                    ),
                                    9.height,
                                    Divider(
                                      height: 0,
                                      thickness: 0.2,
                                      color: AppColor.border,
                                    ),
                                    9.height,

                                    horizentalLocation(
                                      title: "Drop Off",
                                      location:
                                          "JVC - Dubai - United Arab Emi...",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
