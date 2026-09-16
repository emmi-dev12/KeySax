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
const SCALES = {
  youtube: [0, 2, 4, 5, 7, 9, 10],
  major: [0, 2, 4, 5, 7, 9, 11],
  minor: [0, 2, 3, 5, 7, 8, 10],
  pentatonicMajor: [0, 2, 4, 7, 9],
  pentatonicMinor: [0, 3, 5, 7, 10],
  blues: [0, 3, 5, 6, 7, 10],
  mixolydian: [0, 2, 4, 5, 7, 9, 10],
  dorian: [0, 2, 3, 5, 7, 9, 10],
  chromatic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
};
const ROWS = [
  { id: "numbers", title: "1 – 0", codes: ["Backquote","Digit1","Digit2","Digit3","Digit4","Digit5","Digit6","Digit7","Digit8","Digit9","Digit0","Minus","Equal"], labels: ["`","1","2","3","4","5","6","7","8","9","0","-","="], voice: "alto", oct: 4, tr: 0 },
  { id: "qwerty", title: "QWERTY", codes: ["KeyQ","KeyW","KeyE","KeyR","KeyT","KeyY","KeyU","KeyI","KeyO","KeyP","BracketLeft","BracketRight","Backslash"], labels: ["Q","W","E","R","T","Y","U","I","O","P","[","]","\\"], voice: "kalimba", oct: 4, tr: 0 },
  { id: "home", title: "HOME", codes: ["KeyA","KeyS","KeyD","KeyF","KeyG","KeyH","KeyJ","KeyK","KeyL","Semicolon","Quote"], labels: ["A","S","D","F","G","H","J","K","L",";","'"], voice: "piano", oct: 4, tr: 0 },
  { id: "bottom", title: "BOTTOM", codes: ["KeyZ","KeyX","KeyC","KeyV","KeyB","KeyN","KeyM","Comma","Period","Slash"], labels: ["Z","X","C","V","B","N","M",",",".","/"], voice: "guitar", oct: 4, tr: 0 },
  { id: "numpad", title: "NUMPAD", codes: ["Numpad7","Numpad8","Numpad9","NumpadSubtract","Numpad4","Numpad5","Numpad6","NumpadAdd","Numpad1","Numpad2","Numpad3","NumpadEnter","Numpad0","NumpadDecimal","NumpadDivide","NumpadMultiply"], labels: ["7","8","9","−","4","5","6","+","1","2","3","↵","0",".","/","*"], voice: "drums", oct: 4, tr: 0 },
];

const lookup = {};
ROWS.forEach((row, ri) => row.codes.forEach((c, i) => { lookup[c] = [ri, i]; }));
const SHIFT = {"`":"~","1":"!","2":"@","3":"#","4":"$","5":"%","6":"^","7":"&","8":"*","9":"(","0":")","-":"_","=":"+","[":"{","]":"}","\\":"|",";":":","'":"\"",",":"<",".":">","/":"?"};
function typedChar(label, shift) {
  if (!shift) return /^[A-Z]$/.test(label) ? label.toLowerCase() : label;
  return SHIFT[label] || label.toUpperCase();
}

let ctx, master, recDest, recChunks, recProc, recording = false, sustain = false;
const live = new Map();
const bank = new Map();
let recStart = 0;
let pending = null;
let letterCap = null;
let filmCap = null;
let everyKey = false;
let keepAlive = false;
let analyser, wave, waveG;
let letterVideo = true;
let midiEnabled = false;
let midiOut = null;
let soloTimer = null;
let globalOct = 4;
let globalTr = 0;
let root = 0;
let scaleId = "youtube";
let appearance = "dark";
let volume = 0.85;
let engine = "additive";
let midiAccess = null;
let midiDestIndex = 0;
let deferredInstall = null;
const STORE = "keysax-pwa-v1";

