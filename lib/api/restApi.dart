import 'package:iziFile/api/enviroment.dart';
import 'package:iziFile/services/localStorage.dart';
import 'package:dio/dio.dart';

class restApi {
  static Dio _dio = Dio();
  static void configureDio() {
    // Base del url

    _dio.options.baseUrl = Enviroment.apiUrl;
    // Configurar Headers
    _dio.options.headers = {
      'x-token': LocalStorage.prefs.getString('token') ?? ''
    };
  }

  static Future httpGet(String path) async {
    try {
      final resp = await _dio.get(path);

      return resp.data;
    } catch (e) {
      throw ('Error en el GET');
    }
  }

  static Future post(String path, Map<String, dynamic> data) async {
    final formData = FormData.fromMap(data);

    try {
      final resp = await _dio.post(path, data: formData);

      return resp.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        // Capturamos el mensaje específico del error
        String errorMsg = e.response!.data['msg'] ?? 'Error desconocido';
        throw errorMsg;
      } else {
        throw ('Error en el POST');
      }
    }
  }

  static Future put(String path, Map<String, dynamic> data) async {
    final formData = FormData.fromMap(data);

    try {
      final resp = await _dio.put(path, data: formData);
      return resp.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        // Capturamos el mensaje específico del error
        String errorMsg = e.response!.data['msg'] ?? 'Error desconocido';
        throw errorMsg;
      } else {
        throw ('Error en el PUT');
      }
    }
  }

  static Future delete(String path) async {
    try {
      final resp = await _dio.delete(path);
      return resp.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        // Capturamos el mensaje específico del error
        String errorMsg = e.response!.data['msg'] ?? 'Error desconocido';
        throw errorMsg;
      } else {
        throw ('Error en el DELETE');
      }
    }
  }

  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final data = {'id_token': idToken};
    try {
      final resp = await _dio.post('/auth/google', data: data);

      return resp.data;
    } catch (e) {
      throw e;
    }
  }
}
