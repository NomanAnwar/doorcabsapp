class SettingItemModel {
  final String id;
  final String title;
  final String iconPath;
  final SettingCategory category;
  final Function()? onTap;

  SettingItemModel({
    required this.id,
    required this.title,
    required this.iconPath,
    required this.category,
    this.onTap,
  });
}

enum SettingCategory {
  account,
  support,
}

class UserSettings {
  String language;
  String phoneNumber;
  bool notificationsEnabled;

  UserSettings({
    this.language = 'English',
    this.phoneNumber = '',
    this.notificationsEnabled = true,
  });

  UserSettings copyWith({
    String? language,
    String? phoneNumber,
    bool? notificationsEnabled,
  }) {
    return UserSettings(
      language: language ?? this.language,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}