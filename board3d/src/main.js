// Point d'entrée de la scène 3D embarquée par l'app Flutter.
//
// Le contrat avec Flutter tient en deux sens :
//   - Flutter appelle `window.ludoBoard.apply(snapshot)` à chaque changement
//     de partie (voir lib/widgets/board3d/board_snapshot.dart) ;
//   - la page répond par le canal `LudoBoard` : `{type: 'ready'}` une fois la
//     scène prête, `{type: 'tap', pawn: i}` quand le joueur touche un pion
//     jouable.
// La logique du jeu reste entièrement côté Dart : la page ne fait que montrer
// l'état qu'on lui donne et animer le dernier coup.
import * as THREE from 'three';
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js';
import { BASE_TOP, TILE_TOP, buildBoard, cellToWorld, homeSpot } from './board.js';
import { makeHighlightRing, makeShockwave, makeSparks } from './effects.js';
import layout from './layout.json';
import { buildPawn } from './pawns.js';

// ── Rendu ───────────────────────────────────────────────────────────────────
// Sans WebGL, on prévient Flutter, qui garde le plateau 2D.
window.addEventListener('error', (e) => send({ type: 'error', message: String(e.message) }));
let renderer;
try {
  renderer = new THREE.WebGLRenderer({
    antialias: true,
    alpha: true,
    powerPreference: 'high-performance',
  });
} catch (e) {
  send({ type: 'error', message: String(e) });
  throw e;
}
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
renderer.setClearColor(0x000000, 0);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
// Neutral plutôt qu'ACES : ACES délave les quatre couleurs vives du jeu.
renderer.toneMapping = THREE.NeutralToneMapping;
renderer.toneMappingExposure = 0.95;
renderer.outputColorSpace = THREE.SRGBColorSpace;
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
const pmrem = new THREE.PMREMGenerator(renderer);
scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
scene.environmentIntensity = 0.45;

// Lumière chaude en haut à gauche, qui porte les ombres ; un contre-jour
// froid pour détacher les figurines du plateau.
scene.add(new THREE.HemisphereLight(0xfff1e0, 0x2a1d4a, 0.35));
const key = new THREE.DirectionalLight(0xfff0dc, 2.0);
key.position.set(-7, 15, 6);
key.castShadow = true;
key.shadow.mapSize.set(2048, 2048);
Object.assign(key.shadow.camera, { left: -10, right: 10, top: 10, bottom: -10, near: 1, far: 40 });
key.shadow.bias = -0.0004;
key.shadow.normalBias = 0.02;
key.shadow.radius = 5;
scene.add(key);
const rim = new THREE.DirectionalLight(0xa9c4ff, 0.7);
rim.position.set(8, 6, -10);
scene.add(rim);

const { group: board } = buildBoard();
scene.add(board);

// ── Caméra : légèrement inclinée, recadrée pour que le coffret tienne ──────
const camera = new THREE.PerspectiveCamera(30, 1, 0.1, 100);
const target = new THREE.Vector3(0, 0, 0.75);
const viewDir = new THREE.Vector3(0, Math.cos(0.6), Math.sin(0.6)).normalize();
const extents = [];
for (const x of [-8.35, 8.35]) for (const z of [-8.35, 8.35]) for (const y of [-0.7, 0.4]) extents.push(new THREE.Vector3(x, y, z));

function fitCamera() {
  const w = window.innerWidth || 1;
  const h = window.innerHeight || 1;
  camera.aspect = w / h;
  let lo = 5;
  let hi = 120;
  for (let i = 0; i < 30; i++) {
    const d = (lo + hi) / 2;
    camera.position.copy(target).addScaledVector(viewDir, d);
    camera.lookAt(target);
    camera.updateProjectionMatrix();
    camera.updateMatrixWorld();
    const fits = extents.every((p) => {
      const v = p.clone().project(camera);
      return Math.abs(v.x) <= 0.985 && Math.abs(v.y) <= 0.985;
    });
    if (fits) hi = d;
    else lo = d;
  }
  camera.position.copy(target).addScaledVector(viewDir, hi);
  camera.lookAt(target);
  camera.updateProjectionMatrix();
  renderer.setSize(w, h, false);
  renderer.domElement.style.width = `${w}px`;
  renderer.domElement.style.height = `${h}px`;
  sparks.setPixelScale(h * renderer.getPixelRatio() / 600);
  dirty = true;
}

