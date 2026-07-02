/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'AbsensiGeo';
  static const String appTagline = 'Attendance Made Simple';


  // Supabase Configuration
  static const String supabaseUrl =
      'https://jkgqsvpjbsvnmlebzttg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprZ3FzdnBqYnN2bm1sZWJ6dHRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwMDc3OTUsImV4cCI6MjA5ODU4Mzc5NX0.dJDnq_OZqg70PGH9N5jsJ1FjBsp1mmvF2Hrbc-KR5RQ';
  static const String supabaseBucketName = 'attendance-selfies';

  // Splash duration
  static const Duration splashDuration = Duration(seconds: 2);
}
