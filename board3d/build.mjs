// Compile la scène en un seul fichier HTML, sans dépendance réseau :
// assets/board3d/index.html, chargé tel quel par la WebView de l'app.
import { build } from 'esbuild';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';

const result = await build({
  entryPoints: ['src/main.js'],
  bundle: true,
  minify: !process.env.DEBUG,
  format: 'iife',
  target: ['es2019'],
  legalComments: 'none',
  write: false,
});
const js = result.outputFiles[0].text.replace(/<\/script/gi, '<\\/script');
const html = readFileSync('index.template.html', 'utf8').replace('/*BUNDLE*/', () => js);
mkdirSync('../assets/board3d', { recursive: true });
writeFileSync('../assets/board3d/index.html', html);
console.log(`assets/board3d/index.html : ${(html.length / 1024).toFixed(0)} Ko`);
