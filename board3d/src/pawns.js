// Les pions : les quatre animaux du jeu 2D (renard, hibou, grenouille,
// poussin), modelés en volumes simples et émaillés comme des figurines en
// céramique, sur un socle cerclé d'or.
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { COLORS } from './board.js';

const SPECIES = {
  red: fox,
  blue: owl,
  green: frog,
  yellow: chick,
};

const cache = new Map();
function mat(key, make) {
  if (!cache.has(key)) cache.set(key, make());
  return cache.get(key);
}

function glazed(hex, lift = 0) {
  return mat(`glaze-${hex}-${lift}`, () => {
    const c = new THREE.Color(hex);
    if (lift > 0) c.lerp(new THREE.Color(0xffffff), lift);
    if (lift < 0) c.lerp(new THREE.Color(0x000000), -lift);
    return new THREE.MeshPhysicalMaterial({
      color: c,
      roughness: 0.38,
      clearcoat: 1,
      clearcoatRoughness: 0.1,
      sheen: 0.4,
      sheenColor: new THREE.Color(0xffffff),
    });
  });
}

const cream = () => glazed(0xfff4e0);
const ink = () =>
  mat('ink', () =>
    new THREE.MeshPhysicalMaterial({ color: 0x141018, roughness: 0.15, clearcoat: 1 }),
  );
const beak = () => glazed(0xff9800);
const gold = () =>
  mat('gold', () =>
    new THREE.MeshStandardMaterial({ color: 0xd9a441, metalness: 1, roughness: 0.16 }),
  );

function part(geo, material, [x, y, z], [sx, sy, sz] = [1, 1, 1]) {
  const m = new THREE.Mesh(geo, material);
  m.position.set(x, y, z);
  m.scale.set(sx, sy, sz);
  m.castShadow = true;
  m.receiveShadow = true;
  return m;
}

const sphere = new THREE.SphereGeometry(1, 32, 24);
const lowSphere = new THREE.SphereGeometry(1, 16, 12);
const cone = new THREE.ConeGeometry(1, 1, 24);

function eyes(group, y, z, spread, size) {
  for (const s of [-1, 1]) {
    group.add(part(lowSphere, ink(), [s * spread, y, z], [size, size, size]));
    // Le point de lumière dans l'œil : c'est lui qui donne vie à la figurine.
    group.add(
      part(
        lowSphere,
        mat('glint', () => new THREE.MeshBasicMaterial({ color: 0xffffff })),
        [s * spread - size * 0.3, y + size * 0.35, z + size * 0.75],
        [size * 0.28, size * 0.28, size * 0.28],
      ),
    );
  }
}

function fox(g) {
  const fur = glazed(COLORS.red);
  g.add(part(sphere, fur, [0, 0.36, 0], [0.27, 0.3, 0.25]));
  g.add(part(sphere, cream(), [0, 0.33, 0.12], [0.17, 0.22, 0.14]));
  g.add(part(sphere, fur, [0, 0.7, 0.02], [0.21, 0.19, 0.2]));
  // Oreilles pointues, sombres au bout.
  for (const s of [-1, 1]) {
    const ear = part(cone, fur, [s * 0.12, 0.9, -0.01], [0.075, 0.2, 0.05]);
    ear.rotation.z = -s * 0.32;
    g.add(ear);
    const tip = part(cone, ink(), [s * 0.155, 0.975, -0.01], [0.035, 0.07, 0.03]);
    tip.rotation.z = -s * 0.32;
    g.add(tip);
  }
  // Museau clair, pointé vers l'avant.
  const snout = part(cone, cream(), [0, 0.66, 0.24], [0.1, 0.16, 0.08]);
  snout.rotation.x = Math.PI / 2;
  g.add(snout);
  g.add(part(lowSphere, ink(), [0, 0.66, 0.32], [0.035, 0.03, 0.03]));
  g.add(part(sphere, cream(), [-0.11, 0.66, 0.13], [0.08, 0.06, 0.07]));
  g.add(part(sphere, cream(), [0.11, 0.66, 0.13], [0.08, 0.06, 0.07]));
  eyes(g, 0.75, 0.17, 0.085, 0.035);
  // Queue en panache, bout blanc.
  const tail = part(sphere, fur, [0.2, 0.28, -0.2], [0.1, 0.1, 0.22]);
  tail.rotation.y = -0.7;
  tail.rotation.x = 0.5;
  g.add(tail);
  g.add(part(sphere, cream(), [0.31, 0.37, -0.31], [0.07, 0.07, 0.08]));
}

function owl(g) {
  const plume = glazed(COLORS.blue);
  const dark = glazed(COLORS.blue, -0.35);
  g.add(part(sphere, plume, [0, 0.46, 0], [0.28, 0.4, 0.26]));
  g.add(part(sphere, glazed(COLORS.blue, 0.6), [0, 0.38, 0.11], [0.18, 0.24, 0.16]));
  // Ailes repliées.
  for (const s of [-1, 1]) {
    const wing = part(sphere, dark, [s * 0.24, 0.42, -0.02], [0.08, 0.26, 0.18]);
    wing.rotation.z = s * 0.15;
    g.add(wing);
  }
  // Grand disque facial et gros yeux ronds.
  g.add(part(sphere, cream(), [-0.1, 0.66, 0.16], [0.13, 0.13, 0.08]));
  g.add(part(sphere, cream(), [0.1, 0.66, 0.16], [0.13, 0.13, 0.08]));
  for (const s of [-1, 1]) {
    g.add(part(lowSphere, glazed(0xffc107), [s * 0.1, 0.665, 0.215], [0.07, 0.07, 0.04]));
  }
  eyes(g, 0.665, 0.245, 0.1, 0.038);
  const b = part(cone, beak(), [0, 0.57, 0.24], [0.04, 0.09, 0.04]);
  b.rotation.x = Math.PI - 0.5;
  g.add(b);
  // Aigrettes.
  for (const s of [-1, 1]) {
    const tuft = part(cone, dark, [s * 0.17, 0.86, 0], [0.06, 0.16, 0.05]);
    tuft.rotation.z = -s * 0.5;
    g.add(tuft);
  }
}

