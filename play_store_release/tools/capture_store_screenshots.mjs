import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { mkdir, readFile, rm, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';

const root = process.cwd();
const outDir = path.join(root, 'play_store_release', 'screenshots');
const webRoot = path.join(root, 'build', 'web');
const profileDir = path.join(
  root,
  'play_store_release',
  `chrome-profile-${Date.now()}`,
);
const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const appUrl = 'http://127.0.0.1:54001';
const debugPort = 9339;
const phone = { width: 1080, height: 1920, deviceScaleFactor: 1 };

await rm(outDir, { recursive: true, force: true });
await mkdir(outDir, { recursive: true });
await rm(profileDir, { recursive: true, force: true });
await mkdir(profileDir, { recursive: true });

const server = createServer(async (request, response) => {
  try {
    const requestUrl = new URL(request.url ?? '/', appUrl);
    const pathname = decodeURIComponent(requestUrl.pathname);
    let filePath = path.normalize(path.join(webRoot, pathname));
    if (!filePath.startsWith(webRoot)) {
      response.writeHead(403);
      response.end('Forbidden');
      return;
    }
    let fileStat;
    try {
      fileStat = await stat(filePath);
    } catch {
      filePath = path.join(webRoot, 'index.html');
      fileStat = await stat(filePath);
    }
    if (fileStat.isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }
    const ext = path.extname(filePath).toLowerCase();
    const type =
      {
        '.html': 'text/html; charset=utf-8',
        '.js': 'application/javascript; charset=utf-8',
        '.mjs': 'application/javascript; charset=utf-8',
        '.css': 'text/css; charset=utf-8',
        '.json': 'application/json; charset=utf-8',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.svg': 'image/svg+xml',
        '.wasm': 'application/wasm',
        '.otf': 'font/otf',
        '.ttf': 'font/ttf',
      }[ext] ?? 'application/octet-stream';
    response.writeHead(200, { 'content-type': type });
    response.end(await readFile(filePath));
  } catch (error) {
    response.writeHead(500);
    response.end(String(error));
  }
});
await new Promise((resolve) => server.listen(54001, '127.0.0.1', resolve));

const chrome = spawn(
  chromePath,
  [
    '--headless=new',
    `--remote-debugging-port=${debugPort}`,
    `--user-data-dir=${profileDir}`,
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-gpu',
    '--disable-dev-shm-usage',
    `--window-size=${phone.width},${phone.height}`,
    'about:blank',
  ],
  { stdio: 'ignore' },
);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function json(url, options) {
  const response = await fetch(url, options);
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${url}`);
  }
  return response.json();
}

async function waitForChrome() {
  for (let i = 0; i < 80; i += 1) {
    try {
      await json(`http://127.0.0.1:${debugPort}/json/version`);
      return;
    } catch {
      await sleep(250);
    }
  }
  throw new Error('Chrome DevTools endpoint did not become ready.');
}

class CdpClient {
  constructor(wsUrl) {
    this.nextId = 1;
    this.pending = new Map();
    this.events = new Map();
    this.ready = new Promise((resolve, reject) => {
      this.ws = new WebSocket(wsUrl);
      this.ws.addEventListener('open', resolve, { once: true });
      this.ws.addEventListener('error', reject, { once: true });
      this.ws.addEventListener('message', (event) => this.onMessage(event));
    });
  }

  onMessage(event) {
    const message = JSON.parse(event.data);
    if (message.id) {
      const pending = this.pending.get(message.id);
      if (!pending) {
        return;
      }
      this.pending.delete(message.id);
      if (message.error) {
        pending.reject(new Error(message.error.message));
      } else {
        pending.resolve(message.result ?? {});
      }
      return;
    }
    const listeners = this.events.get(message.method) ?? [];
    for (const listener of listeners) {
      listener(message.params ?? {});
    }
  }

