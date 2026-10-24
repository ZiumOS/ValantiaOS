const lines = [
  ['GRUB live menu loaded', 220],
  ['ValantiaOS Gaming · Debian 13 Trixie', 850],
  ['Booting Linux live system on AMD64', 1450],
  ['Starting live session services', 2100],
  ['Starting LightDM display manager', 2780],
  ['Launching XFCE desktop session', 3450],
  ['Live desktop ready · user session', 4150]
];

export function initTerminal() {
  const list = document.querySelector('.boot-lines');
  if (!list) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduced) { lines.forEach(([text]) => { const li=document.createElement('li'); li.textContent=text; li.classList.add('is-done'); list.append(li); }); return; }
  const draw = () => {
    list.replaceChildren();
    lines.forEach(([text, delay], index) => {
      window.setTimeout(() => {
        const previous = list.lastElementChild;
        previous?.classList.replace('is-current', 'is-done');
        const item = document.createElement('li'); item.textContent=text; item.className='is-current'; item.style.animationDelay='0ms'; list.append(item);
        if (index === lines.length - 1) window.setTimeout(draw, 5600);
      }, delay);
    });
  };
  const observer = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting) { draw(); observer.disconnect(); }
  }, { threshold: .35 });
  observer.observe(list.closest('.terminal'));
}
