// ─── Global State ─────────────────────────────────────────────────────────────
let WALLPAPERS = [];
let activeCategory = "all";
let visibleCount = 12;
let filtered = [];

// ─── Custom Cursor ─────────────────────────────────────────────────────────────
const cursor = document.getElementById('cursor');
const cursorRing = document.getElementById('cursor-ring');

let mouseX = 0, mouseY = 0;
let ringX = 0, ringY = 0;

document.addEventListener('mousemove', e => {
  mouseX = e.clientX;
  mouseY = e.clientY;
  if (cursor) {
    cursor.style.left = mouseX + 'px';
    cursor.style.top = mouseY + 'px';
  }
});

function animateRing() {
  ringX += (mouseX - ringX) * 0.12;
  ringY += (mouseY - ringY) * 0.12;
  if (cursorRing) {
    cursorRing.style.left = ringX + 'px';
    cursorRing.style.top = ringY + 'px';
  }
  requestAnimationFrame(animateRing);
}
animateRing();

// ─── Nav ───────────────────────────────────────────────────────────────────────
window.addEventListener('scroll', () => {
  const nav = document.getElementById('nav');
  if (nav) nav.classList.toggle('scrolled', window.scrollY > 60);
});

// ─── Data ──────────────────────────────────────────────────────────────────────
const API_URL = "https://huggingface.co/api/datasets/Rineshbuzz/wallpapers/tree/main";
const BASE_CDN = "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/";

async function init() {
  console.log("🚀 Initializing high-speed storage from Hugging Face...");
  try {
    const res = await fetch(API_URL);
    if (!res.ok) throw new Error(`HTTP Error: ${res.status}`);
    const data = await res.json();
    
    // Filter for MP4 files and map to our format
    WALLPAPERS = data
      .filter(item => item.path.toLowerCase().endsWith('.mp4'))
      .map(item => {
        const filename = item.path;
        const parts = filename.split('_');
        return {
          id: filename,
          title: parts.length > 1 ? parts.slice(1).join(' ').replace('.mp4', '') : filename.replace('.mp4', ''),
          cat: parts.length > 1 ? parts[0].toLowerCase() : "nature",
          video: BASE_CDN + filename,
          thumb: BASE_CDN + filename, 
          free: true 
        };
      });

    console.log("✅ Successfully loaded", WALLPAPERS.length, "high-end wallpapers");
  } catch (err) {
    console.error("❌ HF API Error, falling back:", err);
    // Fallback to local if needed
    WALLPAPERS = [];
  }

  applyFilters();

  // Set up hero background cycler
  if (WALLPAPERS.length > 0) {
    cycleHeroBackground();
    setInterval(cycleHeroBackground, 60000); // Every 60 seconds
  }
}

async function cycleHeroBackground() {
  const video = document.getElementById('heroVideo');
  if (!video || WALLPAPERS.length === 0) return;
  
  const random = WALLPAPERS[Math.floor(Math.random() * WALLPAPERS.length)];
  
  // Fade out
  video.style.opacity = 0;
  
  setTimeout(() => {
    video.src = random.video;
    video.play().catch(() => {});
    
    video.onloadeddata = () => {
      video.style.opacity = 0.8;
    };
  }, 1000);
}

// Hover listeners for video previews
document.addEventListener('mouseover', e => {
  const item = e.target.closest('.thumb-container');
  if (item) {
    const vid = item.querySelector('.thumb-video');
    if (vid) vid.play().catch(() => {});
  }
});

document.addEventListener('mouseout', e => {
  const item = e.target.closest('.thumb-container');
  if (item) {
    const vid = item.querySelector('.thumb-video');
    if (vid) {
      vid.pause();
    }
  }
});


// ─── Filters ───────────────────────────────────────────────────────────────────
document.querySelectorAll('.pill-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.pill-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    activeCategory = btn.dataset.cat;
    visibleCount = 12;
    applyFilters();
  });
});

function applyFilters() {
  filtered = activeCategory === 'all'
    ? [...WALLPAPERS]
    : activeCategory === 'premium'
    ? WALLPAPERS.filter(w => !w.free)
    : WALLPAPERS.filter(w => w.cat === activeCategory);
  renderGrid();
}

