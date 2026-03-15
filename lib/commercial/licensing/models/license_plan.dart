enum LicensePlan { trial, lifetime, subscription, starter, unknown }

LicensePlan licensePlanFromWire(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'trial':
      return LicensePlan.trial;
    case 'lifetime':
      return LicensePlan.lifetime;
    case 'subscription':
      return LicensePlan.subscription;
    case 'starter':
      return LicensePlan.starter;
    default:
      return LicensePlan.unknown;
  }
}

extension LicensePlanWire on LicensePlan {
  String get wireValue {
    switch (this) {
      case LicensePlan.trial:
        return 'trial';
      case LicensePlan.lifetime:
        return 'lifetime';
      case LicensePlan.subscription:
        return 'subscription';
      case LicensePlan.starter:
        return 'starter';
      case LicensePlan.unknown:
        return 'unknown';
    }
  }

  bool get isPaid =>
      this == LicensePlan.lifetime || this == LicensePlan.subscription;
}
