// Requires Node 22+ (built-in WebSocket) and Chrome/Chromium. No npm packages.
import { spawn, spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import fs from 'node:fs/promises';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(root, 'build', 'web-persistence');
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const candidates = [
  process.env.CHROME_EXECUTABLE,
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
].filter(Boolean);
const chromePath = candidates.find((candidate) => existsSync(candidate));
if (!chromePath) throw new Error('Set CHROME_EXECUTABLE to Chrome/Chromium.');
await fs.mkdir(output, { recursive: true });
let dart = process.env.DART_EXECUTABLE || 'dart';
if (!process.env.DART_EXECUTABLE && process.platform === 'win32') {
  // Flutter puts dart.bat on PATH; spawnSync needs the underlying executable.
  const lookup = spawnSync('where.exe', ['dart'], { encoding: 'utf8' });
  for (const candidate of (lookup.stdout || '').trim().split(/\r?\n/)) {
    const executable = /\.exe$/i.test(candidate) ? candidate :
      path.join(path.dirname(candidate), 'cache', 'dart-sdk', 'bin', 'dart.exe');
    if (existsSync(executable)) { dart = executable; break; }
  }
}
const compilation = spawnSync(dart, [
  'compile', 'js', '-O4', '--no-source-maps',
  '-o', path.join(output, 'probe.js'),
  'test/web/database_persistence.dart',
], { cwd: root, stdio: 'inherit', timeout: 120_000 });
if (compilation.error) throw compilation.error;
if (compilation.status !== 0) throw new Error('Browser probe compilation failed.');
await fs.copyFile(
  process.env.DRIFT_WORKER_PATH || path.join(root, 'web', 'drift_worker.js'),
  path.join(output, 'drift_worker.js'),
);
await fs.copyFile(path.join(root, 'web', 'sqlite3.wasm'), path.join(output, 'sqlite3.wasm'));
await fs.writeFile(path.join(output, 'index.html'),
  '<!doctype html><html><head><meta charset="utf-8"></head><body>' +
  '<script src="probe.js" defer></script></body></html>');

// Deliberately omit COOP/COEP to exercise the IndexedDB fallback, not OPFS.
const server = http.createServer(async (request, response) => {
  try {
    const url = new URL(request.url, 'http://localhost');
    const relative = url.pathname === '/' ? '/index.html' : decodeURIComponent(url.pathname);
    const target = path.resolve(output, `.${relative}`);
    if (!target.startsWith(`${output}${path.sep}`)) throw new Error('Invalid path');
    const data = await fs.readFile(target);
    const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm' };
    response.writeHead(200, {
      'Content-Type': types[path.extname(target)] || 'application/octet-stream',
      'Cache-Control': 'no-store',
    });
    response.end(data);
  } catch {
    response.writeHead(404);
    response.end('Not found');
  }
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const origin = `http://127.0.0.1:${server.address().port}`;
const profile = await fs.mkdtemp(path.join(os.tmpdir(), 'honeyday-persistence-'));
const chrome = spawn(chromePath, [
  '--headless=new', '--no-sandbox', '--no-first-run', '--no-default-browser-check',
  '--disable-dev-shm-usage', '--disable-background-networking', '--disable-extensions',
  '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank',
], { stdio: 'ignore' });
let socket;
let nextId = 0;
const pending = new Map();
const exceptions = [];
function send(method, params = {}) {
  const id = ++nextId;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`DevTools timeout: ${method}`));
    }, 10_000);
    pending.set(id, {
      resolve: (value) => { clearTimeout(timer); resolve(value); },
      reject: (error) => { clearTimeout(timer); reject(error); },
    });
    socket.send(JSON.stringify({ id, method, params }));
  });
}
async function waitForReport(expectedPhase) {
  for (let attempt = 0; attempt < 300; attempt++) {
    const result = await send('Runtime.evaluate', {
      expression: 'globalThis.honeydayPersistenceReport || null', returnByValue: true,
    });
    if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
    const value = result.result.value;
    if (value) {
      const report = JSON.parse(value);
      if (report.phase === 'error') throw new Error(JSON.stringify(report, null, 2));
      if (report.phase === expectedPhase) return report;
    }
    await sleep(100);
  }
  throw new Error(`No ${expectedPhase} report from browser. Exceptions: ${JSON.stringify(exceptions)}`);
}
try {
  let port;
  for (let attempt = 0; attempt < 150; attempt++) {
    try {
      port = Number((await fs.readFile(path.join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]);
      break;
    } catch { await sleep(100); }
  }
  if (!port) throw new Error('Chrome did not start its DevTools endpoint.');
  const tab = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT' })).json();
  socket = new WebSocket(tab.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });
  socket.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    if (message.id) {
      const waiter = pending.get(message.id);
      if (waiter) {
        pending.delete(message.id);
        if (message.error) waiter.reject(new Error(JSON.stringify(message.error)));
        else waiter.resolve(message.result);
      }
    } else if (message.method === 'Runtime.exceptionThrown') exceptions.push(message.params);
  });
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Page.navigate', { url: origin });
  console.log('Before reload:', await waitForReport('written'));
  // Destroy the first document without a clean database.close(). A new
  // connection must recover the committed data from durable IndexedDB.
  await send('Page.reload', { ignoreCache: true });
  console.log('After reload:', await waitForReport('verified'));
  if (exceptions.length) throw new Error(JSON.stringify(exceptions));
  console.log('PASS: transaction, savepoint rollback and RETURNING survive a reload.');
} finally {
  if (socket?.readyState === WebSocket.OPEN) {
    try { await send('Browser.close'); } catch { /* Browser may close before replying. */ }
    socket.close();
  }
  for (let attempt = 0; attempt < 30 && chrome.exitCode === null; attempt++) await sleep(100);
  if (chrome.exitCode === null) chrome.kill();
  server.closeAllConnections();
  await new Promise((resolve) => server.close(resolve));
  await fs.rm(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
}
