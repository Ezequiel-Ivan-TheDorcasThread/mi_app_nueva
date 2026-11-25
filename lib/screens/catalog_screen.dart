import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './add_catalog_screen.dart';

class CatalogScreen extends StatefulWidget {
  final bool isAdmin;

  const CatalogScreen({super.key, this.isAdmin = false});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  void _deleteItem(String docId, String title) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirmar eliminación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text('¿Estás segura de que deseas eliminar "$title" del catálogo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('portafolio').doc(docId).delete();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prenda eliminada del catálogo'),
                      backgroundColor: Color(0xFFC62828),
                    ),
                  );
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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
          'Catálogo y Portafolio',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAdmin ? 'GESTIÓN DE TALLER' : 'NUESTRA GALERÍA',
              style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            const Text('Catálogo y Portafolio 📸', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(
              widget.isAdmin
                  ? 'Administra las fotos y los trabajos mostrados en el catálogo.'
                  : 'Inspírate con algunos de nuestros últimos trabajos realizados.',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 18),

            if (widget.isAdmin) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD49B9B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddCatalogScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: const Text(
                    'Agregar nueva foto al catálogo',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('portafolio').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: Color(0xFFD49B9B)),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Center(
                      child: Text('Aún no hay prendas publicadas en el catálogo.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final item = doc.data() as Map<String, dynamic>;
                    final String title = item['titulo'] ?? 'Prenda';
                    final String subtitle = item['descripcion'] ?? '';
                    final String? fotoBase64 = item['foto_base64'];

                    return Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8E5DF),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: (fotoBase64 != null && fotoBase64.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Image.memory(
                                        base64Decode(fotoBase64),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('👗', style: TextStyle(fontSize: 28)),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text(
                                            title,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.isAdmin) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            side: const BorderSide(color: Color(0xFFD49B9B)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AddCatalogScreen(
                                                  docId: doc.id,
                                                  initialData: item,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.edit, size: 10, color: Color(0xFFD49B9B)),
                                              SizedBox(width: 2),
                                              Text('Editar', style: TextStyle(fontSize: 10, color: Color(0xFFD49B9B))),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            side: const BorderSide(color: Color(0xFFC62828)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          onPressed: () => _deleteItem(doc.id, title),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.delete_outline, size: 10, color: Color(0xFFC62828)),
                                              SizedBox(width: 2),
                                              Text('Eliminar', style: TextStyle(fontSize: 10, color: Color(0xFFC62828))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}