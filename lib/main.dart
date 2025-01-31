import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/blocs/necklaces/necklaces_bloc.dart';
import 'core/data/repositories/necklace_repository.dart';
import 'core/services/database_service.dart';
import 'features/necklaces_screen/presentation/necklaces_screen.dart';
import 'features/notes/presentation/notes_screen.dart';
import 'features/notes/bloc/notes_bloc.dart';
import 'features/device_settings_screen/blocs/duration_picker/duration_picker_bloc.dart';
import 'app_bloc_observer.dart';

void main() {
  Bloc.observer = AppBlocObserver();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NecklaceRepository>(
          create: (context) => NecklaceRepositoryImpl(),
          lazy: true,
        ),
        Provider<DatabaseService>(
          create: (context) => DatabaseService(),
          lazy: true,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => NecklacesBloc(
              context.read<NecklaceRepository>(),
              context.read<DatabaseService>(),
            ),
          ),
          BlocProvider(
            create: (context) => NotesBloc(
              context.read<DatabaseService>(),
            ),
          ),
          BlocProvider(
            create: (context) => DurationPickerBloc(),
          ),
        ],
        child: MaterialApp(
          title: 'Calming Necklace',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: Colors.blue[600],
              unselectedItemColor: Colors.grey,
            ),
            useMaterial3: true,
            cardTheme: CardTheme(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            scaffoldBackgroundColor: Colors.grey[50],
            appBarTheme: AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
          ),
          home: const MainScreen(), // Use MainScreen as the home
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    NecklacesScreen(),
    NotesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.spa),
            label: 'Necklaces',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Notes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}