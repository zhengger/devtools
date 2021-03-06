// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js_util.dart';

import '../timeline/timeline.dart';
import '../ui/flutter_html_shim.dart';
import '../ui/plotly.dart';
import '../ui/theme.dart';

class FramesBarPlotly {
  FramesBarPlotly(this._domName, [this.useLogScale = true]);

  // Any duration of cpu/gpu greater than 8 ms is a jank.
  static const int jankMs = 8;

  static const int gpuGoodTraceIndex = 0;
  static const int gpuJankTraceIndex = 1;
  static const int gpuSelectTraceIndex = 2;
  static const int cpuGoodTraceIndex = 3;
  static const int cpuJankTraceIndex = 4;
  static const int cpuSelectTraceIndex = 5;
  // IMPORTANT: Last trace need to update numberOfTraces constant below.

  // Compute total number of traces in graph.
  static const int numberOfTraces = cpuSelectTraceIndex + 1;

  // Any point in our frame chart is in only two traces.  The gpu duration will
  // be in either gpu good or gpu jank trace.  The cpu duration will be in
  // either cpu good or cpu jank trace.  The only exception is a select bar that
  // will be in gpu selection and cpu selection traces.
  static const int activeTracesPerX = 2;

  // Careful if changing this to something other than -1 because of
  // rangemode: nonnegative
  static const int xCoordNotUsed = -1;
  static const int yCoordNotUsed = 0;

  static const int xCoordFirst = 0;

  // Default number of bars displayed in zoom (range slider).
  static const int ticksInRangeSlider = 90;

  final String _domName;
  final bool useLogScale;

  final _yAxisLogScale = AxisLayout(
    title: 'Milliseconds',
    tickformat: '.0f',
    type: 'log',
    range: [0, 2],
    nticks: 3,
    titlefont: Font(color: colorToCss(defaultForeground)),
    tickfont: Font(
      color: colorToCss(defaultForeground),
    ),
    tickmode: 'array',
    tickvals: [
      1,
      10,
      100,
    ],
    ticktext: [
      1,
      10,
      100,
    ],
    hoverformat: '.3f',
  );

  final _yAxisLinearScale = AxisLayout(
    title: 'Milliseconds',
    fixedrange: true,
  );

  Layout getFPSTimeseriesLayout() {
    return Layout(
      plot_bgcolor: colorToCss(chartBackground),
      paper_bgcolor: colorToCss(chartBackground),
      legend: Legend(font: Font(color: colorToCss(defaultForeground))),
      xaxis: AxisLayout(
        rangeslider: RangeSlider(),
        // Hide ticks by using font color of bgColor.
        tickfont: Font(
          color: colorToCss(chartBackground),
          size: 1,
        ),
        rangemode: 'nonnegative',
        autorange: true,
      ),
      yaxis: useLogScale ? _yAxisLogScale : _yAxisLinearScale,
      hovermode: 'x',
      autosize: true,
      barmode: 'stack',
      dragmode: 'pan',
      shapes: [
        // TODO(terry): Display somewhere what the lines are showing (8/16 ms).
        // TODO(terry): Unable to place in legend directly.
        Shape(
          type: 'line',
          xref: 'paper',
          // TOD(terry): Verify do we like the line above or below the bars.
          // layer: 'below',
          x0: 0,
          y0: 8,
          x1: 1,
          y1: 8,
          line: Line(
            dash: 'dot',
            color: colorToCss(mainGpuColor),
            width: 1,
          ),
        ),
        Shape(
          type: 'line',
          xref: 'paper',
          // TOD(terry): Verify do we like the line above or below the bars.
          // layer: 'below',
          x0: 0,
          y0: 16,
          x1: 1,
          y1: 16,
          line: Line(
            dash: 'longdash',
            color: colorToCss(mainCpuColor),
            width: 1,
          ),
        ),
      ],
      margin: Margin(
        l: 60,
        r: 0,
        b: 5,
        t: 5,
        pad: 5,
      ),
    );
  }

