import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../errors/exceptions.dart';

/// KLE HOMECARE — Generic API Service
/// Wraps Dio calls with consistent error handling.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Dio get _dio => DioClient.instance.dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final resp = await _dio.get(path, queryParameters: queryParams);
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final resp = await _dio.post(path, data: data);
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final resp = await _dio.patch(path, data: data);
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final resp = await _dio.put(path, data: data);
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Upload a file as multipart/form-data. Returns the response body.
  /// [queryParams] are appended to the URL (some endpoints take metadata like
  /// week_name/week_start as query params alongside the multipart file body).
  Future<Map<String, dynamic>> postFormData(
    String path, {
    required String fieldName,
    required String fileName,
    required Uint8List bytes,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final resp = await _dio.post(path, data: formData, queryParameters: queryParams);
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Downloads raw bytes (Excel/PDF exports, templates).
  Future<Uint8List> getBytes(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final resp = await _dio.get(
        path,
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(List<int>.from(resp.data as List));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
