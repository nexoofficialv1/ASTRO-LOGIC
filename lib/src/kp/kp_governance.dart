/// Source and safety policy for governed KP calculation.
class KpGovernance {
  const KpGovernance._();

  static const profileVersion = 'kp-governance-v5';
  static const exactChartCastingEnabled = true;

  /// Versioned reconstruction of the classic Krishnamurti Reader-1 table:
  /// J1900 ayanamsha 22°21'50.0004" with Newcomb/Kinoshita precession.
  ///
  /// Historical KP literature does not uniquely determine one modern
  /// ayanamsha implementation, so this identifier must remain visible.
  static const ayanamshaProfile =
      'kp-krishnamurti-classic-j1900-newcomb-v1';

  /// Native Placidus time-division cusps. No Porphyry fallback is allowed.
  static const houseProfile = 'kp-placidus-time-division-native-v1';

  static const validatedStartYear = 1840;
  static const validatedEndYear = 2100;

  static const englishDisclosure =
      'KP Native Chart v4 with Horary RP confirmation uses a versioned classic Krishnamurti Reader-1 reconstruction (J1900 + Newcomb/Kinoshita precession) and a native Placidus time-division cusp solver. Historical KP ayanamsha definitions are not perfectly unique, so the selected profile is always disclosed. Placidus polar failure is rejected rather than silently replaced by another house system. Star/Sub, house-significator and ruling-planet evidence remains practitioner-review material. Marriage and children cusp-sub-lord review is source-bounded and may return Promise, Denial or Insufficient Evidence, but never a real-world guarantee or automatic timing claim. Transit/Ruling-Planet confirmation is a separate evidence layer and confidence is capped at Moderate. Horary Ruling-Planet corroboration uses only the query-moment standard RP subset, never natal DBA or birth data, and does not calculate an exact future event date.';

  static const bengaliDisclosure =
      'KP Native Chart v4 ও Horary RP confirmation-এ versioned classic Krishnamurti Reader-1 reconstruction (J1900 + Newcomb/Kinoshita precession) এবং native Placidus time-division cusp solver ব্যবহার করা হয়েছে। ঐতিহাসিক KP ayanamsha definition একেবারে একক নয়, তাই নির্বাচিত profile সবসময় দেখানো হবে। Polar geometry-তে Placidus ব্যর্থ হলে অন্য house system নীরবে বসানো হবে না; calculation reject হবে। Star/Sub, house-significator ও ruling-planet evidence practitioner review-এর জন্য। Marriage ও Children cusp-sub-lord review source-bounded Promise/Denial/Insufficient Evidence দেখাতে পারে, কিন্তু বাস্তব-world guarantee বা automatic timing claim নয়। Transit/Ruling-Planet confirmation আলাদা evidence layer এবং confidence সর্বোচ্চ Moderate-এ capped। Horary Ruling-Planet corroboration শুধু query-moment standard RP subset ব্যবহার করে; natal DBA বা জন্মতথ্য ব্যবহার করে না এবং exact future event date গণনা করে না।';
}
