import 'package:flutter/material.dart';

List<String> artworkCandidates(String value, {int targetSize = 1200}) {
  if (value.isEmpty) return const [];
  final uri = Uri.tryParse(value);
  if (uri == null) return [value];
  final candidates = <String>[];
  if (uri.host == 'i.ytimg.com' || uri.host == 'img.youtube.com') {
    final parts = uri.pathSegments;
    if (parts.length >= 3 && (parts[0] == 'vi' || parts[0] == 'vi_webp')) {
      final id = parts[1];
      for (final quality in (targetSize <= 360 ? ['hqdefault', 'mqdefault'] : ['maxresdefault', 'sddefault', 'hqdefault'])) {
        candidates.add('https://i.ytimg.com/vi/$id/$quality.jpg');
      }
    }
  } else if (uri.host.endsWith('.googleusercontent.com') ||
      uri.host == 'yt3.ggpht.com' || uri.host == 'lh3.ggpht.com') {
    final resized = value.replaceAllMapped(
      RegExp(r'([=-])(?:w\d+|h\d+|s\d+)(?=[-=&]|$)'),
      (match) => '${match[1]}${value.substring(match.start + 1, match.start + 2)}$targetSize',
    );
    candidates.add(resized);
  }
  candidates.add(value);
  return candidates.toSet().toList();
}

class MusicArtwork extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  const MusicArtwork(this.url, {super.key, this.width, this.height,
    this.fit = BoxFit.cover, this.alignment = Alignment.center, this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
    final dimensions = [width, height, constraints.maxWidth, constraints.maxHeight]
        .whereType<double>().where((value) => value.isFinite && value > 0).toList();
    final logical = dimensions.isEmpty ? 400.0 : dimensions.reduce((a, b) => a > b ? a : b);
    final target = (logical * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(256, 1600).toInt();
    final urls = artworkCandidates(url, targetSize: target);
    Widget candidate(int index) {
      if (index >= urls.length) {
        return errorBuilder?.call(context, StateError('Artwork unavailable'), null) ??
            SizedBox(width: width, height: height,
              child: const ColoredBox(color: Color(0xFF191919),
                child: Center(child: Icon(Icons.music_note, color: Colors.white38))));
      }
      return Image.network(urls[index], key: ValueKey(urls[index]), width: width, height: height, fit: fit,
        alignment: alignment, filterQuality: FilterQuality.high, gaplessPlayback: false,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, progress) => progress == null ? child :
          SizedBox(width: width, height: height, child: const ColoredBox(color: Color(0xFF191919),
            child: Center(child: Icon(Icons.music_note, color: Colors.white24)))),
        errorBuilder: (_, __, ___) => candidate(index + 1));
    }
    return candidate(0);
    });
  }
}
