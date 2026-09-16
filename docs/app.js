const VOICES = [
  { id: "alto", title: "Alto Sax", group: "Horns", accent: "#e0b259", register: 0, hold: true },
  { id: "tenor", title: "Tenor Sax", group: "Horns", accent: "#d17a38", register: 0, hold: true },
  { id: "bari", title: "Bari Sax", group: "Horns", accent: "#9e61b8", register: 0, hold: true },
  { id: "youtube", title: "YouTube Sax", group: "Horns", accent: "#ff6138", register: 0, hold: true },
  { id: "piano", title: "Piano", group: "Keys", accent: "#ebe2cc", register: 0, hold: false },
  { id: "rhodes", title: "Rhodes", group: "Keys", accent: "#f2b86b", register: 0, hold: false },
  { id: "guitar", title: "Guitar", group: "Strings", accent: "#8c5229", register: -12, hold: false },
  { id: "drums", title: "Drums", group: "Drums", accent: "#eb475f", register: 0, hold: false },
  { id: "kalimba", title: "Kalimba", group: "ASMR", accent: "#c79e61", register: 12, hold: false },
  { id: "glass", title: "Crystal Glass", group: "ASMR", accent: "#9ed6e6", register: 12, hold: false },
  { id: "chimes", title: "Chimes", group: "ASMR", accent: "#bfc6f2", register: 19, hold: false },
  { id: "musicBox", title: "Music Box", group: "ASMR", accent: "#e5949e", register: 12, hold: false },
  { id: "pad", title: "Soft Pad", group: "ASMR", accent: "#8cb8b2", register: 0, hold: true },
];

const SAX = {
  alto: { formants: [[820, 2.6, 0.14], [1480, 1.7, 0.18], [2650, 1.25, 0.22], [3800, 0.7, 0.3]], odd: 1.05, even: 1.12, rolloff: 0.78, nH: 16, breath: 0.09, breathF: 2600, chiff: 0.22, vibR: 5.3, vibD: 9, vibDelay: 0.28, scoop: 22, bright: 0.62, sat: 0.26, growl: 0.02, ampVib: 0.04 },
  tenor: { formants: [[520, 2.8, 0.13], [980, 1.9, 0.18], [2200, 1.05, 0.24], [3300, 0.6, 0.32]], odd: 1.02, even: 1.18, rolloff: 0.7, nH: 16, breath: 0.1, breathF: 2100, chiff: 0.2, vibR: 5.0, vibD: 11, vibDelay: 0.32, scoop: 26, bright: 0.48, sat: 0.3, growl: 0.05, ampVib: 0.045 },
  bari: { formants: [[310, 3.0, 0.12], [640, 1.8, 0.16], [1750, 0.95, 0.26], [2800, 0.5, 0.34]], odd: 1.0, even: 1.2, rolloff: 0.62, nH: 14, breath: 0.12, breathF: 1500, chiff: 0.24, vibR: 4.6, vibD: 8, vibDelay: 0.34, scoop: 16, bright: 0.34, sat: 0.36, growl: 0.09, ampVib: 0.03 },
  youtube: { formants: [[760, 3.2, 0.1], [1280, 2.3, 0.14], [2900, 1.5, 0.18], [4100, 0.9, 0.24]], odd: 1.2, even: 0.95, rolloff: 0.68, nH: 18, breath: 0.14, breathF: 3000, chiff: 0.36, vibR: 6.2, vibD: 22, vibDelay: 0.14, scoop: 70, bright: 0.78, sat: 0.42, growl: 0.1, ampVib: 0.08 },
};

const DRUMS = ["Kick","Snare","Hat","Open","Clap","Tom L","Tom M","Tom H","Rim","Crash","Perc","Shaker","Cowbell"];
const STEPS = [0, 2, 4, 5, 7, 9, 10];
const ROWS = [
  { id: "numbers", title: "1 – 0", codes: ["Backquote","Digit1","Digit2","Digit3","Digit4","Digit5","Digit6","Digit7","Digit8","Digit9","Digit0","Minus","Equal"], labels: ["`","1","2","3","4","5","6","7","8","9","0","-","="], voice: "alto", oct: 4, tr: 0 },
  { id: "qwerty", title: "QWERTY", codes: ["KeyQ","KeyW","KeyE","KeyR","KeyT","KeyY","KeyU","KeyI","KeyO","KeyP","BracketLeft","BracketRight","Backslash"], labels: ["Q","W","E","R","T","Y","U","I","O","P","[","]","\\"], voice: "kalimba", oct: 4, tr: 0 },
  { id: "home", title: "HOME", codes: ["KeyA","KeyS","KeyD","KeyF","KeyG","KeyH","KeyJ","KeyK","KeyL","Semicolon","Quote"], labels: ["A","S","D","F","G","H","J","K","L",";","'"], voice: "piano", oct: 4, tr: 0 },
  { id: "bottom", title: "BOTTOM", codes: ["KeyZ","KeyX","KeyC","KeyV","KeyB","KeyN","KeyM","Comma","Period","Slash"], labels: ["Z","X","C","V","B","N","M",",",".","/"], voice: "guitar", oct: 4, tr: 0 },
];

const lookup = {};
ROWS.forEach((row, ri) => row.codes.forEach((c, i) => { lookup[c] = [ri, i]; }));
const SHIFT = {"`":"~","1":"!","2":"@","3":"#","4":"$","5":"%","6":"^","7":"&","8":"*","9":"(","0":")","-":"_","=":"+","[":"{","]":"}","\\":"|",";":":","'":"\"",",":"<",".":">","/":"?"};
function typedChar(label, shift) {
  if (!shift) return /^[A-Z]$/.test(label) ? label.toLowerCase() : label;
  return SHIFT[label] || label.toUpperCase();
}

let ctx, master, recDest, recChunks, recProc, recMedia, recording = false, sustain = false;
const live = new Map();
const bank = new Map();
let recStart = 0;
let pending = null;
let recBits = [];
let recMime = "";

const drops = [];
let sentence = "";
let stage, tape, stageG, tapeG;
let raf = 0;

function midiToHz(m) { return 440 * Math.pow(2, (m - 69) / 12); }
function clamp(m) { return Math.max(24, Math.min(108, m)); }
function voiceById(id) { return VOICES.find(v => v.id === id); }
function noteName(m) {
  return ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"][((m % 12) + 12) % 12] + (Math.floor(m / 12) - 1);
}
function notesFor(row) {
  const v = voiceById(row.voice);
  if (row.voice === "drums") {
    return row.labels.map((label, i) => ({ label, midi: 36 + i, caption: DRUMS[i % DRUMS.length] }));
  }
  const start = (row.oct + 1) * 12 + row.tr + (v?.register || 0);
  return row.labels.map((label, i) => {
    const midi = clamp(start + STEPS[i % STEPS.length] + 12 * Math.floor(i / STEPS.length));
    return { label, midi, caption: noteName(midi) };
  });
}

