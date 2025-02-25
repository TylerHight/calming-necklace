import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'core/blocs/necklaces/necklaces_bloc.dart';
import 'core/data/models/necklace.dart';
import 'core/data/repositories/ble_repository.dart';
import 'core/data/repositories/necklace_repository.dart';
import 'core/services/ble/ble_service.dart';
import 'core/services/database_service.dart';
import 'core/services/logging_service.dart';
import 'features/necklaces_screen/presentation/necklaces_screen.dart';
import 'features/notes_screen/presentation/notes_screen.dart';
import 'features/notes_screen/bloc/notes_bloc.dart';
import 'features/device_settings_screen/blocs/duration_picker/duration_picker_bloc.dart';
import 'app_bloc_observer.dart';
import 'core/utils/ble/ble_permissions.dart';
import 'core/blocs/ble/ble_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging service first
  final loggingService = await LoggingService.getInstance();
  loggingService.logInfo('Application starting...');
  loggingService.logDebug('Initializing core services...');
  
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BleService>(
          create: (context) => BleService(),
          lazy: false,
        ),
        Provider<DatabaseService>(
          create: (context) => DatabaseService(),
          lazy: true,
        ),
        Provider<NecklaceRepository>(
          create: (context) => NecklaceRepositoryImpl(
            databaseService: context.read<DatabaseService>(),
            bleService: context.read<BleService>(), // Add this line
          ),
        ),
        Provider<BleRepository>(
          create: (context) => BleRepository(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => BleBloc(
            bleService: context.read<BleService>(),
            bleRepository: context.read<BleRepository>(),
            necklaceRepository: context.read<NecklaceRepository>(),
          ),
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
            useMaterial3: true,
            cardTheme: CardTheme(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              iconTheme: IconThemeData(color: Colors.black87),
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              elevation: 8,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blue[600],
              unselectedItemColor: Colors.grey[400],
              selectedIconTheme: IconThemeData(size: 28),
              unselectedIconTheme: IconThemeData(size: 24),
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
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
  bool _blePermissionsGranted = false;

  static const List<Widget> _widgetOptions = <Widget>[
    NecklacesScreen(),
    NotesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestBlePermissions();
  }

  Future<void> _checkAndRequestBlePermissions() async {
    if (!await BlePermissions.checkPermissions()) {
      bool granted = await BlePermissions.requestPermissions();
      setState(() {
        _blePermissionsGranted = granted;
      });
      
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions are required for device connectivity'),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.spa),
                activeIcon: Icon(Icons.spa, size: 28),
                label: 'Necklaces',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.note),
                activeIcon: Icon(Icons.note, size: 28),
                label: 'Notes',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue[600],
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
