const Map<String, String> genderNames = {
  'F': 'Female',
  'M': 'Male',
  'O': 'Other',
  'X': 'Unknown',
};

const Map<String, String> genderDescriptions = {
  'F': 'Female',
  'M': 'Male',
  'O': 'Other gender',
  'X': 'Gender unknown',
};

String? getLongGenderName(String shortName) {
  return genderNames[shortName];
}

String? getLongGenderDescription(String shortName) {
  return genderDescriptions[shortName];
}