function frog(g) {
  const skin = glazed(COLORS.green);
  g.add(part(sphere, skin, [0, 0.32, 0], [0.31, 0.25, 0.28]));
  g.add(part(sphere, glazed(COLORS.green, 0.62), [0, 0.28, 0.1], [0.23, 0.17, 0.2]));
  // Yeux posés sur le dessus du crâne.
  for (const s of [-1, 1]) {
    g.add(part(sphere, skin, [s * 0.14, 0.55, 0.06], [0.1, 0.1, 0.1]));
    g.add(part(sphere, cream(), [s * 0.14, 0.57, 0.13], [0.065, 0.065, 0.045]));
  }
  eyes(g, 0.57, 0.17, 0.14, 0.035);
  // Large sourire.
  const smile = new THREE.Mesh(
    new THREE.TorusGeometry(0.15, 0.012, 8, 32, Math.PI * 0.8),
    ink(),
  );
  smile.position.set(0, 0.43, 0.24);
  smile.rotation.z = Math.PI + Math.PI * 0.1;
  smile.rotation.x = -0.35;
  g.add(smile);
  // Pattes avant et arrière.
  for (const s of [-1, 1]) {
    g.add(part(sphere, skin, [s * 0.17, 0.1, 0.2], [0.08, 0.05, 0.1]));
    g.add(part(sphere, skin, [s * 0.27, 0.14, -0.08], [0.1, 0.09, 0.15]));
  }
}

function chick(g) {
  const down = glazed(COLORS.yellow);
  g.add(part(sphere, down, [0, 0.36, 0], [0.28, 0.28, 0.26]));
  g.add(part(sphere, down, [0, 0.7, 0.03], [0.2, 0.19, 0.19]));
  // Petites ailes.
  for (const s of [-1, 1]) {
    const wing = part(sphere, glazed(COLORS.yellow, -0.12), [s * 0.26, 0.38, 0], [0.07, 0.16, 0.14]);
    wing.rotation.z = s * 0.5;
    g.add(wing);
  }
  // Huppe.
  for (const [x, rz, h] of [[-0.05, 0.4, 0.12], [0, 0, 0.15], [0.05, -0.4, 0.12]]) {
    const plume = part(cone, down, [x, 0.9, 0.02], [0.035, h, 0.035]);
    plume.rotation.z = rz;
    g.add(plume);
  }
  // Bec triangulaire.
  const b = part(cone, beak(), [0, 0.67, 0.25], [0.06, 0.11, 0.045]);
  b.rotation.x = Math.PI / 2;
  g.add(b);
  eyes(g, 0.74, 0.18, 0.08, 0.032);
  // Joues roses.
  for (const s of [-1, 1]) {
    g.add(part(lowSphere, glazed(0xff8a80, 0.3), [s * 0.14, 0.66, 0.14], [0.04, 0.025, 0.02]));
  }
  // Pattes.
  for (const s of [-1, 1]) {
    g.add(part(sphere, beak(), [s * 0.1, 0.08, 0.16], [0.07, 0.025, 0.07]));
  }
}

const pedestalGeo = new THREE.CylinderGeometry(0.32, 0.35, 0.08, 40);
pedestalGeo.translate(0, 0.04, 0);
const rimGeo = new THREE.TorusGeometry(0.335, 0.018, 8, 40);
rimGeo.rotateX(Math.PI / 2);

/**
 * Modèle la figurine pièce par pièce, puis fond les pièces qui partagent une
 * matière : une vingtaine de volumes deviennent cinq ou six appels de dessin,
 * ce qui compte avec seize pions et leur passe d'ombre sur un téléphone.
 */
function mergeByMaterial(model) {
  const draft = new THREE.Group();
  model(draft);
  draft.updateMatrixWorld(true);
  const byMaterial = new Map();
  draft.traverse((o) => {
    if (!o.isMesh) return;
    const g = o.geometry.clone().applyMatrix4(o.matrixWorld);
    if (!byMaterial.has(o.material)) byMaterial.set(o.material, []);
    byMaterial.get(o.material).push(g);
  });
  const merged = new THREE.Group();
  for (const [material, geos] of byMaterial) {
    const mesh = new THREE.Mesh(mergeGeometries(geos), material);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    merged.add(mesh);
    geos.forEach((g) => g.dispose());
  }
  return merged;
}

/**
 * Une figurine prête à poser : l'origine est au ras du socle, l'animal
 * regarde vers +z (vers la caméra).
 */
export function buildPawn(color) {
  const root = new THREE.Group();
  const pedestal = part(pedestalGeo, glazed(COLORS[color], -0.25), [0, 0, 0]);
  root.add(pedestal);
  root.add(part(rimGeo, gold(), [0, 0.075, 0]));
  const body = mergeByMaterial((g) => SPECIES[color](g));
  body.position.y = 0.08;
  root.add(body);
  root.userData.body = body;
  // Modelées à l'échelle d'une case, un peu agrandies pour se lire de loin.
  const figure = new THREE.Group();
  figure.scale.setScalar(1.3);
  figure.add(...root.children);
  root.add(figure);
  return root;
}