function makeRng(seed) {
  let s = (seed >>> 0) || 1;
  return () => {
    s = (Math.imul(s, 1664525) + 1013904223) >>> 0;
    return s / 4294967296;
  };
}
function tanhApprox(x) {
  const x2 = x * x;
  return x * (27 + x2) / (27 + 9 * x2);
}
function reedShape(x, drive, even) {
  const d = Math.max(-8, Math.min(8, x * drive));
  return tanhApprox(d + even * d * Math.abs(d));
}
function centsToRatio(c) { return Math.pow(2, c / 1200); }
function adsr(t, attack, decay, sustainL, release, hold) {
  if (t < attack) {
    const x = t / Math.max(attack, 1e-4);
    return x * x * (3 - 2 * x);
  }
  const a = t - attack;
  if (a < decay) return 1 + (sustainL - 1) * (a / Math.max(decay, 1e-4));
  const d = a - decay;
  if (d < hold) return sustainL;
  const r = d - hold;
  if (r >= release) return 0;
  const x = r / Math.max(release, 1e-4);
  return sustainL * (1 - x) * (1 - x);
}
function bqBP(freq, q, sr) {
  const w0 = 2 * Math.PI * freq / sr, alpha = Math.sin(w0) / (2 * Math.max(q, 0.1)), cosw = Math.cos(w0), a0 = 1 + alpha;
  return { b0: alpha / a0, b1: 0, b2: -alpha / a0, a1: -2 * cosw / a0, a2: (1 - alpha) / a0, z1: 0, z2: 0 };
}
function bqLP(freq, q, sr) {
  const w0 = 2 * Math.PI * Math.min(freq, sr * 0.45) / sr, alpha = Math.sin(w0) / (2 * Math.max(q, 0.1)), cosw = Math.cos(w0), a0 = 1 + alpha;
  return { b0: (1 - cosw) * 0.5 / a0, b1: (1 - cosw) / a0, b2: (1 - cosw) * 0.5 / a0, a1: -2 * cosw / a0, a2: (1 - alpha) / a0, z1: 0, z2: 0 };
}
function bqHP(freq, q, sr) {
  const w0 = 2 * Math.PI * freq / sr, alpha = Math.sin(w0) / (2 * Math.max(q, 0.1)), cosw = Math.cos(w0), a0 = 1 + alpha;
  return { b0: (1 + cosw) * 0.5 / a0, b1: -(1 + cosw) / a0, b2: (1 + cosw) * 0.5 / a0, a1: -2 * cosw / a0, a2: (1 - alpha) / a0, z1: 0, z2: 0 };
}
function bqPK(freq, q, gainDB, sr) {
  const A = Math.pow(10, gainDB / 40), w0 = 2 * Math.PI * Math.min(freq, sr * 0.45) / sr, alpha = Math.sin(w0) / (2 * Math.max(q, 0.1)), cosw = Math.cos(w0), a0 = 1 + alpha / A;
  return { b0: (1 + alpha * A) / a0, b1: -2 * cosw / a0, b2: (1 - alpha * A) / a0, a1: -2 * cosw / a0, a2: (1 - alpha / A) / a0, z1: 0, z2: 0 };
}
function bqHS(freq, gainDB, sr) {
  const A = Math.pow(10, gainDB / 40), w0 = 2 * Math.PI * Math.min(freq, sr * 0.45) / sr, cosw = Math.cos(w0);
  const alpha = Math.sin(w0) / 2 * Math.sqrt((A + 1 / A) * 0.8 + 2);
  const a0 = (A + 1) - (A - 1) * cosw + 2 * Math.sqrt(A) * alpha;
  return {
    b0: A * ((A + 1) + (A - 1) * cosw + 2 * Math.sqrt(A) * alpha) / a0,
    b1: -2 * A * ((A - 1) + (A + 1) * cosw) / a0,
    b2: A * ((A + 1) + (A - 1) * cosw - 2 * Math.sqrt(A) * alpha) / a0,
    a1: 2 * ((A - 1) - (A + 1) * cosw) / a0,
    a2: ((A + 1) - (A - 1) * cosw - 2 * Math.sqrt(A) * alpha) / a0,
    z1: 0, z2: 0
  };
}
function bq(f, x) {
  const y = f.b0 * x + f.z1;
  f.z1 = f.b1 * x - f.a1 * y + f.z2;
  f.z2 = f.b2 * x - f.a2 * y;
  return y;
}
function onePole() { return { z: 0 }; }
function lp1(p, x, cutoff) {
  const c = Math.min(0.99, Math.max(0.0005, cutoff));
  p.z += c * (x - p.z);
  return p.z;
}
function wrap1(p) { if (p > 1) return p - Math.floor(p); return p; }
function normalize(out, peak) {
  let m = 0;
  for (let i = 0; i < out.length; i++) m = Math.max(m, Math.abs(out[i]));
  if (m < 1e-6) return out;
  const g = peak / m;
  for (let i = 0; i < out.length; i++) out[i] *= g;
  return out;
}
function fade(out, sr, fi, fo) {
  const nIn = Math.max(1, Math.floor(fi * sr));
  const nOut = Math.max(1, Math.floor(fo * sr));
  const n = out.length;
  for (let i = 0; i < Math.min(nIn, n); i++) {
    const x = i / nIn;
    out[i] *= x * x * (3 - 2 * x);
  }
  for (let i = 0; i < Math.min(nOut, n); i++) {
    const x = i / nOut;
    out[n - 1 - i] *= x * x * (3 - 2 * x);
  }
  return out;
}

