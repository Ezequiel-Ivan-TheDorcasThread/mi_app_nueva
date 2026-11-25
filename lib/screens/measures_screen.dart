import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeasuresScreen extends StatefulWidget {
  const MeasuresScreen({super.key});

  @override
  State<MeasuresScreen> createState() => _MeasuresScreenState();
}

class _MeasuresScreenState extends State<MeasuresScreen> {
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _bustoController = TextEditingController(text: '92');
  final TextEditingController _cinturaController = TextEditingController(text: '74');
  final TextEditingController _caderaController = TextEditingController(text: '101');
  final TextEditingController _talleController = TextEditingController(text: '42');

  String? _selectedClientId;
  String _selectedClientName = 'María González';
  String _clientPhone = '555-123-4567';
  String _clientEmail = 'maria@correo.com';
  String _clientAddress = 'Calle Principal #123';
  String _lastUpdate = '12 abril 2024';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultClient();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bustoController.dispose();
    _cinturaController.dispose();
    _caderaController.dispose();
    _talleController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultClient() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'cliente')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      _setClientData(snapshot.docs.first);
    }
  }

  void _setClientData(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final medidas = data['medidas'] as Map<String, dynamic>?;

    setState(() {
      _selectedClientId = doc.id;
      _selectedClientName = data['nombre'] ?? 'Sin nombre';
      _clientPhone = data['telefono'] ?? 'No registrado';
      _clientEmail = data['correo'] ?? 'No registrado';
      _clientAddress = data['direccion'] ?? 'No registrada';

      _bustoController.text = (medidas?['busto'] ?? '92').toString();
      _cinturaController.text = (medidas?['cintura'] ?? '74').toString();
      _caderaController.text = (medidas?['cadera'] ?? '101').toString();
      _talleController.text = (medidas?['talle'] ?? '42').toString();
      _lastUpdate = medidas?['fecha_actualizacion'] ?? 'Sin actualización previa';
    });
  }

  Future<void> _searchClient() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'cliente')
          .get();

      final matchingDocs = snapshot.docs.where((doc) {
        final nombre = (doc.data()['nombre'] ?? '').toString().toLowerCase();
        return nombre.contains(query);
      }).toList();

      if (matchingDocs.isNotEmpty) {
        _setClientData(matchingDocs.first);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró ninguna clienta con ese nombre'),
              backgroundColor: Color(0xFFE65100),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMeasures() async {
    if (_selectedClientId == null) return;

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final formattedDate = '${now.day}/${now.month}/${now.year}';

      await FirebaseFirestore.instance.collection('usuarios').doc(_selectedClientId).update({
        'medidas': {
          'busto': _bustoController.text.trim(),
          'cintura': _cinturaController.text.trim(),
          'cadera': _caderaController.text.trim(),
          'talle': _talleController.text.trim(),
          'fecha_actualizacion': formattedDate,
        }
      });

      setState(() => _lastUpdate = formattedDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Medidas guardadas en Firebase con éxito!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showContactDataModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Datos de la Clienta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              _buildContactDetail('NOMBRE', _selectedClientName),
              const SizedBox(height: 12),
              _buildContactDetail('TELÉFONO', _clientPhone),
              const SizedBox(height: 12),
              _buildContactDetail('CORREO ELECTRÓNICO', _clientEmail),
              const SizedBox(height: 12),
              _buildContactDetail('DIRECCIÓN', _clientAddress),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A403A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cerrar ventana',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medidas de Clienta',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔍 Buscar Clienta:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Escribe el nombre de la clienta...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFF2F0EB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD49B9B),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: _isLoading ? null : _searchClient,
                        child: const Text('Buscar', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PERFIL DE ${_selectedClientName.toUpperCase()}',
              style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            const Text('Gestión y Búsqueda de Medidas 📏', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text(
              'Estas medidas son privadas y solo las usamos para tus pedidos.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMeasureRow('Busto', _bustoController),
                  const Divider(height: 16),
                  _buildMeasureRow('Cintura', _cinturaController),
                  const Divider(height: 16),
                  _buildMeasureRow('Cadera', _caderaController),
                  const Divider(height: 16),
                  _buildMeasureRow('Talle', _talleController),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Todo actualizado',
                          style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Última toma de medidas · $_lastUpdate',
                          style: const TextStyle(color: Color(0xFF388E3C), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _saveMeasures,
                icon: const Icon(Icons.save_outlined, color: Colors.black87, size: 18),
                label: const Text(
                  'Guardar Medidas de la Clienta',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A403A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showContactDataModal(context),
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 18),
                label: const Text(
                  'Ver datos de contacto de la clienta',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasureRow(String label, TextEditingController controller) {
    return Row(
      children: [
        const Icon(Icons.edit_note, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        Container(
          width: 80,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F0EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Text('cm', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}