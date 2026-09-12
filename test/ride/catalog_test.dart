import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/support/application/support_controller.dart';

void main() {
  test('ride catalog has seven Movera types', () {
    expect(RideSelectionController().rides().length, 7);
    expect(RideSelectionController().payments().length, 7);
  });

  test('support rides catalog is six trips', () {
    expect(SupportController().rides().length, 6);
  });
}
