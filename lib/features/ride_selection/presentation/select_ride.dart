import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/core/maps/route_polyline.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/booking/application/booking_controller.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/application/scheduled_ride_checkout.dart';
import 'package:movera_rider/features/ride_selection/domain/booking_mode.dart';
import 'package:movera_rider/features/ride_selection/presentation/quick_ride_notes_sheet.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/select_date_time.dart';
import 'package:movera_rider/features/ride_booking/application/sheet_coordinator.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/shared/design_system/motion/movera_motion.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

export 'package:movera_rider/features/ride_selection/domain/booking_mode.dart';

class SelectRide extends StatefulWidget {
  const SelectRide({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupPosition,
    required this.destinationPosition,
    this.stops = const <String>[],
    this.bookingMode = BookingMode.now,
    this.lockBookingMode = false,
    this.initialScheduledFor,
    this.initialRideId,
    this.initialPaymentMethod,
    this.parentReservationId,
    this.editingReservationId,
    this.note,
    this.reservations,
    this.onScheduled,
    this.selection,
    this.booking,
    this.realtime,
    this.pickupAlreadyConfirmed = false,
  });

  /// Return-ride entry: same category cards, scheduled mode, reverse route.
  factory SelectRide.forReturnRide(
    Reservation origin, {
    Key? key,
    ReservationController? reservations,
    Future<void> Function(BuildContext context, String reservationId)?
    onScheduled,
  }) {
    const stockholm = LatLng(59.3293, 18.0686);
    LatLng? tryPoint(ReservationPlace place) {
      if (place.lat == null || place.lng == null) return null;
      return LatLng(place.lat!, place.lng!);
    }

    final originPickup = tryPoint(origin.pickup);
    final originDest = tryPoint(origin.destination);
    final known = originDest ?? originPickup ?? stockholm;
    final returnPickup =
        originDest ?? LatLng(known.latitude + 0.006, known.longitude + 0.008);
    final returnDest =
        originPickup ?? LatLng(known.latitude - 0.004, known.longitude - 0.006);
    return SelectRide(
      key: key,
      pickupAddress: origin.destination.label,
      destinationAddress: origin.pickup.label,
      pickupPosition: returnPickup,
      destinationPosition: returnDest,
      bookingMode: BookingMode.scheduled,
      lockBookingMode: true,
      initialScheduledFor: origin.scheduledPickupAt.add(
        const Duration(hours: 3),
      ),
      initialRideId: origin.categoryId,
      initialPaymentMethod: origin.paymentMethod,
      parentReservationId: origin.reservationId,
      note: origin.note,
      reservations: reservations,
      onScheduled: onScheduled,
    );
  }

  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final List<String> stops;
  final BookingMode bookingMode;
  final bool lockBookingMode;
  final DateTime? initialScheduledFor;
  final String? initialRideId;
  final String? initialPaymentMethod;
  final String? parentReservationId;
  final String? editingReservationId;
  final String? note;
  final ReservationController? reservations;
  final Future<void> Function(BuildContext context, String reservationId)?
  onScheduled;

  /// Optional seams are used by behavioral certification; production keeps
  /// the same AppScope-backed defaults.
  final RideSelectionController? selection;
  final BookingController? booking;
  final RideRealtime? realtime;
  final bool pickupAlreadyConfirmed;

  @override
  State<SelectRide> createState() => _SelectRideState();
}

enum _RideFilter { recommended, faster, cheaper }

class _RideOption {
  const _RideOption({
    required this.id,
    required this.image,
    required this.name,
    required this.note,
    required this.arrival,
    required this.etaMin,
    required this.price,
    required this.seats,
    this.badge,
    this.glyph,
  });

  final String id;
  final String image;
  final String name;
  final String note;
  final String arrival;
  final int etaMin;
  final double price;
  final int seats;
  final String? badge;
  final IconData? glyph;
}

class _PaymentOption {
  const _PaymentOption({
    required this.brand,
    required this.name,
    required this.detail,
  });

  final String brand;
  final String name;
  final String detail;
}

