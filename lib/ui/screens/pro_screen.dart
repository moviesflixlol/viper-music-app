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
 Widget plan(String title, String price, String duration, {bool annual=false}) => Container(
  margin:const EdgeInsets.only(bottom:16),padding:const EdgeInsets.all(24),
  decoration:BoxDecoration(color:annual?const Color(0xff231418):const Color(0xff151518),borderRadius:BorderRadius.circular(22),border:Border.all(color:annual?const Color(0xffb44953):const Color(0xff29292e))),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(annual?'THE COMPLETE BUNDLE':'MUSIC PRO',style:const TextStyle(color:Colors.white54,fontSize:11,letterSpacing:1)),Text(duration,style:const TextStyle(color:Colors.white54,fontSize:11))]),
   if(annual)Padding(padding:const EdgeInsets.symmetric(vertical:24),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
    Expanded(child:Image.asset('assets/images/movieflix_header.png',height:44)),const Padding(padding:EdgeInsets.symmetric(horizontal:20),child:Text('+',style:TextStyle(fontSize:28))),Expanded(child:Image.asset('assets/images/header_logo.png',height:44))])),
   const SizedBox(height:14),Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w700)),const SizedBox(height:12),
   Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(price,style:const TextStyle(fontSize:48,fontWeight:FontWeight.w800,letterSpacing:-2)),const Padding(padding:EdgeInsets.only(left:10,bottom:10),child:Text('Telegram Stars',style:TextStyle(color:Colors.white54)))]),
   const SizedBox(height:12),Text(annual?'MovieFlix + Music Pro. One code, one account, both apps.':'Ad-free Music access for your chosen term.',style:const TextStyle(color:Colors.white60,height:1.6)),
   const SizedBox(height:20),SizedBox(width:double.infinity,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:annual?Colors.white:const Color(0xffdf2638),foregroundColor:annual?Colors.black:Colors.white,padding:const EdgeInsets.all(16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),onPressed:()=>launchUrl(Uri.parse('https://t.me/movieflix_pro_bot?start=music')),child:Text(annual?'Get the bundle →':'Get '+title.toLowerCase()+' →'))),
  ]));
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xff09090b),appBar:AppBar(backgroundColor:const Color(0xff09090b),title:Image.asset('assets/images/movieflix_header.png',height:32)),body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:680),child:ListView(padding:const EdgeInsets.all(20),children:[
  const SizedBox(height:20),const Text('MORE OF WHAT YOU LOVE',style:TextStyle(color:Color(0xffff636d),fontSize:11,letterSpacing:2)),
  const SizedBox(height:14),const Text('Your everyday soundtrack.\nWithout the interruptions.',style:TextStyle(fontSize:36,fontWeight:FontWeight.w800,letterSpacing:-1)),
  const SizedBox(height:16),const Text('Choose Music Pro. Get a full year of movies and music with the annual bundle.',style:TextStyle(color:Colors.white60,height:1.6)),const SizedBox(height:28),
  plan('Monthly','50','30 days'),plan('Quarterly','150','90 days'),plan('One year. Both worlds.','350','365 days',annual:true),
  const Text('One-time payment. No automatic renewal. Star costs vary by platform and region.',style:TextStyle(color:Colors.white38,fontSize:12,height:1.6)),const SizedBox(height:28),
  const Text('Already have a code?',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:12),
  const Text('Enter your sign-in email in the bot, choose Music or MovieFlix, and pay. Redeem the code here to start Pro.',style:TextStyle(color:Colors.white60,height:1.6)),const SizedBox(height:18),
  TextField(controller:code,decoration:const InputDecoration(labelText:'VIP promo code',border:OutlineInputBorder())),const SizedBox(height:12),FilledButton(onPressed:busy?null:redeem,child:Text(busy?'Activating…':'Activate Pro')),
  if(message.isNotEmpty)Padding(padding:const EdgeInsets.only(top:16),child:Text(message)),const SizedBox(height:40),
 ]))));
}
