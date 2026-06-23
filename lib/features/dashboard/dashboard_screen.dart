import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardScreen extends StatelessWidget {
  final bool seniorMode;
  final Function(bool) onToggleSenior;

  const DashboardScreen({
    Key? key,
    required this.seniorMode,
    required this.onToggleSenior,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return isWide ? _buildWideLayout(context) : _buildNarrowLayout(context);
      },
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        _Sidebar(),
        Expanded(
          child: _DashboardContent(seniorMode: seniorMode),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return _DashboardContent(seniorMode: seniorMode);
  }
}

class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: const Color(0xFF0D3B7A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CivicOS+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _SidebarItem(
                  label: 'Dashboard', icon: Icons.dashboard, active: true),
              _SidebarItem(label: 'Segnalazioni', icon: Icons.report_problem),
              _SidebarItem(label: 'Rifiuti', icon: Icons.delete_outline),
              _SidebarItem(label: 'Statistiche', icon: Icons.bar_chart),
              _SidebarItem(label: 'Impostazioni', icon: Icons.settings),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;

  const _SidebarItem({
    required this.label,
    required this.icon,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(icon,
              color: Colors.white.withOpacity(active ? 1 : 0.75), size: 20),
          title: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(active ? 1 : 0.75),
              fontSize: 14,
            ),
          ),
          onTap: () {},
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final bool seniorMode;

  const _DashboardContent({required this.seniorMode});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        final pad = isMobile ? 16.0 : 24.0;
        final gap = isMobile ? 16.0 : 24.0;
        return Container(
          color: const Color(0xFFF8FAFD),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Operatori',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF0D3B7A),
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 20 : null,
                      ),
                ),
                SizedBox(height: gap),
                _StatsRow(),
                SizedBox(height: gap),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final mapHeight =
                        w > 700 ? 350.0 : (w * 0.55).clamp(200.0, 350.0);
                    final chartHeight = w > 700 ? 350.0 : 220.0;
                    if (w > 700) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                                flex: 2, child: _MapCard(height: mapHeight)),
                            const SizedBox(width: 20),
                            Expanded(
                                flex: 1,
                                child: _ChartCard(height: chartHeight)),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        _MapCard(height: mapHeight),
                        const SizedBox(height: 16),
                        _ChartCard(height: chartHeight),
                      ],
                    );
                  },
                ),
                SizedBox(height: gap),
                _ReportsTable(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'title': 'Segnalazioni',
        'value': '128',
        'icon': Icons.flag,
        'color': const Color(0xFF0D3B7A)
      },
      {
        'title': 'In lavorazione',
        'value': '34',
        'icon': Icons.build,
        'color': const Color(0xFFF57C00)
      },
      {
        'title': 'Risolte',
        'value': '76',
        'icon': Icons.check_circle,
        'color': const Color(0xFF00897B)
      },
      {
        'title': 'Nuove oggi',
        'value': '18',
        'icon': Icons.new_releases,
        'color': const Color(0xFFE53935)
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w > 600 ? 4 : 2;
        final spacing = 12.0;
        final cardWidth = (w - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats.map((s) {
            return SizedBox(
              width: cardWidth,
              child: _StatCard(
                title: s['title'] as String,
                value: s['value'] as String,
                icon: s['icon'] as IconData,
                color: s['color'] as Color,
                compact: w < 380,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: compact ? 14 : 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final double height;
  const _MapCard({this.height = 350});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mappa Segnalazioni',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(41.9, 12.5),
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.civicos.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: const LatLng(41.91, 12.48),
                        width: 40,
                        height: 40,
                        child: const _MapPin(
                            label: 'Rifiuti', color: Color(0xFFE53935)),
                      ),
                      Marker(
                        point: const LatLng(41.89, 12.50),
                        width: 40,
                        height: 40,
                        child: const _MapPin(
                            label: 'Lampione', color: Color(0xFFF57C00)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final String label;
  final Color color;

  const _MapPin({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Icon(Icons.location_on, color: color, size: 36),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final double height;
  const _ChartCard({this.height = 350});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attività settimanale',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: height,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 25,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Lun',
                          'Mar',
                          'Mer',
                          'Gio',
                          'Ven',
                          'Sab',
                          'Dom'
                        ];
                        if (value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(days[value.toInt()],
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 11));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [12, 19, 8, 14, 10, 6, 9].asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: const Color(0xFF0D3B7A),
                        width: height < 300 ? 12 : 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reports = [
      {
        'id': '#321',
        'tipo': 'Rifiuti',
        'zona': 'Via Roma',
        'stato': 'Aperta',
        'statusColor': const Color(0xFFE53935)
      },
      {
        'id': '#322',
        'tipo': 'Strada',
        'zona': 'Via Milano',
        'stato': 'In lavorazione',
        'statusColor': const Color(0xFFF57C00)
      },
      {
        'id': '#323',
        'tipo': 'Illuminazione',
        'zona': 'Piazza Italia',
        'stato': 'Risolta',
        'statusColor': const Color(0xFF00897B)
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ultime segnalazioni',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333)),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                children: [
                  _headerCell('ID'),
                  _headerCell('Tipo'),
                  _headerCell('Zona'),
                  _headerCell('Stato'),
                ],
              ),
              ...reports.map((r) => TableRow(
                    decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Colors.grey[100]!)),
                    ),
                    children: [
                      _dataCell(r['id'] as String),
                      _dataCell(r['tipo'] as String),
                      _dataCell(r['zona'] as String),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        child: Text(
                          r['stato'] as String,
                          style: TextStyle(
                            color: r['statusColor'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _dataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(text),
    );
  }
}