  async send(method, params = {}) {
    await this.ready;
    const id = this.nextId;
    this.nextId += 1;
    const promise = new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
    });
    this.ws.send(JSON.stringify({ id, method, params }));
    return promise;
  }

  once(method) {
    return new Promise((resolve) => {
      const listeners = this.events.get(method) ?? [];
      const listener = (params) => {
        this.events.set(
          method,
          (this.events.get(method) ?? []).filter((item) => item !== listener),
        );
        resolve(params);
      };
      listeners.push(listener);
      this.events.set(method, listeners);
    });
  }

  close() {
    this.ws?.close();
  }
}

async function openPage(url) {
  await json(`http://127.0.0.1:${debugPort}/json/new?${encodeURIComponent(url)}`, {
    method: 'PUT',
  });
  const pages = await json(`http://127.0.0.1:${debugPort}/json/list`);
  const page = pages.find((item) => item.type === 'page' && item.url.includes('127.0.0.1'));
  if (!page) {
    throw new Error('Could not find the app tab.');
  }
  return new CdpClient(page.webSocketDebuggerUrl);
}

async function configure(client) {
  await client.send('Page.enable');
  await client.send('Runtime.enable');
  await client.send('Network.enable');
  await client.send('Emulation.setDeviceMetricsOverride', {
    width: phone.width,
    height: phone.height,
    deviceScaleFactor: phone.deviceScaleFactor,
    mobile: true,
    screenWidth: phone.width,
    screenHeight: phone.height,
  });
  await client.send('Network.setUserAgentOverride', {
    userAgent:
      'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36',
  });
}

async function navigate(client, url = appUrl) {
  const loaded = client.once('Page.loadEventFired');
  await client.send('Page.navigate', { url });
  await Promise.race([loaded, sleep(12000)]);
  await sleep(8500);
}

async function capture(client, fileName) {
  const result = await client.send('Page.captureScreenshot', {
    format: 'png',
    fromSurface: true,
  });
  await writeFile(path.join(outDir, fileName), Buffer.from(result.data, 'base64'));
  console.log(`saved ${fileName}`);
}

async function tap(client, x, y) {
  await client.send('Input.dispatchTouchEvent', {
    type: 'touchStart',
    touchPoints: [{ x, y, radiusX: 2, radiusY: 2, force: 1 }],
  });
  await sleep(80);
  await client.send('Input.dispatchTouchEvent', {
    type: 'touchEnd',
    touchPoints: [],
  });
}

async function swipe(client, fromX, fromY, toX, toY) {
  await client.send('Input.dispatchTouchEvent', {
    type: 'touchStart',
    touchPoints: [{ x: fromX, y: fromY, radiusX: 2, radiusY: 2, force: 1 }],
  });
  const steps = 14;
  for (let i = 1; i <= steps; i += 1) {
    await client.send('Input.dispatchTouchEvent', {
      type: 'touchMove',
      touchPoints: [
        {
          x: fromX + ((toX - fromX) * i) / steps,
          y: fromY + ((toY - fromY) * i) / steps,
          radiusX: 2,
          radiusY: 2,
          force: 1,
        },
      ],
    });
    await sleep(24);
  }
  await client.send('Input.dispatchTouchEvent', {
    type: 'touchEnd',
    touchPoints: [],
  });
  await sleep(900);
}

try {
  await waitForChrome();
  const client = await openPage(appUrl);
  await configure(client);

  await navigate(client);
  await sleep(5000);
  await capture(client, '01_welcome_projects.png');

  await navigate(client);
  await tap(client, 540, 1765);
  await sleep(1800);
  await capture(client, '02_create_account.png');

  await navigate(client);
  await tap(client, 540, 1865);
  await sleep(1600);
  await capture(client, '03_sign_in.png');

  await client.send('Runtime.evaluate', {
    expression: "localStorage.setItem('flutter.session.signedIn','true');",
  });
  await navigate(client);
  await sleep(3500);
  await capture(client, '04_home_feed.png');
  client.close();
} finally {
  chrome.kill('SIGTERM');
  server.close();
}
