enum PostVisibility {
  public,
  private;

  static PostVisibility fromStorageValue(String? value) {
    switch (value) {
      case 'private':
      case 'connections':
        return PostVisibility.private;
      default:
        return PostVisibility.public;
    }
  }

  String get storageValue => switch (this) {
        PostVisibility.public => 'public',
        PostVisibility.private => 'connections',
      };

  String get arabicLabel => switch (this) {
        PostVisibility.public => 'أي شخص',
        PostVisibility.private => 'الاتصالات فقط',
      };

  String get arabicDescription => switch (this) {
        PostVisibility.public => 'يمكن لأي شخص رؤية المنشور والتفاعل معه',
        PostVisibility.private =>
          'يظهر المنشور لاتصالاتك فقط، ولا يراه غيرهم',
      };
}