function renderSax(midi, id) {
  const p = SAX[id] || SAX.alto;
  const sr = ctx.sampleRate, f0 = midiToHz(midi);
  const dur = 1.55, n = Math.floor(dur * sr), inv = 1 / sr;
  const next = makeRng(midi * 16807 + id.length * 97351 + 13);
  const out = new Float32Array(n);
  const nyquist = sr * 0.45;
  const detune = (next() - 0.5) * 5;
  const breathAmt = p.breath * (0.9 + next() * 0.25);
  const chiffAmt = p.chiff * (0.85 + next() * 0.3);
  const vibDepth = p.vibD * (0.9 + next() * 0.2);
  const vibPhase = next(), vibPhase2 = next(), growlPhase = next();
  const scoop = p.scoop * (0.88 + next() * 0.22);
  const drive = 1.15 + p.sat * 1.4;
  const evenAsym = 0.18 + p.even * 0.08;
  const hCount = Math.min(p.nH, Math.max(8, Math.floor(nyquist / f0)));
  const phases = new Float32Array(hCount);
  for (let i = 0; i < hCount; i++) phases[i] = next();
  const weights = new Float32Array(hCount);
  let wsum = 0;
  const track = 1 + 0.07 * Math.log2(Math.max(f0 / 440, 0.25));
  for (let h = 1; h <= hCount; h++) {
    const freq = f0 * h;
    if (freq > nyquist) continue;
    let w = 1 / Math.pow(h, p.rolloff);
    if (h === 2) w *= 1.22 * p.even;
    else if (h === 3) w *= 0.78 * p.odd;
    else w *= (h % 2 === 1) ? p.odd : p.even;
    const logf = Math.log2(Math.max(freq, 20));
    for (const f of p.formants) {
      const d = logf - Math.log2(f[0] * track);
      w *= 1 + f[1] * Math.exp(-d * d / (2 * f[2] * f[2]));
    }
    if (freq > 1800 && freq < 3800) w *= 1.18;
    weights[h - 1] = w; wsum += w;
  }
  if (wsum > 0) for (let i = 0; i < hCount; i++) weights[i] /= wsum;
  const formantBP = p.formants.slice(0, 4).map(f => bqBP(f[0] * track, 3.6, sr));
  const presence = bqPK(2700 * track, 1.4, 2.8 + p.bright * 2, sr);
  const bell = bqLP(1200 + p.bright * 5800, 0.68, sr);
  const breathBP = bqBP(p.breathF, 1.15, sr);
  const breathHP = bqHP(1400, 0.7, sr);
  const chiffBP = bqBP(4200, 0.7, sr);
  const dcHP = bqHP(45, 0.7, sr);
  const shelf = bqHS(3200, 1.5 + p.bright * 3, sr);
  const toneLP = onePole();
  let pink1 = 0, pink2 = 0, wander = 0;
  const attack = midi < 55 ? 0.024 : 0.014;
  const hold = dur - attack - 0.11 - 0.05;
  for (let i = 0; i < n; i++) {
    const t = i * inv;
    const env = adsr(t, attack, 0.11, 0.8, 0.05, hold);
    const bloom = 1 + 0.07 * (1 - Math.exp(-t / 0.2));
    const brightAttack = 1 + 0.35 * Math.exp(-t / 0.055);
    wander += (next() - 0.5) * 0.09; wander *= 0.997;
    let scoopEnv = 1;
    if (t < 0.07) { const x = t / 0.07; scoopEnv = centsToRatio(-scoop * (1 - x) * (1 - x)); }
    let vib = 0;
    if (t > p.vibDelay) {
      const vt = t - p.vibDelay, fadeV = Math.min(1, vt / 0.22);
      const lfo = Math.sin(2 * Math.PI * (vibPhase + p.vibR * vt)) + 0.14 * Math.sin(2 * Math.PI * (vibPhase2 + p.vibR * 2.02 * vt));
      vib = lfo * vibDepth * fadeV;
    }
    const freq = f0 * scoopEnv * centsToRatio(detune + vib + wander);
    let body = 0;
    for (let h = 1; h <= hCount; h++) {
      const w = weights[h - 1]; if (!w) continue;
      phases[h - 1] = wrap1(phases[h - 1] + freq * h * (1 + 0.00012 * h * h) * inv);
      body += w * Math.sin(2 * Math.PI * phases[h - 1]);
    }
    const pulse = reedShape(Math.sin(2 * Math.PI * phases[0]), drive, evenAsym);
    let sig = body * 0.62 + pulse * 0.38;
    let form = 0;
    for (let k = 0; k < formantBP.length; k++) form += bq(formantBP[k], sig) * (k === 0 ? 0.9 : k === 1 ? 0.55 : 0.32);
    sig = sig * 0.42 + form * 0.58;
    sig = bq(presence, sig); sig = bq(shelf, sig);
    sig = lp1(toneLP, sig, Math.min(0.55, 0.08 + p.bright * 0.28 * env * brightAttack));
    sig = bq(bell, sig);
    const wnoise = next() * 2 - 1;
    pink1 = 0.997 * pink1 + 0.029 * wnoise;
    pink2 = 0.985 * pink2 + 0.14 * wnoise;
    const air = pink1 + 0.45 * pink2 + 0.08 * wnoise;
    const breath = bq(breathHP, bq(breathBP, air)) * breathAmt * (0.45 + 0.55 * env);
    const chiff = bq(chiffBP, wnoise) * chiffAmt * Math.exp(-t / 0.022) * Math.min(1, t / 0.002);
    const click = t < 0.003 ? wnoise * 0.08 * (1 - t / 0.003) : 0;
    const growl = p.growl > 0 ? 1 + p.growl * Math.sin(2 * Math.PI * (growlPhase + 62 * t)) * env : 1;
    const ampVib = 1 + p.ampVib * Math.sin(2 * Math.PI * (vibPhase + 0.21 + p.vibR * t));
    let y = (sig * growl + breath + chiff + click) * env * bloom * ampVib;
    y = bq(dcHP, y);
    if (p.sat > 0) y = reedShape(y, 1 + p.sat * 0.7, 0.12);
    out[i] = y;
  }
  return fade(normalize(out, 0.34), sr, 0.0012, 0.025);
}

function renderPiano(midi) {
  const sr = ctx.sampleRate, f0 = midiToHz(midi), dur = 2.4, n = Math.floor(dur * sr), inv = 1 / sr;
  const next = makeRng(midi * 9917 + 3);
  const out = new Float32Array(n);
  const nyquist = sr * 0.46;
  const stiffness = 0.00012 + 0.00022 * Math.pow(Math.max(0, 72 - midi) / 48, 1.4);
  const hCount = Math.min(18, Math.max(8, Math.floor(nyquist / f0)));
  const phases = new Float32Array(hCount);
  const weights = new Float32Array(hCount);
  let sum = 0;
  for (let h = 1; h <= hCount; h++) {
    let w = 1 / Math.pow(h, 1.05);
    if (h === 2) w *= 0.72; if (h === 3) w *= 0.4;
    const freq = f0 * h;
    w *= 0.55 + 0.7 * Math.exp(-Math.pow((freq - 2400) / 2600, 2));
    weights[h - 1] = w; sum += w; phases[h - 1] = next();
  }
  if (sum) for (let i = 0; i < hCount; i++) weights[i] /= sum;
  const hammerHP = bqHP(800, 0.7, sr), hammerBP = bqBP(2800, 0.8, sr);
  const board = bqPK(Math.max(80, f0 * 0.5), 4.5, 2.2, sr), dc = bqHP(30, 0.7, sr), tone = onePole();
  const vel = 0.86 + next() * 0.14, decayBase = 2.1 + (f0 / 440) * 0.55, hammerAmt = 0.16 * vel;
  for (let i = 0; i < n; i++) {
    const t = i * inv;
    let s = 0;
    for (let h = 1; h <= hCount; h++) {
      const fh = f0 * h * Math.sqrt(1 + stiffness * h * h);
      if (fh > nyquist) continue;
      phases[h - 1] = wrap1(phases[h - 1] + fh * inv);
      s += weights[h - 1] * Math.sin(2 * Math.PI * phases[h - 1]) * Math.exp(-t * (decayBase + h * 0.62));
    }
    const hamEnv = Math.exp(-t / 0.006) * Math.min(1, t / 0.0006);
    const hammer = bq(hammerBP, bq(hammerHP, next() * 2 - 1)) * hammerAmt * hamEnv;
    let y = (s * Math.min(1, t / 0.004) + hammer) * vel;
    y = bq(board, y); y = lp1(tone, y, 0.22 + vel * 0.2); y = bq(dc, y);
    out[i] = y;
  }
  return fade(normalize(out, 0.36), sr, 0.0004, 0.04);
}

