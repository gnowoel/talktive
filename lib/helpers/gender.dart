const Map<String, String> genderNames = {
  'F': 'Female',
  'M': 'Male',
  'O': 'Other',
  'X': 'Unknown',
};

// TODO: Remove this
const Map<String, String> genderDescriptions = {
  'F': 'Female',
  'M': 'Male',
  'O': 'Other', // 'Other gender'
  'X': 'Unknown', // 'Gender unknown'
};

String? getLongGenderName(String shortName) {
  return genderNames[shortName];
}

String? getLongGenderDescription(String shortName) {
  return genderDescriptions[shortName];
}
