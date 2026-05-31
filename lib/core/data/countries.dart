class Country {
  final String code; // ISO 3166-1 alpha-2
  final String nameAr;
  final String nameEn;
  final String dialCode; // includes leading +
  final String flag; // emoji
  const Country({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.dialCode,
    required this.flag,
  });
}

/// The only supported country. Phone sign-in/sign-up is Iraq-only, so the
/// dial code is fixed to +964 and there is no country picker in the UI.
const Country defaultCountry = Country(
  code: 'IQ',
  nameAr: 'العراق',
  nameEn: 'Iraq',
  dialCode: '+964',
  flag: '🇮🇶',
);

/// Supported countries. Intentionally Iraq-only — kept as a list so existing
/// imports and APIs stay valid without special-casing.
const List<Country> countries = [defaultCountry];
