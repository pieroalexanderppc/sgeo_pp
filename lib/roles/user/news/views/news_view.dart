import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:convert';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/safety_button.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<String> monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.calendar_month, color: AppTheme.accentBlue, size: 22),
              const SizedBox(width: 10),
              const Text("Filtrar Noticias"),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Mes:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.textSecondary : null,
                        ),
                      ),
                      DropdownButton<int>(
                        value: tempMonth,
                        dropdownColor: isDark ? AppTheme.bgElevated : null,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(monthNames[index]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => tempMonth = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Año:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.textSecondary : null,
                        ),
                      ),
                      DropdownButton<int>(
                        value: tempYear,
                        dropdownColor: isDark ? AppTheme.bgElevated : null,
                        items: List.generate(5, (index) {
                          int year = currentYear - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => tempYear = val);
                          }
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
              child: Text(
                "Cancelar",
                style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedYear = tempYear;
                  _selectedMonth = tempMonth;
                });
                _fetchRealNews();
              },
              child: Text(
                "Buscar",
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Portadas generadas con código — gradientes tácticos
  Widget _buildFallbackImage(int index) {
    final List<List<Color>> gradientColors = [
      [const Color(0xFF0D1B2A), const Color(0xFF1B2838)],  // Táctico profundo
      [const Color(0xFF1A1A2E), const Color(0xFF16213E)],  // Noche índigo
      [const Color(0xFF0F0E17), const Color(0xFF1A1F36)],  // Oscuro premium
      [const Color(0xFF141E30), const Color(0xFF243B55)],  // Naval
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
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorPair,
        ),
      ),
      child: Stack(
        children: [
          // Patrón de glow sutil
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentBlue.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              selectedIcon,
              size: 72,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafetyLayout(
      showGradientBackground: true,
      appBar: AppBar(
        title: const Text('Noticias de Seguridad'),
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
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? _buildErrorView()
            : _newsList.isEmpty
            ? _buildEmptyView()
            : _buildNewsList(),
      ),
    );
  }

  Widget _buildErrorView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppTheme.bgSurface : Colors.grey.shade100,
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 56,
                      color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppTheme.textSecondary : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SafetyButton(
                    label: 'Reintentar',
                    icon: Icons.refresh,
                    expand: false,
                    onPressed: _fetchRealNews,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppTheme.bgSurface : Colors.grey.shade100,
                  ),
                  child: Icon(
                    Icons.feed_outlined,
                    size: 56,
                    color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "No hay noticias relevantes",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textSecondary : Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Intenta con otra fecha o actualiza",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.textMuted : Colors.grey.shade500,
                  ),
                ),
              ],
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 500.ms),
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
      'Mon,': 'Lun,', 'Tue,': 'Mar,', 'Wed,': 'Mié,', 'Thu,': 'Jue,',
      'Fri,': 'Vie,', 'Sat,': 'Sáb,', 'Sun,': 'Dom,',
      'Jan': 'Ene', 'Feb': 'Feb', 'Mar': 'Mar', 'Apr': 'Abr',
      'May': 'May', 'Jun': 'Jun', 'Jul': 'Jul', 'Aug': 'Ago',
      'Sep': 'Sep', 'Oct': 'Oct', 'Nov': 'Nov', 'Dec': 'Dic',
    };

    replacements.forEach((en, es) {
      dateStr = dateStr.replaceAll(en, es);
    });

    return dateStr;
  }

  Widget _buildNewsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _fetchRealNews,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        itemCount: _newsList.length,
        itemBuilder: (context, index) {
          final news = _newsList[index];
          final String title = news['title']!;
          final String source = news['source']!;
          final String link = news['link']!;
          final String pubDateRaw = news['pubDate']!;

          // Traducir y formatear la fecha
          final String pubDate = _formatDateToSpanish(pubDateRaw);

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderTactical, width: 0.5),
              boxShadow: isDark
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -2)]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
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
                                Colors.black.withValues(alpha: 0.7),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.alertRed.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.language, color: Colors.white, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                source.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
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
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            color: isDark ? AppTheme.textPrimary : null,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Toca para leer el artículo",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textMuted : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark ? AppTheme.accentBlueLight : AppTheme.accentBlue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 60 * index), duration: 350.ms)
          .slideY(begin: 0.05, end: 0, duration: 350.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}
