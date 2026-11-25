import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({super.key});

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _tempPasswordController = TextEditingController(text: 'Costura2024*');
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _tempPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instanceFor(app: secondaryApp).createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _tempPasswordController.text.trim(),
      );

      final String newUid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('usuarios').doc(newUid).set({
        'nombre': _fullNameController.text.trim(),
        'correo': _emailController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'direccion': _addressController.text.trim(),
        'rol': 'cliente',
        'fecha_registro': FieldValue.serverTimestamp(),
        'activo': true,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clienta ${_fullNameController.text.trim()} registrada en Firebase'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Error al registrar clienta';
      if (e.code == 'email-already-in-use') {
        msg = 'Este correo ya está registrado.';
      } else if (e.code == 'weak-password') {
        msg = 'La contraseña debe tener al menos 6 caracteres.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } finally {
      await secondaryApp?.delete();
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
          'Volver al Perfil',
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
            const Text('Dar de alta una clienta 👤', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text(
              'Ingresa los datos generales de la nueva clienta para que pueda acceder al sistema.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
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
                    const Text('Nombre completo *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Lucía Fernández',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa el nombre completo' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Teléfono de contacto *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Ej. 555-987-6543',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa el teléfono' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Correo electrónico *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'ejemplo@correo.com',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa el correo electrónico' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Dirección (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Calle, número, colonia...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Contraseña temporal asignada *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tempPasswordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF2F0EB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'La clienta podrá cambiar esta contraseña al ingresar por primera vez.',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
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
                        onPressed: _isSaving ? null : _registerClient,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Guardar y Dar de Alta Clienta',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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