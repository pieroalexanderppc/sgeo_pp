import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:convert';

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  bool _isLoading = true;
  List<Map<String, String>> _newsList = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRealNews();
  }

  Future<void> _fetchRealNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String rssQuery = "Tacna robo OR delincuencia OR asalto OR policia";
      final String googleUrl = "https://news.google.com/rss/search?q=${Uri.encodeComponent(rssQuery)}&hl=es-419&gl=PE&ceid=PE:es-419";
      
      String rawXml;
      
      if (kIsWeb) {
        // En WEB obligatoriamente usamos al proxy JSON mode "allorigins" para que los navegadores
        // no bloqueen la conexión cruzada por reglas estrictas anti-CORS. 
        final Uri proxyUrl = Uri.parse("https://api.allorigins.win/get?url=${Uri.encodeComponent(googleUrl)}");
        final response = await http.get(proxyUrl);
        
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          rawXml = jsonResponse['contents'] as String; // Extraer el XML crudo empacado en JSON
        } else {
          _setError("Error de servidor web (${response.statusCode}). Reintente más tarde.");
          return;
        }
      } else {
        // En celulares (Android/iOS) podemos hacer conexión limpia, directa y cruda al servidor de Google.
        final response = await http.get(Uri.parse(googleUrl));
        if (response.statusCode == 200) {
          rawXml = utf8.decode(response.bodyBytes);
        } else {
          _setError("Error conectando con Google News (${response.statusCode}). Reintente más tarde.");
          return;
        }
      }

      // Parseamos el XML recuperado (sea por proxy o directamente)
      final document = xml.XmlDocument.parse(rawXml);
      final items = document.findAllElements('item');

        List<Map<String, String>> parsedNews = [];

        for (var item in items.take(15)) {
          final title = item.findElements('title').isNotEmpty ? item.findElements('title').single.innerText : 'Titular Desconocido';
          final link = item.findElements('link').isNotEmpty ? item.findElements('link').single.innerText : '';
          final pubDate = item.findElements('pubDate').isNotEmpty ? item.findElements('pubDate').single.innerText : '';
          final source = item.findElements('source').isNotEmpty ? item.findElements('source').single.innerText : 'Diario Local';
          
          parsedNews.add({
            'title': title,
            'link': link,
            'pubDate': pubDate,
            'source': source,
          });
        }

        setState(() {
          _newsList = parsedNews;
          _isLoading = false;
        });

    } catch (e) {
      debugPrint("ERROR: $e");
      _setError("Error detectado: $e");
    }
  }

  void _setError(String msg) {
    setState(() {
      _errorMessage = msg;
      _isLoading = false;
    });
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
        );
      }
    }
  }

  // Google News RSS muchas veces no incluye foto.
  // Colocaremos imágenes de fondo que varíen cíclicamente para darle dinamismo y buen look a la lista.
  String _getFallbackImage(int index) {
    final List<String> fallbacks = [
      "https://images.unsplash.com/photo-1555845579-dd77ce22ebd1?auto=format&fit=crop&q=80&w=800", // Sirena azul
      "https://images.unsplash.com/photo-1517594422361-55ce413009cf?auto=format&fit=crop&q=80&w=800", // Policia borroso
      "https://images.unsplash.com/photo-1588653926593-3d0ba5f3f0bc?auto=format&fit=crop&q=80&w=800", // Carro Policial
      "https://images.unsplash.com/photo-1453873531674-2151bcd01707?auto=format&fit=crop&q=80&w=800", // Cordon amarillo
    ];
    return fallbacks[index % fallbacks.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Noticias de Seguridad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
             icon: const Icon(Icons.sync_rounded),
             onPressed: _isLoading ? null : _fetchRealNews,
             tooltip: "Refrescar noticias",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _newsList.isEmpty
                  ? _buildEmptyView()
                  : _buildNewsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchRealNews,
              icon: const Icon(Icons.refresh),
              label: const Text("Reintentar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.feed_outlined, size: 80, color: Colors.grey),
           SizedBox(height: 16),
           Text("No hay noticias relevantes en Tacna por ahora.", style: TextStyle(color: Colors.black54)),
         ],
       )
    );
  }

  Widget _buildNewsList() {
    return RefreshIndicator(
      onRefresh: _fetchRealNews,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _newsList.length,
        itemBuilder: (context, index) {
          final news = _newsList[index];
          final String rawTitle = news['title']!;
          final String source = news['source']!;
          final String link = news['link']!;
          final String pubDateRaw = news['pubDate']!;
          
          // Formateo simple de fecha (cortando el largo offset de tiempo GMT)
          final String pubDate = pubDateRaw.length > 16 
              ? pubDateRaw.substring(0, 16) 
              : pubDateRaw;
          
          // Las noticias a veces incluyen " - NombreDiario" al final, lo cortamos para que quede limpio
          final String cleanTitle = rawTitle.contains(' - ') 
              ? rawTitle.substring(0, rawTitle.lastIndexOf(' - ')) 
              : rawTitle;

          final String imageUrl = _getFallbackImage(index);

          return Card(
            elevation: 4,
            shadowColor: Colors.black.withAlpha(25),
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _launchURL(link),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contenedor de la Imagen con Gradiente sobrepuesto
                  Stack(
                    children: [
                      SizedBox(
                        height: 190,
                        width: double.infinity,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Sombra gradiente inferior para que contraste con las etiquetas
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withAlpha(180), Colors.transparent],
                            )
                          ),
                        ),
                      ),
                      // Etiqueta de la Fuente (Radio Uno, Correo, etc)
                      Positioned(
                        bottom: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade700,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 4, offset: const Offset(0, 2))
                            ]
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.language, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                source.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                       // Etiqueta de Fecha
                      Positioned(
                        bottom: 12, right: 12,
                        child: Text(
                          pubDate,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      )
                    ],
                  ),
                  
                  // Cuerpo del texto de la noticia
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              "Toca para leer el artículo completo",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                             Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.blueAccent.shade400)
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
