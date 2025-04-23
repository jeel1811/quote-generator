import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/quotes_service.dart';
import 'providers/quotes_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/quotes/daily_quote_screen.dart';
import 'screens/quotes/add_quote_screen.dart';
import 'screens/quotes/quote_categories_screen.dart';
import 'screens/quotes/favorite_quotes_screen.dart';
import 'screens/quotes/favorites_screen.dart';
import 'screens/quotes/explore_quotes_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create services
    final apiService = ApiService();
    final quotesService = QuotesService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create:
              (_) => QuotesProvider(
                apiService: apiService,
                quotesService: quotesService,
              ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDarkMode = themeProvider.isDarkMode;

          // Define colors based on theme
          final primaryColor = CupertinoColors.systemBlue;
          final backgroundColor =
              isDarkMode
                  ? CupertinoColors.black
                  : CupertinoColors.systemBackground;
          final textColor =
              isDarkMode ? CupertinoColors.white : CupertinoColors.black;

          return CupertinoApp(
            title: 'Quote App',
            theme: CupertinoThemeData(
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
              primaryColor: primaryColor,
              scaffoldBackgroundColor: backgroundColor,
              barBackgroundColor:
                  isDarkMode
                      ? CupertinoColors.systemGrey6.darkColor
                      : CupertinoColors.systemBackground,
              textTheme: CupertinoTextThemeData(
                textStyle: TextStyle(
                  color: textColor,
                  fontFamily: 'SF Pro Display',
                ),
                navTitleTextStyle: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                ),
                navLargeTitleTextStyle: TextStyle(
                  color: textColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                ),
                actionTextStyle: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                ),
                tabLabelTextStyle: TextStyle(
                  fontSize: 11,
                  fontFamily: 'SF Pro Display',
                ),
                pickerTextStyle: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isAuthenticated) {
                  return const HomeScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/reset-password': (context) => const ResetPasswordScreen(),
              '/home': (context) => const HomeScreen(),
              '/daily-quote': (context) => const DailyQuoteScreen(),
              '/favorites': (context) => const FavoritesScreen(),
              '/favorite-quotes': (context) => const FavoriteQuotesScreen(),
              '/categories': (context) => const QuoteCategoriesScreen(),
              '/add-quote': (context) => const AddQuoteScreen(),
              '/explore': (context) => const ExploreQuotesScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
          );
        },
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
  }
}
