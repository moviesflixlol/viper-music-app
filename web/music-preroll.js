(() => {
 let cancel,generation=0;
 window.viperCancelPreroll=()=>{generation++;cancel?.();};
 window.viperMusicPreroll=async token=>{
  const current=++generation;cancel?.();
  if(token){try{const r=await fetch('https://movieflix.lol/api/subscription?action=status&platform=music',{headers:{Authorization:'Bearer '+token},signal:AbortSignal.timeout(5000)});if(r.ok&&(await r.json()).is_premium)return;}catch{}}
  if(current!==generation)return;
  await new Promise(resolve=>{
   let done=false,timer;
   const overlay=document.createElement('div');overlay.style.cssText='position:fixed;inset:0;background:#000;z-index:2147483647;color:white';
   const label=document.createElement('div');label.textContent='Advertisement';label.style.cssText='position:absolute;top:14px;left:20px;font:16px sans-serif';
   const frame=document.createElement('iframe');frame.title='MovieFlix video advertisement';frame.allow='autoplay; fullscreen';frame.src='/player-vast.html';frame.style.cssText='position:absolute;top:48px;left:0;width:100%;height:calc(100% - 48px);border:0';
   const finish=()=>{if(done)return;done=true;clearTimeout(timer);window.removeEventListener('message',receive);overlay.remove();if(cancel===finish)cancel=null;resolve();};
   const receive=e=>{if(e.origin!==location.origin||e.source!==frame.contentWindow)return;
    if(e.data==='movieflix-ad-finished')finish();
    if(e.data==='movieflix-ad-started'){clearTimeout(timer);timer=setTimeout(finish,120000);}
   };
   cancel=finish;window.addEventListener('message',receive);timer=setTimeout(finish,15000);
   overlay.append(label,frame);document.body.append(overlay);
  });
 };
})();
