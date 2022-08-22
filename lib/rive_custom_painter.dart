import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';
import 'package:rive/src/rive_core/artboard.dart';
import 'package:rive/src/rive_core/math/mat2d.dart';
import 'package:rive/src/rive_core/transform_component.dart';

class RivePaintContext {
  final String componentName;
  final void Function(Matrix4 transform) transformChanged;
  final void Function(Canvas canvas) paint;
  final Mat2D _transform = Mat2D();
  TransformComponent _component;

  RivePaintContext({
    @required this.componentName,
    this.paint,
    this.transformChanged,
  });

  void _updateTransform(Mat2D viewTransform) {
    if (_component == null) {
      return;
    }
    // Early out if there are no changes...
    var transform =
        Mat2D.multiply(Mat2D(), viewTransform, _component.worldTransform);
    if (Mat2D.areEqual(transform, _transform)) {
      return;
    }

    Mat2D.copy(_component.transform, transform);
    transformChanged?.call(Matrix4.fromFloat64List(transform.mat4));
  }
}

class RiveCustomPainter extends LeafRenderObjectWidget {
  final Artboard artboard;
  final bool useIntrinsicSize;
  final BoxFit fit;
  final Alignment alignment;
  final List<RivePaintContext> components;

  const RiveCustomPainter({
    @required this.artboard,
    this.useIntrinsicSize = false,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.components,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RiveCustomRenderObject(artboard as RuntimeArtboard)
      ..fit = fit
      ..alignment = alignment
      ..components = components;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RiveCustomRenderObject renderObject) {
    renderObject
      ..artboard = artboard
      ..fit = fit
      ..alignment = alignment
      ..components = components;
  }

  @override
  void didUnmountRenderObject(covariant RiveCustomRenderObject renderObject) {
    renderObject.dispose();
  }
}

class RiveCustomRenderObject extends RiveRenderObject {
  List<RivePaintContext> _components;

  RiveCustomRenderObject(RuntimeArtboard artboard) : super(artboard);
  List<RivePaintContext> get components => _components;
  set components(List<RivePaintContext> value) {
    if (listEquals(_components, value)) {
      return;
    }
    _components = value;
    for (final context in _components) {
      context._component = artboard.objects.firstWhere(
          (element) =>
              element is TransformComponent &&
              element.name == context.componentName,
          orElse: () => null) as TransformComponent;
      if (context._component == null) {
        print('No component named ${context.componentName} found.');
      }
    }
    markNeedsPaint();
  }

  @override
  void draw(Canvas canvas, Mat2D viewTransform) {
    super.draw(canvas, viewTransform);

    for (final context in _components) {
      SchedulerBinding.instance.endOfFrame.then((_) {
        context._updateTransform(viewTransform);
      });

      if (context.paint != null) {
        canvas.save();
        canvas.transform(context._component.worldTransform.mat4);
        context.paint(canvas);
        canvas.restore();
      }
    }
  }
}
