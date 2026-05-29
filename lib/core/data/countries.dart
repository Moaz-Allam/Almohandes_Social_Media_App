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

/// Default country shown when the picker first opens.
const Country defaultCountry = Country(
  code: 'IQ',
  nameAr: 'العراق',
  nameEn: 'Iraq',
  dialCode: '+964',
  flag: '🇮🇶',
);

const List<Country> countries = [
  Country(code: 'IQ', nameAr: 'العراق', nameEn: 'Iraq', dialCode: '+964', flag: '🇮🇶'),
  Country(code: 'SA', nameAr: 'السعودية', nameEn: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  Country(code: 'AE', nameAr: 'الإمارات', nameEn: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪'),
  Country(code: 'KW', nameAr: 'الكويت', nameEn: 'Kuwait', dialCode: '+965', flag: '🇰🇼'),
  Country(code: 'QA', nameAr: 'قطر', nameEn: 'Qatar', dialCode: '+974', flag: '🇶🇦'),
  Country(code: 'BH', nameAr: 'البحرين', nameEn: 'Bahrain', dialCode: '+973', flag: '🇧🇭'),
  Country(code: 'OM', nameAr: 'عُمان', nameEn: 'Oman', dialCode: '+968', flag: '🇴🇲'),
  Country(code: 'YE', nameAr: 'اليمن', nameEn: 'Yemen', dialCode: '+967', flag: '🇾🇪'),
  Country(code: 'JO', nameAr: 'الأردن', nameEn: 'Jordan', dialCode: '+962', flag: '🇯🇴'),
  Country(code: 'LB', nameAr: 'لبنان', nameEn: 'Lebanon', dialCode: '+961', flag: '🇱🇧'),
  Country(code: 'SY', nameAr: 'سوريا', nameEn: 'Syria', dialCode: '+963', flag: '🇸🇾'),
  Country(code: 'PS', nameAr: 'فلسطين', nameEn: 'Palestine', dialCode: '+970', flag: '🇵🇸'),
  Country(code: 'EG', nameAr: 'مصر', nameEn: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  Country(code: 'LY', nameAr: 'ليبيا', nameEn: 'Libya', dialCode: '+218', flag: '🇱🇾'),
  Country(code: 'TN', nameAr: 'تونس', nameEn: 'Tunisia', dialCode: '+216', flag: '🇹🇳'),
  Country(code: 'DZ', nameAr: 'الجزائر', nameEn: 'Algeria', dialCode: '+213', flag: '🇩🇿'),
  Country(code: 'MA', nameAr: 'المغرب', nameEn: 'Morocco', dialCode: '+212', flag: '🇲🇦'),
  Country(code: 'SD', nameAr: 'السودان', nameEn: 'Sudan', dialCode: '+249', flag: '🇸🇩'),
  Country(code: 'SO', nameAr: 'الصومال', nameEn: 'Somalia', dialCode: '+252', flag: '🇸🇴'),
  Country(code: 'DJ', nameAr: 'جيبوتي', nameEn: 'Djibouti', dialCode: '+253', flag: '🇩🇯'),
  Country(code: 'KM', nameAr: 'جزر القمر', nameEn: 'Comoros', dialCode: '+269', flag: '🇰🇲'),
  Country(code: 'MR', nameAr: 'موريتانيا', nameEn: 'Mauritania', dialCode: '+222', flag: '🇲🇷'),
  Country(code: 'TR', nameAr: 'تركيا', nameEn: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  Country(code: 'IR', nameAr: 'إيران', nameEn: 'Iran', dialCode: '+98', flag: '🇮🇷'),
  Country(code: 'AF', nameAr: 'أفغانستان', nameEn: 'Afghanistan', dialCode: '+93', flag: '🇦🇫'),
  Country(code: 'PK', nameAr: 'باكستان', nameEn: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  Country(code: 'IN', nameAr: 'الهند', nameEn: 'India', dialCode: '+91', flag: '🇮🇳'),
  Country(code: 'BD', nameAr: 'بنغلاديش', nameEn: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
  Country(code: 'GB', nameAr: 'المملكة المتحدة', nameEn: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  Country(code: 'FR', nameAr: 'فرنسا', nameEn: 'France', dialCode: '+33', flag: '🇫🇷'),
  Country(code: 'DE', nameAr: 'ألمانيا', nameEn: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  Country(code: 'IT', nameAr: 'إيطاليا', nameEn: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  Country(code: 'ES', nameAr: 'إسبانيا', nameEn: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  Country(code: 'US', nameAr: 'الولايات المتحدة', nameEn: 'United States', dialCode: '+1', flag: '🇺🇸'),
  Country(code: 'CA', nameAr: 'كندا', nameEn: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  Country(code: 'RU', nameAr: 'روسيا', nameEn: 'Russia', dialCode: '+7', flag: '🇷🇺'),
];
