/// A single point in a freehand stroke with optional pressure.
class StrokePoint {
  const StrokePoint(this.x, this.y, [this.pressure]);
  final double x;
  final double y;
  final double? pressure;
}
