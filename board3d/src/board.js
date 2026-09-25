// Le plateau : un coffret en noyer, une toile de lin, des cases en céramique
// émaillée posées dessus, des socles laqués pour les quatre maisons et un
// centre en pyramide.
import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js';
import layout from './layout.json';
import { glazeNormalMap, linenTexture, woodTextures } from './textures.js';

export const COLORS = {
  red: 0xe53935,
  blue: 0x1e88e5,
  green: 0x43a047,
  yellow: 0xfdd835,
};

/** Hauteur du dessus des cases : les pions se posent là. */
export const TILE_TOP = 0.12;
/** Hauteur du dessus des plateaux de maison, où attendent les pions. */
export const BASE_TOP = 0.26;

/** Centre de la case (ligne, colonne) de la grille 15×15, dans la scène. */
export function cellToWorld(row, col) {
  return new THREE.Vector3(col - 7, 0, row - 7);
}

const BASE_REGIONS = {
  red: [0, 0],
  blue: [0, 9],
  green: [9, 9],
  yellow: [9, 0],
};

function shadowed(mesh, cast = true, receive = true) {
  mesh.castShadow = cast;
  mesh.receiveShadow = receive;
  return mesh;
}

export function buildBoard() {
  const group = new THREE.Group();
  const wood = woodTextures();
  const glaze = glazeNormalMap();

  const woodMat = new THREE.MeshPhysicalMaterial({
    map: wood.map,
    roughnessMap: wood.roughness,
    roughness: 1,
    clearcoat: 0.6,
    clearcoatRoughness: 0.25,
  });
  const goldMat = new THREE.MeshStandardMaterial({
    color: 0xd9a441,
    metalness: 1,
    roughness: 0.28,
  });
  const ivoryMat = new THREE.MeshPhysicalMaterial({
    color: 0xfbf6ea,
    roughness: 0.32,
    clearcoat: 0.8,
    clearcoatRoughness: 0.12,
    normalMap: glaze,
    normalScale: new THREE.Vector2(0.35, 0.35),
  });
  const lacquer = {};
  for (const [name, hex] of Object.entries(COLORS)) {
    lacquer[name] = new THREE.MeshPhysicalMaterial({
      color: hex,
      roughness: 0.34,
      clearcoat: 1,
      clearcoatRoughness: 0.08,
      normalMap: glaze,
      normalScale: new THREE.Vector2(0.25, 0.25),
    });
  }

  // ── Le coffret en bois ────────────────────────────────────────────────────
  const slab = shadowed(
    new THREE.Mesh(new RoundedBoxGeometry(16.6, 0.7, 16.6, 4, 0.28), woodMat),
  );
  slab.position.y = -0.35;
  group.add(slab);

  // Rebord : quatre baguettes qui dépassent un peu du plateau.
  const rimGeo = new RoundedBoxGeometry(16.6, 0.34, 0.62, 3, 0.14);
  for (let i = 0; i < 4; i++) {
    const rim = shadowed(new THREE.Mesh(rimGeo, woodMat));
    const a = (i * Math.PI) / 2;
    rim.rotation.y = a;
    rim.position.set(Math.sin(a) * 7.99, 0.02, Math.cos(a) * 7.99);
    group.add(rim);
  }

  // Filet d'or entre le rebord et la toile.
  const inlayGeo = new THREE.BoxGeometry(15.36, 0.05, 0.08);
  for (let i = 0; i < 4; i++) {
    const inlay = shadowed(new THREE.Mesh(inlayGeo, goldMat), false, true);
    const a = (i * Math.PI) / 2;
    inlay.rotation.y = a;
    inlay.position.set(Math.sin(a) * 7.62, 0.02, Math.cos(a) * 7.62);
    group.add(inlay);
  }

  // ── La toile, visible dans les joints entre les cases ────────────────────
  const cloth = shadowed(
    new THREE.Mesh(
      new THREE.PlaneGeometry(15.2, 15.2),
      new THREE.MeshStandardMaterial({ map: linenTexture(8), roughness: 0.95 }),
    ),
    false,
    true,
  );
  cloth.rotation.x = -Math.PI / 2;
  cloth.position.y = 0.001;
  group.add(cloth);

  // ── Les cases ─────────────────────────────────────────────────────────────
  const tileGeo = new RoundedBoxGeometry(0.92, TILE_TOP, 0.92, 2, 0.05);
  tileGeo.translate(0, TILE_TOP / 2, 0);

  const colored = new Map(); // "r,c" → nom de couleur
  const startIdx = new Map(
    Object.entries(layout.startPositions).map(([c, i]) => [i, c]),
  );
  for (const [idx, color] of startIdx.entries()) {
    const [r, c] = layout.outerPath[idx];
    colored.set(`${r},${c}`, color);
  }
  for (const [color, cells] of Object.entries(layout.homeColumns)) {
    for (const [r, c] of cells.slice(0, -1)) colored.set(`${r},${c}`, color);
  }

  const ivoryCells = layout.outerPath.filter(
    ([r, c]) => !colored.has(`${r},${c}`),
  );
  const ivoryTiles = new THREE.InstancedMesh(tileGeo, ivoryMat, ivoryCells.length);
  const m = new THREE.Matrix4();
  ivoryCells.forEach(([r, c], i) => {
    m.makeTranslation(cellToWorld(r, c));
    ivoryTiles.setMatrixAt(i, m);
  });
  shadowed(ivoryTiles);
  group.add(ivoryTiles);

  for (const [key, color] of colored.entries()) {
    const [r, c] = key.split(',').map(Number);
    const tile = shadowed(new THREE.Mesh(tileGeo, lacquer[color]));
    tile.position.copy(cellToWorld(r, c));
    group.add(tile);
  }

  // ── Étoiles des cases sûres, en or repoussé ──────────────────────────────
  const starGeo = new THREE.ExtrudeGeometry(starShape(0.32, 0.14), {
    depth: 0.04,
    bevelEnabled: true,
    bevelThickness: 0.025,
    bevelSize: 0.025,
    bevelSegments: 2,
  });
  starGeo.rotateX(-Math.PI / 2);
  for (const idx of layout.safeZones) {
    if (startIdx.has(idx)) continue;
    const [r, c] = layout.outerPath[idx];
    const star = shadowed(new THREE.Mesh(starGeo, goldMat));
    star.position.copy(cellToWorld(r, c)).setY(TILE_TOP);
    group.add(star);
  }

  // ── Flèches de départ ─────────────────────────────────────────────────────
  const arrowGeo = new THREE.ExtrudeGeometry(arrowShape(), {
    depth: 0.03,
    bevelEnabled: true,
    bevelThickness: 0.02,
    bevelSize: 0.02,
    bevelSegments: 2,
  });
  arrowGeo.rotateX(-Math.PI / 2);
  const arrowMat = new THREE.MeshPhysicalMaterial({
    color: 0xffffff,
    roughness: 0.2,
    clearcoat: 1,
  });
  for (const idx of startIdx.keys()) {
    const [r, c] = layout.outerPath[idx];
    const [nr, nc] = layout.outerPath[(idx + 1) % layout.outerPath.length];
    const arrow = shadowed(new THREE.Mesh(arrowGeo, arrowMat));
    arrow.position.copy(cellToWorld(r, c)).setY(TILE_TOP);
    // La forme pointe vers +x ; on la tourne vers la case suivante.
    arrow.rotation.y = -Math.atan2(nr - r, nc - c);
    group.add(arrow);
  }

  // ── Les quatre maisons ────────────────────────────────────────────────────
  const baseGeo = new RoundedBoxGeometry(5.84, 0.18, 5.84, 4, 0.16);
  baseGeo.translate(0, 0.09, 0);
  const wellGeo = new RoundedBoxGeometry(4.0, 0.08, 4.0, 3, 0.2);
  wellGeo.translate(0, 0.18 + 0.04, 0);
  const padGeo = new THREE.CylinderGeometry(0.44, 0.46, 0.02, 40);
  const ringGeo = new THREE.TorusGeometry(0.46, 0.05, 12, 48);
  ringGeo.rotateX(Math.PI / 2);

  for (const [color, [r0, c0]] of Object.entries(BASE_REGIONS)) {
    const centre = cellToWorld(r0 + 2.5, c0 + 2.5);
    const tray = shadowed(new THREE.Mesh(baseGeo, lacquer[color]));
    tray.position.copy(centre);
    group.add(tray);

    const well = shadowed(new THREE.Mesh(wellGeo, ivoryMat));
    well.position.copy(centre);
    group.add(well);

    const padMat = new THREE.MeshStandardMaterial({
      color: new THREE.Color(COLORS[color]).lerp(new THREE.Color(0xffffff), 0.72),
      roughness: 0.6,
    });
    for (const [r, c] of layout.basePositions[color]) {
      const p = cellToWorld(r, c);
      const pad = shadowed(new THREE.Mesh(padGeo, padMat), false, true);
      pad.position.set(p.x, BASE_TOP + 0.005, p.z);
      group.add(pad);
      const ring = shadowed(new THREE.Mesh(ringGeo, lacquer[color]));
      ring.position.set(p.x, BASE_TOP + 0.01, p.z);
      group.add(ring);
    }
  }

  // ── Le centre : quatre pans en pente vers un joyau ───────────────────────
  // Chaque pan part du côté de sa couleur et monte vers le milieu.
  const apex = new THREE.Vector3(0, 0.62, 0);
  const h = 1.5;
  const corners = {
    blue: [new THREE.Vector3(-h, TILE_TOP, -h), new THREE.Vector3(h, TILE_TOP, -h)],
    green: [new THREE.Vector3(h, TILE_TOP, -h), new THREE.Vector3(h, TILE_TOP, h)],
    yellow: [new THREE.Vector3(h, TILE_TOP, h), new THREE.Vector3(-h, TILE_TOP, h)],
    red: [new THREE.Vector3(-h, TILE_TOP, h), new THREE.Vector3(-h, TILE_TOP, -h)],
  };
  for (const [color, [a, b]] of Object.entries(corners)) {
    const g = new THREE.BufferGeometry().setFromPoints([a, apex, b]);
    g.computeVertexNormals();
    const face = shadowed(new THREE.Mesh(g, lacquer[color]));
    group.add(face);
  }
  const plinth = shadowed(
    new THREE.Mesh(new RoundedBoxGeometry(3.06, TILE_TOP, 3.06, 2, 0.04), goldMat),
  );
  plinth.position.y = TILE_TOP / 2 - 0.001;
  group.add(plinth);

  const gem = shadowed(
    new THREE.Mesh(
      new THREE.OctahedronGeometry(0.26, 0),
      new THREE.MeshPhysicalMaterial({
        // Pas de transmission : elle coûte une passe de rendu en plus, et
        // l'irisation suffit à faire briller la pierre sur un téléphone.
        color: 0xf4f0ff,
        metalness: 0.35,
        roughness: 0.06,
        clearcoat: 1,
        iridescence: 1,
        iridescenceIOR: 1.8,
        emissive: 0x6a4cff,
        emissiveIntensity: 0.12,
      }),
    ),
  );
  gem.position.set(0, 0.86, 0);
  gem.scale.y = 1.35;
  group.add(gem);

  return { group, gem };
}

