import 'package:flutter/material.dart';

/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'ភពមួយពីរនាក់';

  /// Relationship start date — edit to your real anniversary date.
  static final DateTime relationshipStartDate = DateTime(2026, 3, 20, 0, 0, 0);

  /// The only two people allowed to use this app.
  /// We use each person's EMAIL as their stable identity key throughout the
  /// app (Firestore document IDs, message senderId, note authorId, etc).
  /// This is intentional: Firebase Auth UIDs are auto-generated per project
  /// and cannot be forced to a fixed value from the client SDK, so email is
  /// used as the reliable, human-readable, constant identifier instead.
  static const Map<String, AuthorizedUser> authorizedUsersByEmail = {
    'thorngdy@gmail.com': AuthorizedUser(
      uid: 'thorngdy@gmail.com',
      name: 'Thorng Dy',
      email: 'thorngdy@gmail.com',
      phone: '067267968',
    ),
    'seavenh@gmail.com': AuthorizedUser(
      uid: 'seavenh@gmail.com',
      name: 'Seav Enh',
      email: 'seavenh@gmail.com',
      phone: '086514169',
    ),
  };

  /// Lookup table so a phone number can be resolved to its email address.
  static const Map<String, String> phoneToEmail = {
    '067267968': 'thorngdy@gmail.com',
    '086514169': 'seavenh@gmail.com',
  };

  static const String chatRoomId = 'couple_chat_room';
}

class AuthorizedUser {
  final String uid;
  final String name;
  final String email;
  final String phone;

  const AuthorizedUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
  });
}

/// Centralized Khmer copy used throughout the app.
class KhmerText {
  KhmerText._();

  // General
  static const String appName = 'ភពមួយពីរនាក់';
  static const String loading = 'កំពុងផ្ទុក...';
  static const String save = 'រក្សាទុក';
  static const String cancel = 'បោះបង់';
  static const String edit = 'កែសម្រួល';
  static const String delete = 'លុប';
  static const String confirm = 'បញ្ជាក់';
  static const String error = 'មានបញ្ហា';
  static const String success = 'ជោគជ័យ';
  static const String close = 'បិទ';
  static const String areYouSure = 'តើអ្នកប្រាកដទេ?';

  // Auth
  static const String loginTitle = 'សូមស្វាគមន៍';
  static const String loginSubtitle = 'សៀវអិញ 💕 ថងឌី';
  static const String emailOrPhone = 'អ៊ីមែល ឬលេខទូរស័ព្ទ';
  static const String password = 'ពាក្យសម្ងាត់';
  static const String loginButton = 'ចូលប្រើប្រាស់';
  static const String fieldRequired = 'សូមបំពេញព័ត៌មាននេះ';
  static const String unauthorizedUser = 'អ្នកមិនមានសិទ្ធិចូលប្រើកម្មវិធីនេះទេ';
  static const String wrongCredentials = 'អ៊ីមែល/លេខទូរស័ព្ទ ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ';
  static const String loginError = 'មិនអាចចូលគណនីបានទេ សូមព្យាយាមម្តងទៀត';

  // Bottom nav
  static const String navHome = 'ទំព័រដើម';
  static const String navMap = 'ផែនទី';
  static const String navTime = 'រយៈពេល';
  static const String navMessages = 'សារ';
  static const String navProfile = 'គណនី';

  // Drawer
  static const String drawerHome = 'ទំព័រដើម';
  static const String drawerNotes = 'កំណត់ចំណាំ';
  static const String drawerMemories = 'អនុស្សាវរីយ៍';
  static const String drawerGallery = 'វិចិត្រសាល';
  static const String drawerSettings = 'ការកំណត់';
  static const String drawerAbout = 'អំពីកម្មវិធី';
  static const String drawerLogout = 'ចាកចេញ';

  // Home
  static const String homeGreeting = 'សួស្តី';
  static const String homeTogetherSince = 'ចាប់ផ្ដើមជាមួយគ្នាតាំងពី';
  static const String homeDaysTogether = 'ថ្ងៃស្រឡាញ់គ្នា';
  static const String homeNextAnniversary = 'ថ្ងៃខួបបន្ទាប់';
  static const String homeQuickAccess = 'ចូលប្រើរហ័ស';
  static const String homeOurStory = 'រឿងរ៉ាវរបស់យើង';

  // Map
  static const String mapTitle = 'ទីតាំងបច្ចុប្បន្ន';
  static const String mapDistance = 'ចម្ងាយ';
  static const String mapDirections = 'ទិសដៅ';
  static const String mapMyLocation = 'ទីតាំងខ្ញុំ';
  static const String mapPartnerLocation = 'ទីតាំងគូស្នេហ៍';
  static const String mapLocationOff = 'សូមបើកទីតាំង ជាមុនសិន';
  static const String mapPermissionDenied = 'សូមអនុញ្ញាតការចូលប្រើទីតាំង';

