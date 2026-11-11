(() => {
 const tag='https://enchantingboss.com/d.m/F/zYdeGXNRvUZWGvUK/reDmO9wuiZzUElak_PNTacZ2/MCDzE/zfMmDXkSt/NCz/YEw/MzTMMfxpMewB';
 let cancel, generation=0;
 window.viperCancelPreroll=()=>{generation++;cancel?.();};
 window.viperMusicPreroll=async token=>{
  const current=++generation;cancel?.();
  if(token){try{const r=await fetch('https://movieflix.lol/api/subscription?action=status&platform=music',{headers:{Authorization:'Bearer '+token},signal:AbortSignal.timeout(5000)});if(r.ok&&(await r.json()).is_premium)return;}catch{}}
  if(current!==generation)return;
  await new Promise(resolve=>{
   const overlay=document.createElement('div');overlay.style.cssText='position:fixed;inset:0;background:#000;z-index:2147483647;color:white;display:grid;place-items:center';
   const slot=document.createElement('div');slot.style.cssText='position:absolute;inset:48px 0 0';
   const label=document.createElement('div');label.textContent='Advertisement';label.style.cssText='position:absolute;top:14px;left:20px;font:16px sans-serif';
   const video=document.createElement('video');video.playsInline=true;video.muted=true;video.style.display='none';
   overlay.append(slot,label,video);document.body.append(overlay);
   let manager,done=false,timer;
   const finish=()=>{if(done)return;done=true;clearTimeout(timer);try{manager?.destroy();}catch{}overlay.remove();if(cancel===finish)cancel=null;resolve();};cancel=finish;
   timer=setTimeout(finish,8000);
   const start=()=>{if(done)return;try{
    const ima=google.ima,display=new ima.AdDisplayContainer(slot,video),loader=new ima.AdsLoader(display);
    loader.addEventListener(ima.AdErrorEvent.Type.AD_ERROR,finish);
    loader.addEventListener(ima.AdsManagerLoadedEvent.Type.ADS_MANAGER_LOADED,e=>{if(done)return;try{
     manager=e.getAdsManager(video);manager.addEventListener(ima.AdErrorEvent.Type.AD_ERROR,finish);
     manager.addEventListener(ima.AdEvent.Type.CONTENT_RESUME_REQUESTED,finish);manager.addEventListener(ima.AdEvent.Type.ALL_ADS_COMPLETED,finish);
     manager.addEventListener(ima.AdEvent.Type.STARTED,()=>{clearTimeout(timer);timer=setTimeout(finish,120000);});
     manager.init(innerWidth,innerHeight-48,ima.ViewMode.NORMAL);manager.setVolume(0);manager.start();
    }catch{finish();}});
    display.initialize();const request=new ima.AdsRequest();request.adTagUrl=tag;request.linearAdSlotWidth=innerWidth;request.linearAdSlotHeight=innerHeight-48;request.setAdWillAutoPlay(true);request.setAdWillPlayMuted(true);loader.requestAds(request);
   }catch{finish();}};
   if(window.google?.ima)start();else{const script=document.createElement('script');script.src='https://imasdk.googleapis.com/js/sdkloader/ima3.js';script.onload=start;script.onerror=finish;document.head.append(script);}
  });
 };
})();