/**
 * Où se pose un pion arrivé au centre : sur le pan de sa couleur, à mi-pente.
 * [slot] (0..3) écarte les pions d'une même couleur.
 */
export function homeSpot(color, slot) {
  const dir = {
    red: [-1, 0],
    blue: [0, -1],
    green: [1, 0],
    yellow: [0, 1],
  }[color];
  const along = (slot - 1.5) * 0.52;
  const x = dir[0] * 0.95 + (dir[1] !== 0 ? along : 0);
  const z = dir[1] * 0.95 + (dir[0] !== 0 ? along : 0);
  // Hauteur du pan à cet endroit : il monte de TILE_TOP à 0.62 sur 1.5.
  const y = TILE_TOP + (0.62 - TILE_TOP) * (1 - 0.95 / 1.5) + 0.04;
  return new THREE.Vector3(x, y, z);
}

function starShape(outer, inner) {
  const s = new THREE.Shape();
  for (let i = 0; i < 10; i++) {
    const a = (i * Math.PI) / 5 + Math.PI / 2;
    const r = i % 2 === 0 ? outer : inner;
    const x = Math.cos(a) * r;
    const y = Math.sin(a) * r;
    if (i === 0) s.moveTo(x, y);
    else s.lineTo(x, y);
  }
  s.closePath();
  return s;
}

function arrowShape() {
  const s = new THREE.Shape();
  s.moveTo(0.26, 0);
  s.lineTo(-0.04, 0.22);
  s.lineTo(-0.04, 0.08);
  s.lineTo(-0.28, 0.08);
  s.lineTo(-0.28, -0.08);
  s.lineTo(-0.04, -0.08);
  s.lineTo(-0.04, -0.22);
  s.closePath();
  return s;
}
