import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import '../generated/protocol.dart';
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import '../services/resident_service.dart';
import '../utils/endpoint_auth_mixin.dart';

class ResidentEndpoint extends Endpoint with EndpointAuthMixin {
  /// Checks if the authenticated user has a Resident profile and 
  /// performs standard background tasks (daily login bonus, etc.).
  Future<Resident?> getResident(Session session) async {
    final auth = session.authenticated;
    if (auth == null || auth.userIdentifier == null) {
      return null;
    }

    final senderUuid = UuidValue.fromString(auth.userIdentifier!);
    return await ResidentService.getActiveResident(session, senderUuid);
  }

  /// Fetches a Resident profile by their user ID.
  Future<Resident?> getResidentById(Session session, String userId) async {
    InputValidationService.validateUuid(userId).throwIfInvalid();
    final userUuid = UuidValue.fromString(userId);
    return await ResidentService.getResident(session, userUuid);
  }

  /// Initializes a Resident profile for an authenticated user.
  /// This overwrites any existing UserProfile data (e.g. from Google) with
  /// the chosen anonymous persona.
  Future<Resident> initializeResident(
    Session session, {
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    List<String>? interests,
    List<String>? languages,
    String mood = '😊',
  }) async {
    // Input validation
    InputValidationService.validateName(name).throwIfInvalid();
    InputValidationService.validateGender(gender).throwIfInvalid();
    InputValidationService.validateBio(bio).throwIfInvalid();
    InputValidationService.validateStringList(interests, 'Interests').throwIfInvalid();
    InputValidationService.validateStringList(languages, 'Languages').throwIfInvalid();

    final senderUuid = await getUserId(session);

    // 1. Check if resident already exists
    var resident = await ResidentService.getResident(session, senderUuid);
    if (resident != null) {
      return resident; // Already initialized
    }

    // 2. Fetch/Update User Profile (Force Anonymous Identity)
    try {
      final userProfile = await AuthServices.instance.userProfiles
          .findUserProfileByUserId(session, senderUuid);

      // Overwrite Google name with Anonymous name
      await ResidentService.syncAuthProfile(session, senderUuid, name);
    } catch (e) {
      // User profile might not exist (though getting here means we are authenticated)
      // If so, we create one.
      await AuthServices.instance.userProfiles.createUserProfile(
        session,
        senderUuid,
        UserProfileData(
          userName: name,
          fullName: name,
          email: 'anon-$senderUuid@anonymous.talktive.com',
        ),
      );
    }

    // 3. Create Resident with new gamification fields
    resident = Resident(
      userInfoId: senderUuid,
      xp: 0,
      level: 1, // Start at Floor 1
      currentStreak: 0,
      longestStreak: 0,
      trustScore: ApartmentService.TRUST_SCORE_START,
      suspended: false,
      experienceMessageCount: 0,
      userName: name,
      gender: gender,
      country: country,
      bio: bio,
      mood: mood,
      avatar: avatar,
      interests: interests ?? [],
      languages: languages ?? ['en'],
      role: 'resident',
    );

    await Resident.db.insertRow(session, resident);
    return resident;
  }

  /// Updates an existing Resident's profile details.
  Future<Resident> updateResident(
    Session session, {
    required String name,
    required String avatar,
    required String gender,
    required String country,
    required String bio,
    List<String>? interests,
    List<String>? languages,
    String? mood,
  }) async {
    // Input validation
    InputValidationService.validateName(name).throwIfInvalid();
    InputValidationService.validateGender(gender).throwIfInvalid();
    InputValidationService.validateBio(bio).throwIfInvalid();
    InputValidationService.validateStringList(interests, 'Interests').throwIfInvalid();
    InputValidationService.validateStringList(languages, 'Languages').throwIfInvalid();

    final resident = await getAuthenticatedResident(session);
    final senderUuid = resident.userInfoId;

    // Update User Profile name if changed
    await ResidentService.syncAuthProfile(session, senderUuid, name);

    // Update Resident fields
    resident.userName = name;
    resident.avatar = avatar;
    resident.gender = gender;
    resident.country = country;
    resident.bio = bio;
    resident.mood = mood ?? resident.mood;
    resident.interests = interests ?? resident.interests;
    resident.languages = languages ?? resident.languages;

    return await Resident.db.updateRow(session, resident);
  }
}
