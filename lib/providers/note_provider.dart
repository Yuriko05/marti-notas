import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';

/// Provider para el manejo de estado de notas
/// Centraliza la lógica de notas y notifica cambios a la UI
class NoteProvider with ChangeNotifier {
  final NoteService _noteService;

  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;

  NoteProvider({NoteService? noteService})
      : _noteService = noteService ?? NoteService();

  // Getters
  List<NoteModel> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get notesCount => _notes.length;

  /// Stream de notas del usuario
  Stream<List<NoteModel>> getUserNotesStream() {
    return _noteService.getUserNotes();
  }

  /// Crear nueva nota
  Future<String?> createNote({
    required String title,
    required String content,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final noteId = await _noteService.createNote(
        title: title,
        content: content,
      );

      _isLoading = false;

      if (noteId == null) {
        _errorMessage = 'Error al crear la nota';
      }

      notifyListeners();
      return noteId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Actualizar nota existente
  Future<bool> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _noteService.updateNote(
        noteId: noteId,
        title: title,
        content: content,
      );

      _isLoading = false;

      if (!success) {
        _errorMessage = 'Error al actualizar la nota';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Eliminar nota
  Future<bool> deleteNote(String noteId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _noteService.deleteNote(noteId);

      _isLoading = false;

      if (!success) {
        _errorMessage = 'Error al eliminar la nota';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Obtener una nota específica
  Future<NoteModel?> getNote(String noteId) async {
    try {
      return await _noteService.getNote(noteId);
    } catch (e) {
      _errorMessage = 'Error al obtener nota: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Cargar conteo de notas
  Future<int> loadNotesCount() async {
    try {
      return await _noteService.getUserNotesCount();
    } catch (e) {
      debugPrint('NoteProvider: Error al cargar conteo: $e');
      return 0;
    }
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpiar todos los datos
  void clear() {
    _notes = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
