abstract final class A11y {
  /// WCAG 2.5.5 / Android accessibility minimum tap target.
  static const minTap = 48.0;

  /// UI-4: the floor for every tap target (iOS HIG). Use [minTap] where the
  /// layout allows; a control that cannot grow that far must still reach this.
  static const minTapIOS = 44.0;
}
