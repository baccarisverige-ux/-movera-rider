import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/features/active_ride/application/route_change_controller.dart';
import 'package:movera_rider/features/active_ride/presentation/route_change_sheet.dart';
import 'package:movera_rider/features/destination_search/presentation/route_picker_page.dart';
import 'package:movera_rider/features/home/application/home_places_controller.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/ride_booking/domain/route_stop.dart';
import 'package:movera_rider/shared/widgets/early_input_capture.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

/// Which row of the ride details the rider tapped.
enum RouteChangeEntry { pickup, destination, newStop, stop }

/// Opens "Change route" for a live ride: the rider edits the pickup (while
/// the driver is still on the way), the destination or the stops; the new
/// price is shown and confirmed before the driver is told.
///
/// Returns the updated, saved snapshot, or null when nothing changed.
Future<RideSnapshot?> openRouteChange(
  BuildContext context, {
  required RideSnapshot ride,
  required RouteChangeEntry entry,
  required bool pickupLocked,
  RouteChangeController? controller,
}) async {
  final changes =
      controller ??
      RouteChangeController(
        api: AppScope.instance.api,
        geocoding: AppScope.instance.geocoding,
      );
  final places = HomePlacesController();
  await places.load();
  if (!context.mounted) return null;
  final capture = EarlyInputCapture()..start();
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final draft = await Navigator.of(context).push<Map<String, dynamic>>(
      BottomToTopTransition(
        RoutePickerPage(
          pageTitle: 'Change route',
          pickupAddress: ride.pickupAddress,
          destinationAddress: ride.destinationAddress,
          stops: [for (final stop in ride.stops) stop.address],
          stopsSupported: true,
          pickupLocked: pickupLocked,
          openWithNewStop: entry == RouteChangeEntry.newStop,
          initialField: switch (entry) {
            RouteChangeEntry.pickup when !pickupLocked => 'pickup',
            _ => 'destination',
          },
          finishLabel: 'See new price',
          capture: capture,
          here: GeoPoint(ride.pickupLat, ride.pickupLng),
          homeAddress: places.homeAddress,
          workAddress: places.workAddress,
          savedPlaces: places.savedPlaces,
          recent: places.recentAddresses,
          onSetFavourite: (_) async => null,
          onPickOnMap: ({required pickup, required address}) async {
            final start = pickup
                ? LatLng(ride.pickupLat, ride.pickupLng)
                : LatLng(ride.destinationLat, ride.destinationLng);
            final result = await ConfirmPickupSpot.open(
              context,
              initialPosition: start,
              initialAddress: address.isEmpty
                  ? (pickup ? ride.pickupAddress : ride.destinationAddress)
                  : address,
              title: pickup ? 'Confirm pickup spot' : 'Confirm destination',
              confirmLabel: pickup ? 'Confirm pickup' : 'Confirm destination',
            );
            if (result == null) return null;
            return RoutePickerMapPick(
              address: result.address,
              point: GeoPoint(result.position.latitude, result.position.longitude),
            );
          },
          onFinish: (selection) async {
            try {
              final quote = await changes.preview(
                ride: ride,
                pickupAddress: pickupLocked ? null : selection.pickup,
                pickupPoint: pickupLocked ? null : selection.pickupPoint,
                destinationAddress: selection.destination,
                destinationPoint: selection.destinationPoint,
                stops: selection.stops,
              );
              if (!context.mounted) return null;
              final confirmed = await RouteChangeSheet.confirm(
                context,
                quote: quote,
                paymentMethod: ride.paymentMethod,
              );
              if (!confirmed || !context.mounted) return null;
              final updated = await changes.apply(ride: ride, quote: quote);
              return {'ride': updated};
            } on RouteChangeException catch (error) {
              messenger
                ?..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(error.message)));
              return null;
            }
          },
        ),
      ),
    );
    final updated = draft?['ride'];
    return updated is RideSnapshot ? updated : null;
  } finally {
    capture.stop();
  }
}

/// The short confirmation shown after a route change went through.
void showRouteUpdated(
  BuildContext context, {
  required bool driverAssigned,
  String paymentMethod = '',
  double differenceKr = 0,
}) {
  final parts = <String>[
    driverAssigned ? 'Route updated · your driver has been told' : 'Route updated',
  ];
  if (!isCashPayment(paymentMethod) && differenceKr.abs() >= 0.5) {
    final kr = '${differenceKr.abs().round()} kr';
    parts.add(
      differenceKr > 0
          ? '+$kr charged to $paymentMethod'
          : '$kr back to $paymentMethod',
    );
  }
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const ValueKey('route-updated-snack'),
        content: Text(parts.join(' · ')),
        duration: const Duration(seconds: 4),
      ),
    );
}

/// Removes one stop: prices the shorter route, confirms, applies.
Future<RideSnapshot?> removeRouteStop(
  BuildContext context, {
  required RideSnapshot ride,
  required int index,
  RouteChangeController? controller,
}) async {
  if (index < 0 || index >= ride.stops.length) return null;
  final changes =
      controller ??
      RouteChangeController(
        api: AppScope.instance.api,
        geocoding: AppScope.instance.geocoding,
      );
  final kept = [
    for (var i = 0; i < ride.stops.length; i++)
      if (i != index) ride.stops[i],
  ];
  try {
    final quote = await changes.preview(
      ride: ride,
      destinationAddress: ride.destinationAddress,
      stops: [for (final stop in kept) stop.address],
      stopPoints: [for (final stop in kept) GeoPoint(stop.latitude, stop.longitude)],
    );
    if (!context.mounted) return null;
    final confirmed = await RouteChangeSheet.confirm(
      context,
      quote: quote,
      paymentMethod: ride.paymentMethod,
    );
    if (!confirmed || !context.mounted) return null;
    return await changes.apply(ride: ride, quote: quote);
  } on RouteChangeException catch (error) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.message)));
    return null;
  }
}

/// Markers for the stops between pickup and destination.
Set<Marker> routeStopMarkers(List<RouteStop> stops) => {
  for (var i = 0; i < stops.length; i++)
    Marker(
      markerId: MarkerId('stop-$i'),
      position: LatLng(stops[i].latitude, stops[i].longitude),
      infoWindow: InfoWindow(title: 'Stop ${i + 1}', snippet: stops[i].address),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
};

/// Pickup → stops → destination as one straight-line route.
List<LatLng> routeWithStops({
  required LatLng pickup,
  required List<RouteStop> stops,
  required LatLng destination,
}) => [
  pickup,
  for (final stop in stops) LatLng(stop.latitude, stop.longitude),
  destination,
];