  // Time together
  static const String timeTitle = 'រយៈពេលនៅជាមួយគ្នា';
  static const String timeYears = 'ឆ្នាំ';
  static const String timeMonths = 'ខែ';
  static const String timeDays = 'ថ្ងៃ';
  static const String timeHours = 'ម៉ោង';
  static const String timeMinutes = 'នាទី';
  static const String timeSeconds = 'វិនាទី';
  static const String timeCountdown = 'រាប់ថយក្រោយថ្ងៃខួប';
  static const String timeSince = 'ចាប់ផ្តើមតាំងពីៈ';

  // Messages
  static const String messagesTitle = 'សារ';
  static const String messageHint = 'សរសេរសារ...';
  static const String messageSendImageFail = 'មិនអាចផ្ញើរូបភាពបានទេ';
  static const String messageEmpty = 'មិនទាន់មានសារនៅឡើយទេ សូមផ្ញើសារដំបូង 💌';
  static const String newMessages = 'សារថ្មី';

  // Profile
  static const String profileTitle = 'គណនី';
  static const String profileBio = 'ជីវប្រវត្តិសង្ខេប';
  static const String profileBioHint = 'សរសេរអំពីខ្លួនអ្នក...';
  static const String profileEditPhoto = 'ប្តូររូបភាព';
  static const String profileSaved = 'បានរក្សាទុកព័ត៌មានរួចរាល់';
  static const String profileName = 'ឈ្មោះ';
  static const String profilePhone = 'លេខទូរស័ព្ទ';
  static const String profileEmail = 'អ៊ីមែល';

  // Notes
  static const String notesTitle = 'កំណត់ចំណាំរួម';
  static const String notesAdd = 'បន្ថែមកំណត់ចំណាំ';
  static const String notesEmpty = 'មិនទាន់មានកំណត់ចំណាំទេ';
  static const String notesHintTitle = 'ចំណងជើង';
  static const String notesHintContent = 'ខ្លឹមសារ';
  static const String notesDeleted = 'បានលុបកំណត់ចំណាំ';

  // Memories
  static const String memoriesTitle = 'អនុស្សាវរីយ៍ដ៏ស្រស់ស្អាត';
  static const String memoriesEmpty = 'មិនទាន់មានអនុស្សាវរីយ៍ទេ';
  static const String memoriesAdd = 'បន្ថែមអនុស្សាវរីយ៍';

  // Gallery
  static const String galleryTitle = 'វិចិត្រសាលរូបភាព';
  static const String galleryEmpty = 'មិនទាន់មានរូបភាពទេ';
  static const String galleryAdd = 'បន្ថែមរូបភាព';

  // Settings
  static const String settingsTitle = 'ការកំណត់';
  static const String settingsNotifications = 'ការជូនដំណឹង';
  static const String settingsDarkMode = 'ម៉ូតងងឹត';
  static const String settingsLanguage = 'ភាសា';
  static const String settingsAccount = 'គណនី';
  static const String settingsChangePassword = 'ប្តូរពាក្យសម្ងាត់';

  // About
  static const String aboutTitle = 'អំពីកម្មវិធី';
  static const String aboutDescription =
      'ភពមួយពីរនាក់ គឺជាកន្លែងឯកជនសម្រាប់យើងទាំងពីរនាក់ដើម្បីរក្សាទុករាល់អនុស្សាវរីយ៍ សារ និងគ្រប់ពេលវេលាដ៏មានតម្លៃរបស់យើងណាអូនណា៎';
  static const String aboutVersion = 'កំណែ';

  // Logout confirm
  static const String logoutConfirm = 'តើអ្នកពិតជាចង់ចាកចេញមែនទេ?';
}

/// App color palette — soft romantic pink theme.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE8547C);
  static const Color primaryDark = Color(0xFFC73866);
  static const Color primaryLight = Color(0xFFFFC1D9);
  static const Color secondary = Color(0xFFFFA6C1);
  static const Color background = Color(0xFFFFF5F8);
  static const Color surface = Color(0xFFFFFFFF);

  static bool _darkMode = false;
  static void setDarkMode(bool v) => _darkMode = v;

  static Color get textDark => _darkMode ? Colors.white : const Color(0xFF3A2A32);
  static Color get textLight => _darkMode ? Colors.white70 : const Color(0xFF8A6B76);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color gold = Color(0xFFFFD700);

  static const List<Color> heroGradient = [
    Color(0xFFFF8FAB),
    Color(0xFFE8547C),
  ];

  static const List<Color> softGradient = [
    Color(0xFFFFF0F5),
    Color(0xFFFFE0EC),
  ];
}