function renderGuitar(midi) {
  const sr = ctx.sampleRate, f0 = midiToHz(midi), dur = 2.2, n = Math.floor(dur * sr), inv = 1 / sr;
  const next = makeRng(midi * 4241 + 11);
  const out = new Float32Array(n);
  const delayLen = Math.max(8, Math.round(sr / f0));
  const buf = new Float32Array(delayLen);
  const pick = Math.max(2, Math.floor(delayLen * (0.12 + next() * 0.18)));
  for (let i = 0; i < delayLen; i++) {
    const burst = next() * 2 - 1, window = Math.sin(Math.PI * i / delayLen);
    buf[i] = burst * window * (i < pick ? 1 : -0.35);
  }
  let idx = 0, prev = 0;
  const damp = 0.988 - Math.min(0.04, f0 / 18000) + (next() - 0.5) * 0.004;
  const body1 = bqBP(110, 3.2, sr), body2 = bqPK(420, 2.4, 3.5, sr), body3 = bqPK(850, 2.0, 2.2, sr);
  const pickHP = bqHP(1200, 0.7, sr), dc = bqHP(50, 0.7, sr), brightness = onePole();
  const pickAmt = 0.22 + next() * 0.1;
  for (let i = 0; i < n; i++) {
    const t = i * inv;
    const x0 = buf[idx], x1 = buf[(idx + 1) % delayLen];
    const avg = (x0 + x1) * 0.5 * damp;
    const stretched = avg * 0.82 + prev * 0.18;
    prev = avg; buf[idx] = stretched; idx = (idx + 1) % delayLen;
    const pickEnv = Math.exp(-t / 0.012) * Math.min(1, t / 0.0008);
    let y = x0 + bq(pickHP, x0) * pickAmt * pickEnv;
    y += bq(body1, x0) * 0.35;
    y = bq(body2, y); y = bq(body3, y);
    y = lp1(brightness, y, 0.18 + Math.exp(-t / 0.4) * 0.15);
    y = bq(dc, y);
    out[i] = y * Math.min(1, t / 0.003) * Math.exp(-t / (1.15 + 220 / f0));
  }
  return fade(normalize(out, 0.33), sr, 0.0005, 0.03);
}

function renderKalimba(midi) {
  const sr = ctx.sampleRate, f0 = midiToHz(midi), n = Math.floor(3.1 * sr), inv = 1 / sr;
  const next = makeRng(midi * 4873 + 11);
  const out = new Float32Array(n);
  const ratios = [[1, 1, 1.6], [2.012, 0.22, 3.4], [2.758, 0.16, 4.8], [4.072, 0.08, 7]];
  const phases = ratios.map(() => next());
  const nail = bqHP(2400, 0.7, sr), wood = bqPK(420, 2.8, 3, sr), dc = bqHP(40, 0.7, sr);
  for (let i = 0; i < n; i++) {
    const t = i * inv;
    let s = 0;
    for (let k = 0; k < ratios.length; k++) {
      phases[k] = wrap1(phases[k] + f0 * ratios[k][0] * inv);
      s += ratios[k][1] * Math.sin(2 * Math.PI * phases[k]) * Math.exp(-t * ratios[k][2]);
    }
    const click = bq(nail, next() * 2 - 1) * 0.12 * Math.exp(-t / 0.008);
    out[i] = bq(dc, bq(wood, (s + click) * Math.min(1, t / 0.003)));
  }
  return fade(normalize(out, 0.3), sr, 0.0008, 0.08);
}

function renderGlass(midi) {
  const sr = ctx.sampleRate, f0 = midiToHz(midi), n = Math.floor(4.0 * sr), inv = 1 / sr;
  const next = makeRng(midi * 4873 + 23);
  const out = new Float32Array(n);
  const beat = 0.7 + next() * 0.5;
  let p1 = next(), p2 = next(), p3 = next();
  const air = bqBP(5200, 0.6, sr), dc = bqHP(40, 0.7, sr);
  for (let i = 0; i < n; i++) {
    const t = i * inv;
    p1 = wrap1(p1 + f0 * inv); p2 = wrap1(p2 + (f0 + beat) * inv); p3 = wrap1(p3 + f0 * 2.003 * inv);
    const env = Math.min(1, t / 0.06) * Math.exp(-t / 2.4);
    const s = (Math.sin(2 * Math.PI * p1) + Math.sin(2 * Math.PI * p2)) * 0.46 + Math.sin(2 * Math.PI * p3) * 0.07;
    out[i] = bq(dc, (s + bq(air, next() * 2 - 1) * 0.03 * env) * env);
  }
  return fade(normalize(out, 0.26), sr, 0.02, 0.12);
}

function renderRhodes(midi) {
  const sr = ctx.sampleRate, f0 = midiToHz(midi), n = Math.floor(2.6 * sr), inv = 1 / sr;
  const next = makeRng(midi * 4873 + 37);
  const out = new Float32Array(n);
  let p0 = next(), p1 = next(), p2 = next();
  const bell = bqBP(4800, 0.9, sr), body = bqPK(280, 1.2, 2.5, sr), dc = bqHP(40, 0.7, sr);
  for (let i = 0; i < n; i++) {
    const t = i * inv;
    p0 = wrap1(p0 + f0 * inv); p1 = wrap1(p1 + f0 * 2.0008 * inv); p2 = wrap1(p2 + f0 * 4.02 * inv);
    const tine = Math.sin(2 * Math.PI * p0) * Math.exp(-t / 1.15)
      + 0.28 * Math.sin(2 * Math.PI * p1) * Math.exp(-t / 0.55)
      + 0.07 * Math.sin(2 * Math.PI * p2) * Math.exp(-t / 0.22);
    const ham = bq(bell, next() * 2 - 1) * 0.18 * Math.exp(-t / 0.01);
    let y = (tine + ham) * Math.min(1, t / 0.002);
    y = tanhApprox(bq(body, y) * 1.15);
    out[i] = bq(dc, y);
  }
  return fade(normalize(out, 0.3), sr, 0.0006, 0.06);
}

function renderChimes(midi) {
  const sr = ctx.sampleRate, f0 = midiToHz(midi), n = Math.floor(4.2 * sr), inv = 1 / sr;
  const next = makeRng(midi * 4873 + 53);
  const out = new Float32Array(n);
  const ratios = [[1, 1, 0.9], [2.758, 0.55, 1.3], [5.404, 0.28, 1.8], [8.933, 0.12, 2.6]];
  const phases = ratios.map(() => next());
  const air = bqHP(3000, 0.6, sr), dc = bqHP(50, 0.7, sr);
  for (let i = 0; i < n; i++) {
    const t = i * inv;
    let s = 0;
    for (let k = 0; k < ratios.length; k++) {
      const fh = f0 * ratios[k][0]; if (fh > sr * 0.45) continue;
      phases[k] = wrap1(phases[k] + fh * inv);
      s += ratios[k][1] * Math.sin(2 * Math.PI * phases[k]) * Math.exp(-t * ratios[k][2]);
    }
    out[i] = bq(dc, (s + bq(air, next() * 2 - 1) * 0.04 * Math.exp(-t / 0.04)) * Math.min(1, t / 0.002));
  }
  return fade(normalize(out, 0.24), sr, 0.001, 0.15);
}

