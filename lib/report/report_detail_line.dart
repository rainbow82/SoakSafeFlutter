class ReportDetailLine {
  const ReportDetailLine({
    required this.label,
    this.valueText,
    this.showCheckmark = false,
  });

  final String label;
  final String? valueText;
  final bool showCheckmark;

  factory ReportDetailLine.taskDone(String label) =>
      ReportDetailLine(label: label, showCheckmark: true);

  factory ReportDetailLine.chemical(String label, String value) =>
      ReportDetailLine(label: label, valueText: value);
}
