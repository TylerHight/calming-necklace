import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/models/necklace.dart';
import '../../../core/data/repositories/necklace_repository.dart';
import '../../add_device_dialog/blocs/add_device_dialog/add_device_dialog_bloc.dart';
import '../widgets/necklace_panel/necklace_panel.dart';
import '../../../core/blocs/necklaces/necklaces_bloc.dart';
import '../../add_device_dialog/presentation/add_device_dialog.dart';

class NecklacesScreen extends StatefulWidget {
  const NecklacesScreen({super.key});

  @override
  _NecklacesScreenState createState() => _NecklacesScreenState();
}

class _NecklacesScreenState extends State<NecklacesScreen> {
  late NecklaceRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<NecklaceRepository>();
    context.read<NecklacesBloc>().add(FetchNecklacesEvent());
  }

  Future<void> _showAddNecklaceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => AddDeviceDialogBloc(
          _repository,
          context.read<NecklacesBloc>(),
        ),
        child: AddDeviceDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Necklaces',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Material(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showAddNecklaceDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Add Necklace',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<NecklacesBloc, NecklacesState>(
        builder: (context, state) {
          if (state is NecklacesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NecklacesLoaded) {
            return state.necklaces.isEmpty 
              ? _buildEmptyState() 
              : _buildNecklaceList(state.necklaces);
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
            'Tap the "Add Necklace" button above to add your first necklace.',
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
            isConnected: true,
            necklace: necklace,
          ),
        );
      },
    );
  }
}
