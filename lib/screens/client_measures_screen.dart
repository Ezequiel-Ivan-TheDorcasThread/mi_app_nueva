import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientMeasuresScreen extends StatelessWidget {
  const ClientMeasuresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

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
          'Mis Medidas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('No has iniciado sesión'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD49B9B)));
                }

                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final String nombre = data?['nombre'] ?? 'Clienta';
                final medidas = data?['medidas'] as Map<String, dynamic>?;

                final String busto = '${medidas?['busto'] ?? '92'} cm';
                final String cintura = '${medidas?['cintura'] ?? '74'} cm';
                final String cadera = '${medidas?['cadera'] ?? '101'} cm';
                final String talle = '${medidas?['talle'] ?? '42'} cm';
                final String fechaAct = medidas?['fecha_actualizacion'] ?? '12 abril 2024';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERFIL DE ${nombre.toUpperCase()}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text('Mis Medidas ($nombre) 📏', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text(
                        'Estas medidas son privadas y solo las usamos para tus pedidos.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildReadOnlyMeasureRow('Busto', busto),
                            const Divider(height: 20),
                            _buildReadOnlyMeasureRow('Cintura', cintura),
                            const Divider(height: 20),
                            _buildReadOnlyMeasureRow('Cadera', cadera),
                            const Divider(height: 20),
                            _buildReadOnlyMeasureRow('Talle', talle),
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
                                    'Última toma de medidas · $fechaAct',
                                    style: const TextStyle(color: Color(0xFF388E3C), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A403A),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Volver a mi perfil',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildReadOnlyMeasureRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
      ],
    );
  }
}