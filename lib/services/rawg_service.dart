import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game.dart';

class RawgService {
  final String _baseUrl = 'https://api.rawg.io/api';
  final String _apiKey = dotenv.env['RAWG_API_KEY'] ?? '';

  Future<List<Game>> searchGames(String query, {String ordering = '-rating'}) async {
    final url = Uri.parse(
        '$_baseUrl/games?key=$_apiKey&search=$query&ordering=$ordering&page_size=20');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar jogos');
    }
  }

  Future<List<Game>> getPopularGames({String ordering = '-rating', String genre = ''}) async {
    String url = '$_baseUrl/games?key=$_apiKey&ordering=$ordering&page_size=20';
    if (genre.isNotEmpty) url += '&genres=$genre';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar jogos populares');
    }
  }

  Future<List<Game>> getMoreGames({String ordering = '-rating', String genre = '', required int page}) async {
    String url = '$_baseUrl/games?key=$_apiKey&ordering=$ordering&page_size=20&page=$page';
    if (genre.isNotEmpty) url += '&genres=$genre';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar mais jogos');
    }
  }
}