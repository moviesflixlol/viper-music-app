import 'dart:js_interop';
@JS('viperMusicPreroll') external JSPromise<JSAny?> _preroll(JSString token);
Future<void> musicPreroll(String? token) async {try{await _preroll((token??'').toJS).toDart;}catch(_){}}

@JS('viperCancelPreroll') external void _cancel();
void cancelPreroll(){try{_cancel();}catch(_){}}
