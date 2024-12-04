const Map<String, String> genderNames = {
  'F': 'Female',
  'M': 'Male',
  'O': 'Other',
  'X': 'Unknown',
};

String? getLongGenderName(String shortName) {
  return genderNames[shortName];
}