function renderBox(midi) {
  const sr = ctx.sampleRate, f0 = midiToHz(midi), n = Math.floor(1.5 * sr), inv = 1 / sr;
  const next = makeRng(midi * 4873 + 71);
  const out = new Float32Array(n);
  const phases = new Float32Array(6); for (let i = 0; i < 6; i++) phases[i] = next();
  const tick = bqHP(5000, 0.8, sr), dc = bqHP(60, 0.7, sr);
  for (let i = 0; i < n; i++) {
    const t = i * inv;
    let s = 0;
    for (let h = 1; h <= 6; h++) {
      phases[h - 1] = wrap1(phases[h - 1] + f0 * h * (1 + 0.0004 * h * h) * inv);
      s += (1 / Math.pow(h, 1.35)) * Math.sin(2 * Math.PI * phases[h - 1]) * Math.exp(-t * (2.2 + h * 0.8));
    }
    out[i] = bq(dc, (s + bq(tick, next() * 2 - 1) * 0.1 * Math.exp(-t / 0.006)) * Math.min(1, t / 0.0015));
  }
  return fade(normalize(out, 0.28), sr, 0.0004, 0.05);
}

function renderPad(midi) {
  const sr = ctx.sampleRate, f0 = midiToHz(midi), dur = 2.4, n = Math.floor(dur * sr), inv = 1 / sr;
  const next = makeRng(midi * 4873 + 97);
  const out = new Float32Array(n);
  const detune = [-7, -2.5, 0, 3.1, 8];
  const phases = detune.map(() => next());
  const air = bqBP(2400, 0.7, sr), lp = onePole(), dc = bqHP(40, 0.7, sr);
  for (let i = 0; i < n; i++) {
    let s = 0;
    for (let k = 0; k < detune.length; k++) {
      phases[k] = wrap1(phases[k] + f0 * centsToRatio(detune[k]) * inv);
      s += Math.sin(2 * Math.PI * phases[k]);
    }
    s /= detune.length;
    const env = adsr(i * inv, 0.16, 0.2, 0.82, 0.08, dur - 0.44);
    out[i] = bq(dc, lp1(lp, s, 0.12) * env + bq(air, next() * 2 - 1) * 0.05 * env);
  }
  return fade(normalize(out, 0.28), sr, 0.01, 0.04);
}

function renderThump(midi) {
  const sr = ctx.sampleRate, fEnd = Math.max(32, midiToHz(midi)), n = Math.floor(0.85 * sr), inv = 1 / sr;
  const next = makeRng(midi * 4873 + 131);
  const out = new Float32Array(n);
  const fStart = fEnd * (3.4 + next() * 0.5);
  let phase = 0;
  const clickHP = bqHP(2200, 0.7, sr), bodyLP = onePole();
  for (let i = 0; i < n; i++) {
    const t = i * inv, drop = Math.exp(-t / 0.038);
    const freq = fEnd + (fStart - fEnd) * drop;
    phase = wrap1(phase + freq * inv);
    const body = Math.sin(2 * Math.PI * phase) * Math.exp(-t / 0.28);
    const sub = Math.sin(2 * Math.PI * phase * 0.5) * 0.35 * Math.exp(-t / 0.4);
    const click = bq(clickHP, next() * 2 - 1) * 0.22 * Math.exp(-t / 0.004);
    out[i] = lp1(bodyLP, body + sub + click, 0.35 + drop * 0.25) * Math.min(1, t / 0.001);
  }
  return fade(normalize(out, 0.42), sr, 0.0003, 0.04);
}

function renderDrum(midi) {
  const piece = Math.abs(midi - 36) % DRUMS.length;
  const sr = ctx.sampleRate, inv = 1 / sr;
  const next = makeRng(piece * 9917 + 17);
  if (piece === 0) {
    const n = Math.floor(0.55 * sr), out = new Float32Array(n);
    let phase = 0; const hp = bqHP(1800, 0.7, sr);
    for (let i = 0; i < n; i++) {
      const t = i * inv, drop = Math.exp(-t / 0.032);
      phase = wrap1(phase + (48 + 110 * drop) * inv);
      out[i] = Math.sin(2 * Math.PI * phase) * Math.exp(-t / 0.22) + bq(hp, next() * 2 - 1) * 0.18 * Math.exp(-t / 0.004);
    }
    return fade(normalize(out, 0.46), sr, 0.0002, 0.03);
  }
  if (piece === 1) {
    const n = Math.floor(0.32 * sr), out = new Float32Array(n);
    const bp = bqBP(180, 1.1, sr), nbp = bqBP(6400, 0.7, sr);
    let phase = 0;
    for (let i = 0; i < n; i++) {
      const t = i * inv; phase = wrap1(phase + 186 * inv);
      out[i] = bq(bp, Math.sin(2 * Math.PI * phase)) * Math.exp(-t / 0.06) * 0.45 + bq(nbp, next() * 2 - 1) * 0.7 * Math.exp(-t / 0.08);
    }
    return fade(normalize(out, 0.38), sr, 0.0003, 0.02);
  }
  if (piece === 2 || piece === 3) {
    const open = piece === 3, n = Math.floor((open ? 0.28 : 0.055) * sr), out = new Float32Array(n);
    const hp = bqHP(open ? 5500 : 7200, 0.6, sr), bp = bqBP(9000, 0.9, sr), fall = open ? 0.09 : 0.018;
    for (let i = 0; i < n; i++) out[i] = bq(hp, bq(bp, next() * 2 - 1)) * Math.exp(-(i * inv) / fall);
    return fade(normalize(out, open ? 0.26 : 0.22), sr, 0.0002, 0.01);
  }
  if (piece === 4) {
    const n = Math.floor(0.28 * sr), out = new Float32Array(n), bp = bqBP(1400, 0.8, sr), bursts = [0, 0.012, 0.021, 0.034];
    for (let i = 0; i < n; i++) {
      const t = i * inv; let env = 0;
      for (const b of bursts) if (t >= b) env += Math.exp(-(t - b) / 0.018);
      out[i] = bq(bp, next() * 2 - 1) * env * 0.55;
    }
    return fade(normalize(out, 0.34), sr, 0.0002, 0.02);
  }
  if (piece >= 5 && piece <= 7) {
    const freq = [92, 128, 176][piece - 5], n = Math.floor(0.42 * sr), out = new Float32Array(n);
    let phase = 0; const noiseHP = bqHP(1200, 0.7, sr);
    for (let i = 0; i < n; i++) {
      const t = i * inv, f = freq * (1 + 0.18 * Math.exp(-t / 0.04));
      phase = wrap1(phase + f * inv);
      out[i] = Math.sin(2 * Math.PI * phase) * Math.exp(-t / 0.16) + bq(noiseHP, next() * 2 - 1) * 0.12 * Math.exp(-t / 0.01);
    }
    return fade(normalize(out, 0.36), sr, 0.0003, 0.025);
  }
  if (piece === 8) {
    const n = Math.floor(0.12 * sr), out = new Float32Array(n);
    const bp = bqBP(900, 4.5, sr), hp = bqHP(2400, 0.7, sr); let phase = 0;
    for (let i = 0; i < n; i++) {
      const t = i * inv; phase = wrap1(phase + 780 * inv);
      out[i] = bq(bp, Math.sin(2 * Math.PI * phase)) * Math.exp(-t / 0.03) * 0.6 + bq(hp, next() * 2 - 1) * Math.exp(-t / 0.006) * 0.5;
    }
    return fade(normalize(out, 0.3), sr, 0.0002, 0.012);
  }
  if (piece === 9) {
    const n = Math.floor(1.4 * sr), out = new Float32Array(n);
    const hp = bqHP(2800, 0.5, sr), bp = bqBP(7500, 0.6, sr);
    for (let i = 0; i < n; i++) out[i] = bq(hp, bq(bp, next() * 2 - 1)) * Math.exp(-(i * inv) / 0.42);
    return fade(normalize(out, 0.28), sr, 0.0004, 0.06);
  }
  if (piece === 10) {
    const n = Math.floor(0.18 * sr), out = new Float32Array(n);
    const bp = bqBP(420, 2.4, sr); let phase = 0;
    for (let i = 0; i < n; i++) {
      const t = i * inv; phase = wrap1(phase + 410 * inv);
      out[i] = bq(bp, Math.sin(2 * Math.PI * phase) + (next() * 2 - 1) * 0.3) * Math.exp(-t / 0.04);
    }
    return fade(normalize(out, 0.32), sr, 0.0002, 0.015);
  }
  if (piece === 11) {
    const n = Math.floor(0.22 * sr), out = new Float32Array(n), hp = bqHP(6000, 0.6, sr);
    for (let i = 0; i < n; i++) out[i] = bq(hp, next() * 2 - 1) * Math.exp(-(i * inv) / 0.07);
    return fade(normalize(out, 0.22), sr, 0.0002, 0.02);
  }
  const n = Math.floor(0.35 * sr), out = new Float32Array(n);
  let p0 = 0, p1 = 0;
  for (let i = 0; i < n; i++) {
    const t = i * inv; p0 = wrap1(p0 + 540 * inv); p1 = wrap1(p1 + 800 * inv);
    out[i] = (Math.sin(2 * Math.PI * p0) + Math.sin(2 * Math.PI * p1) * 0.7) * Math.exp(-t / 0.12);
  }
  return fade(normalize(out, 0.3), sr, 0.0002, 0.02);
}

