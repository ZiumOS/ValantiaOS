document.addEventListener('DOMContentLoaded', () => {
  const menu = document.querySelector('.menu-toggle');
  const nav = document.querySelector('.site-nav');
  if (menu && nav) {
    menu.addEventListener('click', () => {
      const open = menu.getAttribute('aria-expanded') === 'true';
      menu.setAttribute('aria-expanded', String(!open));
      menu.setAttribute('aria-label', open ? 'Open menu' : 'Close menu');
      nav.classList.toggle('is-open', !open);
    });
    nav.addEventListener('click', event => {
      if (event.target.closest('a')) {
        menu.setAttribute('aria-expanded', 'false');
        menu.setAttribute('aria-label', 'Open menu');
        nav.classList.remove('is-open');
      }
    });
  }

  document.querySelectorAll('[data-copy]').forEach(button => {
    button.addEventListener('click', async () => {
      const code = document.getElementById(button.dataset.copy);
      if (!code) return;
      try {
        await navigator.clipboard.writeText(code.textContent.trim());
        button.textContent = 'Copied';
        window.setTimeout(() => { button.textContent = 'Copy'; }, 1600);
      } catch {
        button.textContent = 'Copy unavailable';
        window.setTimeout(() => { button.textContent = 'Copy'; }, 2000);
      }
    });
  });
  document.querySelectorAll('.copyright').forEach(node => {
    node.textContent = `© ${new Date().getFullYear()} VALANTIAOS PROJECT`;
  });
});
