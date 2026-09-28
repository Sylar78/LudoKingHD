// Textures générées au lancement, dans un canvas : aucune image dans le
// dépôt, et le fichier HTML embarqué reste autonome.
import * as THREE from 'three';

// ── Bruit de valeur lissé, suffisant pour du bois et du lin ────────────────
function hash(x, y) {
  let h = x * 374761393 + y * 668265263;
  h = (h ^ (h >>> 13)) * 1274126177;
  return ((h ^ (h >>> 16)) >>> 0) / 4294967295;
}

function smooth(t) {
  return t * t * (3 - 2 * t);
}

function valueNoise(x, y, period) {
  const xi = Math.floor(x);
  const yi = Math.floor(y);
  const xf = smooth(x - xi);
  const yf = smooth(y - yi);
  const w = (v) => ((v % period) + period) % period;
  const a = hash(w(xi), w(yi));
  const b = hash(w(xi + 1), w(yi));
  const c = hash(w(xi), w(yi + 1));
  const d = hash(w(xi + 1), w(yi + 1));
  return a + (b - a) * xf + (c - a) * yf + (a - b - c + d) * xf * yf;
}

/** Bruit fractal qui se répète sur [period] : la texture se raccorde. */
function fbm(x, y, period, octaves = 4) {
  let sum = 0;
  let amp = 0.5;
  let freq = 1;
  for (let i = 0; i < octaves; i++) {
    sum += amp * valueNoise(x * freq, y * freq, period * freq);
    amp *= 0.5;
    freq *= 2;
  }
  return sum;
}

function canvasTexture(size, paint, { srgb = true, repeat = 1 } = {}) {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  const img = ctx.createImageData(size, size);
  paint(img.data, size);
  ctx.putImageData(img, 0, 0);
  const tex = new THREE.CanvasTexture(canvas);
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(repeat, repeat);
  // 4 laissait les cases et le plateau se brouiller en angle de vue rasant,
  // le point le plus visible de la scène ; 8 passe sur la quasi-totalité des
  // GPU mobiles actuels.
  tex.anisotropy = 8;
  if (srgb) tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

const mix = (a, b, t) => a + (b - a) * t;

/** Noyer verni : veines allongées, cernes, et une rugosité qui suit le fil. */
export function woodTextures() {
  const size = 1024;
  const grain = new Float32Array(size * size);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const u = x / size;
      const v = y / size;
      const warp = fbm(u * 4, v * 16, 4 * 16, 4) * 2.2;
      const rings = Math.sin((v * 22 + warp) * Math.PI);
      const fine = fbm(u * 64, v * 256, 64 * 256, 2);
      grain[y * size + x] = Math.min(1, Math.max(0, 0.5 + rings * 0.32 + (fine - 0.5) * 0.5));
    }
  }
  const dark = [58, 30, 16];
  const light = [132, 78, 42];
  const map = canvasTexture(size, (d) => {
    for (let i = 0; i < size * size; i++) {
      const g = grain[i];
      d[i * 4] = mix(dark[0], light[0], g);
      d[i * 4 + 1] = mix(dark[1], light[1], g);
      d[i * 4 + 2] = mix(dark[2], light[2], g);
      d[i * 4 + 3] = 255;
    }
  });
  const roughness = canvasTexture(
    size,
    (d) => {
      for (let i = 0; i < size * size; i++) {
        const r = 90 + (1 - grain[i]) * 90;
        d[i * 4] = d[i * 4 + 1] = d[i * 4 + 2] = r;
        d[i * 4 + 3] = 255;
      }
    },
    { srgb: false },
  );
  return { map, roughness };
}

/** Toile de lin ivoire sous les cases : on la voit dans les joints. */
export function linenTexture(repeat = 6) {
  const size = 512;
  return canvasTexture(
    size,
    (d) => {
      for (let y = 0; y < size; y++) {
        for (let x = 0; x < size; x++) {
          const warp = Math.sin((x / size) * Math.PI * 2 * 48) * 0.5 + 0.5;
          const weft = Math.sin((y / size) * Math.PI * 2 * 48) * 0.5 + 0.5;
          const n = fbm((x / size) * 16, (y / size) * 16, 16, 3);
          const t = 0.55 * n + 0.22 * warp + 0.23 * weft;
          const i = (y * size + x) * 4;
          d[i] = mix(186, 222, t);
          d[i + 1] = mix(170, 206, t);
          d[i + 2] = mix(138, 170, t);
          d[i + 3] = 255;
        }
      }
    },
    { repeat },
  );
}

/**
 * Carte de normales d'une céramique émaillée : de très légères ondulations
 * qui cassent le reflet, comme sur un carreau fait main.
 */
export function glazeNormalMap() {
  const size = 512;
  const h = new Float32Array(size * size);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      h[y * size + x] = fbm((x / size) * 6, (y / size) * 6, 6, 4);
    }
  }
  const at = (x, y) => h[((y + size) % size) * size + ((x + size) % size)];
  return canvasTexture(
    size,
    (d) => {
      const strength = 2.4;
      for (let y = 0; y < size; y++) {
        for (let x = 0; x < size; x++) {
          const dx = (at(x + 1, y) - at(x - 1, y)) * strength;
          const dy = (at(x, y + 1) - at(x, y - 1)) * strength;
          const len = Math.hypot(dx, dy, 1);
          const i = (y * size + x) * 4;
          d[i] = ((-dx / len) * 0.5 + 0.5) * 255;
          d[i + 1] = ((-dy / len) * 0.5 + 0.5) * 255;
          d[i + 2] = ((1 / len) * 0.5 + 0.5) * 255;
          d[i + 3] = 255;
        }
      }
    },
    { srgb: false },
  );
}
