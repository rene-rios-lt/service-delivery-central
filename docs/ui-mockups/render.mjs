#!/usr/bin/env node
/*
 * Render every mockup screen to a PNG at its supported platform viewport(s).
 *
 * Drives headless Google Chrome over the DevTools Protocol and uses
 * Emulation.setDeviceMetricsOverride to set an EXACT CSS viewport + 2x device
 * scale. This emulates the viewport off-screen, so it is not subject to the
 * OS/Chrome minimum-window-width clamp that distorts narrow (mobile) layouts
 * when using --window-size with --screenshot.
 *
 * Idempotent: re-running overwrites images/.  Requires only Node + Chrome.
 *
 * Output: docs/ui-mockups/images/<name>.png   (CSS size x2)
 */
import { spawn } from 'node:child_process';
import { writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';

const DIR = dirname(fileURLToPath(import.meta.url));
const SCREENS = join(DIR, 'screens');
const OUT = join(DIR, 'images');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 9333;

// name, html, cssWidth, cssHeight
const JOBS = [
  // Shared
  ['login__web-1280x800',                  'login.html',               1280, 800],
  ['login__mobile-390x844',                'login.html',                390, 844],
  ['components__reference-1280x980',       'components.html',          1280, 980],
  // Dispatcher (Desktop + Web)
  ['dispatcher-dashboard__desktop-1440x900','dispatcher-dashboard.html',1440, 900],
  ['dispatcher-dashboard__web-1280x800',   'dispatcher-dashboard.html',1280, 800],
  ['dispatcher-redirect__desktop-1440x900','dispatcher-redirect.html', 1440, 900],
  ['dispatcher-force-release__desktop-1440x900','dispatcher-force-release.html', 1440, 900],
  ['dispatcher-nav__desktop-1440x900',     'dispatcher-nav.html',      1440, 900],
  // Service Rep (Mobile)
  ['rep-vehicle-select__mobile-390x844',   'rep-vehicle-select.html',   390, 844],
  ['rep-idle__mobile-390x844',             'rep-idle.html',             390, 844],
  ['rep-job-offer__mobile-390x844',        'rep-job-offer.html',        390, 844],
  ['rep-active-job__mobile-390x844',       'rep-active-job.html',       390, 844],
  ['rep-on-site__mobile-390x844',          'rep-on-site.html',          390, 844],
  ['rep-nav-drawer__mobile-390x844',       'rep-nav-drawer.html',       390, 844],
  ['rep-release-vehicle__mobile-390x844',  'rep-release-vehicle.html',  390, 844],
  // Requester (Desktop + Web + Mobile)
  ['requester-submit__web-1280x800',       'requester-submit.html',    1280, 800],
  ['requester-submit__mobile-390x844',     'requester-submit.html',     390, 844],
  ['requester-finding__mobile-390x844',    'requester-finding.html',    390, 844],
  ['requester-tracking__web-1280x800',     'requester-tracking.html',  1280, 800],
  ['requester-tracking__mobile-390x844',   'requester-tracking.html',   390, 844],
  ['requester-redirect__web-1280x800',     'requester-redirect.html',  1280, 800],
  ['requester-redirect__mobile-390x844',   'requester-redirect.html',   390, 844],
  ['requester-complete__mobile-390x844',   'requester-complete.html',   390, 844],
];

mkdirSync(OUT, { recursive: true });

const chrome = spawn(CHROME, [
  '--headless=new',
  `--remote-debugging-port=${PORT}`,
  '--remote-allow-origins=*',
  '--no-first-run',
  '--no-default-browser-check',
  '--hide-scrollbars',
  '--disable-gpu',
  'about:blank',
], { stdio: 'ignore' });

// --- minimal CDP client over the browser-level WebSocket ---
async function browserWsUrl() {
  for (let i = 0; i < 50; i++) {
    try {
      const r = await fetch(`http://127.0.0.1:${PORT}/json/version`);
      const j = await r.json();
      if (j.webSocketDebuggerUrl) return j.webSocketDebuggerUrl;
    } catch { /* not up yet */ }
    await sleep(100);
  }
  throw new Error('Chrome DevTools endpoint never came up');
}

function makeConn(url) {
  const ws = new WebSocket(url);
  let id = 0;
  const pending = new Map();
  const waiters = [];
  ws.addEventListener('message', (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
    } else if (msg.method) {
      for (let i = waiters.length - 1; i >= 0; i--) {
        if (waiters[i].method === msg.method && (!waiters[i].sessionId || waiters[i].sessionId === msg.sessionId)) {
          waiters[i].resolve(msg.params);
          waiters.splice(i, 1);
        }
      }
    }
  });
  const ready = new Promise((res) => ws.addEventListener('open', () => res()));
  const send = (method, params = {}, sessionId) =>
    new Promise((resolve, reject) => {
      const m = { id: ++id, method, params };
      if (sessionId) m.sessionId = sessionId;
      pending.set(m.id, { resolve, reject });
      ws.send(JSON.stringify(m));
    });
  const waitFor = (method, sessionId, ms = 8000) =>
    new Promise((resolve, reject) => {
      const w = { method, sessionId, resolve };
      waiters.push(w);
      setTimeout(() => { const i = waiters.indexOf(w); if (i >= 0) { waiters.splice(i, 1); resolve(null); } }, ms);
    });
  return { ws, ready, send, waitFor };
}

const wsUrl = await browserWsUrl();
const conn = makeConn(wsUrl);
await conn.ready;

for (const [name, html, w, h] of JOBS) {
  // fresh target per screen
  const { targetId } = await conn.send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await conn.send('Target.attachToTarget', { targetId, flatten: true });

  await conn.send('Page.enable', {}, sessionId);
  await conn.send('Emulation.setDeviceMetricsOverride', {
    width: w, height: h, deviceScaleFactor: 2, mobile: false,
    screenWidth: w, screenHeight: h,
  }, sessionId);

  const loaded = conn.waitFor('Page.loadEventFired', sessionId);
  await conn.send('Page.navigate', { url: `file://${SCREENS}/${html}` }, sessionId);
  await loaded;
  await sleep(450); // settle fonts / gradients

  const { data } = await conn.send('Page.captureScreenshot', {
    format: 'png', captureBeyondViewport: false,
    clip: { x: 0, y: 0, width: w, height: h, scale: 1 },
  }, sessionId);

  writeFileSync(join(OUT, `${name}.png`), Buffer.from(data, 'base64'));
  console.log(`  ✓ ${name}.png  (${w}x${h} @2x)`);
  await conn.send('Target.closeTarget', { targetId }, sessionId);
}

conn.ws.close();
chrome.kill();
console.log(`Done → ${OUT}`);