// ── Effets ──────────────────────────────────────────────────────────────────
const rings = [0, 1, 2, 3].map(() => {
  const r = makeHighlightRing();
  r.visible = false;
  scene.add(r);
  return r;
});
const shockwave = makeShockwave();
scene.add(shockwave);
const sparks = makeSparks();
scene.add(sparks.points);

// ── Pions ───────────────────────────────────────────────────────────────────
/** @type {Map<string, {obj: THREE.Group, color: string, player: number, index: number, pos: number, target: THREE.Vector3, scale: number}>} */
const pawns = new Map();
let rosterKey = '';
let snapshot = null;
let versions = null;
let moveAnim = null;
let captureAnim = null;
let queuedCapture = null;
let dirty = true;

const keyOf = (player, index) => `${player}:${index}`;

/** Où se tient un pion à la position [pos] (même codage que le modèle Dart). */
function spotFor(color, index, pos) {
  if (pos === -1) {
    const [r, c] = layout.basePositions[color][index % 4];
    return cellToWorld(r, c).setY(BASE_TOP);
  }
  if (pos >= 0 && pos <= 51) {
    const [r, c] = layout.outerPath[pos];
    return cellToWorld(r, c).setY(TILE_TOP);
  }
  if (pos === 105) return homeSpot(color, index);
  const [r, c] = layout.homeColumns[color][pos - 100];
  return cellToWorld(r, c).setY(TILE_TOP);
}

function rebuildRoster(players) {
  for (const p of pawns.values()) scene.remove(p.obj);
  pawns.clear();
  players.forEach((pl, pi) => {
    pl.pawns.forEach((pos, i) => {
      const obj = buildPawn(pl.color);
      obj.userData.key = keyOf(pi, i);
      const spot = spotFor(pl.color, i, pos);
      obj.position.copy(spot);
      scene.add(obj);
      pawns.set(keyOf(pi, i), { obj, color: pl.color, player: pi, index: i, pos, target: spot, scale: 1 });
    });
  });
}

/** Les pions qui se partagent une case s'écartent et rapetissent un peu. */
function layoutResting() {
  const byCell = new Map();
  for (const [k, p] of pawns) {
    if (moveAnim?.key === k) continue;
    if (captureAnim?.keys.has(k)) continue;
    const held = queuedCapture?.held.get(k);
    const pos = held ?? p.pos;
    p.target = spotFor(p.color, p.index, pos);
    p.scale = 1;
    if (pos < 0 || pos === 105) continue;
    const cell = `${p.target.x},${p.target.z}`;
    if (!byCell.has(cell)) byCell.set(cell, []);
    byCell.get(cell).push(p);
  }
  const spread = 0.21;
  const patterns = {
    2: [[-1, 0], [1, 0]],
    3: [[-1, -0.6], [1, -0.6], [0, 0.9]],
    4: [[-1, -1], [1, -1], [-1, 1], [1, 1]],
  };
  for (const group of byCell.values()) {
    const n = group.length;
    if (n < 2) continue;
    group.sort((a, b) => a.player - b.player || a.index - b.index);
    group.forEach((p, i) => {
      const [ox, oz] = patterns[n]?.[i] ?? [
        Math.cos((2 * Math.PI * i) / n) * 1.2,
        Math.sin((2 * Math.PI * i) / n) * 1.2,
      ];
      p.target = p.target.clone().add(new THREE.Vector3(ox * spread, 0, oz * spread));
      p.scale = 0.72;
    });
  }
  dirty = true;
}

function apply(next) {
  const players = next.players ?? [];
  const roster = players.map((p) => `${p.color}${p.pawns.length}`).join('|');
  const fresh = roster !== rosterKey || versions === null;
  if (roster !== rosterKey) {
    rosterKey = roster;
    rebuildRoster(players);
  }
  for (const p of pawns.values()) p.pos = players[p.player].pawns[p.index];
  snapshot = next;

  if (fresh) {
    // Première image, ou nouvelle partie : on pose tout sans rejouer le
    // dernier coup, qui a eu lieu avant que la page n'existe.
    versions = { move: next.move?.version ?? -1, capture: next.capture?.version ?? -1 };
    moveAnim = captureAnim = queuedCapture = null;
    layoutResting();
    for (const p of pawns.values()) {
      p.obj.position.copy(p.target);
      p.obj.scale.setScalar(p.scale);
    }
    return;
  }

  if (next.move && next.move.version > versions.move) {
    versions.move = next.move.version;
    startMove(next.move);
  }
  if (next.capture && next.capture.version > versions.capture) {
    versions.capture = next.capture.version;
    const held = new Map(next.capture.pawns.map((c) => [keyOf(c.player, c.pawn), c.fromPos]));
    const capture = { ...next.capture, held };
    if (moveAnim) queuedCapture = capture;
    else startCapture(capture);
  }
  layoutResting();
}

