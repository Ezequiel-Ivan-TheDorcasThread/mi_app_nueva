import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CreateOrderScreen extends StatefulWidget {
  final String? initialService;

  const CreateOrderScreen({super.key, this.initialService});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedService;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _base64Image;
  String? _imageName;
  bool _isSubmitting = false;

  final List<String> _services = [
    'Ajustes y Reparaciones',
    'Confección a Medida',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialService != null && _services.contains(widget.initialService)) {
      _selectedService = widget.initialService;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCompressImage() async {
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD49B9B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Obtener nombre de la clienta
      final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      final String clientName = (userDoc.data()?['nombre'] ?? 'Clienta').toString();

      // Generar un número corto de folio basado en la hora
      final String folio = '#${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';

      // Guardar pedido en Firestore
      final docRef = await FirebaseFirestore.instance.collection('pedidos').add({
        'folio': folio,
        'id_usuario': user.uid,
        'nombre_cliente': clientName,
        'servicio': _selectedService,
        'titulo_prenda': _titleController.text.trim().isEmpty
            ? _selectedService
            : _titleController.text.trim(),
        'descripcion_detalles': _descriptionController.text.trim(),
        'foto_base64': _base64Image,
        'fecha_solicitud': FieldValue.serverTimestamp(),
        'fecha_entrega': _dateController.text.trim(),
        'costo_total': _selectedService == 'Ajustes y Reparaciones' ? '80.00' : '500.00',
        'anticipo': '0.00',
        'estado': 'En espera de aceptación',
      });

      // Crear notificación para la costurera
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'para_rol': 'costurera',
        'id_pedido': docRef.id,
        'mensaje': 'Nuevo pedido ($folio) recibido de $clientName.',
        'leida': false,
        'fecha_envio': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud enviada con éxito al taller!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar pedido: $e'), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          'Nuevo Pedido',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NUEVO PEDIDO',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            const Text('Cuéntanos tu idea ✨', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const Text(
              'Déjanos los detalles y te contactaremos para confirmar.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('¿Qué servicio necesitas?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedService,
                      decoration: InputDecoration(
                        hintText: 'Selecciona una opción',
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _services.map((String service) {
                        return DropdownMenuItem<String>(
                          value: service,
                          child: Text(service, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedService = value),
                      validator: (value) => value == null ? 'Por favor selecciona un servicio' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text('Prenda o título corto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Ajuste de vestido de noche',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa un título breve' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text('Cuéntanos un poco más', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ej: Necesito ajustar el largo de un vestido...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Ingresa los detalles de lo que necesitas' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text('Foto de referencia (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickAndCompressImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F0EB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _base64Image != null ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _base64Image != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                              color: _base64Image != null ? const Color(0xFF2E7D32) : const Color(0xFFD49B9B),
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _imageName ?? 'Sube una foto',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            const Text('JPG o PNG · Se comprime automáticamente', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('¿Para cuándo lo necesitas?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        hintText: 'dd/mm/aaaa',
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        suffixIcon: const Icon(Icons.calendar_month, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Selecciona la fecha requerida' : null,
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD49B9B),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isSubmitting ? null : _submitOrder,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Enviar Solicitud >',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                      ],
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