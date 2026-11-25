import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailScreen extends StatefulWidget {
  final bool isAdmin;
  final String? orderId;

  const OrderDetailScreen({
    super.key,
    required this.isAdmin,
    this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _costController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String orderId, String folio, String clientId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(orderId)
        .collection('mensajes')
        .add({
      'id_emisor': user.uid,
      'es_costurera': widget.isAdmin,
      'mensaje': text,
      'fecha_envio': FieldValue.serverTimestamp(),
    });

    // Enviar notificación a la contraparte
    if (widget.isAdmin) {
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'id_usuario': clientId,
        'id_pedido': orderId,
        'mensaje': 'Ana (Costurera) te envió un mensaje en el pedido $folio.',
        'leida': false,
        'fecha_envio': FieldValue.serverTimestamp(),
      });
    } else {
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'para_rol': 'costurera',
        'id_pedido': orderId,
        'mensaje': 'Nuevo mensaje en el pedido $folio.',
        'leida': false,
        'fecha_envio': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateCosts(String orderId) async {
    await FirebaseFirestore.instance.collection('pedidos').doc(orderId).update({
      'costo_total': _costController.text.trim(),
      'anticipo': _advanceController.text.trim(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Costos actualizados en el pedido'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F5F0),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('No se especificó un pedido.')),
      );
    }

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
          'Detalle del Pedido',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('pedidos').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD49B9B)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('El pedido no existe.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String folio = data['folio'] ?? '#000';
          final String title = data['titulo_prenda'] ?? 'Servicio';
          final String service = data['servicio'] ?? '';
          final String clientName = data['nombre_cliente'] ?? 'Clienta';
          final String clientId = data['id_usuario'] ?? '';
          final String description = data['descripcion_detalles'] ?? '';
          final String deliveryDate = data['fecha_entrega'] ?? '';
          final String status = data['estado'] ?? 'En espera de aceptación';
          final String? fotoBase64 = data['foto_base64'];

          if (_costController.text.isEmpty) {
            _costController.text = (data['costo_total'] ?? '0.00').toString();
          }
          if (_advanceController.text.isEmpty) {
            _advanceController.text = (data['anticipo'] ?? '0.00').toString();
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta Principal de Información
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$folio · $service', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Clienta: $clientName', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                            Text('Fecha de entrega: $deliveryDate', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const Divider(height: 24),
                            const Text('Detalles solicitados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87)),

                            // Mostrar foto de referencia si existe
                            if (fotoBase64 != null && fotoBase64.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text('Foto de referencia:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  base64Decode(fotoBase64),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],

                            const Divider(height: 24),

                            // Sección de Costos (Editable para Costurera, Solo Lectura para Clienta)
                            if (widget.isAdmin) ...[
                              const Text('Cotización y Pagos (Taller)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _costController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Costo Total (\$)',
                                        filled: true,
                                        fillColor: const Color(0xFFF2F0EB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _advanceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Anticipo (\$)',
                                        filled: true,
                                        fillColor: const Color(0xFFF2F0EB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _updateCosts(widget.orderId!),
                                  child: const Text('Actualizar Costos', style: TextStyle(color: Colors.black87)),
                                ),
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Costo Total: \$${data['costo_total'] ?? '0.00'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Anticipo: \$${data['anticipo'] ?? '0.00'}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text('💬 Chat del Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),

                      // Mensajes en tiempo real desde Firestore
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('pedidos')
                            .doc(widget.orderId)
                            .collection('mensajes')
                            .orderBy('fecha_envio', descending: false)
                            .snapshots(),
                        builder: (context, msgSnapshot) {
                          final msgs = msgSnapshot.data?.docs ?? [];
                          if (msgs.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('Aún no hay mensajes. Escribe para iniciar la conversación.',
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                            );
                          }

                          return Column(
                            children: msgs.map((m) {
                              final msgData = m.data() as Map<String, dynamic>;
                              final bool esCosturera = msgData['es_costurera'] ?? false;
                              final bool isMe = esCosturera == widget.isAdmin;

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFFD49B9B) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        esCosturera ? 'Ana (Costurera)' : clientName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isMe ? Colors.white70 : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        msgData['mensaje'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isMe ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Barra inferior para escribir mensaje
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF2F0EB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFFD49B9B),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: () => _sendMessage(widget.orderId!, folio, clientId),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}