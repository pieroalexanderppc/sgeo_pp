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

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

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
      final int lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
      final String startDateStr =
          "$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-01";
      final String endDateStr =
          "$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}";

      final String keywords = "Tacna robo OR delincuencia OR asalto OR policia";
      final String rssQuery =
          "$keywords after:$startDateStr before:$endDateStr";
      final String googleUrl =
          "https://news.google.com/rss/search?q=${Uri.encodeComponent(rssQuery)}&hl=es-419&gl=PE&ceid=PE:es-419";

      String rawXml;

      if (kIsWeb) {
        // En WEB obligatoriamente usamos al proxy JSON mode "allorigins" para que los navegadores
        // no bloqueen la conexión cruzada por reglas estrictas anti-CORS.
        final Uri proxyUrl = Uri.parse(
          "https://api.allorigins.win/get?url=${Uri.encodeComponent(googleUrl)}",
        );
        final response = await http.get(proxyUrl);

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          rawXml =
              jsonResponse['contents']
                  as String; // Extraer el XML crudo empacado en JSON
        } else {
          _setError(
            "Error de servidor web (${response.statusCode}). Reintente más tarde.",
          );
          return;
        }
      } else {
        // En celulares (Android/iOS) podemos hacer conexión limpia, directa y cruda al servidor de Google.
        final response = await http.get(Uri.parse(googleUrl));
        if (response.statusCode == 200) {
          rawXml = utf8.decode(response.bodyBytes);
        } else {
          _setError(
            "Error conectando con Google News (${response.statusCode}). Reintente más tarde.",
          );
          return;
        }
      }

      // Parseamos el XML recuperado (sea por proxy o directamente)
      final document = xml.XmlDocument.parse(rawXml);
      final items = document.findAllElements('item');

      List<Map<String, String>> parsedNews = [];
      Set<String> seenTitles = {};

      for (var item in items) {
        final title = item.findElements('title').isNotEmpty
            ? item.findElements('title').single.innerText
            : 'Titular Desconocido';
        final link = item.findElements('link').isNotEmpty
            ? item.findElements('link').single.innerText
            : '';
        final pubDate = item.findElements('pubDate').isNotEmpty
            ? item.findElements('pubDate').single.innerText
            : '';
        final source = item.findElements('source').isNotEmpty
            ? item.findElements('source').single.innerText
            : 'Diario Local';

        // Las noticias a veces incluyen " - NombreDiario" al final, lo cortamos para que quede limpio
        final String cleanTitle = title.contains(' - ')
            ? title.substring(0, title.lastIndexOf(' - ')).trim()
            : title.trim();

        // Si ya procesamos una noticia con el mismo título (evitar repetidas en el feed)
        if (seenTitles.contains(cleanTitle)) {
          continue;
        }
        seenTitles.add(cleanTitle);

        parsedNews.add({
          'title': cleanTitle,
          'link': link,
          'pubDate': pubDate,
          'source': source,
        });

        // Retornamos máximo unas 15 noticias únicas
        if (parsedNews.length >= 15) break;
      }

      if (mounted) {
        setState(() {
          _newsList = parsedNews;
          _isLoading = false;
        });
      }
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

  void _showDatePickerDialog() {
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;
    final int currentYear = DateTime.now().year;

    final List<String> monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filtrar Noticias"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Mes:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<int>(
                        value: tempMonth,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(monthNames[index]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null)
                            setDialogState(() => tempMonth = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Año:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<int>(
                        value: tempYear,
                        items: List.generate(5, (index) {
                          int year = currentYear - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => tempYear = val);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedYear = tempYear;
                  _selectedMonth = tempMonth;
                });
                _fetchRealNews();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text("Buscar"),
            ),
          ],
        );
      },
    );
  }

  // Portadas generadas con código para que simulen una imagen
  // de fondo bonita y abstracta de seguridad sin depender de internet.
  Widget _buildFallbackImage(int index) {
    final List<List<Color>> gradientColors = [
      [Colors.blue.shade900, Colors.blue.shade600], // Estilo Policial
      [
        Colors.grey.shade900,
        Colors.grey.shade600,
      ], // Estilo Oscuro/Periodístico
      [Colors.indigo.shade900, Colors.indigo.shade500], // Estilo Noche
      [Colors.blueGrey.shade900, Colors.blueGrey.shade600], // Estilo Serio
    ];

    final List<IconData> referenceIcons = [
      Icons.local_police_rounded,
      Icons.security_rounded,
      Icons.policy_rounded,
      Icons.shield_rounded,
    ];

    final colorPair = gradientColors[index % gradientColors.length];
    final selectedIcon = referenceIcons[index % referenceIcons.length];

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorPair,
        ),
      ),
      child: Center(
        child: Icon(
          selectedIcon,
          size: 80,
          color: Colors.white.withAlpha(
            50,
          ), // Un gris casi transparente para que sea "fondo"
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Noticias de Seguridad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _showDatePickerDialog,
            tooltip: "Filtrar por fecha",
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _isLoading ? null : _fetchRealNews,
            tooltip: "Refrescar noticias",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRealNews,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
            : _errorMessage.isNotEmpty
            ? _buildErrorView()
            : _newsList.isEmpty
            ? _buildEmptyView()
            : _buildNewsList(),
      ),
    );
  }

  Widget _buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _fetchRealNews,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reintentar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No hay noticias relevantes en Tacna por ahora.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateToSpanish(String rawDate) {
    if (rawDate.isEmpty) return '';
    // Ejemplo date raw: "Wed, 15 Apr 2026 12:00:00 GMT" -> Cortamos a "Wed, 15 Apr 2026"
    String dateStr = rawDate.length > 16 ? rawDate.substring(0, 16) : rawDate;

    final Map<String, String> replacements = {
      'Mon,': 'Lun,',
      'Tue,': 'Mar,',
      'Wed,': 'Mié,',
      'Thu,': 'Jue,',
      'Fri,': 'Vie,',
      'Sat,': 'Sáb,',
      'Sun,': 'Dom,',
      'Jan': 'Ene',
      'Feb': 'Feb',
      'Mar': 'Mar',
      'Apr': 'Abr',
      'May': 'May',
      'Jun': 'Jun',
      'Jul': 'Jul',
      'Aug': 'Ago',
      'Sep': 'Sep',
      'Oct': 'Oct',
      'Nov': 'Nov',
      'Dec': 'Dic',
    };

    replacements.forEach((en, es) {
      dateStr = dateStr.replaceAll(en, es);
    });

    return dateStr;
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
          final String title = news['title']!;
          final String source = news['source']!;
          final String link = news['link']!;
          final String pubDateRaw = news['pubDate']!;

          // Traducir y formatear la fecha
          final String pubDate = _formatDateToSpanish(pubDateRaw);

          return Card(
            elevation: 4,
            shadowColor: Colors.black.withAlpha(25),
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            color: Theme.of(context).cardColor,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _launchURL(link),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contenedor de la Imagen con Gradiente sobrepuesto
                  Stack(
                    children: [
                      _buildFallbackImage(index),
                      // Sombra gradiente inferior para que contraste con las etiquetas
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withAlpha(180),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Etiqueta de la Fuente (Radio Uno, Correo, etc)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade700,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.language,
                                color: Colors.white,
                                size: 14,
                              ),
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
                        bottom: 12,
                        right: 12,
                        child: Text(
                          pubDate,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Cuerpo del texto de la noticia
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            color: Theme.of(context).colorScheme.onSurface,
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
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