  // Return a list of all of traces in trace index order:
  // e.g., [
  //         GPU Good Trace Data,   // array index gpuGoodTraceIndex
  //         GPU Jank Trace Data,   // array index gpuJankTraceIndex
  //         GPU Select Trace Data, // array index gpuSelectTraceIndex
  //         CPU Good Trace Data,   // array index cpuGoodTraceIndex
  //         CPU Jank Trace Data,   // array index cpuJankTraceIndex
  //         CPU Select Trace Data, // array index cpuSelectTraceIndex
  //       ]
  static List<Data> createFPSTraces() {
    final List<Data> allTraces = [];

    // Strange plotly bug with initial setup of x,y.  If x and y are empty array
    // then the first entry, for each trace, isn't rendered but hover does
    // display the Y value.  So prime each trace with some data.  Added
    // at x-axis coord of xCoordNotUsed (-1) (hide rangemode: nonnegative
    // displays at 0 and greater) and y is zero.

    // trace GPU Good
    allTraces.insert(
      gpuGoodTraceIndex,
      Data(
        y: [yCoordNotUsed],
        x: [xCoordNotUsed],
        type: 'bar',
        legendgroup: 'good_group',
        name: 'GPU',
        hoverinfo: 'y+name',
        hoverlabel: HoverLabel(
          font: Font(
            color: colorToCss(hoverTextColor),
          ),
        ),
        marker: Marker(
          color: colorToCss(mainGpuColor),
        ),
        width: [0],
      ),
    );

    // trace GPU Jank
    allTraces.insert(
      gpuJankTraceIndex,
      Data(
        y: [yCoordNotUsed],
        x: [xCoordNotUsed],
        type: 'bar',
        legendgroup: 'jank_group',
        name: 'GPU Jank',
        hoverinfo: 'y+name',
        hoverlabel: HoverLabel(
          font: Font(
            color: colorToCss(hoverTextHighContrastColor),
          ),
          bordercolor: colorToCss(hoverJankColor),
        ),
        marker: Marker(
          color: colorToCss(gpuJankColor),
        ),
        width: [0],
      ),
    );

    // trace GPU Select
    allTraces.insert(
      gpuSelectTraceIndex,
      Data(
        y: [yCoordNotUsed],
        x: [xCoordNotUsed],
        hoverinfo: 'y+name',
        hoverlabel: HoverLabel(
          bgcolor: colorToCss(selectedGpuColor),
          font: Font(
            color: colorToCss(hoverTextHighContrastColor),
          ),
          bordercolor: colorToCss(selectedGpuColor),
        ),
        showlegend: false,
        type: 'bar',
        marker: Marker(
          color: colorToCss(selectedGpuColor),
        ),
      ),
    );

    // trace CPU Good
    allTraces.insert(
      cpuGoodTraceIndex,
      Data(
        y: [yCoordNotUsed],
        x: [xCoordNotUsed],
        type: 'bar',
        legendgroup: 'good_group',
        name: 'CPU',
        hoverinfo: 'y+name',
        hoverlabel: HoverLabel(
          font: Font(
            color: colorToCss(hoverTextColor),
          ),
        ),
        marker: Marker(
          color: colorToCss(mainCpuColor),
        ),
        width: [0],
      ),
    );

    // trace CPU Jank
    allTraces.insert(
      cpuJankTraceIndex,
      Data(
        y: [yCoordNotUsed],
        x: [xCoordNotUsed],
        type: 'bar',
        legendgroup: 'jank_group',
        name: 'CPU Jank',
        hoverinfo: 'y+name',
        hoverlabel: HoverLabel(
          font: Font(
            color: colorToCss(hoverTextHighContrastColor),
          ),
          bordercolor: colorToCss(hoverJankColor),
        ),
        marker: Marker(
          color: colorToCss(cpuJankColor),
        ),
        width: [0],
      ),
    );

    // trace CPU Select
    allTraces.insert(
      cpuSelectTraceIndex,
      Data(
        y: [yCoordNotUsed],
        x: [xCoordNotUsed],
        hoverinfo: 'y+name',
        hoverlabel: HoverLabel(
          bgcolor: colorToCss(selectedCpuColor),
          font: Font(
            color: colorToCss(hoverTextHighContrastColor),
          ),
          bordercolor: colorToCss(selectedCpuColor),
        ),
        showlegend: false,
        type: 'bar',
        marker: Marker(
          color: colorToCss(selectedCpuColor),
        ),
      ),
    );

    assert(allTraces.length == numberOfTraces);

    return allTraces;
  }

  void plotFPS() {
    Plotly.newPlot(
      _domName,
      createFPSTraces(),
      getFPSTimeseriesLayout(),
      Configuration(
        responsive: true,
        displaylogo: false,
        displayModeBar: false,
      ),
    );
  }

  void plotFPSDatum(
    int dataIndex,
    num cpuDuration,
    num gpuDuration,
    bool paused,
  ) {
    final List<int> traces = [];

    traces.add(cpuDuration > jankMs ? cpuJankTraceIndex : cpuGoodTraceIndex);
    traces.add(gpuDuration > jankMs ? gpuJankTraceIndex : gpuGoodTraceIndex);

    final TraceData data = TraceData(
      x: [
        [dataIndex],
        [dataIndex],
      ],
      y: [
        [cpuDuration],
        [gpuDuration],
      ],
    );

    Plotly.extendTraces(
      _domName,
      data,
      traces,
    );

    if (!paused) rangeSliderToLast(dataIndex);
  }

