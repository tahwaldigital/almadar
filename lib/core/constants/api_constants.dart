class ApiConstants {
  ApiConstants._();

  // Site + custom plugin namespace (Almadar Mobile API).
  // IMPORTANT: use the canonical www host. The server 301-redirects non-www → www,
  // and that redirect turns POST (register/login) into GET and drops the body,
  // which made account creation & login fail. Hitting www directly avoids it.
  static const String siteUrl = 'https://www.almadr-news.com';

  // The site uses plain permalinks, so the working REST form is ?rest_route=.
  // If you enable pretty permalinks, switch apiBase to '$siteUrl/wp-json/almadar/v1'.
  static const String apiBase = '$siteUrl/?rest_route=/almadar/v1';

  // For DioClient baseUrl (absolute endpoint URLs are used everywhere below).
  static const String baseUrl = siteUrl;

  // ── Content endpoints ──────────────────────────────────────────────
  static const String config = '$apiBase/config';
  static const String settings = '$apiBase/settings';
  static const String posts = '$apiBase/posts';
  static const String categories = '$apiBase/categories';
  static const String breakingNews = '$apiBase/breaking-news';
  static const String trending = '$apiBase/trending';
  static const String mostViewed = '$apiBase/most-viewed';
  static const String search = '$apiBase/search';
  static const String videos = '$apiBase/videos';
  static const String pages = '$apiBase/pages';
  static const String authors = '$apiBase/authors';
  static const String comments = '$apiBase/comments';

  // ── Auth endpoints ─────────────────────────────────────────────────
  static const String authLogin = '$apiBase/auth/login';
  static const String authRegister = '$apiBase/auth/register';
  static const String authRefresh = '$apiBase/auth/refresh';
  static const String authMe = '$apiBase/auth/me';
  static const String authValidate = '$apiBase/auth/validate';
  static const String authSocial = '$apiBase/auth/social';
  static const String authForgotPassword = '$apiBase/auth/forgot-password';
  static const String authDelete = '$apiBase/auth/delete';
  static const String authVerifyEmail = '$apiBase/auth/verify-email';
  static const String authResendCode = '$apiBase/auth/resend-code';

  // ── Devices / notifications ────────────────────────────────────────
  static const String devicesRegister = '$apiBase/devices/register';
  static const String devicesUnregister = '$apiBase/devices/unregister';
  static const String notificationsFeed = '$apiBase/notifications/feed';

  // ── Admin / publishing (تتطلب مستخدمًا بصلاحية نشر) ────────────────
  // ينشئ منشورًا في ووردبريس. عند is_breaking=true يجب أن يقوم الخادم
  // (إضافة المدار/Novamira) بإرسال إشعار الدفع لموضوع breaking. لا يُرسَل
  // الدفع من التطبيق أبدًا (مفتاح FCM السري يبقى على الخادم فقط).
  static const String adminCreatePost = '$apiBase/admin/posts';
  static const String adminUploadMedia = '$apiBase/admin/media';

  // ── FCM topics (must match the WordPress plugin settings) ──────────
  static const String topicAll = 'news_all';
  static const String topicBreaking = 'breaking';
  static const String topicCategoryPrefix = 'cat_';

  // ── Query defaults ─────────────────────────────────────────────────
  static const int defaultPerPage = 10;

  // ── Local storage keys ─────────────────────────────────────────────
  static const String tokenKey = 'jwt_token';
  static const String refreshKey = 'jwt_refresh';
  static const String userKey = 'user_data';
  static const String savedPostsBox = 'saved_posts';
  static const String cachedPostsBox = 'cached_posts';
  static const String categoriesBox = 'categories';
  static const String searchHistoryKey = 'search_history';
  static const String themeKey = 'dark_mode';

  // ── Timeouts ───────────────────────────────────────────────────────
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
