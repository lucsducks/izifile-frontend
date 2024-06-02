import 'package:iziFile/api/restApi.dart';
import 'package:iziFile/models/http/auth_response.dart';
import 'package:iziFile/router/router.dart';
import 'package:iziFile/services/localStorage.dart';
import 'package:iziFile/services/navigation_service.dart';
import 'package:iziFile/services/notificacion_service.dart';
import 'package:flutter/material.dart';

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthProvider extends ChangeNotifier {
  String? _token;
  Usuario? user;
  AuthStatus authStatus = AuthStatus.checking;
  AuthProvider() {
    isAuthenticated();
  }
  login(String email, String password) {
    final data = {'correo': email, 'password': password};
    restApi.post('/auth/login', data).then((json) {
      final authResponse = AuthResponse.fromMap(json);
      user = authResponse.usuario;
      if (user!.verificado == false) {
        LocalStorage.prefs.setString('correoPersonal', email);
        NotificationsService.showSnackbarError('Usuario no verificado');
        resend(email);
        return NavigationService.verificationReplaceTo(
            Flurorouter.verificationRoute,
            arguments: {'correoPersonal': email});
      }
      authStatus = AuthStatus.authenticated;
      LocalStorage.prefs.setString('token', authResponse.token);
      NavigationService.replaceTo(Flurorouter.dashboardRoute);
      restApi.configureDio();
      notifyListeners();
    }).catchError((e) {
      NotificationsService.showSnackbarError(e.toString());
    });
  }

  register(String email, String password, String nombre) {
    final data = {'nombre': nombre, 'correo': email, 'password': password};
    restApi.post('/usuarios', data).then((json) {
      final authResponse = AuthResponse.fromMap(json);
      user = authResponse.usuario;
      authStatus = AuthStatus.authenticated;
      LocalStorage.prefs.setString('token', authResponse.token);
      NavigationService.replaceTo(Flurorouter.dashboardRoute);
      restApi.configureDio();
      notifyListeners();
    }).catchError((e) {
      NotificationsService.showSnackbarError(e.toString());
      throw e;
    });
  }

  verification(String codigoVerificacion) {
    final data = {
      'codigoVerificacion': codigoVerificacion,
      'correo': LocalStorage.prefs.getString('correoPersonal')
    };
    restApi.post('/usuarios/verify', data).then((json) {
      final authResponse = AuthResponse.fromMap(json);
      user = authResponse.usuario;
      authStatus = AuthStatus.authenticated;
      LocalStorage.prefs.setString('token', authResponse.token);
      NavigationService.replaceTo(Flurorouter.dashboardRoute);
      restApi.configureDio();
      notifyListeners();
    }).catchError((e) {
      if (e is Map && e.containsKey('errors')) {
        final errorMsg = e['errors'][0]['msg'];
        NotificationsService.showSnackbarError(errorMsg);
      } else {
        NotificationsService.showSnackbarError('Hable con el administrador');
      }
    });
  }

  resend(String correo) {
    final data = {'correo': correo};
    restApi.post('/usuarios/resend', data).then((json) {
      restApi.configureDio();
      notifyListeners();
    }).catchError((e) {
      if (e is Map && e.containsKey('errors')) {
        final errorMsg = e['errors'][0]['msg'];
        NotificationsService.showSnackbarError(errorMsg);
      } else {
        NotificationsService.showSnackbarError('Hable con el administrador');
      }
    });
  }

  Future<bool> isAuthenticated() async {
    final token = LocalStorage.prefs.getString('token');
    if (token == null) {
      authStatus = AuthStatus.notAuthenticated;
      notifyListeners();
      return false;
    }

    try {
      final resp = await restApi.httpGet('/auth');
      final authReponse = AuthResponse.fromMap(resp);
      LocalStorage.prefs.setString('token', authReponse.token);
      user = authReponse.usuario;
      authStatus = AuthStatus.authenticated;
      restApi.configureDio();
      notifyListeners();
      return true;
    } catch (e) {
      authStatus = AuthStatus.notAuthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> googleSignIn(String idToken, context) async {
    try {
      final response = await restApi.googleLogin(idToken);
      // ignore: unnecessary_null_comparison
      if (response != null) {
        _token = response['token'];
        user = Usuario.fromMap(response['usuario']);
        authStatus = AuthStatus.authenticated;
        LocalStorage.prefs.setString('token', _token!);
        notifyListeners();
        NavigationService.replaceTo(Flurorouter.dashboardRoute);
        restApi.configureDio();
      }
    } catch (error) {
      // Manejar errores aquí
      if (error is Map && error.containsKey('errors')) {
        final errorMsg = error['errors'][0]['msg'];
        NotificationsService.showSnackbarError(errorMsg);
      } else {
        NotificationsService.showSnackbarError('Hable con el administrador');
      }
    }
    notifyListeners();
  }

  logout() {
    LocalStorage.prefs.remove('token');
    authStatus = AuthStatus.notAuthenticated;
    NavigationService.replaceTo(Flurorouter.loginRoute);
    notifyListeners();
  }
}