  // Chunky plotting of data to reduce plotly live charting lag.
  void plotFPSDataList(
    List<int> dataIndexes,
    List<num> cpuDurations,
    List<num> gpuDurations,
    bool paused,
  ) {
    final List<int> cpuGoodX = [];
    final List<num> cpuGoodTrace = [];

    final List<int> cpuJankX = [];
    final List<num> cpuJankTrace = [];

    final List<int> gpuGoodX = [];
    final List<num> gpuGoodTrace = [];

    final List<int> gpuJankX = [];
    final List<num> gpuJankTrace = [];

    final int totalIndexes = dataIndexes.length;
    for (int dataIndex = 0; dataIndex < totalIndexes; dataIndex++) {
      final num cpuDuration = cpuDurations[dataIndex];
      final num gpuDuration = gpuDurations[dataIndex];

      if (cpuDuration > jankMs) {
        cpuJankX.add(dataIndexes[dataIndex]);
        cpuJankTrace.add(cpuDuration);
      } else {
        cpuGoodX.add(dataIndexes[dataIndex]);
        cpuGoodTrace.add(cpuDuration);
      }

      if (gpuDuration > jankMs) {
        gpuJankX.add(dataIndexes[dataIndex]);
        gpuJankTrace.add(gpuDuration);
      } else {
        gpuGoodX.add(dataIndexes[dataIndex]);
        gpuGoodTrace.add(gpuDuration);
      }
    }

    final TraceData data = TraceData(x: [], y: []);
    final List<int> traces = [];
    if (cpuJankX.isNotEmpty) {
      data.x.add(cpuJankX);
      data.y.add(cpuJankTrace);
      traces.add(cpuJankTraceIndex);
    }
    if (cpuGoodX.isNotEmpty) {
      data.x.add(cpuGoodX);
      data.y.add(cpuGoodTrace);
      traces.add(cpuGoodTraceIndex);
    }
    if (gpuJankX.isNotEmpty) {
      data.x.add(gpuJankX);
      data.y.add(gpuJankTrace);
      traces.add(gpuJankTraceIndex);
    }
    if (gpuGoodX.isNotEmpty) {
      data.x.add(gpuGoodX);
      data.y.add(gpuGoodTrace);
      traces.add(gpuGoodTraceIndex);
    }

    // TODO(terry): Eliminate this JS call (result of reified List?).
    extendTraces4(
      _domName,
      cpuGoodX,
      gpuGoodX,
      cpuJankX,
      gpuJankX,
      cpuGoodTrace,
      gpuGoodTrace,
      cpuJankTrace,
      gpuJankTrace,
      [
        cpuGoodTraceIndex,
        gpuGoodTraceIndex,
        cpuJankTraceIndex,
        gpuJankTraceIndex,
      ],
    );

    if (!paused) rangeSliderToLast(dataIndexes.last + 1);
  }

  void rangeSliderToLast(int dataIndex) {
    Plotly.update(
      _domName,
      [Data()],
      Layout(
        xaxis: AxisLayout(
          // Hide ticks by using font color of bgColor as we slide.
          tickfont: Font(
            color: colorToCss(chartBackground),
          ),
          rangemode: 'nonnegative',
          range: [dataIndex - ticksInRangeSlider, dataIndex],
          rangeslider: RangeSlider(
            rangemode: 'nonnegative',
            autorange: true,
          ),
        ),
      ),
    );
  }

  void chartClick(String domName, Function f) {
    mouseClick(domName, f);
  }

  void chartHover(String domName, Function f) {
    hoverOver(domName, f);
  }

  void chartLegendClick(String domName, Function f) {
    legendClick(domName, f);
  }
}

class SelectTrace {
  SelectTrace(
    this.traceIndex,
    this.ptNumber,
    this.xValue,
    this.yValue,
  );

  final int traceIndex;
  int ptNumber;
  final num xValue;
  final num yValue;
}

class Selection {
  Selection(
    this._domName,
    dynamic graphDiv,
  ) : _data = getProperty(graphDiv, 'data');

  final String _domName;
  final List<Data> _data;
  List<SelectTrace> selectInfo = [];

  bool isSelected(List<SelectTrace> newSelection) =>
      selectInfo.length == FramesBarPlotly.activeTracesPerX &&
      selectInfo[0].xValue == newSelection[0].xValue &&
      selectInfo[1].xValue == newSelection[1].xValue;

  int get selectedPointNumber =>
      selectInfo.isNotEmpty ? selectInfo[0].ptNumber : -1;

