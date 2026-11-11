import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../state/music_controller.dart';

class ProScreen extends StatefulWidget {
 final MusicController controller;
 const ProScreen({super.key, required this.controller});
 @override State<ProScreen> createState()=>_ProScreenState();
}
class _ProScreenState extends State<ProScreen> {
 final code=TextEditingController(); String message=''; bool busy=false;
 @override void dispose(){code.dispose();super.dispose();}
 Future<void> redeem() async {
  final token=widget.controller.authService.token;
  if(token==null){setState(()=>message='Sign in with your email first.');return;}
  setState(()=>busy=true);
  try{
   final response=await http.post(Uri.parse('https://movieflix.lol/api/subscription?action=redeem_promo&platform=music'),
    headers:{'Authorization':'Bearer $token','Content-Type':'application/json'},body:jsonEncode({'promo_code':code.text.trim()}));
   final data=jsonDecode(response.body) as Map<String,dynamic>;
   if(mounted)setState(()=>message=response.statusCode==200?'Music Pro activated. Annual plans include MovieFlix too.':data['error']?.toString()??'Could not redeem code.');
  }catch(_){if(mounted)setState(()=>message='Connection failed. Please retry.');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Music Pro')),body:ListView(padding:const EdgeInsets.all(20),children:[
  const Text('Listen with Pro',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:16),
  const ListTile(title:Text('1 month · Music'),trailing:Text('50 Stars')),
  const ListTile(title:Text('3 months · Music'),trailing:Text('150 Stars')),
  const ListTile(title:Text('1 year · Music + MovieFlix'),trailing:Text('350 Stars')),
  const SizedBox(height:16),const Text('Open the bot, enter your sign-in email, choose Music or MovieFlix and pay with Stars. Redeem the single-use code here. Access starts when you redeem.'),
  const SizedBox(height:16),FilledButton(onPressed:()=>launchUrl(Uri.parse('https://t.me/movieflix_pro_bot?start=music')),child:const Text('Buy through Telegram')),
  const SizedBox(height:24),TextField(controller:code,decoration:const InputDecoration(labelText:'Promo code',border:OutlineInputBorder())),
  const SizedBox(height:12),FilledButton(onPressed:busy?null:redeem,child:Text(busy?'Redeeming…':'Redeem code')),
  if(message.isNotEmpty)Padding(padding:const EdgeInsets.only(top:16),child:Text(message)),
 ]));
}
