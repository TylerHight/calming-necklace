import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/ble/ble_bloc.dart';
import '../../../core/blocs/ble/ble_state.dart';
import '../../../core/data/models/necklace.dart';
import '../../../core/data/repositories/ble_repository.dart';
import '../../../core/data/repositories/necklace_repository.dart';
import '../../../core/services/ble/ble_service.dart';
import '../../../core/services/database_service.dart';
import '../../add_device_dialog/blocs/add_device_dialog/add_device_dialog_bloc.dart';
import '../../add_device_dialog/blocs/device_selector/device_selector_bloc.dart';
import '../widgets/necklace_panel/necklace_panel.dart';
import '../../../core/blocs/necklaces/necklaces_bloc.dart';
import '../../add_device_dialog/presentation/add_device_dialog.dart';
import '../widgets/help_dialog.dart';
import '../../../core/ui/ui_constants.dart';

class NecklacesScreen extends StatefulWidget {
  const NecklacesScreen({super.key});

  @override
  _NecklacesScreenState createState() => _NecklacesScreenState();
}

class _NecklacesScreenState extends State<NecklacesScreen> {
  late NecklaceRepository _repository;
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _repository = context.read<NecklaceRepository>();
    _databaseService = context.read<DatabaseService>();
    context.read<NecklacesBloc>().add(FetchNecklacesEvent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh necklaces when returning to screen
    if (mounted) {
      context.read<NecklacesBloc>().add(FetchNecklacesEvent());
    }
  }

  Future<void> _showAddNecklaceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider<BleBloc>(
            create: (context) => BleBloc(
              bleService: context.read<BleService>(),
              bleRepository: context.read<BleRepository>(),
              necklaceRepository: context.read<NecklaceRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => AddDeviceDialogBloc(
              _repository,
              context.read<NecklacesBloc>(),
              context.read<BleBloc>(),
            ),
          ),
          BlocProvider(
            create: (context) => DeviceSelectorBloc(
              bleRepository: context.read<BleRepository>(),
              bleBloc: context.read<BleBloc>(),
            ),
          ),
        ],
        child: AddDeviceDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNecklaceDialog,
        shape: const CircleBorder(),
        backgroundColor: UIConstants.floatingActionButtonColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: UIConstants.appBarGradientColors,
            ),
          ),
        ),
        title: const Text(
          'My Necklaces',
          style: TextStyle(
            color: UIConstants.appBarTitleColor,
            fontWeight: FontWeight.w500,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How to use necklaces',
            color: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const NecklacesHelpDialog(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NecklacesBloc, NecklacesState>(
        builder: (context, state) {
          if (state is NecklacesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NecklacesLoaded) {
            if (state.necklaces.isEmpty) {
              return _buildEmptyState();
            }
            return _buildNecklaceList(state.necklaces);
          } else if (state is NecklacesError) {
            return Center(child: Text(state.message));
          }
          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.spa,
              size: 48,
              color: Colors.blue[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No necklaces added yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the plus button at the bottom-right to add your first necklace.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNecklaceList(List<Necklace> necklaces) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: necklaces.length,
      itemBuilder: (context, index) {
        final repository = context.read<NecklaceRepository>();
        final necklace = necklaces[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: NecklacePanel(
            index: index,
            repository: repository,
            name: necklace.name,
            necklace: necklace,
            databaseService: _databaseService, // Pass DatabaseService
          ),
        );
      },
    );
  }
}