function startMove(move) {
  const p = pawns.get(keyOf(move.player, move.pawn));
  if (!p) return;
  const positions = [move.fromPos, ...move.path];
  const points = positions.map((pos) => spotFor(p.color, p.index, pos));
  // Le point de départ réel est là où la figurine se trouve à l'écran.
  points[0] = p.obj.position.clone();
  const steps = Math.max(1, move.path.length);
  moveAnim = {
    key: keyOf(move.player, move.pawn),
    points,
    t: 0,
    duration: Math.min(1.4, Math.max(0.2, steps * 0.2)),
  };
}

function startCapture(capture) {
  const keys = new Set();
  const flights = [];
  for (const c of capture.pawns) {
    const k = keyOf(c.player, c.pawn);
    const p = pawns.get(k);
    if (!p) continue;
    keys.add(k);
    flights.push({ p, from: p.obj.position.clone(), to: spotFor(p.color, p.index, -1) });
  }
  const at = spotFor('red', 0, capture.cellPos);
  shockwave.position.set(at.x, TILE_TOP + 0.02, at.z);
  shockwave.visible = true;
  sparks.burst(at);
  captureAnim = { keys, flights, t: 0, duration: 1.0 };
  queuedCapture = null;
  layoutResting();
}

// ── Boucle d'animation ──────────────────────────────────────────────────────
const clock = new THREE.Clock();
const easeInOut = (t) => (t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2);

function tick() {
  requestAnimationFrame(tick);
  const dt = Math.min(clock.getDelta(), 0.05);
  const time = clock.elapsedTime;

  if (moveAnim) {
    moveAnim.t += dt;
    const p = pawns.get(moveAnim.key);
    const n = moveAnim.points.length - 1;
    const u = Math.min(1, moveAnim.t / moveAnim.duration) * n;
    const i = Math.min(n - 1, Math.floor(u));
    const s = easeInOut(Math.min(1, u - i));
    const a = moveAnim.points[i];
    const b = moveAnim.points[i + 1];
    p.obj.position.lerpVectors(a, b, s);
    p.obj.position.y += Math.sin(Math.PI * s) * 0.75;
    // Écrasement à l'atterrissage, étirement en l'air.
    const squash = 1 - 0.18 * Math.max(0, 1 - Math.abs(s - 0.02) * 12) * (s > 0.5 ? 1 : 0.4);
    p.obj.userData.body.scale.set(1 / Math.sqrt(squash), squash + Math.sin(Math.PI * s) * 0.08, 1 / Math.sqrt(squash));
    const dir = Math.atan2(b.x - a.x, b.z - a.z);
    if (Math.hypot(b.x - a.x, b.z - a.z) > 0.01) p.obj.rotation.y = dampAngle(p.obj.rotation.y, dir, dt * 14);
    p.obj.scale.setScalar(1);
    dirty = true;
    if (moveAnim.t >= moveAnim.duration) {
      p.obj.userData.body.scale.set(1, 1, 1);
      moveAnim = null;
      if (queuedCapture) startCapture(queuedCapture);
      else layoutResting();
    }
  }

  if (captureAnim) {
    captureAnim.t += dt;
    const t = Math.min(1, captureAnim.t / captureAnim.duration);
    const e = easeInOut(t);
    for (const f of captureAnim.flights) {
      f.p.obj.position.lerpVectors(f.from, f.to, e);
      f.p.obj.position.y += Math.sin(Math.PI * e) * 2.2;
      f.p.obj.rotation.y = e * Math.PI * 4;
      f.p.obj.rotation.z = Math.sin(Math.PI * e) * 0.6;
    }
    shockwave.material.uniforms.uProgress.value = Math.min(1, t * 1.4);
    shockwave.visible = t * 1.4 < 1;
    sparks.step(dt, 1 - t);
    dirty = true;
    if (t >= 1) {
      for (const f of captureAnim.flights) f.p.obj.rotation.set(0, 0, 0);
      captureAnim = null;
      shockwave.visible = false;
      sparks.step(0, 0);
      layoutResting();
    }
  }

  // Les pions au repos glissent vers leur place et se retournent vers nous.
  const k = 1 - Math.exp(-dt * 12);
  for (const [key, p] of pawns) {
    if (moveAnim?.key === key || captureAnim?.keys.has(key)) continue;
    const o = p.obj;
    if (o.position.distanceToSquared(p.target) > 1e-7 || Math.abs(o.scale.x - p.scale) > 1e-4 || Math.abs(o.rotation.y) > 1e-4) {
      o.position.lerp(p.target, k);
      o.scale.setScalar(o.scale.x + (p.scale - o.scale.x) * k);
      o.rotation.y = dampAngle(o.rotation.y, 0, dt * 10);
      dirty = true;
    }
  }

  // Pions jouables : un anneau sous le socle et un petit sautillement.
  const choosing = snapshot?.phase === 'choosingPawn' && !moveAnim && !captureAnim;
  const movable = choosing ? snapshot.movable ?? [] : [];
  rings.forEach((ring, i) => {
    const p = i < movable.length ? pawns.get(keyOf(snapshot.current, movable[i])) : null;
    ring.visible = !!p;
    if (p) {
      ring.position.set(p.target.x, p.target.y + 0.012, p.target.z);
      ring.scale.setScalar(p.scale);
      ring.material.uniforms.uTime.value = time + i * 0.4;
      ring.material.uniforms.uColor.value.set(0xffe9a8);
    }
  });
  for (const p of pawns.values()) {
    const body = p.obj.userData.body;
    if (moveAnim?.key === keyOf(p.player, p.index)) continue;
    const active = choosing && p.player === snapshot.current && movable.includes(p.index);
    const y = active ? 0.08 + Math.abs(Math.sin(time * 5 + p.index)) * 0.09 : 0.08;
    if (Math.abs(body.position.y - y) > 1e-4) {
      body.position.y = active ? y : body.position.y + (y - body.position.y) * k;
      dirty = true;
    }
  }
  if (movable.length) dirty = true;

  if (dirty) {
    renderer.render(scene, camera);
    dirty = false;
  }
}

