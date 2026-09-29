import {readFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
for (const file of ['app.js','api.js','core.js','config.js']) execFileSync(process.execPath,['--check',`dist/${file}`],{stdio:'inherit'});
const html=await readFile('dist/index.html','utf8');
for(const match of html.matchAll(/(?:src|href)="([^"#]+)"/g)){if(!match[1].startsWith('http'))await readFile('dist/'+match[1]);}
await readFile('dist/vendor/supabase.js');
console.log('JavaScript syntax and local assets verified.');