  void select(List<SelectTrace> newSelection) {
    // Supports one bar selection and not selecting a currently selected bar.
    assert(newSelection.length == FramesBarPlotly.activeTracesPerX &&
        newSelection[0].traceIndex != FramesBarPlotly.gpuSelectTraceIndex &&
        newSelection[1].traceIndex != FramesBarPlotly.cpuSelectTraceIndex);

    final List<SelectTrace> oldSelectInfo = unselect();

    // Maybe adjust our current pointNumbers (plotly term is an array index
    // into data). If we messed with a trace and the old pointNumbers was before
    // our new bar we need to adjust.
    if (oldSelectInfo.isNotEmpty) {
      final int oldTrace0 = oldSelectInfo[0].traceIndex;
      final int oldPtNum0 = oldSelectInfo[0].ptNumber;
      final int oldTrace1 = oldSelectInfo[1].traceIndex;
      final int oldPtNum1 = oldSelectInfo[1].ptNumber;

      final int newTrace0 = newSelection[0].traceIndex;
      final int newPtNum0 = newSelection[0].ptNumber;
      final int newTrace1 = newSelection[1].traceIndex;
      final int newPtNum1 = newSelection[1].ptNumber;

      // After unselecting, the old selection data is restored back to our
      // traces (gpu good/jank and cpu good/jank) from the selection traces.
      // Adjust the newSelection pointNumbers to point to the new location of
      // the real data after unselect.
      if (oldTrace0 == newTrace0 && newPtNum0 >= oldPtNum0) {
        newSelection[0].ptNumber += 1;
      }
      if (oldTrace1 == newTrace1 && newPtNum1 >= oldPtNum1) {
        newSelection[1].ptNumber += 1;
      }
    }

    // This is our new current selection.
    selectInfo = newSelection;

    // Make room for our selection bar remove the data we're selecting it will
    // exist in the selection traces.
    for (var selectTrace in selectInfo) {
      _data[selectTrace.traceIndex].x.removeAt(selectTrace.ptNumber);
      _data[selectTrace.traceIndex].y.removeAt(selectTrace.ptNumber);
    }

    // Move the data to the selection traces.
    extendTraces2(_domName, [
      selectInfo[0].xValue,
    ], [
      selectInfo[1].xValue,
    ], [
      selectInfo[0].yValue,
    ], [
      selectInfo[1].yValue,
    ], [
      FramesBarPlotly.gpuSelectTraceIndex,
      FramesBarPlotly.cpuSelectTraceIndex,
    ]);

    // Construct the hover names for each selection trace.
    final String gpuSelectionHoverName =
        selectInfo[0].traceIndex == FramesBarPlotly.gpuGoodTraceIndex
            ? 'GPU'
            : 'GPU Jank';
    final String cpuSelectionHoverName =
        selectInfo[1].traceIndex == FramesBarPlotly.cpuGoodTraceIndex
            ? 'CPU'
            : 'CPU Jank';

    // Update the hovers for the selection traces.
    Plotly.restyle(
      _domName,
      'name',
      [gpuSelectionHoverName],
      [FramesBarPlotly.gpuSelectTraceIndex],
    );
    Plotly.restyle(
      _domName,
      'name',
      [cpuSelectionHoverName],
      [FramesBarPlotly.cpuSelectTraceIndex],
    );
  }

  /// Unselect the current bar in the selection traces. Then restore the data
  /// point in the gpu good/jank and cpu good/jank trace.
  ///
  /// Returns the old selectionInfo of empty list if no selection.
  List<SelectTrace> unselect() {
    if (selectInfo.isNotEmpty) {
      for (var selectTrace in selectInfo) {
        final int trace = selectTrace.traceIndex;
        final int ptNumber = selectTrace.ptNumber;
        final num xValue = selectTrace.xValue;
        final num yValue = selectTrace.yValue;

        // Restore our data point (selected) back to traces (gpu good/jank &
        // cpu good/jank).
        _data[trace].x.insert(ptNumber, xValue);
        _data[trace].y.insert(ptNumber, yValue);
      }

      // Remove all trace selection data.
      _data[FramesBarPlotly.gpuSelectTraceIndex].x.removeAt(1);
      _data[FramesBarPlotly.gpuSelectTraceIndex].y.removeAt(1);
      _data[FramesBarPlotly.cpuSelectTraceIndex].x.removeAt(1);
      _data[FramesBarPlotly.cpuSelectTraceIndex].y.removeAt(1);

      final List<SelectTrace> oldSelectInfo = [];
      oldSelectInfo.add(selectInfo[0]);
      oldSelectInfo.add(selectInfo[1]);

      selectInfo = [];

      return oldSelectInfo;
    }

    return [];
  }
}
