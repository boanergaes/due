import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/study_resource.dart';
import '../services/api_client.dart';

class ResourceProvider extends ChangeNotifier {
  final ApiClient apiClient;

  final Map<String, List<StudyResource>> _resourcesByKey = {};
  final Map<String, bool> _loadingByKey = {};
  final Map<String, String?> _errorByKey = {};

  bool _isUploading = false;
  String? _uploadError;

  ResourceProvider({required this.apiClient});

  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;

  String _makeKey(String type, int id) => '${type}_$id';

  List<StudyResource> getResources(String type, int id) {
    return _resourcesByKey[_makeKey(type, id)] ?? [];
  }

  bool isLoading(String type, int id) {
    return _loadingByKey[_makeKey(type, id)] ?? false;
  }

  String? getError(String type, int id) {
    return _errorByKey[_makeKey(type, id)];
  }

  /// Fetch all study resources attached to a class or assignment
  Future<List<StudyResource>> fetchResources({
    required String type,
    required int id,
  }) async {
    final key = _makeKey(type, id);
    _loadingByKey[key] = true;
    _errorByKey[key] = null;
    notifyListeners();

    try {
      final response = await apiClient.get(
        ApiConfig.resources,
        queryParams: {
          'resourceable_type': type,
          'resourceable_id': id.toString(),
        },
      );

      final List<StudyResource> list = [];
      if (response is Map<String, dynamic> && response['resources'] is List) {
        for (final item in response['resources'] as List) {
          if (item is Map<String, dynamic>) {
            list.add(StudyResource.fromJson(item));
          }
        }
      }

      _resourcesByKey[key] = list;
      return list;
    } on ApiException catch (e) {
      _errorByKey[key] = e.message;
      return [];
    } catch (e) {
      _errorByKey[key] = 'Failed to load resources: $e';
      return [];
    } finally {
      _loadingByKey[key] = false;
      notifyListeners();
    }
  }

  /// Upload a study resource (PDF, image, text, doc)
  Future<StudyResource?> uploadResource({
    required String type,
    required int id,
    String? title,
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
  }) async {
    _isUploading = true;
    _uploadError = null;
    notifyListeners();

    try {
      final fields = {
        'resourceable_type': type,
        'resourceable_id': id.toString(),
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      };

      final response = await apiClient.uploadMultipart(
        ApiConfig.resources,
        fileField: 'file',
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        fields: fields,
      );

      if (response is Map<String, dynamic> && response['resource'] is Map<String, dynamic>) {
        final newResource = StudyResource.fromJson(
          response['resource'] as Map<String, dynamic>,
        );

        final key = _makeKey(type, id);
        final current = _resourcesByKey[key] ?? [];
        _resourcesByKey[key] = [newResource, ...current];
        notifyListeners();
        return newResource;
      }
      return null;
    } on ApiException catch (e) {
      _uploadError = e.message;
      return null;
    } catch (e) {
      _uploadError = 'File upload failed: $e';
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Delete a study resource and free up quota
  Future<bool> deleteResource(
    int resourceId, {
    required String type,
    required int parentId,
  }) async {
    try {
      await apiClient.delete(ApiConfig.resourceDetail(resourceId));

      final key = _makeKey(type, parentId);
      final current = _resourcesByKey[key];
      if (current != null) {
        _resourcesByKey[key] = current.where((r) => r.id != resourceId).toList();
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _uploadError = e.message;
      return false;
    } catch (e) {
      _uploadError = 'Failed to delete resource: $e';
      return false;
    }
  }
}
