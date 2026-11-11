import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viper_music/models/playlist.dart';
import 'package:viper_music/models/song.dart';
import 'package:viper_music/ui/components/music_artwork.dart';
import 'package:viper_music/ui/components/playlist_artwork.dart';
import 'package:viper_music/ui/components/more_songs_sheet.dart';

Song song(String id) => Song(id: id, title: 'Song $id', artist: 'Artist', thumbnailUrl: '');
void main() {
 test('artwork asks for larger images and keeps working fallbacks', () {
   final yt=artworkCandidates('https://i.ytimg.com/vi/abc123/hqdefault.jpg');
   expect(yt.first,'https://i.ytimg.com/vi/abc123/maxresdefault.jpg');
   expect(yt.last,'https://i.ytimg.com/vi/abc123/hqdefault.jpg');
   final google=artworkCandidates('https://lh3.googleusercontent.com/cover=w60-h60-l90-rj');
   expect(google.first,contains('w1200-h1200'));expect(google.last,contains('w60-h60'));
   expect(artworkCandidates('https://example.test/cover.jpg'),['https://example.test/cover.jpg']);
 });
 test('single-track playback still gets unique recommendations', () {
   final choices=moreSongs(queue:[song('a')],currentId:'a',recommended:[song('b'),song('a')],trending:[song('b'),song('c')]);
   expect(choices.map((s)=>s.id),['b','c']);
 });
 test('up next excludes songs already passed in the queue', () {
   final choices=moreSongs(queue:[song('a'),song('b'),song('c')],currentId:'b',recommended:[song('a'),song('d')],trending:[]);
   expect(choices.map((s)=>s.id),['c','d']);
 });
 testWidgets('playlist artwork is a square containing the first four covers', (tester) async {
   final pl=Playlist(id:'playlist',name:'My playlist',tracks:List.generate(5,(i)=>song('$i')));
   await tester.pumpWidget(MaterialApp(home:Center(child:PlaylistArtwork(playlist:pl,size:160))));
   expect(find.byType(MusicArtwork),findsNWidgets(4));
   final size=tester.getSize(find.byType(PlaylistArtwork));expect(size.width,160);expect(size.height,160);
   expect(find.byType(Row),findsNWidgets(2));
 });
 testWidgets('an upward drag opens the song sheet and selecting a song works', (tester) async {
   Song? selected;
   await tester.pumpWidget(MaterialApp(home:Builder(builder:(context)=>Scaffold(body:SwipeUpSongs(
     onOpen:()=>showModalBottomSheet<void>(context:context,isScrollControlled:true,
       builder:(_)=>MoreSongsSheet(songs:[song('b'),song('c')],onSelected:(song)=>selected=song)),
     child:const SizedBox.expand(child:Center(child:Text('Player artwork'))),
   )))));
   await tester.drag(find.text('Player artwork'),const Offset(0,-120));
   await tester.pumpAndSettle();expect(find.text('More songs'),findsOneWidget);
   await tester.tap(find.text('Song b'));expect(selected?.id,'b');
 });
}
