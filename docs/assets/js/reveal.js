export function initReveals() {
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const items = document.querySelectorAll('.section-label,.intro-grid>*,.stat-line,.section-heading,.feature-card,.features-footnote,.boot-copy>*,.terminal,.desktop-intro>*,.screenshot-placeholder,.download-grid>*,.safety-note,.build-grid>*,.faq-grid>*');
  if (reduceMotion || !('IntersectionObserver' in window)) return;
  items.forEach((item, index) => { item.classList.add('reveal'); if (item.classList.contains('feature-card')) item.style.setProperty('--reveal-delay', `${index % 4 * 70}ms`); });
  const observer = new IntersectionObserver(entries => entries.forEach(entry => {
    if (entry.isIntersecting) { entry.target.classList.add('is-visible'); observer.unobserve(entry.target); }
  }), { threshold: .12 });
  items.forEach(item => observer.observe(item));
}

export function initScrollUI() {
  const header = document.querySelector('.site-header');
  const progress = document.querySelector('.scroll-progress span');
  const links = [...document.querySelectorAll('.site-nav a[href^="#"]')];
  let ticking = false;
  const update = () => {
    const max = document.documentElement.scrollHeight - innerHeight;
    if (progress) progress.style.transform = `scaleX(${max > 0 ? scrollY / max : 0})`;
    header?.classList.toggle('is-scrolled', scrollY > 18);
    ticking = false;
  };
  addEventListener('scroll', () => { if (!ticking) { ticking = true; requestAnimationFrame(update); } }, { passive: true });
  update();
  if ('IntersectionObserver' in window && links.length) {
    const sections = links.map(link => document.querySelector(link.getAttribute('href'))).filter(Boolean);
    const observer = new IntersectionObserver(entries => entries.forEach(entry => {
      if (entry.isIntersecting) links.forEach(link => link.classList.toggle('is-active', link.hash === `#${entry.target.id}`));
    }), { rootMargin: '-25% 0px -65% 0px' });
    sections.forEach(section => observer.observe(section));
  }
}

export function initInteractions() {
  const touch = matchMedia('(hover: none)').matches;
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!touch && !reduceMotion) document.querySelectorAll('[data-tilt]').forEach(card => {
    card.addEventListener('pointermove', event => {
      const rect = card.getBoundingClientRect();
      const x = (event.clientX - rect.left) / rect.width, y = (event.clientY - rect.top) / rect.height;
      card.style.setProperty('--mx', `${x * 100}%`); card.style.setProperty('--my', `${y * 100}%`);
      card.style.transform = `rotateX(${(0.5 - y) * 5}deg) rotateY(${(x - 0.5) * 5}deg) translateY(-2px)`;
    });
    card.addEventListener('pointerleave', () => { card.style.transform = ''; card.style.setProperty('--mx', '50%'); card.style.setProperty('--my', '50%'); });
  });
  if (!touch && !reduceMotion) document.querySelectorAll('.magnetic').forEach(button => {
    button.addEventListener('pointermove', event => {
      const rect = button.getBoundingClientRect();
      button.style.transform = `translate(${(event.clientX - rect.left - rect.width / 2) * .08}px, ${(event.clientY - rect.top - rect.height / 2) * .12}px)`;
    });
    button.addEventListener('pointerleave', () => { button.style.transform = ''; });
  });
}
