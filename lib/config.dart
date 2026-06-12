// إعدادات SMTP و Pepper
const String SMTP_HOST = 'smtp.gmail.com';
const int SMTP_PORT = 587;
const String SMTP_USERNAME = ''; // أضف اسم المستخدم هنا
const String SMTP_PASSWORD = ''; // استخدم App Password لو جيميل
const String FROM_EMAIL = ''; // نفس البريد المستخدم للإرسال
const String FROM_NAME = 'UpHeal Security'; // الاسم الذي يظهر للمستلم

// Pepper ثابت لتشفير الباسورد
const String PASSWORD_PEPPER = 'D9f#7kLp2@wVx8qZrT1mY!uB4sE0jHcN';

// Supabase Configuration
const String SUPABASE_URL = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://gcxxmjptbyvlabqzcprv.supabase.co',
);

const String SUPABASE_ANON_KEY = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

// API Configuration
const String API_BASE_URL = String.fromEnvironment(
        'UPHEAL_API_URL',
        defaultValue: 'https://upheal-rag.onrender.com'
);

// Google OAuth Web Client ID (used as serverClientId for google_sign_in)
// Generate from Google Cloud Console → Credentials → Web Client ID.
// Never store the Client Secret in Flutter code.
const String googleWebClientId =
    '44271976212-nj77h4ulis531dtmdibka4orgetpauu7.apps.googleusercontent.com';