function renderVoice(id, midi) {
  switch (id) {
    case "alto": case "tenor": case "bari": case "youtube": return renderSax(midi, id);
    case "piano": return renderPiano(midi);
    case "guitar": return renderGuitar(midi);
    case "kalimba": return renderKalimba(midi);
    case "glass": return renderGlass(midi);
    case "chimes": return renderChimes(midi);
    case "rhodes": return renderRhodes(midi);
    case "musicBox": return renderBox(midi);
    case "pad": return renderPad(midi);
    case "drums": return renderDrum(midi);
    case "thump": return renderThump(midi);
    default: return renderPiano(midi);
  }
}

function bufferFrom(samples) {
  const b = ctx.createBuffer(1, samples.length, ctx.sampleRate);
  b.getChannelData(0).set(samples);
  return b;
}

function playBuffer(audioBuf, hold) {
  const src = ctx.createBufferSource();
  src.buffer = audioBuf;
  if (hold) {
    src.loop = true;
    src.loopStart = Math.min(0.24, audioBuf.duration * 0.2);
    src.loopEnd = Math.max(src.loopStart + 0.35, audioBuf.duration - 0.06);
  }
  const g = ctx.createGain();
  g.gain.value = 1;
  src.connect(g); g.connect(master);
  src.start();
  return {
    hold: !!hold,
    stop(now = ctx.currentTime) {
      g.gain.cancelScheduledValues(now);
      g.gain.setValueAtTime(Math.max(0.0001, g.gain.value), now);
      g.gain.exponentialRampToValueAtTime(0.0001, now + 0.12);
      try { src.stop(now + 0.14); } catch (_) {}
    }
  };
}

function startVoice(id, midi) {
  const key = id + ":" + midi;
  let buf = bank.get(key);
  if (!buf) {
    buf = bufferFrom(renderVoice(id, midi));
    bank.set(key, buf);
  }
  const hold = !!voiceById(id)?.hold || id === "thump" && false;
  return playBuffer(buf, hold);
}

function unlock() {
  if (ctx) {
    if (ctx.state === "suspended") ctx.resume();
    return;
  }
  ctx = new (window.AudioContext || window.webkitAudioContext)({ latencyHint: "interactive" });
  master = ctx.createGain();
  master.gain.value = 0.85;
  const comp = ctx.createDynamicsCompressor();
  comp.threshold.value = -16; comp.knee.value = 10; comp.ratio.value = 2.4;
  comp.attack.value = 0.004; comp.release.value = 0.12;
  master.connect(comp);
  comp.connect(ctx.destination);
  recDest = ctx.createMediaStreamDestination();
  comp.connect(recDest);
  document.getElementById("gate").hidden = true;
  document.getElementById("status").textContent = "Tap a pad. Hardware keys work too.";
  startStage();
  warmup();
}

function warmup() {
  const jobs = [];
  ROWS.forEach(row => notesFor(row).forEach(n => jobs.push([row.voice, n.midi])));
  jobs.push(["thump", 24]);
  let i = 0;
  const step = () => {
    if (!ctx || i >= jobs.length) return;
    const [id, midi] = jobs[i++];
    const key = id + ":" + midi;
    if (!bank.has(key)) {
      try { bank.set(key, bufferFrom(renderVoice(id, midi))); } catch (_) {}
    }
    setTimeout(step, 0);
  };
  setTimeout(step, 40);
}

function lane(keyId, salt) {
  let h = 2166136261;
  const s = keyId + ":" + salt;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); }
  return 0.14 + (Math.abs(h) % 1000) / 1000 * 0.72;
}

function spawnDrop(ch, color, keyId) {
  const now = performance.now();
  drops.push({ ch, color, x: lane(keyId, drops.length), born: now, end: null, keyId });
  sentence += ch;
  if (!recording && sentence.length > 96) sentence = sentence.slice(-80);
}

function endDrop(keyId) {
  const now = performance.now();
  for (let i = drops.length - 1; i >= 0; i--) {
    if (drops[i].keyId === keyId && drops[i].end == null) { drops[i].end = now; break; }
  }
}

