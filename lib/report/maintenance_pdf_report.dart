import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/models/models.dart';
import 'package:soaksafe/report/report_event_rows.dart';

abstract final class MaintenancePdfReport {
  static const _headerColor = PdfColor.fromInt(0xFF006494);
  static const _rowAltColor = PdfColor.fromInt(0xFFF7F9FC);
  static const _titleColor = PdfColor.fromInt(0xFF0A1628);
  static const _subColor = PdfColor.fromInt(0xFF374151);
  static const _bodyColor = PdfColor.fromInt(0xFF111827);

  static Future<Uint8List> build({
    required List<MaintenanceEventRecord> events,
    required String ownerLine,
  }) async {
    final rowTime = DateFormat('MM/dd/yyyy hh:mm a');
    final generated = DateFormat('MM/dd/yyyy HH:mm z').format(DateTime.now());

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              AppStrings.pdfReportDocumentTitle,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: _titleColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              AppStrings.pdfReportGeneratedLine(generated),
              style: const pw.TextStyle(fontSize: 11, color: _subColor),
            ),
          ];

          if (ownerLine.isNotEmpty) {
            widgets.add(
              pw.Text(
                ownerLine,
                style: const pw.TextStyle(fontSize: 11, color: _subColor),
              ),
            );
          }

          widgets.addAll([
            pw.SizedBox(height: 12),
            _tableHeader(),
            pw.SizedBox(height: 4),
          ]);

          if (events.isEmpty) {
            widgets.add(
              pw.Text(
                AppStrings.reportNoEvents,
                style: const pw.TextStyle(fontSize: 10, color: _bodyColor),
              ),
            );
          } else {
            var alt = false;
            for (final event in events) {
              final time = rowTime.format(
                DateTime.fromMillisecondsSinceEpoch(event.eventTimeMillis),
              );
              final snapshotLabel =
                  '${event.target.label} — ${AppStrings.reportCardSubtitle}';

              widgets.add(_dataRow(
                time,
                snapshotLabel,
                '—',
                alt: alt,
              ));
              alt = !alt;

              for (final line in ReportEventRows.buildDetailRows(event)) {
                final value = line.showCheckmark
                    ? AppStrings.pdfValueCompleted
                    : (line.valueText ?? '');
                widgets.add(_dataRow(time, line.label, value, alt: alt));
                alt = !alt;
              }

              widgets.add(pw.SizedBox(height: 6));
            }
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _tableHeader() {
    return pw.Container(
      color: _headerColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              AppStrings.pdfColDatetime,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              AppStrings.pdfColItem,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              AppStrings.pdfColValueStatus,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _dataRow(
    String dateTime,
    String item,
    String value, {
    required bool alt,
  }) {
    return pw.Container(
      color: alt ? _rowAltColor : PdfColors.white,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              dateTime,
              style: const pw.TextStyle(fontSize: 10, color: _bodyColor),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              item,
              style: const pw.TextStyle(fontSize: 10, color: _bodyColor),
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10, color: _bodyColor),
            ),
          ),
        ],
      ),
    );
  }
}
