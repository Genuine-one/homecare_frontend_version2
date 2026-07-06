/// KLE HOMECARE — MIS Report Excel export builders.
///
/// Pure builder functions: they assemble the workbook bytes and a suggested
/// file name. Saving to disk and showing progress/result UI stays with the
/// caller (the Resources tab), since that's where BuildContext/mounted live.
import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import '../../providers/mis_report_provider.dart';

class MisExcelResult {
  final List<int> bytes;
  final String fileName;
  const MisExcelResult(this.bytes, this.fileName);
}

/// Two-sheet workbook for a single resource: revenue summary + job details.
MisExcelResult buildResourceExcel(
  ResourceReportItem resource,
  MisReportState state,
  String periodLabel,
) {
  // ── Color palette ──────────────────────────────────────────────────
  final cPurple     = xl.ExcelColor.fromHexString('FF6A1B9A');
  final cPurpleMed  = xl.ExcelColor.fromHexString('FF8E24AA');
  final cPurpleHdr  = xl.ExcelColor.fromHexString('FFAB47BC');
  final cPurplePale = xl.ExcelColor.fromHexString('FFF3E5F5');
  final cWhite      = xl.ExcelColor.fromHexString('FFFFFFFF');
  final cGrey       = xl.ExcelColor.fromHexString('FFF5F5F5');
  final cGreyMed    = xl.ExcelColor.fromHexString('FFE0E0E0');
  final cGreen      = xl.ExcelColor.fromHexString('FF1B5E20');
  final cGreenBg    = xl.ExcelColor.fromHexString('FFE8F5E9');
  final cBlue       = xl.ExcelColor.fromHexString('FF0D47A1');
  final cOrange     = xl.ExcelColor.fromHexString('FFE65100');
  final cRed        = xl.ExcelColor.fromHexString('FFB71C1C');
  final cViolet     = xl.ExcelColor.fromHexString('FF4A148C');
  final cTextDark   = xl.ExcelColor.fromHexString('FF1A202C');
  final cTextGrey   = xl.ExcelColor.fromHexString('FF757575');
  final cBorderPurple = xl.ExcelColor.fromHexString('FFCE93D8');
  final cBorderLight  = xl.ExcelColor.fromHexString('FFE1BEE7');

  // ── Helpers ────────────────────────────────────────────────────────
  xl.Border thinBdr(xl.ExcelColor color) =>
      xl.Border(borderStyle: xl.BorderStyle.Thin, borderColorHex: color);
  xl.Border medBdr(xl.ExcelColor color) =>
      xl.Border(borderStyle: xl.BorderStyle.Medium, borderColorHex: color);

  void sc(
    xl.Sheet sh, int col, int row, dynamic value, {
    bool bold = false,
    int fontSize = 10,
    xl.ExcelColor? fg,
    xl.ExcelColor? bg,
    xl.HorizontalAlign align = xl.HorizontalAlign.Left,
    bool dataBorder = false,
    bool headerBorder = false,
  }) {
    final cell = sh.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is int) {
      cell.value = xl.IntCellValue(value);
    } else if (value is double) {
      cell.value = xl.DoubleCellValue(value);
    } else {
      cell.value = xl.TextCellValue((value ?? '').toString());
    }
    final bdr = dataBorder ? thinBdr(cBorderLight) : null;
    final hBdr = headerBorder ? medBdr(cBorderPurple) : null;
    cell.cellStyle = xl.CellStyle(
      bold: bold,
      fontSize: fontSize,
      fontColorHex: fg ?? cTextDark,
      backgroundColorHex: bg ?? xl.ExcelColor.none,
      horizontalAlign: align,
      verticalAlign: xl.VerticalAlign.Center,
      leftBorder:   hBdr ?? bdr ?? xl.Border(),
      rightBorder:  hBdr ?? bdr ?? xl.Border(),
      topBorder:    hBdr ?? bdr ?? xl.Border(),
      bottomBorder: hBdr ?? bdr ?? xl.Border(),
    );
  }

  void mergeRow(xl.Sheet sh, int row, int fromCol, int toCol) {
    sh.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: fromCol, rowIndex: row),
      xl.CellIndex.indexByColumnRow(columnIndex: toCol,   rowIndex: row),
    );
  }

  final now = DateFormat('dd MMM yyyy  HH:mm').format(DateTime.now());

  // ══════════════════════════════════════════════════════════════════
  // SHEET 1 — Resource Revenue Summary
  // ══════════════════════════════════════════════════════════════════
  final xcel = xl.Excel.createExcel();
  final s1 = xcel['Resource Revenue'];

  // Column widths (0-based)
  s1.setColumnWidth(0, 5.5);   // #
  s1.setColumnWidth(1, 24.0);  // Resource Name
  s1.setColumnWidth(2, 16.0);  // Category
  s1.setColumnWidth(3, 11.0);  // Accepted
  s1.setColumnWidth(4, 11.0);  // Completed
  s1.setColumnWidth(5, 12.0);  // In Progress
  s1.setColumnWidth(6, 10.0);  // Pending
  s1.setColumnWidth(7, 14.0);  // Completion %
  s1.setColumnWidth(8, 16.0);  // Revenue (INR)

  // Row 0 — Company title banner (merged A1:I1)
  mergeRow(s1, 0, 0, 8);
  sc(s1, 0, 0, 'KLE HOMECARE  –  RESOURCE REVENUE REPORT',
      bold: true, fontSize: 14, fg: cWhite, bg: cPurple,
      align: xl.HorizontalAlign.Center, headerBorder: true);
  s1.setRowHeight(0, 32);

  // Row 1 — Period left | Generated right
  mergeRow(s1, 1, 0, 4);
  sc(s1, 0, 1, '  Period :  $periodLabel',
      fontSize: 10, fg: cWhite, bg: cPurpleMed,
      align: xl.HorizontalAlign.Left, headerBorder: true);
  mergeRow(s1, 1, 5, 8);
  sc(s1, 5, 1, 'Generated :  $now  ',
      fontSize: 10, fg: cWhite, bg: cPurpleMed,
      align: xl.HorizontalAlign.Right, headerBorder: true);
  s1.setRowHeight(1, 22);

  // Row 2 — thin purple divider
  for (int c = 0; c <= 8; c++) {
    sc(s1, c, 2, '', bg: cPurple);
  }
  s1.setRowHeight(2, 5);

  // Row 3 — Column headers
  const s1H = ['#', 'Resource Name', 'Category', 'Accepted',
    'Completed', 'In Progress', 'Pending', 'Completion %', 'Revenue (INR)'];
  const s1A = [
    xl.HorizontalAlign.Center, xl.HorizontalAlign.Left,
    xl.HorizontalAlign.Left,   xl.HorizontalAlign.Center,
    xl.HorizontalAlign.Center, xl.HorizontalAlign.Center,
    xl.HorizontalAlign.Center, xl.HorizontalAlign.Center,
    xl.HorizontalAlign.Right,
  ];
  for (var c = 0; c < s1H.length; c++) {
    sc(s1, c, 3, s1H[c], bold: true, fontSize: 10,
        fg: cWhite, bg: cPurpleHdr, align: s1A[c], headerBorder: true);
  }
  s1.setRowHeight(3, 26);

  // Row 4 — Data row
  final rate = resource.jobsAccepted > 0
      ? resource.jobsCompleted / resource.jobsAccepted * 100
      : 0.0;
  sc(s1, 0, 4, 1,
      align: xl.HorizontalAlign.Center, bg: cWhite, dataBorder: true);
  sc(s1, 1, 4, resource.name, bold: true, bg: cWhite, dataBorder: true);
  sc(s1, 2, 4, resource.category ?? '—', bg: cWhite, dataBorder: true,
      fg: cTextGrey);
  sc(s1, 3, 4, resource.jobsAccepted,
      align: xl.HorizontalAlign.Center, bg: cWhite,
      dataBorder: true, fg: cBlue, bold: true);
  sc(s1, 4, 4, resource.jobsCompleted,
      align: xl.HorizontalAlign.Center, bg: cGreenBg,
      dataBorder: true, fg: cGreen, bold: true);
  sc(s1, 5, 4, resource.jobsInProgress,
      align: xl.HorizontalAlign.Center, bg: cWhite,
      dataBorder: true, fg: cViolet);
  sc(s1, 6, 4, resource.jobsPending,
      align: xl.HorizontalAlign.Center, bg: cWhite,
      dataBorder: true, fg: cOrange);
  sc(s1, 7, 4, '${rate.toStringAsFixed(1)}%',
      align: xl.HorizontalAlign.Center, bg: cWhite, dataBorder: true,
      bold: rate >= 80,
      fg: rate >= 80 ? cGreen : cOrange);
  sc(s1, 8, 4, resource.revenue.toInt(),
      align: xl.HorizontalAlign.Right, bg: cGreenBg,
      dataBorder: true, fg: cGreen, bold: true);
  s1.setRowHeight(4, 24);

  // Row 5 — light divider
  for (int c = 0; c <= 8; c++) sc(s1, c, 5, '', bg: cGreyMed);
  s1.setRowHeight(5, 6);

  int nextRow = 6;

  // Service Breakdown (if available)
  if (resource.serviceBreakdown.isNotEmpty) {
    mergeRow(s1, nextRow, 0, 8);
    sc(s1, 0, nextRow, '  SERVICE BREAKDOWN',
        bold: true, fontSize: 10, fg: cWhite, bg: cPurpleMed,
        align: xl.HorizontalAlign.Left, headerBorder: true);
    s1.setRowHeight(nextRow, 24);
    nextRow++;

    // Sub-headers
    sc(s1, 0, nextRow, '#', bold: true, fg: cWhite, bg: cPurpleHdr,
        align: xl.HorizontalAlign.Center, headerBorder: true);
    sc(s1, 1, nextRow, 'Service Type', bold: true, fg: cWhite,
        bg: cPurpleHdr, headerBorder: true);
    sc(s1, 2, nextRow, 'Count', bold: true, fg: cWhite, bg: cPurpleHdr,
        align: xl.HorizontalAlign.Center, headerBorder: true);
    for (int c = 3; c <= 8; c++) {
      sc(s1, c, nextRow, '', bg: cPurpleHdr, headerBorder: true);
    }
    s1.setRowHeight(nextRow, 24);
    nextRow++;

    for (var i = 0; i < resource.serviceBreakdown.length; i++) {
      final b   = resource.serviceBreakdown[i];
      final rbg = i.isEven ? cWhite : cPurplePale;
      sc(s1, 0, nextRow, i + 1,
          align: xl.HorizontalAlign.Center, bg: rbg, dataBorder: true);
      sc(s1, 1, nextRow, b['service_type'] as String? ?? '',
          bg: rbg, dataBorder: true);
      sc(s1, 2, nextRow, (b['count'] as num?)?.toInt() ?? 0,
          align: xl.HorizontalAlign.Center, bg: rbg, dataBorder: true,
          bold: true, fg: cPurpleMed);
      for (int c = 3; c <= 8; c++) sc(s1, c, nextRow, '', bg: rbg);
      s1.setRowHeight(nextRow, 22);
      nextRow++;
    }
    // spacer after breakdown
    for (int c = 0; c <= 8; c++) sc(s1, c, nextRow, '', bg: cGreyMed);
    s1.setRowHeight(nextRow, 5);
    nextRow++;
  }

  // Footer row
  mergeRow(s1, nextRow, 0, 8);
  sc(s1, 0, nextRow,
      'KLE Homecare Management System  |  This report is confidential.',
      fontSize: 8, fg: cTextGrey, bg: cGrey,
      align: xl.HorizontalAlign.Center);
  s1.setRowHeight(nextRow, 18);

  // ══════════════════════════════════════════════════════════════════
  // SHEET 2 — Employee Job Details
  // ══════════════════════════════════════════════════════════════════
  final s2 = xcel['Employee Job Details'];

  // Column widths
  s2.setColumnWidth(0, 5.0);   // #
  s2.setColumnWidth(1, 22.0);  // Patient Name
  s2.setColumnWidth(2, 14.0);  // Contact
  s2.setColumnWidth(3, 20.0);  // Service Type
  s2.setColumnWidth(4, 14.0);  // Status
  s2.setColumnWidth(5, 14.0);  // Preferred Date
  s2.setColumnWidth(6, 7.0);   // Days
  s2.setColumnWidth(7, 16.0);  // Total Amount
  s2.setColumnWidth(8, 16.0);  // Paid Amount

  // Row 0 — Title
  mergeRow(s2, 0, 0, 8);
  sc(s2, 0, 0,
      'EMPLOYEE JOB DETAILS  ·  ${resource.name.toUpperCase()}',
      bold: true, fontSize: 13, fg: cWhite, bg: cPurple,
      align: xl.HorizontalAlign.Center, headerBorder: true);
  s2.setRowHeight(0, 32);

  // Row 1 — Period + Category + Generated
  mergeRow(s2, 1, 0, 8);
  sc(s2, 0, 1,
      '  Period: $periodLabel    |    '
      'Category: ${resource.category ?? "—"}    |    '
      'Generated: $now  ',
      fontSize: 10, fg: cWhite, bg: cPurpleMed,
      align: xl.HorizontalAlign.Center, headerBorder: true);
  s2.setRowHeight(1, 22);

  // Row 2 — thin divider
  for (int c = 0; c <= 8; c++) sc(s2, c, 2, '', bg: cPurple);
  s2.setRowHeight(2, 5);

  // Row 3 — Column headers
  const s2H = [
    '#', 'Patient Name', 'Contact', 'Service Type', 'Status',
    'Preferred Date', 'Days', 'Total Amt (INR)', 'Paid Amt (INR)',
  ];
  const s2A = [
    xl.HorizontalAlign.Center, xl.HorizontalAlign.Left,
    xl.HorizontalAlign.Center, xl.HorizontalAlign.Left,
    xl.HorizontalAlign.Center, xl.HorizontalAlign.Center,
    xl.HorizontalAlign.Center, xl.HorizontalAlign.Right,
    xl.HorizontalAlign.Right,
  ];
  for (var c = 0; c < s2H.length; c++) {
    sc(s2, c, 3, s2H[c], bold: true, fontSize: 10,
        fg: cWhite, bg: cPurpleHdr, align: s2A[c], headerBorder: true);
  }
  s2.setRowHeight(3, 26);

  final jobs = state.patientServiceReport
      .where((j) => j.assignedResource == resource.name)
      .toList();

  if (jobs.isEmpty) {
    mergeRow(s2, 4, 0, 8);
    sc(s2, 0, 4, 'No detailed job records found for this period.',
        fg: cTextGrey, bg: cGrey,
        align: xl.HorizontalAlign.Center, dataBorder: true);
    s2.setRowHeight(4, 24);
  } else {
    for (var idx = 0; idx < jobs.length; idx++) {
      final j      = jobs[idx];
      final rowIdx = 4 + idx;
      final rowBg  = idx.isEven ? cWhite : cPurplePale;

      // Status colour coding
      xl.ExcelColor sBg, sFg;
      switch (j.status) {
        case 'completed':
          sBg = xl.ExcelColor.fromHexString('FFE8F5E9');
          sFg = cGreen;
        case 'in_progress':
          sBg = xl.ExcelColor.fromHexString('FFEDE7F6');
          sFg = cViolet;
        case 'assigned':
          sBg = xl.ExcelColor.fromHexString('FFE3F2FD');
          sFg = cBlue;
        case 'cancelled':
          sBg = xl.ExcelColor.fromHexString('FFFFEBEE');
          sFg = cRed;
        default:
          sBg = xl.ExcelColor.fromHexString('FFFFF3E0');
          sFg = cOrange;
      }
      final statusLabel = j.status
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? '' :
                '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

      sc(s2, 0, rowIdx, idx + 1,
          align: xl.HorizontalAlign.Center, bg: rowBg, dataBorder: true);
      sc(s2, 1, rowIdx, j.patientName,
          bold: true, bg: rowBg, dataBorder: true);
      sc(s2, 2, rowIdx, j.contactNumber ?? '—',
          align: xl.HorizontalAlign.Center, bg: rowBg, dataBorder: true,
          fg: cTextGrey);
      sc(s2, 3, rowIdx, j.serviceType, bg: rowBg, dataBorder: true);
      sc(s2, 4, rowIdx, statusLabel,
          bold: true, align: xl.HorizontalAlign.Center,
          fg: sFg, bg: sBg, dataBorder: true);
      sc(s2, 5, rowIdx, j.preferredDate ?? '—',
          align: xl.HorizontalAlign.Center, bg: rowBg, dataBorder: true);
      sc(s2, 6, rowIdx, j.numDays,
          align: xl.HorizontalAlign.Center, bg: rowBg, dataBorder: true);
      sc(s2, 7, rowIdx, j.totalAmount?.toInt() ?? 0,
          align: xl.HorizontalAlign.Right, bg: rowBg,
          dataBorder: true, fg: cGreen);
      final isPaid = j.paidAmount != null && j.totalAmount != null &&
          j.paidAmount! >= j.totalAmount!;
      sc(s2, 8, rowIdx, j.paidAmount?.toInt() ?? 0,
          align: xl.HorizontalAlign.Right, bold: isPaid,
          bg: isPaid ? cGreenBg : rowBg,
          dataBorder: true, fg: cGreen);
      s2.setRowHeight(rowIdx, 22);
    }

    // Totals row
    final totalRow = 4 + jobs.length;
    final totalAmt = jobs.fold<double>(
        0, (s, j) => s + (j.totalAmount ?? 0));
    final paidAmt  = jobs.fold<double>(
        0, (s, j) => s + (j.paidAmount  ?? 0));

    sc(s2, 0, totalRow, '', bg: cPurplePale, headerBorder: true);
    mergeRow(s2, totalRow, 1, 6);
    sc(s2, 1, totalRow,
        'TOTAL   (${jobs.length} job${jobs.length == 1 ? '' : 's'})',
        bold: true, fg: cPurple, bg: cPurplePale,
        align: xl.HorizontalAlign.Right, headerBorder: true);
    sc(s2, 7, totalRow, totalAmt.toInt(),
        bold: true, align: xl.HorizontalAlign.Right,
        fg: cGreen, bg: cGreenBg, headerBorder: true);
    sc(s2, 8, totalRow, paidAmt.toInt(),
        bold: true, align: xl.HorizontalAlign.Right,
        fg: cGreen, bg: cGreenBg, headerBorder: true);
    s2.setRowHeight(totalRow, 26);

    // Spacer + footer
    final footerRow = totalRow + 1;
    for (int c = 0; c <= 8; c++) sc(s2, c, footerRow, '', bg: cGreyMed);
    s2.setRowHeight(footerRow, 5);

    final fr2 = footerRow + 1;
    mergeRow(s2, fr2, 0, 8);
    sc(s2, 0, fr2,
        'KLE Homecare Management System  |  This report is confidential.',
        fontSize: 8, fg: cTextGrey, bg: cGrey,
        align: xl.HorizontalAlign.Center);
    s2.setRowHeight(fr2, 18);
  }

  // Delete default Sheet1 AFTER all sheets are set up
  xcel.delete('Sheet1');

  final bytes = xcel.save();
  if (bytes == null) throw Exception('Failed to encode Excel');
  final safeName  = resource.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  final safeLabel = periodLabel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  return MisExcelResult(bytes, 'KLE_${safeName}_$safeLabel.xlsx');
}