function drawScene(g, w, h, now, bg) {
  if (bg) {
    g.fillStyle = "#0d0908";
    g.fillRect(0, 0, w, h);
    const last = drops[drops.length - 1];
    if (last) {
      g.globalAlpha = 0.16;
      g.fillStyle = last.color;
      g.fillRect(0, 0, w, h);
      g.globalAlpha = 1;
    }
  } else {
    g.clearRect(0, 0, w, h);
  }
  g.textAlign = "center";
  g.textBaseline = "middle";
  for (const d of drops) {
    const age = (now - d.born) / 1000;
    const p = Math.min(1, age / 0.48);
    const ease = 1 - Math.pow(1 - p, 3);
    let a = 1;
    if (d.end != null) a = Math.max(0, 1 - (now - d.end) / 850);
    if (a <= 0.02) continue;
    const y = (-0.06 + ease * 0.48) * h;
    g.globalAlpha = a;
    g.fillStyle = d.color;
    g.shadowColor = "rgba(0,0,0,0.45)";
    g.shadowBlur = 18;
    g.font = `800 ${Math.round(h * (d.ch.length > 2 ? 0.12 : 0.2))}px "SF Pro Rounded","Nunito",system-ui,sans-serif`;
    g.fillText(d.ch === " " ? "␣" : d.ch, d.x * w, y);
  }
  g.shadowBlur = 0;
  if (sentence) {
    g.globalAlpha = 0.94;
    g.fillStyle = "#f4ece2";
    const size = sentence.length > 64 ? 22 : sentence.length > 32 ? 28 : sentence.length > 16 ? 36 : 44;
    g.font = `600 ${Math.round(size * (h / 720))}px "SF Pro Rounded","Nunito",system-ui,sans-serif`;
    wrapText(g, sentence, w / 2, h * 0.86, w * 0.82, size * 1.2 * (h / 720));
  }
  g.globalAlpha = 1;
}

function wrapText(g, text, x, y, max, lh) {
  const words = text.split(/(\s+)/);
  const lines = [];
  let line = "";
  words.forEach(w => {
    const t = line + w;
    if (g.measureText(t).width > max && line) { lines.push(line); line = w.trimStart(); }
    else line = t;
  });
  if (line) lines.push(line);
  const top = y - (lines.length - 1) * lh / 2;
  lines.forEach((l, i) => g.fillText(l, x, top + i * lh));
}

function resizeStage() {
  const dpr = Math.min(2, window.devicePixelRatio || 1);
  stage.width = Math.floor(window.innerWidth * dpr);
  stage.height = Math.floor(window.innerHeight * dpr);
}

function tick() {
  const now = performance.now();
  drawScene(stageG, stage.width, stage.height, now, false);
  drawScene(tapeG, tape.width, tape.height, now, true);
  while (drops.length && drops[0].end != null && now - drops[0].end > 1200) drops.shift();
  raf = requestAnimationFrame(tick);
}

function startStage() {
  stage = document.getElementById("stage");
  tape = document.getElementById("tape");
  stageG = stage.getContext("2d");
  tapeG = tape.getContext("2d");
  resizeStage();
  window.addEventListener("resize", resizeStage);
  if (!raf) raf = requestAnimationFrame(tick);
}

function noteOn(keyId, row, index, shift) {
  if (!ctx) unlock();
  if (live.has(keyId)) return;
  const v = voiceById(row.voice);
  const n = notesFor(row)[index];
  if (!n) return;
  const voice = startVoice(row.voice, n.midi);
  live.set(keyId, { voice, row: row.id, index });
  const pad = document.querySelector(`[data-key="${keyId}"]`);
  if (pad) pad.classList.add("on");
  const ch = typedChar(n.label, shift);
  spawnDrop(ch, v.accent, keyId);
}

function noteOff(keyId) {
  const slot = live.get(keyId);
  if (!slot) return;
  if (!sustain || slot.voice.hold) slot.voice.stop();
  live.delete(keyId);
  document.querySelector(`[data-key="${keyId}"]`)?.classList.remove("on");
  endDrop(keyId);
}

function spaceOn() {
  if (!ctx) unlock();
  if (live.has("space")) return;
  live.set("space", { voice: startVoice("thump", 24), hold: false });
  document.getElementById("space").classList.add("on");
  spawnDrop(" ", "#6b5cc7", "space");
}
function spaceOff() {
  const s = live.get("space");
  if (s) s.voice.stop();
  live.delete("space");
  document.getElementById("space").classList.remove("on");
  endDrop("space");
}

function render() {
  const root = document.getElementById("rows");
  root.innerHTML = "";
  ROWS.forEach((row, ri) => {
    const v = voiceById(row.voice);
    const ns = notesFor(row);
    const wrap = document.createElement("section");
    wrap.className = "row";
    wrap.innerHTML = `<div class="row-bar">
      <h2>${row.title}</h2>
      <select data-row="${ri}"></select>
      <div class="step">OCT <button data-oct="${ri}" data-d="-1">−</button><b>${row.oct}</b><button data-oct="${ri}" data-d="1">+</button></div>
      <div class="step">TR <button data-tr="${ri}" data-d="-1">−</button><b>${row.tr === 0 ? "0" : (row.tr > 0 ? "+"+row.tr : row.tr)}</b><button data-tr="${ri}" data-d="1">+</button></div>
    </div><div class="pads"></div>`;
    const sel = wrap.querySelector("select");
    let group = "";
    let og = null;
    VOICES.forEach(voice => {
      if (voice.group !== group) {
        group = voice.group;
        og = document.createElement("optgroup");
        og.label = group;
        sel.append(og);
      }
      const o = document.createElement("option");
      o.value = voice.id; o.textContent = voice.title;
      if (voice.id === row.voice) o.selected = true;
      og.append(o);
    });
    sel.onchange = () => { row.voice = sel.value; render(); };
    wrap.querySelectorAll("[data-oct]").forEach(b => b.onclick = () => { row.oct = Math.min(7, Math.max(1, row.oct + Number(b.dataset.d))); render(); });
    wrap.querySelectorAll("[data-tr]").forEach(b => b.onclick = () => { row.tr = Math.min(12, Math.max(-12, row.tr + Number(b.dataset.d))); render(); });
    const pads = wrap.querySelector(".pads");
    ns.forEach((n, i) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "pad";
      btn.style.setProperty("--accent", v.accent);
      btn.dataset.key = `${row.id}-${i}`;
      btn.innerHTML = `<small>${n.label}</small><b>${n.caption}</b>`;
      bindPad(btn, () => noteOn(`${row.id}-${i}`, row, i, false), () => noteOff(`${row.id}-${i}`));
      pads.append(btn);
    });
    root.append(wrap);
  });
}

function bindPad(el, down, up) {
  const go = e => { e.preventDefault(); down(); };
  const end = e => { e.preventDefault(); up(); };
  el.addEventListener("pointerdown", go);
  el.addEventListener("pointerup", end);
  el.addEventListener("pointercancel", end);
  el.addEventListener("pointerleave", e => { if (e.buttons) up(); });
}

function wavFromFloat(chunks, rate) {
  let len = 0; chunks.forEach(c => len += c.length);
  const pcm = new Int16Array(len);
  let o = 0;
  chunks.forEach(c => { for (let i = 0; i < c.length; i++) pcm[o++] = Math.max(-1, Math.min(1, c[i])) * 32767; });
  const buf = new ArrayBuffer(44 + pcm.length * 2);
  const v = new DataView(buf);
  const w = (s, p) => { for (let i = 0; i < s.length; i++) v.setUint8(p + i, s.charCodeAt(i)); };
  w("RIFF", 0); v.setUint32(4, 36 + pcm.length * 2, true); w("WAVE", 8); w("fmt ", 12);
  v.setUint32(16, 16, true); v.setUint16(20, 1, true); v.setUint16(22, 1, true);
  v.setUint32(24, rate, true); v.setUint32(28, rate * 2, true); v.setUint16(32, 2, true); v.setUint16(34, 16, true);
  w("data", 36); v.setUint32(40, pcm.length * 2, true);
  new Uint8Array(buf, 44).set(new Uint8Array(pcm.buffer));
  return new Blob([buf], { type: "audio/wav" });
}

