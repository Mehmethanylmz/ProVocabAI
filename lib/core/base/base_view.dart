import 'package:flutter/material.dart';

class BaseView<T extends ChangeNotifier> extends StatefulWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final T viewModel;
  final Function(T model) onModelReady;
  final VoidCallback? onDispose;

  const BaseView({
    super.key,
    required this.viewModel,
    required this.builder,
    required this.onModelReady,
    this.onDispose,
  });

  @override
  State<BaseView<T>> createState() => _BaseViewState<T>();
}

class _BaseViewState<T extends ChangeNotifier> extends State<BaseView<T>> {
  late T model;

  @override
  void initState() {
    model = widget.viewModel;
    widget.onModelReady(model);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.onDispose != null) widget.onDispose!();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model,
      builder: (context, child) => widget.builder(context, model, child),
    );
  }
}