class _SelectRideState extends State<SelectRide>
    with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF5C656C);
  static const Color _line = Color(0xFFE7EBEE);
  static const Color _accent = Color(0xFF2D5878);
  static const Color _accentSoft = Color(0xFFEAF2F8);
  static const Color _field = Color(0xFFF6F5F1);
  static const Color _cta = Color(0xFF11181D);

  List<_RideOption> get _allRides {
    return _selection.rides().map((ride) {
      return _RideOption(
        id: ride.id,
        image: ride.image,
        name: ride.name,
        note: ride.note,
        arrival: ride.arrival,
        etaMin: ride.etaMin,
        price: ride.price,
        seats: ride.seats,
        badge: ride.badge,
        glyph: ride.glyph == 'bolt'
            ? Icons.bolt_rounded
            : ride.glyph == 'pets'
            ? Icons.pets_rounded
            : null,
      );
    }).toList();
  }

  List<_PaymentOption> get _payments {
    return _selection.payments().map((item) {
      return _PaymentOption(
        brand: item.brand,
        name: item.name,
        detail: item.detail,
      );
    }).toList();
  }

  _RideFilter _filter = _RideFilter.recommended;
  late final bool _ownsSelection = widget.selection == null;
  late final RideSelectionController _selection =
      widget.selection ??
      RideSelectionController(
        bookingMode: widget.bookingMode,
        lockBookingMode: widget.lockBookingMode,
        paymentStore: AppScope.instance.defaultPayment,
      );
  bool _mapReady = false;
  bool _mapMountScheduled = false;
  bool _mapParked = false;
  bool _overlayOn = false;
  bool _pickupConfirmed = false;
  bool _bookingInFlight = false;
  RideNotes _notes = RideNotes.empty;
  late String _pickupAddress;
  late LatLng _pickupPosition;
  // ignore: unused_field
  GoogleMapController? _mapController;
  late final AnimationController _sheetSlide;

  ReservationController get _reservations =>
      widget.reservations ?? AppScope.instance.reservations;

  @override
  void initState() {
    super.initState();
    _pickupAddress = widget.pickupAddress;
    _pickupPosition = widget.pickupPosition;
    _pickupConfirmed = widget.pickupAlreadyConfirmed;
    _sheetSlide = AnimationController(
      vsync: this,
      duration: MoveraDurations.sheetOpen,
      value: 1,
    );
    _sheetSlide.addListener(_syncSheetOverlay);
    _syncSheetOverlay();
    if (widget.initialRideId != null) {
      final ride = _selection.rideById(widget.initialRideId!);
      _selection.selectRide(ride.id, ride.price);
    }
    final paymentName =
        widget.initialPaymentMethod ??
        (widget.editingReservationId == null
            ? null
            : _reservations.byId(widget.editingReservationId!)?.paymentMethod);
    _selection.selectPaymentNamed(paymentName);
    if (paymentName == null) {
      unawaited(_restoreSavedPayment());
    }
    if (widget.initialScheduledFor != null) {
      _selection.scheduleFor(widget.initialScheduledFor);
    } else if (widget.bookingMode == BookingMode.scheduled) {
      _selection.setBookingMode(BookingMode.scheduled);
    }
    _loadQuotes();
  }

  Future<void> _restoreSavedPayment() async {
    await _selection.restoreDefaultPayment();
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sheetSlide.duration = MoveraMotion.of(context, MoveraDurations.sheetOpen);
    if (!_mapMountScheduled) {
      _mapMountScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_mountMapWhenRouteSettles());
      });
    }
  }

  Future<void> _mountMapWhenRouteSettles() async {
    await waitForCurrentRouteToSettle(context);
    if (!mounted) return;
    setState(() => _mapReady = true);
  }

  Future<void> _loadQuotes() async {
    final generation = _selection.beginQuotes();
    await _selection.loadQuotes(
      generation: generation,
      pickup: widget.pickupAddress,
      destination: widget.destinationAddress,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_ownsSelection) _selection.dispose();
    _sheetSlide.removeListener(_syncSheetOverlay);
    _sheetSlide.dispose();
    _mapController = null;
    setWebOverlayOpen(false);
    AppScope.instance.maps.detach(owner: MapOwners.selectRide);
    super.dispose();
  }

  void _syncSheetOverlay() {
    final cover = _sheetSlide.value > 0.05;
    if (cover == _overlayOn) return;
    _overlayOn = cover;
    setWebOverlayOpen(cover);
  }

  _RideOption get _selectedRide =>
      _allRides.firstWhere((ride) => ride.id == _selection.selectedRideId);

  double _priceFor(_RideOption ride) =>
      _selection.priceFor(ride.id, ride.price);

  void _selectRide(String id) {
    final catalog = _allRides.firstWhere((ride) => ride.id == id).price;
    setState(() {
      _selection.selectRide(id, catalog);
    });
  }

  void _nudgePrice(int delta) {
    final ride = _selectedRide;
    final current = _priceFor(ride);
    final next = _selection.changeOffer(
      id: ride.id,
      catalog: ride.price,
      delta: delta,
    );
    if (next == current) return;
    setState(() {});
  }

  List<_RideOption> get _visibleRides {
    final rides = [..._allRides];
    switch (_filter) {
      case _RideFilter.faster:
        rides.sort((a, b) => a.etaMin.compareTo(b.etaMin));
        break;
      case _RideFilter.cheaper:
        rides.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _RideFilter.recommended:
        break;
    }
    return rides;
  }

  TextStyle _text(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  String _compactAddress(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return 'Unknown place';
    final parts = cleaned
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => !RegExp(r'^\d{3,}$').hasMatch(part))
        .toList();
    if (parts.isEmpty) return cleaned;
    if (parts.length == 1) return parts.first;
    return '${parts[0]}, ${parts[1]}';
  }

  String _kr(double value) => 'kr ${value.toStringAsFixed(0)}';

  double _minSheet(MediaQueryData media) =>
      (348 + media.padding.bottom).clamp(300.0, media.size.height * 0.48);

  double _maxSheet(MediaQueryData media) {
    final minH = _minSheet(media);
    final largeText = media.textScaler.scale(1) >= 1.6;
    final topClearance = largeText ? 0.0 : 72.0;
    final maxH = media.size.height - media.padding.top - topClearance;
    return maxH < minH + 64 ? minH + 64 : maxH;
  }

  void _onSheetDragUpdate(DragUpdateDetails details, MediaQueryData media) {
    final range = _maxSheet(media) - _minSheet(media);
    if (range <= 0) return;
    final next = (_sheetSlide.value - details.primaryDelta! / range).clamp(
      0.0,
      1.0,
    );
    _sheetSlide.value = next;
  }

  void _onSheetDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final target = velocity < -480
        ? 1.0
        : velocity > 480
        ? 0.0
        : _sheetSlide.value >= 0.42
        ? 1.0
        : 0.0;
    _sheetSlide.animateTo(
      target,
      duration: MoveraMotion.of(context, MoveraDurations.large),
      curve: MoveraCurves.snap,
    );
  }

  Future<void> _fitRoute() async {
    if (!mounted) return;
    final pickup = widget.pickupPosition;
    final destination = widget.destinationPosition;
    final samePoint =
        (pickup.latitude - destination.latitude).abs() < 0.00008 &&
        (pickup.longitude - destination.longitude).abs() < 0.00008;
    try {
      if (samePoint) {
        await AppScope.instance.maps.animateCamera(
          GeoPoint(pickup.latitude, pickup.longitude),
          zoom: 14.4,
        );
        return;
      }
      await AppScope.instance.maps.fitBounds(
        GeoPoint(pickup.latitude, pickup.longitude),
        GeoPoint(destination.latitude, destination.longitude),
        padding: 56,
      );
    } catch (_) {}
  }

  Future<void> _withParkedMap(Future<void> Function() action) async {
    if (!_mapParked) {
      setState(() => _mapParked = true);
      AppScope.instance.maps.detach(owner: MapOwners.selectRide);
      _mapController = null;
      // Dispose the current platform map for one frame before mounting the
      // next ride stage. This prevents overlapping maps without a visible
      // arbitrary 90 ms pause.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    try {
      await action();
    } finally {
      final routeIsCurrent = mounted && (ModalRoute.of(context)?.isCurrent ?? false);
      if (routeIsCurrent) setState(() => _mapParked = false);
    }
  }

  Future<void> _chooseLater() async {
    await _withParkedMap(() async {
      if (!mounted) return;
      final when = await ScheduleDateTimeSelector.choose(context);
      if (when == null || !mounted) return;
      if (!_pickupConfirmed) {
        final spot = await ConfirmPickupSpot.open(
          context,
          initialPosition: _pickupPosition,
          initialAddress: _pickupAddress,
          scheduledSummary:
              '${when.day} ${_month(when)} · ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
          confirmLabel: 'Confirm pickup spot',
        );
        if (spot == null || !mounted) return;
        _pickupAddress = spot.address;
        _pickupPosition = spot.position;
        _pickupConfirmed = true;
      }
      setState(() => _selection.scheduleFor(when));
    });
  }

  String _month(DateTime when) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[when.month - 1];
  }

  Future<void> _showBookingPicker() async {
    if (widget.lockBookingMode) {
      await _chooseLater();
      return;
    }
    var chooseLaterAfterClose = false;
    await MoveraSheet.show<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'When do you want to ride?',
                    style: _text(20, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                _sheetChoice(
                  icon: Icons.bolt_rounded,
                  title: 'Book now',
                  subtitle: 'Request a driver right away',
                  selected: _selection.bookingMode == BookingMode.now,
                  onTap: () {
                    setState(() => _selection.setBookingMode(BookingMode.now));
                    Navigator.pop(sheetContext);
                  },
                ),
                _sheetChoice(
                  icon: Icons.calendar_month_rounded,
                  title: 'Book for later',
                  subtitle: 'Choose a date and pickup time',
                  selected: _selection.bookingMode == BookingMode.scheduled,
                  onTap: () {
                    chooseLaterAfterClose = true;
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chooseLaterAfterClose && mounted) {
      await _chooseLater();
    }
  }

  Future<void> _showPaymentPicker() async {
    await MoveraSheet.show<void>(
      context: context,
      backgroundColor: const Color(0xFFF6F5F1),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F5F1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Payment', style: _text(22, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'PAYMENT METHODS',
                  style: _text(
                    10,
                    weight: FontWeight.w600,
                    color: _muted,
                    letterSpacing: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _payments.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: 62,
                            endIndent: 16,
                            color: _line,
                          ),
                        _walletPaymentTile(i, sheetContext),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _bookScheduled() async {
    try {
      if (_selection.scheduledFor == null) {
        await _chooseLater();
      }
      if (_selection.scheduledFor == null || !mounted) return;
      await _withParkedMap(() async {
        if (!mounted) return;
        if (!_pickupConfirmed) {
          final when = _selection.scheduledFor;
          final spot = await ConfirmPickupSpot.open(
            context,
            initialPosition: _pickupPosition,
            initialAddress: _pickupAddress,
            scheduledSummary: when == null
                ? null
                : '${when.day} ${_month(when)} · ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
            confirmLabel: 'Confirm pickup spot',
          );
          if (spot == null || !mounted) return;
          _pickupAddress = spot.address;
          _pickupPosition = spot.position;
          _pickupConfirmed = true;
        }
        final created = await ScheduledRideCheckout.run(
          context,
          reservations: _reservations,
          selection: _selection,
          pickup: ReservationPlace(
            label: _pickupAddress,
            lat: _pickupPosition.latitude,
            lng: _pickupPosition.longitude,
          ),
          destination: ReservationPlace(
            label: widget.destinationAddress,
            lat: widget.destinationPosition.latitude,
            lng: widget.destinationPosition.longitude,
          ),
          pickupPosition: _pickupPosition,
          note: _driverNote(widget.note),
          parentReservationId: widget.parentReservationId,
          editingReservationId: widget.editingReservationId,
          original: widget.editingReservationId == null
              ? null
              : _reservations.byId(widget.editingReservationId!),
        );
        if (!mounted || created == null) return;
        final opener = widget.onScheduled;
        if (opener != null) {
          await opener(context, created.reservationId);
          return;
        }
        Navigator.pop(context, created);
      });
    } finally {
      _releaseBookingLock();
    }
  }

  String? _driverNote(String? extra) {
    final parts = <String>[
      if (extra != null && extra.trim().isNotEmpty) extra.trim(),
      ..._notes.selected,
    ];
    if (parts.isEmpty) return extra;
    return parts.join(' · ');
  }

  Future<void> _openNotes() async {
    final next = await showQuickRideNotesSheet(context, initial: _notes);
    if (!mounted || next == null) return;
    setState(() => _notes = next);
  }

  void _releaseBookingLock() {
    _bookingInFlight = false;
    if (mounted) setState(() {});
  }

  void _releaseRouteWork() {
    _bookingInFlight = false;
    _selection.cancelPendingQuotes();
  }

  void _onRoutePop(bool didPop, Object? _) {
    if (!didPop) return;
    _releaseRouteWork();
  }

  void _book() {
    if (_bookingInFlight) return;

    final selected = _selectedRide;
    if (!_selection.quoteIsAvailable(selected.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price unavailable. Refreshing fare…'),
        ),
      );
      unawaited(_loadQuotes());
      return;
    }

    _bookingInFlight = true;
    setState(() {});
    if (_selection.bookingMode == BookingMode.scheduled) {
      _bookScheduled();
      return;
    }
    _bookNow();
  }

  void _bookNow() {
    final selected = _selectedRide;
    final quote = _selection.quoteForBooking(selected.id);
    final authoritativePrice = _selection.authoritativePriceFor(selected.id);
    if (quote == null ||
        authoritativePrice == null ||
        quote.signedPayload == null ||
        quote.signedPayload!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fare changed or expired. Refreshing price…')),
      );
      _releaseBookingLock();
      unawaited(_loadQuotes());
      return;
    }
    final paymentItem = _selection.selectedPaymentItem();
    if (paymentItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payment method is available.')),
      );
      _releaseBookingLock();
      return;
    }
    final payment = _PaymentOption(
      brand: paymentItem.brand,
      name: paymentItem.name,
      detail: paymentItem.detail,
    );
    _withParkedMap(() async {
      try {
        if (!mounted) return;
        if (FindingDriverController.active != null) return;

        String rideId;
        try {
          rideId = await (widget.booking ?? BookingController()).submitFinding(
            pickupAddress: _pickupAddress,
            destinationAddress: widget.destinationAddress,
            pickupLat: _pickupPosition.latitude,
            pickupLng: _pickupPosition.longitude,
            destinationLat: widget.destinationPosition.latitude,
            destinationLng: widget.destinationPosition.longitude,
            rideType: selected.id,
            price: authoritativePrice,
            paymentMethod: payment.brand,
            quoteId: quote.id,
            quoteSignedPayload: quote.signedPayload,
            quoteExpiresAt: quote.expiresAt,
            quoteTotalMinor: quote.totalMinor,
            rideTypeLabel: selected.name,
            paymentMethodLabel: payment.name,
            notes: _notes,
          );
          if (rideId.trim().isEmpty) {
            throw StateError('Booking response did not contain a ride id.');
          }
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'We could not book this ride. Check the fare and try again.',
              ),
            ),
          );
          unawaited(_loadQuotes());
          return;
        }

        if (!mounted) return;
        if (FindingDriverController.active != null) return;
        SheetCoordinator.instance.open(RideSheet.finding);
        try {
          await Navigator.push(
            context,
            RideStageTransition(
            FindingDrivers(
                pickupAddress: _pickupAddress,
                destinationAddress: widget.destinationAddress,
                pickupPosition: _pickupPosition,
                destinationPosition: widget.destinationPosition,
                rideType: selected.name,
                price: authoritativePrice,
                paymentMethod: payment.name,
                notes: _notes,
                realtime: widget.realtime,
              ),
              settings: const RouteSettings(name: AppRoutes.findingDriver),
            ),
          );
        } finally {
          SheetCoordinator.instance.close(RideSheet.finding);
        }
      } finally {
        _releaseBookingLock();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final showLiveMap = _mapReady && !_mapParked;
    final minSheet = _minSheet(media);
    return PopScope(
      onPopInvokedWithResult: _onRoutePop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F5F1),
        body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: minSheet,
            child: RepaintBoundary(
              child: showLiveMap
                  ? CustomGoogleMap(
                      key: const ValueKey('select-ride-map'),
                      initialPosition: CameraPosition(
                        target: widget.pickupPosition,
                        zoom: 13.2,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('pickup'),
                          position: widget.pickupPosition,
                        ),
                        Marker(
                          markerId: const MarkerId('destination'),
                          position: widget.destinationPosition,
                        ),
                      },
                      polylines: {
                        routePolyline(
                          id: 'route',
                          from: widget.pickupPosition,
                          to: widget.destinationPosition,
                          color: _accent,
                        ),
                      },
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      trafficEnabled: false,
                      buildingsEnabled: false,
                      indoorViewEnabled: false,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        AppScope.instance.maps.attach(
                          controller,
                          owner: MapOwners.selectRide,
                        );
                        AppScope.instance.map.drawRoute(
                          'select',
                          GeoPoint(
                            widget.pickupPosition.latitude,
                            widget.pickupPosition.longitude,
                          ),
                          GeoPoint(
                            widget.destinationPosition.latitude,
                            widget.destinationPosition.longitude,
                          ),
                        );
                        AppScope.instance.map.upsertMarker(
                          'pickup',
                          GeoPoint(
                            widget.pickupPosition.latitude,
                            widget.pickupPosition.longitude,
                          ),
                        );
                        AppScope.instance.map.upsertMarker(
                          'destination',
                          GeoPoint(
                            widget.destinationPosition.latitude,
                            widget.destinationPosition.longitude,
                          ),
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) unawaited(_fitRoute());
                        });
                      },
                    )
                  : const _RouteCanvas(),
            ),
          ),
          Positioned(
            top: media.padding.top + 8,
            left: 16,
            right: 16,
            child: PointerInterceptor(child: _searchBar()),
          ),
          AnimatedBuilder(
            animation: _sheetSlide,
            builder: (context, _) {
              final minSheet = _minSheet(media);
              final maxSheet = _maxSheet(media);
              final sheetHeight =
                  minSheet + (maxSheet - minSheet) * _sheetSlide.value;
              final collapsed = _sheetSlide.value < 0.38;
              final visibleRides = collapsed
                  ? <_RideOption>[_selectedRide]
                  : _visibleRides;
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: sheetHeight,
                child: PointerInterceptor(
                  child: Material(
                    color: Colors.white,
                    elevation: 18,
                    shadowColor: const Color(
                      0xFF162C36,
                    ).withValues(alpha: 0.16),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (details) =>
                              _onSheetDragUpdate(details, media),
                          onVerticalDragEnd: _onSheetDragEnd,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _line,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  16,
                                  0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Choose your ride',
                                        style: _text(
                                          22,
                                          weight: FontWeight.w700,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ),
                                    _priceStepper(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!collapsed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                            child: _filterRow(),
                          )
                        else
                          const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            physics: collapsed
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                            itemCount: visibleRides.length,
                            itemBuilder: (context, index) =>
                                _rideTile(visibleRides[index]),
                          ),
                        ),
                        _footer(media.padding.bottom),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF162C36).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
              tooltip: 'Back',
            ),
            Expanded(
              child: Text(
                _compactAddress(widget.destinationAddress),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(15, weight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _priceStepper() {
    final ride = _selectedRide;
    final price = _priceFor(ride);
    final minimum = (ride.price * 0.65).roundToDouble();
    final maximum = (ride.price * 1.8).roundToDouble();
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            Icons.remove_rounded,
            enabled: price > minimum,
            onTap: () => _nudgePrice(-10),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _kr(price),
              style: _text(13.5, weight: FontWeight.w600),
            ),
          ),
          _stepperButton(
            Icons.add_rounded,
            enabled: price < maximum,
            onTap: () => _nudgePrice(10),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(
    IconData icon, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? _ink : _muted.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'Recommended',
            selected: _filter == _RideFilter.recommended,
            onTap: () => setState(() => _filter = _RideFilter.recommended),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Faster',
            icon: Icons.schedule_rounded,
            selected: _filter == _RideFilter.faster,
            onTap: () => setState(() => _filter = _RideFilter.faster),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Cheaper',
            icon: Icons.payments_outlined,
            selected: _filter == _RideFilter.cheaper,
            onTap: () => setState(() => _filter = _RideFilter.cheaper),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _accentSoft : _field,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? _accent : _line, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? _accent : _muted),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: _text(
                13,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rideTile(_RideOption ride) {
    final selected = ride.id == _selection.selectedRideId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectRide(ride.id),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFBFCFC) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _accent : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF162C36).withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  height: 72,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          excludeFromSemantics: true,
                          ride.image,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          cacheWidth: 216,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car_filled_rounded,
                            color: _muted,
                            size: 36,
                          ),
                        ),
                      ),
                      if (ride.glyph != null)
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: _accentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(ride.glyph, size: 14, color: _accent),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ride.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _text(16, weight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            _kr(_priceFor(ride)),
                            style: _text(16, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(ride.arrival, style: _text(12.5, color: _muted)),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: _muted,
                          ),
                          Text(
                            ' ${ride.seats}',
                            style: _text(12.5, color: _muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ride.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          12.5,
                          color: _muted,
                          weight: FontWeight.w400,
                        ),
                      ),
                      if (ride.badge != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? _accent : _accentSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ride.badge!,
                            style: _text(
                              9.5,
                              weight: FontWeight.w700,
                              color: selected ? Colors.white : _accent,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(double bottomInset) {
    final selected = _selectedRide;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Column(
        children: [
          _paymentButton(),
          const SizedBox(height: 8),
          _notesButton(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _cta,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: _bookingInFlight ? null : _book,
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 54,
                      child: Center(
                        child: Text(
                          _selection.bookingMode.ctaLabel(selected.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(
                            16,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: _cta,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _showBookingPicker,
                  child: const SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notesButton() {
    final title = _notes.isEmpty
        ? 'Anything we should know?'
        : _notes.selected.join(' · ');
    final detail = _notes.isEmpty
        ? 'Optional. Your driver will see this'
        : 'Saved for this ride';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _openNotes,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 86,
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Positioned(
                        left: i * 16.0,
                        child: Image.asset(
                          excludeFromSemantics: true,
                          [
                            AppAssets.noteBags,
                            AppAssets.notePet,
                            AppAssets.noteBaby,
                            AppAssets.noteChild,
                          ][i],
                          height: 36,
                          width: 36,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(12, color: _muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentButton() {
    final method = _payments[_selection.selectedPayment];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _showPaymentPicker,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _brandMark(method.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(
                        11.5,
                        weight: FontWeight.w500,
                        color: method.brand == 'cash' ? _accent : _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletPaymentTile(int index, BuildContext sheetContext) {
    final method = _payments[index];
    final selected = _selection.selectedPayment == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selection.selectPayment(index));
          Navigator.pop(sheetContext);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              _brandMark(method.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: _text(14.5, weight: FontWeight.w600),
                    ),
                    Text(
                      selected ? 'Default for rides' : method.detail,
                      style: _text(
                        11.5,
                        color: selected ? _accent : _muted,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? _ink : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _ink : _line,
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetChoice({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _accent : _line),
        ),
        child: Row(
          children: [
            Icon(icon, color: _ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _text(16, weight: FontWeight.w600)),
                  Text(subtitle, style: _text(13, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandMark(String brand) {
    if (brand == 'swish') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 42,
          height: 38,
          child: SvgPicture.asset(
            'assets/images/swish_brand.svg',
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    Widget logo;
    Color background = Colors.white;
    if (brand == 'apple') {
      logo = SvgPicture.asset(
        'assets/images/apple_pay_brand.svg',
        fit: BoxFit.contain,
      );
    } else if (brand == 'google') {
      logo = Transform.scale(
        scale: 1.18,
        child: Image.asset(
          excludeFromSemantics: true,
          'assets/images/google_pay_brand.png',
          fit: BoxFit.contain,
        ),
      );
    } else if (brand == 'paypal') {
      logo = Image.asset(
        excludeFromSemantics: true,
        AppAssets.paypal,
        fit: BoxFit.contain,
      );
    } else if (brand == 'cards') {
      logo = Row(
        children: [
          Expanded(
            child: Image.asset(
              excludeFromSemantics: true,
              AppAssets.visa,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Image.asset(
              excludeFromSemantics: true,
              AppAssets.mastercard,
              fit: BoxFit.contain,
            ),
          ),
        ],
      );
    } else if (brand == 'cash') {
      background = const Color(0xFFEEF6F0);
      logo = const Icon(
        Icons.payments_outlined,
        color: Color(0xFF1F7A4D),
        size: 20,
      );
    } else {
      logo = Image.asset(
        excludeFromSemantics: true,
        AppAssets.wallet,
        color: _ink,
        fit: BoxFit.contain,
      );
    }
    return Container(
      width: 42,
      height: 38,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: background == Colors.white ? _line : background,
        ),
      ),
      child: logo,
    );
  }
}

class _RouteCanvas extends StatelessWidget {
  const _RouteCanvas();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _RoutePainter(),
      child: SizedBox.expand(),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDCE8DE), Color(0xFFEEF3E8), Color(0xFFF6F5F1)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final water = Paint()
      ..color = const Color(0xFFC9D9D4).withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.18,
          size.width * 0.38,
          28,
        ),
        const Radius.circular(20),
      ),
      water,
    );

    final land = Paint()..color = const Color(0xFFD7E3D4);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.42), 46, land);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.62), 34, land);

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.18,
        size.width * 0.84,
        size.height * 0.46,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2D5878).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2D5878)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    void pin(Offset c, Color color) {
      canvas.drawCircle(c, 9, Paint()..color = color);
      canvas.drawCircle(c, 4.2, Paint()..color = Colors.white);
    }

    pin(Offset(size.width * 0.16, size.height * 0.72), const Color(0xFF1D252C));
    pin(Offset(size.width * 0.84, size.height * 0.46), const Color(0xFF2D5878));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