function pickMime(kinds) {
  if (typeof MediaRecorder === "undefined") return "";
  return kinds.find(t => MediaRecorder.isTypeSupported(t)) || "";
}

function startWavTap() {
  recChunks = [];
  try {
    recProc = ctx.createScriptProcessor(2048, 1, 1);
    master.connect(recProc);
    const mute = ctx.createGain(); mute.gain.value = 0;
    recProc.connect(mute); mute.connect(ctx.destination);
    recProc.onaudioprocess = e => { if (recording) recChunks.push(new Float32Array(e.inputBuffer.getChannelData(0))); };
  } catch (_) {
    recProc = null;
  }
}

function startRec() {
  recording = true;
  drops.length = 0;
  sentence = "";
  recChunks = [];
  recBits = [];
  recStart = ctx.currentTime;
  recMime = "";
  recMedia = null;
  startWavTap();
  tape.hidden = false;
  document.body.classList.add("filming");
  document.getElementById("record").classList.add("rec");
  document.getElementById("record").textContent = "Stop";
  document.getElementById("status").textContent = "Recording — letters drop, sentence forms";
  drawScene(tapeG, tape.width, tape.height, performance.now(), true);
  const mime = pickMime([
    "video/mp4;codecs=avc1.42E01E,mp4a.40.2",
    "video/mp4",
    "video/webm;codecs=vp9,opus",
    "video/webm;codecs=vp8,opus",
    "video/webm"
  ]);
  try {
    if (typeof tape.captureStream === "function") {
      const vStream = tape.captureStream(30);
      const tracks = [...vStream.getVideoTracks(), ...(recDest?.stream.getAudioTracks() || [])];
      const mixed = new MediaStream(tracks);
      const opts = mime ? { mimeType: mime, videoBitsPerSecond: 5_000_000 } : { videoBitsPerSecond: 5_000_000 };
      recMedia = new MediaRecorder(mixed, opts);
      recMime = recMedia.mimeType || mime || "video/webm";
      recMedia.ondataavailable = e => { if (e.data && e.data.size) recBits.push(e.data); };
      recMedia.start(200);
    }
  } catch (err) {
    recMedia = null;
    document.getElementById("status").textContent = "Recording audio — video unavailable here";
  }
}

function stopRec() {
  recording = false;
  document.body.classList.remove("filming");
  document.getElementById("record").classList.remove("rec");
  document.getElementById("record").textContent = "Record";
  const dur = Math.max(0.4, ctx.currentTime - recStart);
  const wav = recChunks && recChunks.length ? wavFromFloat(recChunks, ctx.sampleRate) : null;
  try { recProc && recProc.disconnect(); } catch (_) {}
  let finished = false;
  const finish = videoBlob => {
    if (finished) return;
    finished = true;
    tape.hidden = true;
    pending = {
      wav,
      video: videoBlob && videoBlob.size > 800 ? videoBlob : null,
      sentence,
      dur,
      mime: recMime
    };
    document.getElementById("sentence-preview").textContent = pending.sentence || "(no letters)";
    const hasVideo = !!pending.video;
    document.querySelector('[data-export="clipAudio"]').hidden = !hasVideo;
    document.querySelector('[data-export="clipVideo"]').hidden = !hasVideo;
    document.getElementById("export").hidden = false;
    document.getElementById("status").textContent = hasVideo ? "Clip is ready." : "Audio is ready. Video isn’t supported in this browser.";
  };
  if (recMedia && recMedia.state !== "inactive") {
    recMedia.onstop = () => finish(new Blob(recBits, { type: recMime || "video/webm" }));
    try { recMedia.requestData(); } catch (_) {}
    recMedia.stop();
    setTimeout(() => { if (!pending) finish(new Blob(recBits, { type: recMime || "video/webm" })); }, 1200);
  } else {
    finish(null);
  }
}

function downloadBlob(blob, name) {
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 4000);
}

function extFor(mime) {
  if (!mime) return "webm";
  if (mime.includes("mp4")) return "mp4";
  return "webm";
}

function exportKind(kind) {
  document.getElementById("export").hidden = true;
  if (!pending) return;
  if (kind === "audioOnly") {
    if (pending.wav) downloadBlob(pending.wav, "keysax.wav");
    return;
  }
  if (!pending.video) {
    if (pending.wav) downloadBlob(pending.wav, "keysax.wav");
    return;
  }
  const name = "keysax-letters." + extFor(pending.mime);
  downloadBlob(pending.video, name);
  if (kind === "clipAudio" && pending.wav) {
    // Combined stream already has audio when the browser allowed it.
    // WAV is a fallback if the clip is silent.
  }
}

document.getElementById("start").onclick = unlock;
document.getElementById("sustain").onclick = function () {
  sustain = !sustain;
  this.classList.toggle("on", sustain);
  if (!sustain) live.forEach((s, id) => { if (!s.voice.hold) s.voice.stop(); });
};
document.getElementById("record").onclick = () => {
  if (!ctx) unlock();
  recording ? stopRec() : startRec();
};
document.getElementById("export-cancel").onclick = () => { document.getElementById("export").hidden = true; };
document.querySelectorAll("[data-export]").forEach(b => b.onclick = () => exportKind(b.dataset.export));
bindPad(document.getElementById("space"), spaceOn, spaceOff);

window.addEventListener("keydown", e => {
  if (e.metaKey || e.ctrlKey || e.repeat) return;
  if (e.code === "Space") { e.preventDefault(); spaceOn(); return; }
  if (e.code === "Tab") { e.preventDefault(); document.getElementById("sustain").click(); return; }
  if (e.code === "Escape") { live.forEach((_, id) => noteOff(id)); spaceOff(); return; }
  if (e.code === "ArrowUp") { ROWS.forEach(r => r.oct = Math.min(7, r.oct + 1)); render(); return; }
  if (e.code === "ArrowDown") { ROWS.forEach(r => r.oct = Math.max(1, r.oct - 1)); render(); return; }
  const hit = lookup[e.code];
  if (!hit) return;
  e.preventDefault();
  const [ri, i] = hit;
  noteOn(`${ROWS[ri].id}-${i}`, ROWS[ri], i, e.shiftKey);
});
window.addEventListener("keyup", e => {
  if (e.code === "Space") { spaceOff(); return; }
  const hit = lookup[e.code];
  if (!hit) return;
  const [ri, i] = hit;
  noteOff(`${ROWS[ri].id}-${i}`);
});

render();
if ("serviceWorker" in navigator) navigator.serviceWorker.register("./sw.js").catch(() => {});
