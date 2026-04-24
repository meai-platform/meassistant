import 'package:flutter/material.dart';

/// Table card widget
class TableCard extends StatelessWidget {
  final List<List<String>> tableRows;
  final String? fontFamily;

  const TableCard({
    super.key,
    required this.tableRows,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    if (tableRows.isEmpty) return const SizedBox.shrink();

    final headers = tableRows.first;
    final rows = tableRows.skip(1).toList();

    final scrollController = ScrollController();

    return Container(
      decoration: BoxDecoration(
        gradient: SweepGradient(
          startAngle: 0,
          endAngle: 6.28319, // 2 * pi
          colors: [
            const Color(0xFFA829F0), // top-left
            const Color(0xFF5E308B), // fade
            Colors.white.withValues(alpha: 0.7), // top-right
            Colors.white.withValues(alpha: 0.7), // bottom-left
            const Color(0xFFA829F0), // bottom-right
            const Color(0xFF5E308B), // fade
            Colors.white.withValues(alpha: 0.7), // closing loop
          ],
          stops: const [0.0, 0.15, 0.35, 0.45, 0.50, 0.70, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(1), // Border thickness
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: scrollController,
          child: DataTable(
              columns: headers
                  .map((h) => DataColumn(
                        label: Text(
                          h,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xff0f0f0f), // dark1000
                            fontWeight: FontWeight.w300,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ))
                  .toList(),
              rows: rows.map((row) {
                return DataRow(
                  cells: row
                      .map((cell) => DataCell(
                            Text(
                              cell.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xff26262B), // dark900
                                fontWeight: FontWeight.w300,
                                fontFamily: fontFamily,
                              ),
                            ),
                          ))
                      .toList(),
                );
              }).toList(),
              headingRowHeight: 40,
              dataRowMaxHeight: 40,
              dataRowMinHeight: 10,
              columnSpacing: 30,
            ),
        ),
      ),
    );
  }
}

