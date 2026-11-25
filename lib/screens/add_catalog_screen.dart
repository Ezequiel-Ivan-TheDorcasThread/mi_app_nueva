import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AddCatalogScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;

  const AddCatalogScreen({super.key, this.docId, this.initialData});

  @override
  State<AddCatalogScreen> createState() => _AddCatalogScreenState();
}

class _AddCatalogScreenState extends State<AddCatalogScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedType = '📷 Muestra de Trabajo / Portafolio (Solo exhibición)';
  String? _base64Image;
  String? _imageName;
  bool _isSaving = false;

  final List<String> _publicationTypes = [
    '📷 Muestra de Trabajo / Portafolio (Solo exhibición)',
    '🏷️ Prenda en Venta / Bajo Pedido',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!['titulo'] ?? '';
      _descriptionController.text = widget.initialData!['descripcion'] ?? '';
      final cat = widget.initialData!['categoria'] ?? '';
      if (_publicationTypes.contains(cat)) {
        _selectedType = cat;
      }
      _base64Image = widget.initialData!['foto_base64'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final File file = File(image.path);
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 600,
      minHeight: 600,
      quality: 60,
    );

    if (compressedBytes != null) {
      setState(() {
        _base64Image = base64Encode(compressedBytes);
        _imageName = image.name;
      });
    }
  }

  Future<void> _saveCatalogItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'titulo': _titleController.text.trim(),
        'categoria': _selectedType,
        'descripcion': _descriptionController.text.trim(),
        'foto_base64': _base64Image ?? '',
        'fecha_publicacion': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance.collection('portafolio').doc(widget.docId).update(data);
      } else {
        await FirebaseFirestore.instance.collection('portafolio').add(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.docId != null ? '¡Publicación actualizada!' : '¡Publicado con éxito en el catálogo!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.docId != null;

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
          'Volver al Catálogo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal, fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MÓDULO COSTURERA',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              isEditing ? 'Editar Publicación ✏️' : 'Agregar Imagen al Catálogo 📷',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Sube trabajos del portafolio o prendas disponibles para mostrar a tus clientas.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Título del trabajo o prenda *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Vestido de gala rojo o Blusa de lino disponible',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa un título' : null,
                    ),
                    const SizedBox(height: 18),
                    const Text('Tipo de publicación *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _publicationTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedType = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text('Descripción o detalles *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Escribe los detalles: tipo de confección, tipo de tela, precio...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa una descripción' : null,
                    ),
                    const SizedBox(height: 18),
                    const Text('Fotografía', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F0EB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_base64Image != null && _base64Image!.isNotEmpty)
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              (_base64Image != null && _base64Image!.isNotEmpty)
                                  ? Icons.check_circle
                                  : Icons.folder_open,
                              color: (_base64Image != null && _base64Image!.isNotEmpty)
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFD49B9B),
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Text(
                                _imageName ??
                                    ((_base64Image != null && _base64Image!.isNotEmpty)
                                        ? 'Imagen cargada'
                                        : 'Elegir archivo'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text('JPG o PNG · Se comprime automáticamente',
                                style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD49B9B),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSaving ? null : _saveCatalogItem,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isEditing ? 'Guardar Cambios' : 'Publicar en el Catálogo',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}