// ─── Grid Render ─────────────────────────────────────────────────────
function renderGrid() {
  const grid = document.getElementById('wallpaperGrid');
  if (!grid) return;
  const slice = filtered.slice(0, visibleCount);

  if (!slice.length) {
    grid.innerHTML = `<p style="color: var(--muted); padding: 60px 0; text-align: center; grid-column: 1/-1;">Nothing here yet. Check back soon.</p>`;
    return;
  }

  grid.innerHTML = slice.map(w => {
    const isPro = !w.free;
    const videoUrl = w.video;
    const thumbUrl = w.thumb;
    
    const fallbacks = {
      nature: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&q=60&w=800',
      city: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&q=60&w=800',
      space: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&q=60&w=800',
      abstract: 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&q=60&w=800',
      minimal: 'https://images.unsplash.com/photo-1494438639946-1ebd1d20bf85?auto=format&fit=crop&q=60&w=800'
    };
    const fallback = fallbacks[w.cat?.toLowerCase()] || fallbacks.minimal;
    const isVideoThumb = thumbUrl.toLowerCase().endsWith('.mp4');

    const thumbHtml = `
      <div class="thumb-container">
        ${isVideoThumb 
          ? `<video src="${thumbUrl}" muted loop playsinline autoplay class="thumb-img"></video>`
          : `<img src="${thumbUrl}" alt="${w.title}" loading="lazy" class="thumb-img" 
               onerror="this.src='${fallback}'; this.style.opacity='0.8';" />`
        }
        <video src="${videoUrl}" muted loop playsinline class="thumb-video" oncontextmenu="return false;" controlsList="nodownload"></video>
      </div>
    `;

    return `
      <div class="masonry-item ${isPro ? 'is-pro' : ''}" onclick="openLightbox('${w.id}')">
        ${thumbHtml}
        ${isPro ? `<div class="pro-badge">PRO</div>
        <div class="pro-lock">
          <div class="pro-lock-icon">🔒</div>
          <div class="pro-lock-text">Pro</div>
        </div>` : ''}
        <div class="masonry-info">
          <div class="masonry-name">${w.title}</div>
          <div class="masonry-tag">${w.cat}</div>
        </div>
      </div>
    `;
  }).join('');

  const loadMoreBtn = document.getElementById('loadMoreBtn');
  if (loadMoreBtn) {
    loadMoreBtn.style.display = visibleCount >= filtered.length ? 'none' : 'inline-flex';
  }
}

const loadMoreBtn = document.getElementById('loadMoreBtn');
if (loadMoreBtn) {
  loadMoreBtn.addEventListener('click', () => {
    visibleCount += 12;
    renderGrid();
  });
}

// ─── Lightbox ─────────────────────────────────────────────────────────────────
window.openLightbox = function(id) {
  const w = WALLPAPERS.find(x => x.id === id);
  if (!w) return;

  const lb = document.getElementById('lightbox');
  const vid = document.getElementById('lightboxVideo');
  if (!lb || !vid) return;

  vid.src = w.video;
  vid.play();
  document.getElementById('lightboxTitle').textContent = w.title;
  document.getElementById('lightboxCat').textContent = `${w.cat} · ${w.free ? 'Free' : 'Pro'}`;

  document.getElementById('lightboxActions').innerHTML = 
    `<button class="btn-pill btn-fill" style="font-size:13px;" onclick="goToPricing()">Use in App</button>`;

  lb.classList.add('open');
};

window.closeLightbox = function() {
  const lb = document.getElementById('lightbox');
  const vid = document.getElementById('lightboxVideo');
  if (lb) lb.classList.remove('open');
  if (vid) vid.pause();
};

window.goToPricing = function() {
  window.closeLightbox();
  const pricing = document.getElementById('pricing');
  if (pricing) pricing.scrollIntoView({ behavior: 'smooth' });
};

const closeBtn = document.getElementById('lightboxClose');
if (closeBtn) closeBtn.addEventListener('click', window.closeLightbox);

const lbBg = document.getElementById('lightbox');
if (lbBg) {
  lbBg.addEventListener('click', e => {
    if (e.target === lbBg) window.closeLightbox();
  });
}

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') window.closeLightbox();
});

// ─── Gumroad Checkout ──────────────────────────────────────────────────────────
const GUMROAD_URL = 'https://rineshba.gumroad.com/l/zwcysk';

window.openCheckout = function() {
  // The Gumroad script will automatically pick up clicks on elements with 'gumroad-button' class.
  // This function remains as a fallback or for dynamic triggers.
  window.location.href = GUMROAD_URL;
};

// ─── Boot ──────────────────────────────────────────────────────────────────────
init();
