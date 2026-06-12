import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

void safeGoBack(BuildContext context, {String? fallbackLocation}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackLocation ?? const HomeRoute().location);
  }
}
