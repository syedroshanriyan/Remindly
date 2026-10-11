import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/hive_service.dart';

class DiaryProvider extends ChangeNotifier {
  final List<DiaryEntry> _entries = [];
  String _selectedCategory = 'All';
  bool _sortNewestFirst = true;

  List<DiaryEntry> get entries => List.unmodifiable(_entries);
  String get selectedCategory => _selectedCategory;
  bool get sortNewestFirst => _sortNewestFirst;

  DiaryProvider() {
    loadEntries();
  }

  void loadEntries() {
    try {
      final stored = HiveService.diaryBox.values.toList();
      _entries.clear();
      for (final item in stored) {
        try {
          if (item is Map) {
            _entries.add(DiaryEntry.fromMap(item));
          }
        } catch (_) {}
      }
      _sortEntries();
      notifyListeners();
    } catch (_) {}
  }

  List<DiaryEntry> get activeEntries {
    var list = _entries.where((e) => !e.isArchived).toList();
    if (_selectedCategory != 'All') {
      list = list
          .where((e) =>
              e.category.toLowerCase() == _selectedCategory.toLowerCase() ||
              e.tags.any(
                  (t) => t.toLowerCase() == _selectedCategory.toLowerCase()))
          .toList();
    }
    return list;
  }

  List<DiaryEntry> get pinnedEntries =>
      activeEntries.where((e) => e.isPinned).toList();

  List<DiaryEntry> get unpinnedEntries =>
      activeEntries.where((e) => !e.isPinned).toList();

  List<DiaryEntry> get archivedEntries =>
      _entries.where((e) => e.isArchived).toList();

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleSortOrder() {
    _sortNewestFirst = !_sortNewestFirst;
    _sortEntries();
    notifyListeners();
  }

  void togglePin(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _entries[index].isPinned = !_entries[index].isPinned;
    HiveService.diaryBox.put(_entries[index].id, _entries[index].toMap());
    notifyListeners();
  }

  void addEntry(DiaryEntry entry) {
    _entries.add(entry);
    HiveService.diaryBox.put(entry.id, entry.toMap());
    _sortEntries();
    notifyListeners();
  }

  void updateEntry(DiaryEntry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      addEntry(entry);
      return;
    }

    _entries[index] = entry;
    HiveService.diaryBox.put(entry.id, entry.toMap());
    _sortEntries();
    notifyListeners();
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    HiveService.diaryBox.delete(id);
    notifyListeners();
  }

  void archiveEntry(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _entries[index].isArchived = true;
    HiveService.diaryBox.put(_entries[index].id, _entries[index].toMap());
    notifyListeners();
  }

  void restoreEntry(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _entries[index].isArchived = false;
    HiveService.diaryBox.put(_entries[index].id, _entries[index].toMap());
    notifyListeners();
  }

  List<DiaryEntry> searchEntries(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return activeEntries;

    return activeEntries.where((e) {
      final inTitle = e.title.toLowerCase().contains(q);
      final inContent = e.content.toLowerCase().contains(q);
      final inTags = e.tags.any((t) => t.toLowerCase().contains(q));
      return inTitle || inContent || inTags;
    }).toList();
  }

  void _sortEntries() {
    if (_sortNewestFirst) {
      _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }
}
