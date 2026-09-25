// Effets en shaders : l'anneau qui désigne les pions jouables et l'onde de
// choc d'une capture. Deux quads plaqués au sol, dessinés en additif.
import * as THREE from 'three';

const vertex = /* glsl */ `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`;

/** Anneau lumineux qui respire sous un pion jouable, cerclé de tirets qui tournent. */
export function makeHighlightRing() {
  const material = new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 },
      uColor: { value: new THREE.Color(0xffe082) },
    },
    vertexShader: vertex,
    fragmentShader: /* glsl */ `
      uniform float uTime;
      uniform vec3 uColor;
      varying vec2 vUv;
      void main() {
        vec2 p = vUv * 2.0 - 1.0;
        float r = length(p);
        float a = atan(p.y, p.x);
        float pulse = 0.5 + 0.5 * sin(uTime * 4.0);
        float radius = 0.66 + 0.06 * pulse;
        // Halo doux, puis un trait net, puis des tirets qui tournent.
        float glow = exp(-pow((r - radius) * 7.0, 2.0)) * (0.55 + 0.45 * pulse);
        float line = smoothstep(0.035, 0.0, abs(r - radius));
        float dashes = step(0.5, fract(a / 6.2831853 * 12.0 - uTime * 0.6));
        float outer = smoothstep(0.03, 0.0, abs(r - 0.9)) * dashes;
        float alpha = glow * 1.3 + line * 1.4 + outer;
        float fill = smoothstep(radius, 0.0, r) * 0.18 * pulse;
        gl_FragColor = vec4(uColor * (alpha + fill), 1.0);
      }
    `,
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
  });
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(1.25, 1.25), material);
  mesh.rotation.x = -Math.PI / 2;
  mesh.renderOrder = 2;
  return mesh;
}

/** Onde de choc rouge au point de capture ; [uProgress] va de 0 à 1. */
export function makeShockwave() {
  const material = new THREE.ShaderMaterial({
    uniforms: { uProgress: { value: 0 } },
    vertexShader: vertex,
    fragmentShader: /* glsl */ `
      uniform float uProgress;
      varying vec2 vUv;
      void main() {
        vec2 p = vUv * 2.0 - 1.0;
        float r = length(p);
        float t = uProgress;
        float front = t * 0.95;
        float width = 0.05 + 0.18 * t;
        float ring = exp(-pow((r - front) / width, 2.0));
        float core = smoothstep(0.35, 0.0, r) * (1.0 - t) * 1.2;
        float fade = 1.0 - smoothstep(0.55, 1.0, t);
        vec3 hot = mix(vec3(1.0, 0.85, 0.4), vec3(1.0, 0.18, 0.12), t);
        gl_FragColor = vec4(hot * (ring + core) * fade, 1.0);
      }
    `,
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
  });
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(3.2, 3.2), material);
  mesh.rotation.x = -Math.PI / 2;
  mesh.renderOrder = 3;
  mesh.visible = false;
  return mesh;
}

/** Gerbe d'étincelles qui retombent, pour la capture. */
export function makeSparks(count = 48) {
  const positions = new Float32Array(count * 3);
  const velocities = [];
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  const material = new THREE.ShaderMaterial({
    uniforms: { uFade: { value: 1 }, uScale: { value: 1 } },
    vertexShader: /* glsl */ `
      uniform float uScale;
      void main() {
        vec4 mv = modelViewMatrix * vec4(position, 1.0);
        gl_PointSize = uScale * 90.0 / -mv.z;
        gl_Position = projectionMatrix * mv;
      }
    `,
    fragmentShader: /* glsl */ `
      uniform float uFade;
      void main() {
        float d = length(gl_PointCoord - 0.5);
        float a = smoothstep(0.5, 0.0, d);
        gl_FragColor = vec4(vec3(1.0, 0.7, 0.3) * a * uFade, 1.0);
      }
    `,
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
  });
  const points = new THREE.Points(geo, material);
  points.visible = false;
  points.frustumCulled = false;

  return {
    points,
    burst(origin) {
      velocities.length = 0;
      for (let i = 0; i < count; i++) {
        const a = Math.random() * Math.PI * 2;
        const s = 1.5 + Math.random() * 2.5;
        velocities.push(new THREE.Vector3(Math.cos(a) * s, 2.5 + Math.random() * 3, Math.sin(a) * s));
        positions[i * 3] = origin.x;
        positions[i * 3 + 1] = origin.y + 0.3;
        positions[i * 3 + 2] = origin.z;
      }
      geo.attributes.position.needsUpdate = true;
      points.visible = true;
    },
    step(dt, fade) {
      for (let i = 0; i < count; i++) {
        const v = velocities[i];
        if (!v) continue;
        v.y -= 9.8 * dt;
        positions[i * 3] += v.x * dt;
        positions[i * 3 + 1] = Math.max(0.14, positions[i * 3 + 1] + v.y * dt);
        positions[i * 3 + 2] += v.z * dt;
      }
      geo.attributes.position.needsUpdate = true;
      material.uniforms.uFade.value = fade;
      points.visible = fade > 0.01;
    },
    setPixelScale(s) {
      material.uniforms.uScale.value = s;
    },
  };
}
