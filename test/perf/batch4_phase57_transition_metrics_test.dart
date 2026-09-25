import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/observability/observability.dart';
import 'package:movera_rider/core/performance/route_transition_metrics.dart';

class _RecordingLogger implements LoggerSink {
  final events = <String>[];
  final extras = <Map<String, Object?>>[];

  @override
  void log(
    TelemetryLevel level,
    String event, {
    Map<String, Object?> extra = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(event);
    extras.add(extra);
  }
}

void main() {
  tearDown(Observability.reset);

  test('57C reports each transition latency phase independently', () {
    final logger = _RecordingLogger();
    Observability.configure(loggerSink: logger);

    RouteTransitionMetrics.routePreparation(
      const Duration(milliseconds: 11),
      stopCount: 2,
    );
    RouteTransitionMetrics.homeMapParking(const Duration(milliseconds: 22));
    RouteTransitionMetrics.navigationBarrier(const Duration(milliseconds: 33));
    RouteTransitionMetrics.nextMapReady(const Duration(milliseconds: 44));

    expect(logger.events, [
      'performance.route_preparation',
      'performance.home_map_parking',
      'performance.ride_selection_navigation_barrier',
      'performance.ride_selection_next_map_ready',
    ]);
    expect(logger.extras[0]['durationMs'], 11.0);
    expect(logger.extras[0]['stopCount'], 2);
    expect(logger.extras[1]['durationMs'], 22.0);
    expect(logger.extras[2]['durationMs'], 33.0);
    expect(logger.extras[3]['durationMs'], 44.0);
  });

  test('57C telemetry contains no route addresses or rider location', () {
    final logger = _RecordingLogger();
    Observability.configure(loggerSink: logger);

    RouteTransitionMetrics.routePreparation(
      const Duration(microseconds: 12500),
      stopCount: 1,
    );

    expect(logger.extras.single.keys, {'durationMs', 'stopCount'});
    expect(logger.extras.single['durationMs'], 12.5);
  });
}
