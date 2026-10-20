import 'dart:js_interop';

@JS()
@staticInterop
class _Navigator {}

extension on _Navigator {
  external JSBoolean vibrate(JSAny pattern);
}

@JS('navigator')
external _Navigator get _navigator;

void vibrate() {
  _navigator.vibrate([350.toJS, 120.toJS, 350.toJS, 120.toJS, 350.toJS].toJS);
}
