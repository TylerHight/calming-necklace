import 'package:flutter/material.dart';
import '../widgets/necklace_panel/necklace_panel.dart';
import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/core/blocs/ble_connection/ble_connection_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/necklace_repository.dart';

class NecklacesScreen extends StatefulWidget {
  const NecklacesScreen({super.key});

  @override
  _NecklacesScreenState createState() => _NecklacesScreenState();
}

class _NecklacesScreenState extends State<NecklacesScreen> {
  final List<Necklace> _necklaces = [
    Necklace(
      id: '1',
      name: 'Lavender Dream',
      color: 'Purple',
      autoTurnOffEnabled: true,
      periodicEmissionEnabled: true,
      emission1Duration: Duration(seconds: 3),
      releaseInterval1: Duration(seconds: 20),
      emission2Duration: Duration(seconds: 8),
      releaseInterval2: Duration(seconds: 30),
      description: 'This is the first necklace description.',
    ),
    Necklace(
      id: '2',
      name: 'Ocean Breeze',
      color: 'Blue',
      autoTurnOffEnabled: false,
      periodicEmissionEnabled: true,
      emission1Duration: Duration(seconds: 3),
      releaseInterval1: Duration(seconds: 10),
      emission2Duration: Duration(seconds: 8),
      releaseInterval2: Duration(seconds: 20),
      description: 'This is the second necklace description.',
    ),
    Necklace(
      id: '3',
      name: 'Forest Mist',
      color: 'Green',
      autoTurnOffEnabled: true,
      periodicEmissionEnabled: false,
      emission1Duration: Duration(minutes: 20),
      releaseInterval1: Duration(minutes: 40),
      emission2Duration: Duration(minutes: 25),
      releaseInterval2: Duration(minutes: 50),
      description: 'This is the third necklace description.',
    ),
  ];

  final BleConnectionBloc _bleConnectionBloc = BleConnectionBloc();

  Future<void> _showAddNecklaceDialog() async {
    // Implement the dialog to add a new necklace
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
      body: _necklaces.isEmpty ? _buildEmptyState() : _buildNecklaceList(),
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

  Widget _buildNecklaceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _necklaces.length,
      itemBuilder: (context, index) {
        final repository = context.read<NecklaceRepository>();
        final necklace = _necklaces[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: NecklacePanel(
            index: index,
            repository: repository,
            name: necklace.name,
            isConnected: true,
            necklace: necklace,
            bleConnectionBloc: _bleConnectionBloc,
          ),
        );
      },
    );
  }
}
