import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';

class SftpProvider extends ChangeNotifier {
  SSHClient? _sshClient;
  SftpClient? _sftpClient;
  List<SftpName> _directories = [];

  List<SftpName> get directories => _directories;

  // Método para iniciar la conexión SFTP
  Future<void> connectSftp({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      _sshClient = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        onPasswordRequest: () => password,
      );

      _sftpClient = await _sshClient!.sftp();
      notifyListeners();
    } catch (e) {
      // Manejar el error adecuadamente
    }
  }

  Future<void> listDirectories(String path) async {
    if (_sftpClient == null) {
      return;
    }

    try {
      final items = await _sftpClient!.listdir(path);
      // Filtrar por directorios basándose en el longname
      _directories = items.where((item) {
        return item.longname.startsWith('d');
      }).toList();
      notifyListeners();
    } catch (e) {
      // Manejar el error adecuadamente
    }
  }

  // Método para desconectar la sesión SFTP
  void disconnect() {
    _sshClient?.close();
    _sshClient = null;
    _sftpClient = null;
    _directories.clear();
    notifyListeners();
  }
}