const drops = [];
let sentence = "";
let stage, tape, film, stageG, tapeG, filmG;
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
  const pattern = SCALES[scaleId] || SCALES.youtube;
  const start = (row.oct + 1) * 12 + root + row.tr + (v?.register || 0);
  return row.labels.map((label, i) => {
    const midi = clamp(start + pattern[i % pattern.length] + 12 * Math.floor(i / pattern.length));
    return { label, midi, caption: noteName(midi) };
  });
}
function spaceMIDI() {
  const pc = ((root + globalTr) % 12 + 12) % 12;
  return 24 + pc;
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

function fracDelay(maxLen) {
  const buf = new Float32Array(Math.max(32, maxLen));
  let w = 0;
  return {
    read(delay) {
      const n = buf.length;
      let r = w - Math.max(1, delay);
      while (r < 0) r += n;
      const i0 = ((Math.floor(r) % n) + n) % n;
      const i1 = (i0 + 1) % n;
      const f = r - Math.floor(r);
      return buf[i0] * (1 - f) + buf[i1] * f;
    },
    write(x) {
      buf[w] = x;
      w++;
      if (w >= buf.length) w = 0;
    }
  };
}

function renderReed(midi, id) {
  const p = SAX[id] || SAX.alto;
  const sr = ctx.sampleRate, f0 = midiToHz(midi);
  const dur = 1.55, n = Math.floor(dur * sr), inv = 1 / sr;
  const next = makeRng(midi * 11017 + id.length * 42421 + 7);
  const out = new Float32Array(n);
  const delay = fracDelay(Math.floor(sr / 40) + 8);
  const boreLP = onePole();
  const bell = bqLP(1100 + p.bright * 4400, 0.7, sr);
  const form1 = bqBP(p.formants[0][0], 3.4, sr);
  const form2 = bqBP(p.formants[1][0], 2.8, sr);
  const breathBP = bqBP(p.breathF, 1.1, sr);
  const dc = bqHP(40, 0.7, sr);
  const vibPhase = next();
  const stiffness = 2.4 + p.sat * 1.2;
  let wander = 0;
  const attack = 0.016, decay = 0.1, hold = dur - attack - decay - 0.05;
  for (let i = 0; i < n; i++) {
    const t = i * inv;
    const env = adsr(t, attack, decay, 0.8, 0.05, hold);
    let pressure = 0.7 * env;
    if (t < 0.05) pressure *= 0.5 + 0.5 * (t / 0.05);
    wander += (next() - 0.5) * 0.08; wander *= 0.997;
    let vib = 0;
    if (t > p.vibDelay) {
      const vt = t - p.vibDelay;
      vib = Math.sin(2 * Math.PI * (vibPhase + p.vibR * vt)) * p.vibD * Math.min(1, vt / 0.2);
    }
    let scoopEnv = 1;
    if (t < 0.06) { const x = t / 0.06; scoopEnv = centsToRatio(-p.scoop * (1 - x) * (1 - x)); }
    const freq = f0 * scoopEnv * centsToRatio(vib + wander);
    const delaySamp = Math.max(4, sr / freq);
    const y = delay.read(delaySamp);
    const noise = next() * 2 - 1;
    const reed = tanhApprox((pressure - y) * stiffness);
    const flow = reed * 0.58 + noise * (0.035 + p.breath * 0.4) * pressure;
    const intoBore = flow + y * (0.84 + 0.08 * (1 - p.bright));
    delay.write(lp1(boreLP, intoBore, 0.16 + p.bright * 0.38));
    let tone = y + flow * 0.18;
    tone = bq(bell, tone);
    tone = tone * 0.55 + bq(form1, tone) * 0.5 + bq(form2, tone) * 0.28;
    const breath = bq(breathBP, noise) * p.breath * env;
    let s = (tone + breath) * env;
    if (p.growl > 0) s *= 1 + p.growl * Math.sin(2 * Math.PI * (0.3 + 66 * t));
    out[i] = bq(dc, s);
  }
  return fade(normalize(out, 0.32), sr, 0.0015, 0.025);
}

function renderVoice(id, midi) {
  switch (id) {
    case "alto": case "tenor": case "bari": case "youtube":
      return engine === "reed" ? renderReed(midi, id) : renderSax(midi, id);
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
  const key = id + ":" + midi + ":" + (["alto","tenor","bari","youtube"].includes(id) ? engine : "x");
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
  master.gain.value = volume;
  const comp = ctx.createDynamicsCompressor();
  comp.threshold.value = -16; comp.knee.value = 10; comp.ratio.value = 2.4;
  comp.attack.value = 0.004; comp.release.value = 0.12;
  master.connect(comp);
  comp.connect(ctx.destination);
  recDest = ctx.createMediaStreamDestination();
  comp.connect(recDest);
  analyser = ctx.createAnalyser();
  analyser.fftSize = 256;
  analyser.smoothingTimeConstant = 0.72;
  comp.connect(analyser);
  master.gain.value = volume;
  ctx.onstatechange = () => { if (keepAlive && ctx.state === "suspended") ctx.resume(); };
  const scaleTitle = document.getElementById("scale")?.selectedOptions[0]?.textContent || "YouTube";
  document.getElementById("status").textContent = "Four rows · " + scaleTitle;
  if (!stageStarted) startStage();
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
    const key = id + ":" + midi + ":" + (["alto","tenor","bari","youtube"].includes(id) ? engine : "x");
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

function clearLetters() {
  drops.length = 0;
  sentence = "";
  flash("Cleared");
}

function backspaceLetter() {
  if (!drops.length && !sentence) return;
  const last = drops.pop();
  if (last && sentence.endsWith(last.ch)) sentence = sentence.slice(0, -last.ch.length);
  else if (sentence) sentence = sentence.slice(0, -1);
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
  if (stageG) drawScene(stageG, stage.width, stage.height, now, false);
  if (tapeG && recording) drawScene(tapeG, tape.width, tape.height, now, true);
  if (filmG && recording) drawApp(filmG, film.width, film.height, now);
  drawWave();
  while (drops.length && drops[0].end != null && now - drops[0].end > 1200) drops.shift();
  raf = requestAnimationFrame(tick);
}

function drawWave() {
  if (!waveG) return;
  const w = wave.width, h = wave.height;
  waveG.clearRect(0, 0, w, h);
  const accent = voiceById(ROWS[0].voice)?.accent || "#dcb359";
  const bins = 24, gap = 2;
  const barW = Math.max(2, (w - gap * (bins - 1)) / bins);
  let data = null;
  if (analyser) {
    data = new Uint8Array(analyser.frequencyBinCount);
    analyser.getByteFrequencyData(data);
  }
  let rms = 0;
  for (let i = 0; i < bins; i++) {
    const t = i / bins;
    let v = 0.08;
    if (data) {
      const lo = Math.min(data.length - 1, Math.floor(Math.pow(data.length, t)));
      const hi = Math.max(lo + 1, Math.min(data.length, Math.floor(Math.pow(data.length, (i + 1) / bins))));
      let sum = 0;
      for (let k = lo; k < hi; k++) sum += data[k];
      v = Math.min(1, (sum / Math.max(1, hi - lo)) / 255 * 1.55);
      rms += v;
    }
    const bh = Math.max(2, v * h);
    const x = i * (barW + gap);
    const y = (h - bh) / 2;
    waveG.globalAlpha = 0.35 + 0.65 * (1 - t * 0.4);
    waveG.fillStyle = accent;
    const r = barW / 2;
    waveG.beginPath();
    if (waveG.roundRect) waveG.roundRect(x, y, barW, bh, r);
    else waveG.rect(x, y, barW, bh);
    waveG.fill();
  }
  rms = Math.min(1, (rms / bins) * 1.4);
  if (rms > 0.02) {
    waveG.globalAlpha = 0.55;
    waveG.fillRect(0, h * 0.5 - 0.6, w * rms, 1.2);
  }
  waveG.globalAlpha = 1;
}

let stageStarted = false;
function hexFill(hex, a) {
  const n = parseInt((hex || "#dcb359").replace("#", ""), 16);
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
}

function fillRound(g, x, y, w, h, r) {
  g.beginPath();
  if (g.roundRect) g.roundRect(x, y, w, h, r);
  else g.rect(x, y, w, h);
  g.fill();
}

function drawApp(g, W, H, now) {
  const grd = g.createRadialGradient(W * 0.5, H * 0.42, 40, W * 0.5, H * 0.42, Math.max(W, H) * 0.72);
  grd.addColorStop(0, "#291a12");
  grd.addColorStop(1, "#0f0b0a");
  g.fillStyle = grd;
  g.fillRect(0, 0, W, H);
  g.textBaseline = "middle";
  g.fillStyle = "#f4ece2";
  g.font = `600 ${Math.round(H * 0.032)}px "SF Pro Rounded",system-ui,sans-serif`;
  g.textAlign = "left";
  g.fillText("KeySax", W * 0.04, H * 0.055);
  g.fillStyle = "rgba(244,236,226,0.55)";
  g.font = `500 ${Math.round(H * 0.02)}px "SF Pro Rounded",system-ui,sans-serif`;
  g.fillText(document.getElementById("status")?.textContent || "", W * 0.04, H * 0.09);

  const marginX = W * 0.04;
  const top = H * 0.13;
  const area = H * 0.72;
  const rowH = area / (ROWS.length + 1);
  ROWS.forEach((row, ri) => {
    const y0 = top + ri * rowH;
    const v = voiceById(row.voice);
    const ns = notesFor(row);
    g.fillStyle = "rgba(244,236,226,0.5)";
    g.font = `600 ${Math.round(H * 0.018)}px "SF Pro Rounded",system-ui,sans-serif`;
    g.textAlign = "left";
    g.fillText(row.title, marginX, y0 + rowH * 0.12);
    g.textAlign = "right";
    g.fillText(v.title, W - marginX, y0 + rowH * 0.12);
    const padsY = y0 + rowH * 0.26;
    const padsH = rowH * 0.62;
    const gap = Math.max(6, W * 0.006);
    const padsW = W - marginX * 2;
    const pw = (padsW - gap * (ns.length - 1)) / ns.length;
    ns.forEach((n, i) => {
      const x = marginX + i * (pw + gap);
      const on = live.has(`${row.id}-${i}`);
      g.fillStyle = on ? v.accent : hexFill(v.accent, 0.2);
      fillRound(g, x, padsY, pw, padsH, Math.min(14, padsH * 0.22));
      g.strokeStyle = hexFill(v.accent, on ? 0.9 : 0.35);
      g.lineWidth = 1;
      g.beginPath();
      if (g.roundRect) g.roundRect(x, padsY, pw, padsH, Math.min(14, padsH * 0.22));
      g.stroke();
      g.fillStyle = on ? "#fff" : "rgba(244,236,226,0.55)";
      g.textAlign = "center";
      g.font = `700 ${Math.round(padsH * 0.2)}px "SF Pro Rounded",system-ui,sans-serif`;
      g.fillText(n.label, x + pw / 2, padsY + padsH * 0.34);
      g.fillStyle = on ? "#fff" : "rgba(244,236,226,0.92)";
      g.font = `600 ${Math.round(padsH * 0.26)}px "Iowan Old Style",Palatino,serif`;
      g.fillText(n.caption, x + pw / 2, padsY + padsH * 0.68);
    });
  });
  const spaceY = top + ROWS.length * rowH + rowH * 0.22;
  const spaceH = rowH * 0.5;
  const onSpace = live.has("space");
  g.fillStyle = onSpace ? "#6b5cc7" : "rgba(107,92,199,0.22)";
  fillRound(g, marginX, spaceY, W - marginX * 2, spaceH, 16);
  g.fillStyle = onSpace ? "#fff" : "rgba(244,236,226,0.9)";
  g.textAlign = "center";
  g.font = `700 ${Math.round(spaceH * 0.28)}px "SF Pro Rounded",system-ui,sans-serif`;
  g.fillText("space  " + noteName(spaceMIDI()), W / 2, spaceY + spaceH / 2);

  drawScene(g, W, H, now, false);
}

function startStage() {
  stage = document.getElementById("stage");
  tape = document.getElementById("tape");
  film = document.getElementById("film");
  wave = document.getElementById("wave");
  stageG = stage.getContext("2d");
  tapeG = tape.getContext("2d", { alpha: false });
  filmG = film.getContext("2d", { alpha: false });
  waveG = wave.getContext("2d");
  const dpr = Math.min(2, window.devicePixelRatio || 1);
  wave.width = Math.floor(160 * dpr);
  wave.height = Math.floor(28 * dpr);
  resizeStage();
  if (!stageStarted) {
    window.addEventListener("resize", resizeStage);
    stageStarted = true;
  }
  if (!raf) raf = requestAnimationFrame(tick);
}

function noteOn(keyId, row, index, shift) {
  if (!ctx) unlock();
  if (live.has(keyId)) return;
  const v = voiceById(row.voice);
  const n = notesFor(row)[index];
  if (!n) return;
  const voice = startVoice(row.voice, n.midi);
  live.set(keyId, { voice, row: row.id, index, midi: n.midi });
  const pad = document.querySelector(`[data-key="${keyId}"]`);
  if (pad) pad.classList.add("on");
  const ch = typedChar(n.label, shift);
  spawnDrop(ch, v.accent, keyId);
  midiSend(true, n.midi);
}

function noteOff(keyId) {
  const slot = live.get(keyId);
  if (!slot) return;
  if (!sustain || slot.voice.hold) slot.voice.stop();
  if (slot.midi != null) midiSend(false, slot.midi);
  live.delete(keyId);
  document.querySelector(`[data-key="${keyId}"]`)?.classList.remove("on");
  endDrop(keyId);
}

function spaceOn() {
  if (!ctx) unlock();
  if (live.has("space")) return;
  live.set("space", { voice: startVoice("thump", spaceMIDI()), hold: false });
  document.getElementById("space").classList.add("on");
  spawnDrop(" ", "#6b5cc7", "space");
  midiSend(true, spaceMIDI());
}
function spaceOff() {
  const s = live.get("space");
  if (s) s.voice.stop();
  live.delete("space");
  document.getElementById("space").classList.remove("on");
  endDrop("space");
  midiSend(false, spaceMIDI());
}

function trLabel(n) { return n === 0 ? "0" : (n > 0 ? "+" + n : String(n)); }

function render() {
  const rootEl = document.getElementById("rows");
  rootEl.innerHTML = "";
  ROWS.forEach((row, ri) => {
    const v = voiceById(row.voice);
    const ns = notesFor(row);
    const wrap = document.createElement("section");
    wrap.className = "row";
    wrap.innerHTML = `<div class="row-bar">
      <h2>${row.title}</h2>
      <label class="voice-menu">
        <span class="dot" style="background:${v.accent}"></span>
        <span class="voice-title">${v.title}</span>
        <svg class="chev" viewBox="0 0 10 10" aria-hidden="true"><path d="M1.5 3.5L5 7l3.5-3.5" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>
        <select data-row="${ri}" aria-label="Sound for ${row.title}"></select>
      </label>
      <span class="grow"></span>
      <div class="step">OCT
        <button class="mini" data-oct="${ri}" data-d="-1" type="button" aria-label="Octave down">
          <svg viewBox="0 0 16 16"><path d="M3.5 8h9" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>
        </button>
        <b>${row.oct}</b>
        <button class="mini" data-oct="${ri}" data-d="1" type="button" aria-label="Octave up">
          <svg viewBox="0 0 16 16"><path d="M8 3.5v9M3.5 8h9" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>
        </button>
      </div>
      <div class="step">TR
        <button class="mini" data-tr="${ri}" data-d="-1" type="button" aria-label="Transpose down">
          <svg viewBox="0 0 16 16"><path d="M3.5 8h9" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>
        </button>
        <b>${trLabel(row.tr)}</b>
        <button class="mini" data-tr="${ri}" data-d="1" type="button" aria-label="Transpose up">
          <svg viewBox="0 0 16 16"><path d="M8 3.5v9M3.5 8h9" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>
        </button>
      </div>
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
    sel.onchange = () => { row.voice = sel.value; render(); save(); fillRowSettings(); };
    wrap.querySelectorAll("[data-oct]").forEach(b => b.onclick = () => {
      row.oct = Math.min(7, Math.max(1, row.oct + Number(b.dataset.d)));
      render();
      save();
    });
    wrap.querySelectorAll("[data-tr]").forEach(b => b.onclick = () => {
      row.tr = Math.min(12, Math.max(-12, row.tr + Number(b.dataset.d)));
      render();
      save();
    });
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
    rootEl.append(wrap);
  });
  syncChrome();
}

function syncChrome() {
  document.getElementById("oct-global").textContent = String(globalOct);
  document.getElementById("tr-global").textContent = trLabel(globalTr);
  document.getElementById("space-note").textContent = noteName(spaceMIDI());
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

function captureCanvas(canvas, withAudio) {
  if (typeof MediaRecorder === "undefined") return null;
  const grab = canvas.captureStream || canvas.mozCaptureStream;
  if (!grab) return null;
  let vStream;
  try { vStream = grab.call(canvas, 30); } catch (_) { return null; }
  const videoTracks = vStream.getVideoTracks();
  if (!videoTracks.length) return null;
  const tracks = [...videoTracks];
  if (withAudio && recDest) recDest.stream.getAudioTracks().forEach(t => tracks.push(t));
  const mixed = new MediaStream(tracks);
  const mimes = withAudio
    ? ["video/webm;codecs=vp8,opus", "video/webm", "video/mp4", "video/webm;codecs=vp9,opus"]
    : ["video/webm;codecs=vp8", "video/webm", "video/mp4"];
  const mime = pickMime(mimes);
  const chunks = [];
  let rec = null;
  const tryStart = stream => {
    const opts = mime ? { mimeType: mime, videoBitsPerSecond: 8_000_000 } : { videoBitsPerSecond: 8_000_000 };
    rec = new MediaRecorder(stream, opts);
  };
  try {
    tryStart(mixed);
  } catch (_) {
    try { tryStart(vStream); } catch (err) { return null; }
  }
  rec.ondataavailable = e => { if (e.data && e.data.size) chunks.push(e.data); };
  rec.onerror = () => {};
  try { rec.start(100); } catch (_) { return null; }
  return { rec, chunks, mime: rec.mimeType || mime || "video/webm" };
}

function stopCapture(cap) {
  return new Promise(resolve => {
    if (!cap || !cap.rec || cap.rec.state === "inactive") {
      resolve(cap && cap.chunks.length ? new Blob(cap.chunks, { type: cap.mime }) : null);
      return;
    }
    let done = false;
    const finish = () => {
      if (done) return;
      done = true;
      const blob = cap.chunks.length ? new Blob(cap.chunks, { type: cap.mime }) : null;
      resolve(blob && blob.size > 400 ? blob : null);
    };
    cap.rec.onstop = finish;
    try { cap.rec.requestData(); } catch (_) {}
    try { cap.rec.stop(); } catch (_) { finish(); }
    setTimeout(finish, 2500);
  });
}

async function startRec() {
  if (!ctx) unlock();
  recording = true;
  pending = null;
  drops.length = 0;
  sentence = "";
  recChunks = [];
  letterCap = null;
  filmCap = null;
  recStart = ctx.currentTime;
  startWavTap();
  document.body.classList.add("filming");
  document.getElementById("record").classList.add("rec");
  document.getElementById("record").title = "Stop";
  const monitors = document.getElementById("rec-monitors");
  monitors.hidden = false;
  const now = performance.now();
  if (tapeG) drawScene(tapeG, tape.width, tape.height, now, true);
  if (filmG) drawApp(filmG, film.width, film.height, now);
  await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
  filmCap = captureCanvas(film, true);
  if (letterVideo) letterCap = captureCanvas(tape, true);
  if (!filmCap && navigator.mediaDevices && navigator.mediaDevices.getDisplayMedia) {
    try {
      const ds = await navigator.mediaDevices.getDisplayMedia({
        video: { frameRate: 30 },
        audio: false,
        preferCurrentTab: true,
        selfBrowserSurface: "include"
      });
      const tracks = [...ds.getVideoTracks(), ...(recDest ? recDest.stream.getAudioTracks() : [])];
      const mime = pickMime(["video/webm;codecs=vp8,opus", "video/webm", "video/mp4"]);
      const chunks = [];
      const rec = new MediaRecorder(new MediaStream(tracks), mime ? { mimeType: mime, videoBitsPerSecond: 8_000_000 } : { videoBitsPerSecond: 8_000_000 });
      rec.ondataavailable = e => { if (e.data && e.data.size) chunks.push(e.data); };
      rec.start(100);
      filmCap = { rec, chunks, mime: rec.mimeType || mime || "video/webm", display: ds };
    } catch (_) {}
  }
  const gotVideo = !!(filmCap || letterCap);
  document.getElementById("status").textContent = gotVideo
    ? "Recording the app…"
    : "Recording audio — video unavailable here";
}

async function stopRec() {
  recording = false;
  document.body.classList.remove("filming");
  document.getElementById("record").classList.remove("rec");
  document.getElementById("record").title = "Record";
  document.getElementById("status").textContent = "Finishing clip…";
  const wav = recChunks && recChunks.length ? wavFromFloat(recChunks, ctx.sampleRate) : null;
  try { recProc && recProc.disconnect(); } catch (_) {}
  const [filmBlob, letterBlob] = await Promise.all([stopCapture(filmCap), stopCapture(letterCap)]);
  try { filmCap?.display?.getTracks().forEach(t => t.stop()); } catch (_) {}
  document.getElementById("rec-monitors").hidden = true;
  pending = {
    wav,
    film: filmBlob,
    video: letterBlob,
    filmMime: filmCap?.mime || "",
    mime: letterCap?.mime || filmCap?.mime || "video/webm",
    sentence,
    dur: Math.max(0.4, ctx.currentTime - recStart)
  };
  letterCap = null;
  filmCap = null;
  document.getElementById("sentence-preview").textContent = pending.sentence || "(no letters)";
  const hasFilm = !!pending.film;
  const hasLetters = !!pending.video;
  document.querySelector('[data-export="appAudio"]').hidden = !hasFilm;
  document.querySelector('[data-export="appVideo"]').hidden = !hasFilm;
  document.querySelector('[data-export="clipAudio"]').hidden = !hasLetters;
  document.querySelector('[data-export="clipVideo"]').hidden = !hasLetters;
  document.getElementById("export").hidden = false;
  document.getElementById("status").textContent = (hasFilm || hasLetters) ? "Clip is ready." : "Audio is ready. Video didn’t capture in this browser.";
}

function downloadBlob(blob, name) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = name;
  a.rel = "noopener";
  a.style.display = "none";
  document.body.appendChild(a);
  a.click();
  setTimeout(() => { a.remove(); URL.revokeObjectURL(url); }, 4000);
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
    else flash("No audio in that take");
    return;
  }
  if (kind === "appAudio" || kind === "appVideo") {
    if (pending.film) downloadBlob(pending.film, "keysax-app." + extFor(pending.filmMime || pending.mime));
    else if (pending.wav) { downloadBlob(pending.wav, "keysax.wav"); flash("No app video — saved WAV"); }
    else flash("Nothing to download");
    return;
  }
  if (pending.video) {
    downloadBlob(pending.video, "keysax-letters." + extFor(pending.mime));
    return;
  }
  if (pending.wav) {
    downloadBlob(pending.wav, "keysax.wav");
    flash("No letter video — saved WAV");
  }
}

function flash(text) {
  document.getElementById("status").textContent = text;
}

function prefsSnapshot() {
  return {
    appearance, scaleId, root, volume, sustain, letterVideo, midiEnabled, midiDestIndex,
    globalOct, globalTr, engine, everyKey, keepAlive,
    rows: ROWS.map(r => ({ id: r.id, voice: r.voice, oct: r.oct, tr: r.tr }))
  };
}

function save() {
  const payload = JSON.stringify(prefsSnapshot());
  try { localStorage.setItem(STORE, payload); } catch (_) {}
}

function load() {
  let raw = null;
  try { raw = localStorage.getItem(STORE); } catch (_) {}
  if (!raw) return;
  try {
    const s = JSON.parse(raw);
    if (!s || typeof s !== "object") return;
    if (s.appearance === "system" || s.appearance === "dark" || s.appearance === "light") appearance = s.appearance;
    if (s.scaleId && SCALES[s.scaleId]) scaleId = s.scaleId;
    if (Number.isFinite(s.root)) root = Math.max(0, Math.min(11, s.root | 0));
    if (Number.isFinite(s.volume)) volume = Math.max(0, Math.min(1, Number(s.volume)));
    if (typeof s.sustain === "boolean") sustain = s.sustain;
    if (typeof s.letterVideo === "boolean") letterVideo = s.letterVideo;
    if (typeof s.midiEnabled === "boolean") midiEnabled = s.midiEnabled;
    if (Number.isFinite(s.midiDestIndex)) midiDestIndex = Math.max(0, s.midiDestIndex | 0);
    if (Number.isFinite(s.globalOct)) globalOct = Math.max(1, Math.min(7, s.globalOct | 0));
    if (Number.isFinite(s.globalTr)) globalTr = Math.max(-12, Math.min(12, s.globalTr | 0));
    if (s.engine === "additive" || s.engine === "reed") engine = s.engine;
    if (typeof s.everyKey === "boolean") everyKey = s.everyKey;
    if (typeof s.keepAlive === "boolean") keepAlive = s.keepAlive;
    if (Array.isArray(s.rows)) {
      s.rows.forEach(saved => {
        const row = ROWS.find(r => r.id === saved.id);
        if (!row) return;
        if (saved.voice && VOICES.some(v => v.id === saved.voice)) row.voice = saved.voice;
        if (Number.isFinite(saved.oct)) row.oct = Math.max(1, Math.min(7, saved.oct | 0));
        if (Number.isFinite(saved.tr)) row.tr = Math.max(-12, Math.min(12, saved.tr | 0));
      });
    }
  } catch (_) {}
}

function applyForm() {
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.value = String(val); };
  set("appearance", appearance);
  set("scale", scaleId);
  set("root", root);
  set("engine", engine);
  set("volume", volume);
  document.getElementById("sustain").checked = sustain;
  document.getElementById("letter-video").classList.toggle("on", letterVideo);
  document.getElementById("midi").classList.toggle("on", midiEnabled);
  document.getElementById("midi-enable").checked = midiEnabled;
  document.getElementById("engine-blurb").textContent = engine === "reed" ? "Physical-model waveguide" : "Additive harmonics + breath";
  document.getElementById("record").title = letterVideo ? "Record letter video" : "Record WAV";
  const ek = document.getElementById("every-key");
  const ka = document.getElementById("keep-alive");
  if (ek) ek.checked = everyKey;
  if (ka) ka.checked = keepAlive;
}

function fillRowSettings() {
  const host = document.getElementById("row-settings");
  host.innerHTML = "";
  ROWS.forEach((row, ri) => {
    const lab = document.createElement("label");
    lab.className = "field";
    lab.append({ numbers: "Number row", qwerty: "QWERTY row", home: "Home row", bottom: "Bottom row", numpad: "Numpad" }[row.id] || row.title);
    const sel = document.createElement("select");
    let group = "", og = null;
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
    sel.onchange = () => { row.voice = sel.value; render(); save(); };
    lab.append(sel);
    host.append(lab);
    void ri;
  });
}

function isStandalone() {
  return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true;
}

function showInstallHints() {
  const canPrompt = !!deferredInstall;
  const standalone = isStandalone();
  const install = document.getElementById("install");
  const installSettings = document.getElementById("install-settings");
  if (install) install.hidden = standalone || !canPrompt;
  if (installSettings) installSettings.hidden = standalone || !canPrompt;
  const showIos = !standalone && !canPrompt && (/iphone|ipad|ipod/i.test(navigator.userAgent) || (navigator.userAgent.includes("Safari") && !navigator.userAgent.includes("Chrome") && !navigator.userAgent.includes("Chromium")));
  const iosHint = document.getElementById("ios-hint-settings");
  if (iosHint) iosHint.hidden = !showIos;
}

async function promptInstall() {
  if (!deferredInstall) {
    showInstallHints();
    flash("Use the browser menu to install KeySax");
    return;
  }
  deferredInstall.prompt();
  await deferredInstall.userChoice;
  deferredInstall = null;
  showInstallHints();
  flash("Installed");
}

function bumpOctave(delta) {
  ROWS.forEach(r => r.oct = Math.min(7, Math.max(1, r.oct + delta)));
  globalOct = Math.min(7, Math.max(1, globalOct + delta));
  render();
  save();
  flash("Octave " + globalOct);
}

function bumpTranspose(delta) {
  ROWS.forEach(r => r.tr = Math.min(12, Math.max(-12, r.tr + delta)));
  globalTr = Math.min(12, Math.max(-12, globalTr + delta));
  render();
  save();
}

function setSustain(on) {
  sustain = !!on;
  const el = document.getElementById("sustain");
  if (el.checked !== sustain) el.checked = sustain;
  if (!sustain) live.forEach((s, id) => { if (!s.voice.hold) s.voice.stop(); });
  save();
  flash(sustain ? "Sustain on" : "Sustain off");
}
function toggleSustain() { setSustain(!sustain); }

function midiSend(on, midi) {
  if (!midiEnabled || !midiOut) return;
  try { midiOut.send([on ? 0x90 : 0x80, Math.max(0, Math.min(127, midi)), on ? 100 : 0]); } catch (_) {}
}

function midiOutputs() {
  return midiAccess ? [...midiAccess.outputs.values()] : [];
}

function pickMidi() {
  const outs = midiOutputs();
  midiOut = outs[Math.min(midiDestIndex, Math.max(0, outs.length - 1))] || null;
}

function fillMidiDest() {
  const sel = document.getElementById("midi-dest");
  const outs = midiOutputs();
  sel.innerHTML = "";
  if (!outs.length) {
    sel.append(new Option("No MIDI destinations", "0"));
    midiOut = null;
    return;
  }
  outs.forEach((o, i) => sel.append(new Option(o.name, String(i))));
  if (midiDestIndex >= outs.length) midiDestIndex = 0;
  sel.value = String(midiDestIndex);
  pickMidi();
}

async function setMIDI(on) {
  midiEnabled = !!on;
  document.getElementById("midi").classList.toggle("on", midiEnabled);
  document.getElementById("midi-enable").checked = midiEnabled;
  if (midiEnabled && navigator.requestMIDIAccess) {
    try {
      midiAccess = await navigator.requestMIDIAccess();
      fillMidiDest();
      flash(midiOut ? "MIDI out on · " + midiOut.name : "MIDI out on — no destination");
    } catch (_) {
      midiOut = null;
      flash("MIDI permission denied");
    }
  } else {
    midiOut = null;
    if (midiEnabled) flash("MIDI not available here");
    else flash("MIDI out off");
  }
  save();
}

async function toggleMIDI() {
  await setMIDI(!midiEnabled);
}

function playOneShot(midi, dur) {
  const voice = startVoice(ROWS[0].voice, midi);
  setTimeout(() => voice.stop(), dur * 1000);
}

function toggleSolo() {
  if (soloTimer) {
    clearTimeout(soloTimer);
    soloTimer = null;
    document.getElementById("solo").classList.remove("on");
    flash("Solo stopped");
    return;
  }
  document.getElementById("solo").classList.add("on");
  flash("Random solo");
  if (!ctx) unlock();
  const notes = notesFor(ROWS[0]).map(n => n.midi);
  let cursor = Math.floor(notes.length / 3);
  let phrases = 4 + Math.floor(Math.random() * 4);
  const step = () => {
    if (!soloTimer && phrases < 0) return;
    if (phrases <= 0) {
      document.getElementById("solo").classList.remove("on");
      soloTimer = null;
      return;
    }
    const length = 5 + Math.floor(Math.random() * 6);
    let i = 0;
    const note = () => {
      if (!document.getElementById("solo").classList.contains("on")) return;
      if (i >= length) {
        phrases--;
        soloTimer = setTimeout(step, 180);
        return;
      }
      if (Math.random() < 1 / 7) {
        i++;
        soloTimer = setTimeout(note, 140);
        return;
      }
      const leap = [-2, -1, -1, 0, 1, 1, 2, 3][Math.floor(Math.random() * 8)];
      cursor = (cursor + leap + notes.length * 4) % notes.length;
      const dur = i === length - 1 ? [0.35, 0.5, 0.7][Math.floor(Math.random() * 3)] : [0.12, 0.14, 0.18, 0.22, 0.28][Math.floor(Math.random() * 5)];
      playOneShot(notes[cursor], dur * 0.92);
      i++;
      soloTimer = setTimeout(note, dur * 1000);
    };
    note();
  };
  soloTimer = setTimeout(step, 30);
}

function applyAppearance() {
  const mode = appearance;
  const dark = mode === "dark" || (mode === "system" && !window.matchMedia("(prefers-color-scheme: light)").matches);
  document.documentElement.classList.toggle("light", !dark);
  document.documentElement.classList.toggle("dark", dark);
  document.querySelector('meta[name="theme-color"]').content = dark ? "#0f0b0a" : "#d1bda3";
}

function openSheet(id) { document.getElementById(id).hidden = false; }
function closeSheet(id) { document.getElementById(id).hidden = true; }

document.getElementById("sustain").onchange = function () { setSustain(this.checked); };
document.getElementById("record").onclick = () => {
  if (!ctx) unlock();
  if (!letterVideo && !recording) {
    // still record audio; video capture stays on if letter video is on
  }
  recording ? stopRec() : startRec();
};
document.getElementById("export-cancel").onclick = () => closeSheet("export");
document.querySelectorAll("[data-export]").forEach(b => b.onclick = () => exportKind(b.dataset.export));
bindPad(document.getElementById("space"), spaceOn, spaceOff);

document.getElementById("oct-down").onclick = () => bumpOctave(-1);
document.getElementById("oct-up").onclick = () => bumpOctave(1);
document.getElementById("tr-down").onclick = () => bumpTranspose(-1);
document.getElementById("tr-up").onclick = () => bumpTranspose(1);
document.getElementById("volume").oninput = e => {
  volume = Number(e.target.value);
  if (master) master.gain.value = volume;
  save();
};
document.getElementById("clear-letters").onclick = clearLetters;
document.getElementById("letter-video").onclick = function () {
  letterVideo = !letterVideo;
  this.classList.toggle("on", letterVideo);
  this.title = letterVideo ? "Letter video on — letters drop, sentence forms" : "Letter video off";
  document.getElementById("record").title = letterVideo ? "Record letter video" : "Record WAV";
  save();
};
document.getElementById("solo").onclick = () => { if (!ctx) unlock(); toggleSolo(); };
document.getElementById("midi").onclick = toggleMIDI;
document.getElementById("help").onclick = () => openSheet("help-sheet");
document.getElementById("help-close").onclick = () => closeSheet("help-sheet");
document.getElementById("settings").onclick = () => openSheet("settings-sheet");
document.getElementById("settings-close").onclick = () => closeSheet("settings-sheet");
document.getElementById("appearance").onchange = e => { appearance = e.target.value; applyAppearance(); save(); };
document.getElementById("scale").onchange = e => { scaleId = e.target.value; render(); save(); flash("Four rows · " + e.target.selectedOptions[0].textContent); };
document.getElementById("root").onchange = e => { root = Number(e.target.value); render(); save(); };
document.getElementById("every-key").onchange = e => { everyKey = e.target.checked; save(); };
document.getElementById("keep-alive").onchange = e => { keepAlive = e.target.checked; save(); if (keepAlive && ctx && ctx.state === "suspended") ctx.resume(); };
document.getElementById("engine").onchange = e => {
  engine = e.target.value;
  document.getElementById("engine-blurb").textContent = engine === "reed" ? "Physical-model waveguide" : "Additive harmonics + breath";
  save();
  flash(engine === "reed" ? "Reed Model" : "Classic Sax");
};
document.getElementById("midi-enable").onchange = e => { setMIDI(e.target.checked); };
document.getElementById("midi-dest").onchange = e => { midiDestIndex = Number(e.target.value); pickMidi(); save(); };
document.getElementById("midi-refresh").onclick = () => { if (midiEnabled) setMIDI(true); else fillMidiDest(); };
document.getElementById("install").onclick = promptInstall;
document.getElementById("install-settings").onclick = promptInstall;
document.querySelectorAll(".tab").forEach(tab => {
  tab.onclick = () => {
    document.querySelectorAll(".tab").forEach(t => t.classList.toggle("on", t === tab));
    document.querySelectorAll(".tab-panel").forEach(p => { p.hidden = p.id !== "tab-" + tab.dataset.tab; });
  };
});

window.addEventListener("keydown", e => {
  if (e.target && ["INPUT", "SELECT", "TEXTAREA"].includes(e.target.tagName)) return;
  if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.code === "KeyR") {
    e.preventDefault();
    if (!ctx) unlock();
    recording ? stopRec() : startRec();
    return;
  }
  if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.code === "KeyL") {
    e.preventDefault();
    if (!ctx) unlock();
    toggleSolo();
    return;
  }
  if ((e.metaKey || e.ctrlKey) && e.code === "Period") {
    e.preventDefault();
    live.forEach((_, id) => noteOff(id)); spaceOff();
    flash("All notes off");
    return;
  }
  if ((e.metaKey || e.ctrlKey) && e.code === "Backspace") {
    e.preventDefault();
    clearLetters();
    return;
  }
  if (e.metaKey || e.ctrlKey || (e.repeat && e.code !== "Backspace")) return;
  if (e.code === "Backspace") { e.preventDefault(); backspaceLetter(); return; }
  if (e.code === "Delete") { e.preventDefault(); clearLetters(); return; }
  if (e.code === "Space") { e.preventDefault(); spaceOn(); return; }
  if (e.code === "Tab") { e.preventDefault(); toggleSustain(); return; }
  if (e.code === "Escape") {
    live.forEach((_, id) => noteOff(id)); spaceOff();
    closeSheet("help-sheet"); closeSheet("settings-sheet"); closeSheet("export");
    return;
  }
  if (e.code === "ArrowUp") { bumpOctave(1); return; }
  if (e.code === "ArrowDown") { bumpOctave(-1); return; }
  const hit = lookup[e.code];
  if (hit) {
    e.preventDefault();
    const [ri, i] = hit;
    noteOn(`${ROWS[ri].id}-${i}`, ROWS[ri], i, e.shiftKey);
    return;
  }
  if (everyKey && !e.metaKey && !e.ctrlKey && !/^Meta|Control|Alt|Shift/.test(e.key)) {
    const row = ROWS[2];
    const ns = notesFor(row);
    let h = 0;
    for (let i = 0; i < e.code.length; i++) h = Math.imul(h, 31) + e.code.charCodeAt(i);
    noteOn("any-" + e.code, row, Math.abs(h) % ns.length, e.shiftKey);
  }
});
window.addEventListener("keyup", e => {
  if (e.code === "Space") { spaceOff(); return; }
  const hit = lookup[e.code];
  if (hit) {
    const [ri, i] = hit;
    noteOff(`${ROWS[ri].id}-${i}`);
    return;
  }
  noteOff("any-" + e.code);
});
window.matchMedia("(prefers-color-scheme: light)").addEventListener("change", applyAppearance);
window.addEventListener("beforeinstallprompt", e => {
  e.preventDefault();
  deferredInstall = e;
  showInstallHints();
});
window.keysaxFromHelper = function (code, down, shift) {
  unlock();
  if (code === "Space") { down ? spaceOn() : spaceOff(); return; }
  const hit = lookup[code];
  if (hit) {
    const [ri, i] = hit;
    const id = `${ROWS[ri].id}-${i}`;
    down ? noteOn(id, ROWS[ri], i, !!shift) : noteOff(id);
    return;
  }
  if (!down) { noteOff("any-" + code); return; }
  const row = ROWS[2];
  const ns = notesFor(row);
  let h = 0;
  for (let i = 0; i < code.length; i++) h = Math.imul(h, 31) + code.charCodeAt(i);
  noteOn("any-" + code, row, Math.abs(h) % ns.length, !!shift);
};

function pollListener() {
  const el = document.getElementById("listener-status");
  if (!el) return;
  fetch("http://127.0.0.1:18765/status", { cache: "no-store" })
    .then(r => r.json())
    .then(j => {
      el.textContent = j.ok ? "Mac key listener is running. Type in other apps — KeySax will sound." : "Mac key listener is off.";
    })
    .catch(() => { el.textContent = "Mac key listener is off."; });
}
pollListener();
setInterval(pollListener, 4000);

window.addEventListener("appinstalled", () => {
  deferredInstall = null;
  showInstallHints();
  flash("KeySax installed");
});

(function fillRoot() {
  const sel = document.getElementById("root");
  ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"].forEach((name, i) => {
    const o = document.createElement("option");
    o.value = String(i); o.textContent = name;
    sel.append(o);
  });
})();

load();
applyAppearance();
applyForm();
fillRowSettings();
render();
startStage();
showInstallHints();
document.getElementById("status").textContent = "Four rows · " + (document.getElementById("scale").selectedOptions[0]?.textContent || "YouTube");
if (midiEnabled) setMIDI(true);
["pointerdown", "keydown", "touchstart"].forEach(type => {
  window.addEventListener(type, () => unlock(), { capture: true });
});
window.addEventListener("pagehide", save);
document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "hidden") save();
  if (keepAlive && ctx && ctx.state === "suspended") ctx.resume();
});
setInterval(() => { if (keepAlive && ctx && ctx.state === "suspended") ctx.resume(); }, 2500);
if ("serviceWorker" in navigator) navigator.serviceWorker.register("./sw.js").catch(() => {});