function dampAngle(from, to, f) {
  let d = to - from;
  d = Math.atan2(Math.sin(d), Math.cos(d));
  return from + d * Math.min(1, f);
}

// ── Toucher ─────────────────────────────────────────────────────────────────
const raycaster = new THREE.Raycaster();
const ndc = new THREE.Vector2();
const floor = new THREE.Plane(new THREE.Vector3(0, 1, 0), -TILE_TOP);
let down = null;

renderer.domElement.addEventListener('pointerdown', (e) => {
  down = { x: e.clientX, y: e.clientY };
});
renderer.domElement.addEventListener('pointerup', (e) => {
  if (!down || Math.hypot(e.clientX - down.x, e.clientY - down.y) > 12) return;
  down = null;
  if (!snapshot || snapshot.phase !== 'choosingPawn' || moveAnim || captureAnim) return;
  const pawn = pick(e.clientX, e.clientY);
  if (pawn !== null) send({ type: 'tap', pawn });
});

/** Le pion jouable sous le doigt : d'abord la figurine touchée, sinon le plus proche du point touché. */
function pick(x, y) {
  const rect = renderer.domElement.getBoundingClientRect();
  ndc.set(((x - rect.left) / rect.width) * 2 - 1, -((y - rect.top) / rect.height) * 2 + 1);
  raycaster.setFromCamera(ndc, camera);
  const candidates = (snapshot.movable ?? [])
    .map((i) => pawns.get(keyOf(snapshot.current, i)))
    .filter(Boolean);
  const hits = raycaster.intersectObjects(candidates.map((p) => p.obj), true);
  if (hits.length) {
    let o = hits[0].object;
    while (o && !o.userData.key) o = o.parent;
    const p = o && pawns.get(o.userData.key);
    if (p) return p.index;
  }
  const point = new THREE.Vector3();
  if (!raycaster.ray.intersectPlane(floor, point)) return null;
  let best = null;
  let bestD = 0.75;
  for (const p of candidates) {
    const d = Math.hypot(p.target.x - point.x, p.target.z - point.z);
    if (d < bestD) {
      bestD = d;
      best = p.index;
    }
  }
  return best;
}

function send(message) {
  const text = JSON.stringify(message);
  if (window.LudoBoard?.postMessage) window.LudoBoard.postMessage(text);
  window.dispatchEvent(new CustomEvent('ludoboard', { detail: message }));
}

// ── Démarrage ───────────────────────────────────────────────────────────────
window.ludoBoard = {
  apply,
  /** Pour les tests et les captures : true quand plus rien ne bouge. */
  get idle() {
    return !moveAnim && !captureAnim;
  },
};
window.addEventListener('resize', fitCamera);
fitCamera();
tick();
send({ type: 'ready' });