/// Two-sheet workbook: overall resources revenue + patients grouped by
/// assigned resource (respects the currently active filters).
MisExcelResult buildOverallResourcesExcel(
  MisReportState state,
  String periodLabel,
) {
  // ── Color palette ────────────────────────────────────────────────────
  final cPurple   = xl.ExcelColor.fromHexString('FF6A1B9A');
  final cPurpleLt = xl.ExcelColor.fromHexString('FFECE0F5');
  final cPurpleMd = xl.ExcelColor.fromHexString('FFD1A8EA');
  final cGreen    = xl.ExcelColor.fromHexString('FF2E7D32');
  final cGreenLt  = xl.ExcelColor.fromHexString('FFE8F5E9');
  final cAmber    = xl.ExcelColor.fromHexString('FFF57F17');
  final cAmberLt  = xl.ExcelColor.fromHexString('FFFFF8E1');
  final cBlue     = xl.ExcelColor.fromHexString('FF1565C0');
  final cBlueLt   = xl.ExcelColor.fromHexString('FFE3F2FD');
  final cRed      = xl.ExcelColor.fromHexString('FFB71C1C');
  final cRedLt    = xl.ExcelColor.fromHexString('FFFFEBEE');
  final cGrey     = xl.ExcelColor.fromHexString('FFF3EEF8');
  final cGreyMed  = xl.ExcelColor.fromHexString('FFE0D9ED');
  final cTextDark = xl.ExcelColor.fromHexString('FF1A1A2E');
  final cTextGrey = xl.ExcelColor.fromHexString('FF757575');
  final cWhite    = xl.ExcelColor.fromHexString('FFFFFFFF');
  final cAlt      = xl.ExcelColor.fromHexString('FFFAF7FD');

  final thinBorder = xl.Border(
      borderStyle: xl.BorderStyle.Thin,
      borderColorHex: xl.ExcelColor.fromHexString('FFD0C0E8'));
  final thickBorder = xl.Border(
      borderStyle: xl.BorderStyle.Medium,
      borderColorHex: cPurple);
  final noneBorder = xl.Border(borderStyle: xl.BorderStyle.None);

  // ── Helper: write styled cell ────────────────────────────────────────
  void sc(
      xl.Sheet sheet,
      int col, int row, dynamic val, {
      bool bold = false, double fontSize = 10,
      xl.ExcelColor? fg, xl.ExcelColor? bg,
      xl.HorizontalAlign align = xl.HorizontalAlign.Left,
      xl.VerticalAlign vAlign = xl.VerticalAlign.Center,
      xl.Border? left, xl.Border? right,
      xl.Border? top, xl.Border? bottom,
      bool wrap = false,
    }) {
    final idx = xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);
    sheet.updateCell(idx, xl.TextCellValue(val?.toString() ?? ''));
    sheet.updateCell(idx, xl.TextCellValue(val?.toString() ?? ''),
        cellStyle: xl.CellStyle(
          bold: bold,
          fontSize: fontSize.toInt(),
          fontColorHex: fg ?? cTextDark,
          backgroundColorHex: bg ?? cWhite,
          horizontalAlign: align,
          verticalAlign: vAlign,
          leftBorder: left ?? thinBorder,
          rightBorder: right ?? thinBorder,
          topBorder: top ?? thinBorder,
          bottomBorder: bottom ?? thinBorder,
          textWrapping: wrap ? xl.TextWrapping.WrapText : null,
        ));
  }

  void mergeRow(xl.Sheet sheet, int row, int startCol, int endCol) {
    sheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: row),
      xl.CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: row),
    );
  }

  final now      = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
  final svcLabel = state.serviceFilter ?? 'All Services';
  final resLabel = state.resourceFilter != null
      ? (state.availableResources.firstWhere(
          (r) => r['id'] == state.resourceFilter,
          orElse: () => {'name': 'Selected Resource'})['name'] as String)
      : 'All Resources';

  final xcel = xl.Excel.createExcel();

  // ================================================================
  // SHEET 1: Resources Revenue Summary
  // ================================================================
  final s1 = xcel['Resources Revenue'];

  // Column widths
  for (final e in {
    0: 5.0, 1: 30.0, 2: 18.0, 3: 14.0, 4: 14.0,
    5: 14.0, 6: 14.0, 7: 14.0, 8: 18.0,
  }.entries) {
    s1.setColumnWidth(e.key, e.value);
  }

  // Title row
  mergeRow(s1, 0, 0, 8);
  sc(s1, 0, 0, 'KLE HOMECARE — Overall Resources Revenue Report',
      bold: true, fontSize: 16, fg: cWhite, bg: cPurple,
      align: xl.HorizontalAlign.Center,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s1.setRowHeight(0, 38);

  // Sub-title: period + filters
  mergeRow(s1, 1, 0, 8);
  sc(s1, 0, 1,
      'Period: $periodLabel  |  Service: $svcLabel  |  Resource: $resLabel  |  Generated: $now',
      fontSize: 9, fg: cWhite, bg: cPurpleMd,
      align: xl.HorizontalAlign.Center,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s1.setRowHeight(1, 22);

  // Spacer
  for (int c = 0; c <= 8; c++) sc(s1, c, 2, '', bg: cGrey,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s1.setRowHeight(2, 8);

  // Header row
  final s1Headers = [
    '#', 'Resource Name', 'Category',
    'Accepted', 'Completed', 'In Progress',
    'Pending', 'Completion %', 'Revenue (₹)',
  ];
  for (int c = 0; c < s1Headers.length; c++) {
    sc(s1, c, 3, s1Headers[c],
        bold: true, fontSize: 10, fg: cWhite, bg: cPurple,
        align: c == 0
            ? xl.HorizontalAlign.Center
            : c >= 3
                ? xl.HorizontalAlign.Center
                : xl.HorizontalAlign.Left,
        left: xl.Border(borderStyle: xl.BorderStyle.Medium, borderColorHex: cWhite),
        right: xl.Border(borderStyle: xl.BorderStyle.Medium, borderColorHex: cWhite),
        top: noneBorder, bottom: noneBorder);
  }
  s1.setRowHeight(3, 28);

  // Data rows
  final resources = state.resourceReport;
  double totalRev = 0;
  int totalAcc = 0, totalComp = 0, totalIP = 0, totalPend = 0;
  for (int i = 0; i < resources.length; i++) {
    final r   = resources[i];
    final row = 4 + i;
    final bg  = i.isEven ? cAlt : cWhite;
    final comp = r.jobsAccepted > 0
        ? (r.jobsCompleted / r.jobsAccepted * 100).round()
        : 0;
    totalRev  += r.revenue;
    totalAcc  += r.jobsAccepted;
    totalComp += r.jobsCompleted;
    totalIP   += r.jobsInProgress;
    totalPend += r.jobsPending;

    sc(s1, 0, row, '${i + 1}',
        align: xl.HorizontalAlign.Center, bg: bg, fontSize: 9);
    sc(s1, 1, row, r.name, bold: true, bg: bg, fontSize: 9);
    sc(s1, 2, row, r.category, bg: bg, fontSize: 9, fg: cTextGrey);
    sc(s1, 3, row, r.jobsAccepted,
        align: xl.HorizontalAlign.Center, bg: bg, fontSize: 9);
    sc(s1, 4, row, r.jobsCompleted,
        align: xl.HorizontalAlign.Center,
        bg: r.jobsCompleted > 0 ? cGreenLt : bg, fg: cGreen, bold: r.jobsCompleted > 0);
    sc(s1, 5, row, r.jobsInProgress,
        align: xl.HorizontalAlign.Center,
        bg: r.jobsInProgress > 0 ? cBlueLt : bg, fg: cBlue);
    sc(s1, 6, row, r.jobsPending,
        align: xl.HorizontalAlign.Center,
        bg: r.jobsPending > 0 ? cAmberLt : bg, fg: cAmber);
    sc(s1, 7, row, '$comp%',
        align: xl.HorizontalAlign.Center,
        bg: comp >= 80 ? cGreenLt : comp >= 50 ? cAmberLt : cRedLt,
        fg: comp >= 80 ? cGreen : comp >= 50 ? cAmber : cRed, bold: true);
    sc(s1, 8, row,
        NumberFormat('#,##0.00').format(r.revenue),
        align: xl.HorizontalAlign.Right, bold: true,
        bg: r.revenue > 0 ? cPurpleLt : bg, fg: cPurple);
    s1.setRowHeight(row, 22);
  }

  // Totals row
  final totRow = 4 + resources.length;
  mergeRow(s1, totRow, 0, 2);
  sc(s1, 0, totRow, 'TOTAL',
      bold: true, fontSize: 11, fg: cWhite, bg: cPurple,
      align: xl.HorizontalAlign.Center,
      left: thickBorder, right: thickBorder,
      top: thickBorder, bottom: thickBorder);
  for (final e in {
    3: totalAcc, 4: totalComp, 5: totalIP, 6: totalPend,
  }.entries) {
    sc(s1, e.key, totRow, e.value,
        bold: true, fontSize: 10, fg: cWhite, bg: cPurple,
        align: xl.HorizontalAlign.Center,
        left: thickBorder, right: thickBorder,
        top: thickBorder, bottom: thickBorder);
  }
  sc(s1, 7, totRow, '',
      bg: cPurple,
      left: thickBorder, right: thickBorder,
      top: thickBorder, bottom: thickBorder);
  sc(s1, 8, totRow,
      NumberFormat('#,##0.00').format(totalRev),
      bold: true, fontSize: 11, fg: cWhite, bg: cPurple,
      align: xl.HorizontalAlign.Right,
      left: thickBorder, right: thickBorder,
      top: thickBorder, bottom: thickBorder);
  s1.setRowHeight(totRow, 28);

  // Footer
  final s1FooterSpacer = totRow + 1;
  for (int c = 0; c <= 8; c++) sc(s1, c, s1FooterSpacer, '', bg: cGreyMed,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s1.setRowHeight(s1FooterSpacer, 5);
  mergeRow(s1, s1FooterSpacer + 1, 0, 8);
  sc(s1, 0, s1FooterSpacer + 1,
      'KLE Homecare Management System  |  Confidential — For Internal Use Only.',
      fontSize: 8, fg: cTextGrey, bg: cGrey,
      align: xl.HorizontalAlign.Center,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s1.setRowHeight(s1FooterSpacer + 1, 18);

  // ================================================================
  // SHEET 2: Patients by Resource
  // ================================================================
  final s2 = xcel['Patient Records'];

  for (final e in {
    0: 5.0, 1: 28.0, 2: 16.0, 3: 20.0, 4: 14.0,
    5: 16.0, 6: 14.0, 7: 12.0, 8: 16.0, 9: 16.0,
  }.entries) {
    s2.setColumnWidth(e.key, e.value);
  }

  // Title
  mergeRow(s2, 0, 0, 9);
  sc(s2, 0, 0, 'KLE HOMECARE — Patients by Resource',
      bold: true, fontSize: 16, fg: cWhite, bg: cPurple,
      align: xl.HorizontalAlign.Center,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s2.setRowHeight(0, 38);

  mergeRow(s2, 1, 0, 9);
  sc(s2, 0, 1,
      'Period: $periodLabel  |  Service: $svcLabel  |  Resource: $resLabel  |  Generated: $now',
      fontSize: 9, fg: cWhite, bg: cPurpleMd,
      align: xl.HorizontalAlign.Center,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s2.setRowHeight(1, 22);

  for (int c = 0; c <= 9; c++) sc(s2, c, 2, '', bg: cGrey,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s2.setRowHeight(2, 8);

  // Column headers
  final s2Headers = [
    '#', 'Patient Name', 'Contact', 'Service Type', 'Status',
    'Assigned Resource', 'Pref. Date', 'Days', 'Total (₹)', 'Paid (₹)',
  ];
  for (int c = 0; c < s2Headers.length; c++) {
    sc(s2, c, 3, s2Headers[c],
        bold: true, fontSize: 10, fg: cWhite, bg: cPurple,
        align: c == 0 || c >= 7
            ? xl.HorizontalAlign.Center
            : xl.HorizontalAlign.Left,
        left: xl.Border(borderStyle: xl.BorderStyle.Medium, borderColorHex: cWhite),
        right: xl.Border(borderStyle: xl.BorderStyle.Medium, borderColorHex: cWhite),
        top: noneBorder, bottom: noneBorder);
  }
  s2.setRowHeight(3, 28);

  // Group patients by assigned resource
  final patients = state.patientServiceReport;
  final grouped = <String, List<PatientServiceItem>>{};
  for (final p in patients) {
    final res = p.assignedResource ?? '';
    final key = res.isEmpty ? 'Unassigned' : res;
    grouped.putIfAbsent(key, () => []).add(p);
  }

  int currentRow = 4;
  int globalIdx  = 1;

  for (final entry in grouped.entries) {
    final resourceName = entry.key;
    final pts = entry.value;

    // Resource group header
    mergeRow(s2, currentRow, 0, 9);
    sc(s2, 0, currentRow, '  $resourceName  (${pts.length} patient${pts.length == 1 ? '' : 's'})',
        bold: true, fontSize: 10, fg: cPurple, bg: cPurpleLt,
        align: xl.HorizontalAlign.Left,
        left: thickBorder, right: thickBorder,
        top: thickBorder, bottom: thickBorder);
    s2.setRowHeight(currentRow, 24);
    currentRow++;

    double groupTotal = 0, groupPaid = 0;

    for (final p in pts) {
      final bg = (globalIdx - 1).isEven ? cAlt : cWhite;
      final total = p.totalAmount ?? 0;
      final paid  = p.paidAmount  ?? 0;
      final statusColor = switch (p.status.toLowerCase()) {
        'completed'   => cGreen,
        'in_progress' => cBlue,
        'pending'     => cAmber,
        'cancelled'   => cRed,
        _             => cTextGrey,
      };
      final statusBg = switch (p.status.toLowerCase()) {
        'completed'   => cGreenLt,
        'in_progress' => cBlueLt,
        'pending'     => cAmberLt,
        'cancelled'   => cRedLt,
        _             => bg,
      };
      groupTotal += total;
      groupPaid  += paid;

      sc(s2, 0, currentRow, '$globalIdx',
          align: xl.HorizontalAlign.Center, bg: bg, fontSize: 9);
      sc(s2, 1, currentRow, p.patientName, bold: true, bg: bg, fontSize: 9);
      sc(s2, 2, currentRow, p.contactNumber ?? '', bg: bg, fontSize: 9, fg: cTextGrey);
      sc(s2, 3, currentRow, p.serviceType, bg: bg, fontSize: 9);
      sc(s2, 4, currentRow, p.status.replaceAll('_', ' ').toUpperCase(),
          bold: true, fontSize: 8.5, fg: statusColor, bg: statusBg,
          align: xl.HorizontalAlign.Center);
      sc(s2, 5, currentRow, p.assignedResource ?? '', bg: bg, fontSize: 9);
      sc(s2, 6, currentRow, p.preferredDate ?? '', bg: bg, fontSize: 9,
          align: xl.HorizontalAlign.Center);
      sc(s2, 7, currentRow, p.numDays,
          align: xl.HorizontalAlign.Center, bg: bg, fontSize: 9);
      sc(s2, 8, currentRow,
          NumberFormat('#,##0.00').format(total),
          align: xl.HorizontalAlign.Right, bg: bg, fontSize: 9);
      sc(s2, 9, currentRow,
          NumberFormat('#,##0.00').format(paid),
          align: xl.HorizontalAlign.Right,
          bg: paid >= total ? cGreenLt : cAmberLt,
          fg: paid >= total ? cGreen : cAmber, fontSize: 9);
      s2.setRowHeight(currentRow, 20);
      currentRow++;
      globalIdx++;
    }

    // Group subtotal
    mergeRow(s2, currentRow, 0, 7);
    sc(s2, 0, currentRow, 'Subtotal — $resourceName',
        bold: true, fontSize: 9, fg: cPurple, bg: cPurpleLt,
        align: xl.HorizontalAlign.Right,
        left: thickBorder, right: noneBorder,
        top: thickBorder, bottom: thickBorder);
    sc(s2, 8, currentRow,
        NumberFormat('#,##0.00').format(groupTotal),
        bold: true, fontSize: 9, fg: cPurple, bg: cPurpleLt,
        align: xl.HorizontalAlign.Right,
        left: thickBorder, right: thickBorder,
        top: thickBorder, bottom: thickBorder);
    sc(s2, 9, currentRow,
        NumberFormat('#,##0.00').format(groupPaid),
        bold: true, fontSize: 9, fg: cPurple, bg: cPurpleLt,
        align: xl.HorizontalAlign.Right,
        left: thickBorder, right: thickBorder,
        top: thickBorder, bottom: thickBorder);
    s2.setRowHeight(currentRow, 20);
    currentRow++;

    // Group spacer
    for (int c = 0; c <= 9; c++) sc(s2, c, currentRow, '', bg: cGreyMed,
        left: noneBorder, right: noneBorder,
        top: noneBorder, bottom: noneBorder);
    s2.setRowHeight(currentRow, 6);
    currentRow++;
  }

  // Grand totals
  final grandTotal = patients.fold<double>(0, (s, p) => s + (p.totalAmount ?? 0));
  final grandPaid  = patients.fold<double>(0, (s, p) => s + (p.paidAmount  ?? 0));
  mergeRow(s2, currentRow, 0, 7);
  sc(s2, 0, currentRow, 'GRAND TOTAL',
      bold: true, fontSize: 11, fg: cWhite, bg: cPurple,
      align: xl.HorizontalAlign.Center,
      left: thickBorder, right: thickBorder,
      top: thickBorder, bottom: thickBorder);
  sc(s2, 8, currentRow,
      NumberFormat('#,##0.00').format(grandTotal),
      bold: true, fontSize: 11, fg: cWhite, bg: cPurple,
      align: xl.HorizontalAlign.Right,
      left: thickBorder, right: thickBorder,
      top: thickBorder, bottom: thickBorder);
  sc(s2, 9, currentRow,
      NumberFormat('#,##0.00').format(grandPaid),
      bold: true, fontSize: 11, fg: cWhite, bg: cPurple,
      align: xl.HorizontalAlign.Right,
      left: thickBorder, right: thickBorder,
      top: thickBorder, bottom: thickBorder);
  s2.setRowHeight(currentRow, 28);

  // Footer
  final s2FooterSpacer = currentRow + 1;
  for (int c = 0; c <= 9; c++) sc(s2, c, s2FooterSpacer, '', bg: cGreyMed,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s2.setRowHeight(s2FooterSpacer, 5);
  mergeRow(s2, s2FooterSpacer + 1, 0, 9);
  sc(s2, 0, s2FooterSpacer + 1,
      'KLE Homecare Management System  |  Confidential — For Internal Use Only.',
      fontSize: 8, fg: cTextGrey, bg: cGrey,
      align: xl.HorizontalAlign.Center,
      left: noneBorder, right: noneBorder,
      top: noneBorder, bottom: noneBorder);
  s2.setRowHeight(s2FooterSpacer + 1, 18);

  // Delete default Sheet1 AFTER all custom sheets are ready
  xcel.delete('Sheet1');

  final bytes = xcel.save();
  if (bytes == null) throw Exception('Failed to encode Excel');
  final safeLabel = periodLabel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  return MisExcelResult(bytes, 'KLE_Overall_Resources_$safeLabel.xlsx');
}
