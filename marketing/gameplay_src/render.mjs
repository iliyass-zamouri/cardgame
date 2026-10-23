import { chromium } from 'playwright-core';
import { spawn } from 'child_process';
const [,, out, fps='30', only] = process.argv;
const browser = await chromium.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', args:['--allow-file-access-from-files'] });
const page = await browser.newPage({ viewport:{width:1920,height:1080} });
page.on('pageerror', e=>console.error('PAGEERR', e.message));
await page.goto('file://'+process.cwd()+'/scene.html');
await page.waitForFunction(()=>window.ready);
await page.evaluate(()=>window.ready);
if (only) { // stills: comma list of times
  for (const t of only.split(',')) { await page.evaluate(t=>window.seek(t), +t); await page.screenshot({path:`${out}/still_${t}.jpg`, quality:80}); }
  await browser.close(); process.exit(0);
}
const dur = await page.evaluate(()=>window.DUR), n = Math.round(dur*+fps);
const ff = spawn('ffmpeg',['-y','-v','error','-f','image2pipe','-framerate',fps,'-c:v','mjpeg','-i','-','-c:v','libx264','-preset','slow','-crf','18','-pix_fmt','yuv420p',out],{stdio:['pipe','inherit','inherit']});
for (let f=0; f<n; f++) {
  await page.evaluate(t=>window.seek(t), f/+fps);
  const buf = await page.screenshot({type:'jpeg', quality:95});
  if (!ff.stdin.write(buf)) await new Promise(r=>ff.stdin.once('drain', r));
  if (f%60===0) console.log('frame', f, '/', n);
}
ff.stdin.end(); await new Promise(r=>ff.on('close', r)); await browser.close();
