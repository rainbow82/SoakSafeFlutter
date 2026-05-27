import 'package:soaksafe/core/models/models.dart';
import 'package:soaksafe/core/utils/codecs.dart';
import 'package:soaksafe/report/report_detail_line.dart';

abstract final class ReportEventRows {
  static List<ReportDetailLine> buildDetailRows(MaintenanceEventRecord row) {
    final lines = <ReportDetailLine>[];
    for (final item in LineItemsCodec.resolveLineItems(row)) {
      if (item.amount == null) {
        lines.add(ReportDetailLine.taskDone(item.label));
      } else if (item.amount! > 0) {
        lines.add(ReportDetailLine.chemical(item.label, formatChem(item.amount!)));
      }
    }
    return lines;
  }

  static String formatChem(double value) => value.toStringAsFixed(2);
}
