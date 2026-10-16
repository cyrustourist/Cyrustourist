import '../core/language/menu_translations.dart';

/// متن‌های بخش تماس و دوستان (فارسی و انگلیسی؛ بقیهٔ زبان‌ها انگلیسی نشان داده می‌شوند).
class CT {
  CT._();

  static bool get fa => MenuLanguage.current == 'fa';

  static String t(String key, [Map<String, String>? params]) {
    final table = fa ? _fa : _en;
    var s = table[key] ?? _en[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => s = s.replaceAll('{$k}', v));
    }
    return s;
  }

  /// کلید پیام آمادهٔ رد تماس ← متن.
  static String msg(String key) => t('msg_$key');

  static String ago(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return '${t('today')} $hm';
    if (diff == 1) return '${t('yesterday')} $hm';
    return t('days_ago', {'n': '$diff'});
  }

  static String duration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600 ? '${seconds ~/ 3600}:$m:$s' : '$m:$s';
  }

  static String remaining(int? untilMs) {
    if (untilMs == null) return t('blocked_forever');
    final left = untilMs - DateTime.now().millisecondsSinceEpoch;
    if (left <= 0) return '';
    final mins = (left / 60000).ceil();
    if (mins < 60) return t('blocked_left', {'t': t('n_min', {'n': '$mins'})});
    final hours = (mins / 60).ceil();
    if (hours < 48) return t('blocked_left', {'t': t('n_hour', {'n': '$hours'})});
    return t('blocked_left', {'t': t('n_day', {'n': '${(hours / 24).ceil()}'})});
  }

  static const Map<String, String> _fa = {
    'calls_title': 'تماس‌ها',
    'delete_all': 'پاک کردن همه',
    'delete_all_confirm': 'همهٔ تماس‌های این لیست پاک شود؟',
    'delete_one': 'پاک کردن',
    'deleted_one': 'پاک شد.',
    'deleted_all': 'همه پاک شد.',
    'back_btn': 'بازگشت',
    'block_btn': 'مسدود',
    'voice_call': 'تماس صوتی',
    'video_call': 'تماس تصویری',
    'video_soon': 'تماس تصویری به‌زودی آماده به‌کار می‌شود. سپاسگزاریم.',
    'tab_friends': 'دوستان',
    'tab_recent': 'تازه‌ها',
    'tab_blocked': 'مسدودشده',
    'add_friend': 'افزودن دوست',
    'add_to_friends': 'افزودن به دوستان',
    'in_friends': 'در دوستان',
    'friend_added': '{name} به دوستان اضافه شد.',
    'friend_exists': '{name} از قبل در دوستان شما بود.',
    'remove_friend': 'حذف از دوستان',
    'remove_confirm': '{name} از لیست دوستان حذف شود؟',
    'friend_removed': 'از دوستان حذف شد.',
    'cancel': 'انصراف',
    'delete': 'حذف',
    'temp_block': 'بلاک موقت',
    'block_calls': 'مسدود کردن تماس',
    'unblock': 'رفع بلاک',
    'block_title': 'تماس‌های {name} تا چه مدت مسدود شود؟',
    'block_note': 'فقط تماس مسدود می‌شود؛ هر وقت خواستید از تب «مسدودشده» رفعش کنید.',
    'block_1h': '۱ ساعت',
    'block_24h': '۲۴ ساعت',
    'block_7d': '۷ روز',
    'block_forever': 'تا وقتی خودم بردارم',
    'blocked_done': 'تماس‌های {name} مسدود شد.',
    'unblocked_done': 'بلاک برداشته شد.',
    'blocked_empty': 'کسی مسدود نشده است.',
    'blocked_forever': 'تا رفع بلاک',
    'blocked_left': 'مانده: {t}',
    'n_min': '{n} دقیقه',
    'n_hour': '{n} ساعت',
    'n_day': '{n} روز',
    'friends_empty': 'هنوز دوستی اضافه نکرده‌اید.',
    'friends_empty_hint': 'با دکمهٔ «+»، جی‌میل یا شمارهٔ تأییدشدهٔ دوستتان را اضافه کنید.',
    'recent_empty': 'هنوز تماسی نداشته‌اید.',
    'pick_friend': 'انتخاب دوست برای تماس',
    'search_friend': 'جستجوی دوست',
    'no_match': 'موردی پیدا نشد.',
    'add_title': 'افزودن دوست',
    'add_desc': 'جی‌میل یا شمارهٔ همراهِ تأییدشدهٔ دوستتان در سایروس توریست (یا نام کاربری‌اش) را وارد کنید. دوست مستقیم به لیست شما اضافه می‌شود.',
    'add_field': 'جی‌میل، شماره (09…) یا نام کاربری',
    'add_btn': 'افزودن به دوستان',
    'add_empty': 'جی‌میل، شماره یا نام کاربری را وارد کنید.',
    'add_done': 'تمام',
    'need_profile': 'برای تماس و لیست دوستان، ابتدا شناسه کاربری خود را تکمیل کنید.',
    'go_profile': 'تکمیل شناسه کاربری',
    'retry': 'تلاش دوباره',
    'net_error': 'ارتباط با سرور برقرار نشد.',
    'op_failed': 'انجام نشد.',
    'incoming': 'تماس صوتی ورودی',
    'dir_out': 'خروجی',
    'dir_in': 'ورودی',
    'st_missed': 'از دست رفته',
    'st_declined': 'رد شد',
    'st_canceled': 'لغو شد',
    'msg_later': 'بعداً با شما تماس می‌گیرم',
    'msg_cant_talk': 'الان نمی‌توانم صحبت کنم',
    'peer_msg': '{name}: {msg}',
    'accept': 'پاسخ',
    'decline_btn': 'رد',
    'mic_title': 'دسترسی به میکروفن',
    'mic_body': 'برای تماس صوتی به میکروفن نیاز است. با زدن «اجازه می‌دهم» پنجرهٔ سیستم باز می‌شود؛ لطفاً تأیید کنید تا هنگام تماس معطل نشوید.',
    'mic_allow': 'اجازه می‌دهم',
    'mic_denied': 'بدون دسترسی به میکروفن تماس ممکن نیست. از تنظیمات گوشی (برنامه‌ها ← سایروس توریست ← دسترسی‌ها) میکروفن را فعال کنید.',
    'decline': 'رد',
    'end_call': 'پایان تماس',
    'speaker': 'بلندگو',
    'fsi_title': 'زنگ تماس روی قفل گوشی',
    'fsi_body': 'برای اینکه هنگام تماس ورودی صفحهٔ تماس روی قفل گوشی باز شود و زنگ بخورد، اجازهٔ «اعلان‌های تمام‌صفحه» را برای سایروس توریست روشن کنید.',
    'fsi_open': 'باز کردن تنظیمات',
    'fsi_later': 'بعداً',
    'mute': 'بی‌صدا',
    'video': 'ویدیو',
    'ongoing_title': 'تماس صوتی در جریان',
    'missed_msg_title': 'پیام از {name}',
    'today': 'امروز',
    'yesterday': 'دیروز',
    'days_ago': '{n} روز پیش',
    'call_btn': 'تماس',
    'profile_call': 'تماس صوتی',
    'profile_video': 'تماس تصویری',
  };

  static const Map<String, String> _en = {
    'calls_title': 'Calls',
    'delete_all': 'Clear all',
    'delete_all_confirm': 'Clear all calls from this list?',
    'delete_one': 'Delete',
    'deleted_one': 'Deleted.',
    'deleted_all': 'All cleared.',
    'back_btn': 'Unblock',
    'block_btn': 'Block',
    'voice_call': 'Voice call',
    'video_call': 'Video call',
    'video_soon': 'Video calls will be ready soon. Thank you.',
    'tab_friends': 'Friends',
    'tab_recent': 'New',
    'tab_blocked': 'Blocked',
    'add_friend': 'Add friend',
    'add_to_friends': 'Add to friends',
    'in_friends': 'In friends',
    'friend_added': '{name} was added to your friends.',
    'friend_exists': '{name} is already in your friends.',
    'remove_friend': 'Remove from friends',
    'remove_confirm': 'Remove {name} from your friends?',
    'friend_removed': 'Removed from friends.',
    'cancel': 'Cancel',
    'delete': 'Remove',
    'temp_block': 'Block for now',
    'block_calls': 'Block calls',
    'unblock': 'Unblock',
    'block_title': 'Block calls from {name} for how long?',
    'block_note': 'Only calls are blocked. You can unblock any time from the "Blocked" tab.',
    'block_1h': '1 hour',
    'block_24h': '24 hours',
    'block_7d': '7 days',
    'block_forever': 'Until I unblock',
    'blocked_done': 'Calls from {name} are blocked.',
    'unblocked_done': 'Unblocked.',
    'blocked_empty': 'No one is blocked.',
    'blocked_forever': 'Until unblocked',
    'blocked_left': 'Left: {t}',
    'n_min': '{n} min',
    'n_hour': '{n} h',
    'n_day': '{n} d',
    'friends_empty': 'You have no friends yet.',
    'friends_empty_hint': 'Tap "+" and add a friend by their verified Gmail or phone number.',
    'recent_empty': 'No calls yet.',
    'pick_friend': 'Choose a friend to call',
    'search_friend': 'Search friends',
    'no_match': 'Nothing found.',
    'add_title': 'Add a friend',
    'add_desc': "Enter your friend's verified Gmail or mobile number on Cyrus Tourist (or their username). They are added to your list right away.",
    'add_field': 'Gmail, phone (09…) or username',
    'add_btn': 'Add to friends',
    'add_empty': 'Enter a Gmail, phone number or username.',
    'add_done': 'Done',
    'need_profile': 'Complete your profile first to use calls and the friends list.',
    'go_profile': 'Complete profile',
    'retry': 'Retry',
    'net_error': 'Could not reach the server.',
    'op_failed': 'Failed.',
    'incoming': 'Incoming voice call',
    'dir_out': 'Outgoing',
    'dir_in': 'Incoming',
    'st_missed': 'Missed',
    'st_declined': 'Declined',
    'st_canceled': 'Canceled',
    'msg_later': "I'll call you later",
    'msg_cant_talk': "Can't talk right now",
    'peer_msg': '{name}: {msg}',
    'accept': 'Answer',
    'decline_btn': 'Decline',
    'mic_title': 'Microphone access',
    'mic_body': 'Voice calls need the microphone. Tap "Allow" and confirm the system prompt so you are not kept waiting during a call.',
    'mic_allow': 'Allow',
    'mic_denied': 'Calls cannot work without microphone access. Enable it in phone Settings > Apps > Cyrus Tourist > Permissions.',
    'decline': 'Decline',
    'end_call': 'End call',
    'speaker': 'Speaker',
    'fsi_title': 'Ringing on the lock screen',
    'fsi_body': 'To show the call screen and ring when the phone is locked, allow "Full-screen notifications" for Cyrus Tourist.',
    'fsi_open': 'Open settings',
    'fsi_later': 'Later',
    'mute': 'Mute',
    'video': 'Video',
    'ongoing_title': 'Voice call in progress',
    'missed_msg_title': 'Message from {name}',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'days_ago': '{n} days ago',
    'call_btn': 'Call',
    'profile_call': 'Voice call',
    'profile_video': 'Video call',
  };
}
