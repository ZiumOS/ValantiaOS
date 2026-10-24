const prefersReducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
const lowPower = (navigator.hardwareConcurrency || 8) <= 4 || /Mobi|Android/i.test(navigator.userAgent);

export function initBlackhole() {
  const canvas = document.querySelector('.blackhole-canvas');
  const hero = canvas?.closest('.hero');
  if (!canvas || !hero || prefersReducedMotion.matches) return;
  const ctx = canvas.getContext('2d', { alpha: false });
  if (!ctx) return;
  let width=0,height=0,dpr=1,frame=0,running=false,time=0,pointerX=0,pointerY=0,targetX=0,targetY=0,scrollFactor=0,stars=[];
  const resize=()=>{
    const box=hero.getBoundingClientRect(); width=box.width;height=box.height;
    dpr=Math.min(devicePixelRatio||1,lowPower ? .65 : .85);
    canvas.width=Math.round(width*dpr);canvas.height=Math.round(height*dpr);
    stars=Array.from({length:Math.max(45,Math.round(width*height/(lowPower?15000:9500)))},()=>({x:Math.random()*width,y:Math.random()*height,r:Math.random()*1.2+.2,a:Math.random()*.55+.12,p:Math.random()*6.28}));
  };
  const render=()=>{
    if(!running)return;frame=requestAnimationFrame(render);time+=.006;
    pointerX+=(targetX-pointerX)*.025;pointerY+=(targetY-pointerY)*.025;
    const w=canvas.width,h=canvas.height,cx=w*(width<680?.9:.69+pointerX*.018),cy=h*(.48+pointerY*.018-scrollFactor*.03),r=Math.min(width<680?height*.25:Math.min(width,height),height)*(.19+scrollFactor*.03);
    ctx.fillStyle='#07090b';ctx.fillRect(0,0,w,h);
    for(const s of stars){ctx.globalAlpha=s.a*(.7+.3*Math.sin(time*2+s.p));ctx.fillStyle='#dcebe8';ctx.fillRect(((s.x+time*2)%width)*dpr,s.y*dpr,s.r*dpr,s.r*dpr)}ctx.globalAlpha=1;
    const glow=ctx.createRadialGradient(cx,cy,r*.6,cx,cy,r*2.2);glow.addColorStop(0,'#07090b00');glow.addColorStop(.38,'#ffc47712');glow.addColorStop(.68,'#83e6de13');glow.addColorStop(1,'#07090b00');ctx.fillStyle=glow;ctx.fillRect(0,0,w,h);
    ctx.save();ctx.translate(cx,cy);ctx.rotate(-.17+time*.07);ctx.scale(1,.27);
    const disk=ctx.createRadialGradient(0,0,r*.88,0,0,r*1.85);disk.addColorStop(0,'#07090b00');disk.addColorStop(.21,'#07090b00');disk.addColorStop(.32,'#83e6de66');disk.addColorStop(.39,'#ffc477');disk.addColorStop(.46,'#ffe8bd99');disk.addColorStop(.57,'#83e6de24');disk.addColorStop(1,'#07090b00');ctx.fillStyle=disk;ctx.beginPath();ctx.arc(0,0,r*1.85,0,Math.PI*2);ctx.fill();
    const bright=ctx.createLinearGradient(-r*1.6,0,r*1.6,0);bright.addColorStop(0,'#ffc47708');bright.addColorStop(.62,'#ffc47708');bright.addColorStop(.8,'#fff0d0cc');bright.addColorStop(1,'#fff0d01a');ctx.strokeStyle=bright;ctx.lineWidth=Math.max(2,r*.07);ctx.beginPath();ctx.ellipse(0,0,r*1.3,r*1.3,0,Math.PI,Math.PI*2);ctx.stroke();ctx.restore();
    const ring=ctx.createRadialGradient(cx,cy,r*.94,cx,cy,r*1.12);ring.addColorStop(0,'#030405');ring.addColorStop(.76,'#030405');ring.addColorStop(.85,'#ffe1af');ring.addColorStop(.92,'#83e6de99');ring.addColorStop(1,'#07090b00');ctx.fillStyle=ring;ctx.beginPath();ctx.arc(cx,cy,r*1.12,0,Math.PI*2);ctx.fill();
  };
  const start=()=>{if(!running&&!document.hidden){running=true;render()}};const stop=()=>{running=false;cancelAnimationFrame(frame)};
  resize();new IntersectionObserver(([entry])=>entry.isIntersecting?start():stop(),{threshold:0}).observe(hero);
  document.addEventListener('visibilitychange',()=>document.hidden?stop():start());addEventListener('resize',resize,{passive:true});
  addEventListener('scroll',()=>{scrollFactor=Math.min(1,Math.max(0,scrollY/Math.max(1,hero.offsetHeight)))},{passive:true});
  hero.addEventListener('pointermove',event=>{if(event.pointerType==='touch')return;const rect=hero.getBoundingClientRect();targetX=(event.clientX-rect.left)/rect.width-.5;targetY=(event.clientY-rect.top)/rect.height-.5},{passive:true});
  hero.addEventListener('pointerleave',()=>{targetX=0;targetY=0},{passive:true});
}
