import { initBlackhole } from './blackhole.js';
import { initInteractions, initReveals, initScrollUI } from './reveal.js';
import { initTerminal } from './terminal.js';

document.addEventListener('DOMContentLoaded', () => {
  const cursor = document.querySelector('.cursor-glow');
  if (cursor && matchMedia('(hover: hover) and (pointer: fine)').matches && !matchMedia('(prefers-reduced-motion: reduce)').matches) {
    document.addEventListener('pointermove', event => { cursor.style.setProperty('--x', `${event.clientX}px`); cursor.style.setProperty('--y', `${event.clientY}px`); }, { passive: true });
  } else cursor?.remove();

  const menu = document.querySelector('.menu-toggle');
  const nav = document.querySelector('.site-nav');
  if (menu && nav) {
    menu.addEventListener('click', () => {
      const open = menu.getAttribute('aria-expanded') === 'true';
      menu.setAttribute('aria-expanded', String(!open));
      menu.setAttribute('aria-label', open ? 'Open navigation' : 'Close navigation');
      nav.classList.toggle('is-open', !open);
    });
    nav.addEventListener('click', event => {
      if (event.target.closest('a')) {
        menu.setAttribute('aria-expanded', 'false'); menu.setAttribute('aria-label', 'Open navigation'); nav.classList.remove('is-open');
      }
    });
  }
  document.querySelectorAll('[data-copy]').forEach(button => button.addEventListener('click', async () => {
    const code = document.getElementById(button.dataset.copy);
    if (!code) return;
    try { await navigator.clipboard.writeText(code.textContent.trim()); button.textContent = 'Copied'; }
    catch { button.textContent = 'Clipboard unavailable'; }
    window.setTimeout(() => { button.textContent = 'Copy'; }, 1800);
  }));
  initBlackhole(); initReveals(); initScrollUI(); initInteractions(); initTerminal();
});
