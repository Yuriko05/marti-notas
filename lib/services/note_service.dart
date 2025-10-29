import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/note_model.dart';

/// Servicio para gestionar notas en Firestore
class NoteService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NoteService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Stream de notas del usuario actual
  Stream<List<NoteModel>> getUserNotes() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              NoteModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Crear una nueva nota
  Future<String?> createNote({
    required String title,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('NoteService: No hay usuario autenticado');
        return null;
      }

      final noteData = {
        'title': title,
        'content': content,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('notes').add(noteData);
      debugPrint('NoteService: Nota creada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('NoteService: Error al crear nota: $e');
      rethrow;
    }
  }

  /// Actualizar una nota existente
  Future<bool> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('NoteService: No hay usuario autenticado');
        return false;
      }

      await _firestore.collection('notes').doc(noteId).update({
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('NoteService: Nota actualizada: $noteId');
      return true;
    } catch (e) {
      debugPrint('NoteService: Error al actualizar nota: $e');
      return false;
    }
  }

  /// Eliminar una nota
  Future<bool> deleteNote(String noteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('NoteService: No hay usuario autenticado');
        return false;
      }

      // Verificar que la nota pertenece al usuario
      final noteDoc = await _firestore.collection('notes').doc(noteId).get();
      
      if (!noteDoc.exists) {
        debugPrint('NoteService: Nota no encontrada');
        return false;
      }

      final noteData = noteDoc.data();
      if (noteData?['userId'] != user.uid) {
        debugPrint('NoteService: No tienes permiso para eliminar esta nota');
        return false;
      }

      await _firestore.collection('notes').doc(noteId).delete();
      debugPrint('NoteService: Nota eliminada: $noteId');
      return true;
    } catch (e) {
      debugPrint('NoteService: Error al eliminar nota: $e');
      return false;
    }
  }

  /// Obtener una nota específica
  Future<NoteModel?> getNote(String noteId) async {
    try {
      final doc = await _firestore.collection('notes').doc(noteId).get();
      
      if (!doc.exists) {
        return null;
      }

      return NoteModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('NoteService: Error al obtener nota: $e');
      return null;
    }
  }

  /// Contar notas del usuario
  Future<int> getUserNotesCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: user.uid)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('NoteService: Error al contar notas: $e');
      return 0;
    }
  }
}
