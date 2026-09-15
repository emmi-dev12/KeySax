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

let ctx, master, recDest, recChunks, recProc, recording = false, sustain = false;
const live = new Map();
const hits = [];
let recStart = 0;
let pending = null;

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

function unlock() {
  if (ctx) return;
  ctx = new (window.AudioContext || window.webkitAudioContext)({ latencyHint: "interactive" });
  master = ctx.createGain();
  master.gain.value = 0.85;
  master.connect(ctx.destination);
  recDest = ctx.createMediaStreamDestination();
  master.connect(recDest);
  document.getElementById("gate").hidden = true;
  document.getElementById("status").textContent = "Tap a pad. Hardware keys work too.";
}

function envGain(t0, attack, decay, sustainLevel, release, hold) {
  const g = ctx.createGain();
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(1, t0 + attack);
  g.gain.exponentialRampToValueAtTime(Math.max(0.001, sustainLevel), t0 + attack + decay);
  return g;
}

function noiseBuffer(seconds) {
  const n = Math.floor(ctx.sampleRate * seconds);
  const b = ctx.createBuffer(1, n, ctx.sampleRate);
  const d = b.getChannelData(0);
  for (let i = 0; i < n; i++) d[i] = Math.random() * 2 - 1;
  return b;
}

function playTone({ freq, type = "sine", dur = 1.2, attack = 0.01, decay = 0.12, sus = 0.001, gain = 0.2, filter, noise, hold }) {
  const t0 = ctx.currentTime;
  const osc = ctx.createOscillator();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, t0);
  const g = ctx.createGain();
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(gain, t0 + attack);
  if (hold) {
    g.gain.setValueAtTime(gain * 0.75, t0 + attack + decay);
  } else {
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  }
  let node = osc;
  if (filter) {
    const f = ctx.createBiquadFilter();
    Object.assign(f, { type: filter.type || "lowpass" });
    f.frequency.value = filter.freq || 1200;
    f.Q.value = filter.q || 0.8;
    osc.connect(f); node = f;
  }
  node.connect(g); g.connect(master);
  osc.start(t0);
  const stop = (now = ctx.currentTime) => {
    g.gain.cancelScheduledValues(now);
    g.gain.setValueAtTime(Math.max(0.0001, g.gain.value), now);
    g.gain.exponentialRampToValueAtTime(0.0001, now + 0.12);
    try { osc.stop(now + 0.14); } catch (_) {}
  };
  if (!hold) osc.stop(t0 + dur + 0.05);
  if (noise) {
    const src = ctx.createBufferSource();
    src.buffer = noiseBuffer(Math.min(1, dur));
    const ng = ctx.createGain();
    ng.gain.setValueAtTime(noise, t0);
    ng.gain.exponentialRampToValueAtTime(0.0001, t0 + Math.min(0.2, dur));
    const hp = ctx.createBiquadFilter();
    hp.type = "highpass"; hp.frequency.value = 1800;
    src.connect(hp); hp.connect(ng); ng.connect(master);
    src.start(t0); src.stop(t0 + 0.25);
  }
  return { stop, hold };
}

function playSax(freq, id) {
  const bright = id === "youtube" ? 3200 : id === "bari" ? 900 : id === "tenor" ? 1400 : 1800;
  return playTone({ freq, type: "sawtooth", dur: 2, attack: 0.02, decay: 0.1, gain: 0.12, hold: true, filter: { type: "lowpass", freq: bright, q: 0.7 }, noise: 0.03 });
}

function playPiano(freq) {
  const t0 = ctx.currentTime;
  const g = ctx.createGain();
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(0.22, t0 + 0.005);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + 2.4);
  g.connect(master);
  [1, 2, 3, 4].forEach((h, i) => {
    const o = ctx.createOscillator();
    o.type = "sine";
    o.frequency.value = freq * h * (1 + 0.0002 * h * h);
    const hg = ctx.createGain();
    hg.gain.value = 1 / (h * 1.1);
    o.connect(hg); hg.connect(g);
    o.start(t0); o.stop(t0 + 2.5);
  });
  return { stop: (now = ctx.currentTime) => { g.gain.cancelScheduledValues(now); g.gain.setTargetAtTime(0.0001, now, 0.05); }, hold: false };
}

function playGuitar(freq) {
  const len = Math.max(32, Math.round(ctx.sampleRate / freq));
  const buf = ctx.createBuffer(1, len, ctx.sampleRate);
  const d = buf.getChannelData(0);
  for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.sin(Math.PI * i / len);
  const src = ctx.createBufferSource();
  src.buffer = buf; src.loop = true;
  const f = ctx.createBiquadFilter();
  f.type = "lowpass"; f.frequency.value = 1800;
  const g = ctx.createGain();
  const t0 = ctx.currentTime;
  g.gain.setValueAtTime(0.28, t0);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + 1.8);
  src.connect(f); f.connect(g); g.connect(master);
  src.start(t0); src.stop(t0 + 1.9);
  return { stop: (now = ctx.currentTime) => { g.gain.setTargetAtTime(0.0001, now, 0.04); }, hold: false };
}

function playKalimba(freq) {
  const t0 = ctx.currentTime;
  const g = ctx.createGain();
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(0.24, t0 + 0.004);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + 2.6);
  g.connect(master);
  [1, 2.01, 2.76].forEach((r, i) => {
    const o = ctx.createOscillator();
    o.frequency.value = freq * r;
    const hg = ctx.createGain(); hg.gain.value = i === 0 ? 1 : 0.18;
    o.connect(hg); hg.connect(g); o.start(t0); o.stop(t0 + 2.7);
  });
  return { stop: (n = ctx.currentTime) => g.gain.setTargetAtTime(0.0001, n, 0.05), hold: false };
}

function playGlass(freq) {
  const t0 = ctx.currentTime;
  const g = ctx.createGain();
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.linearRampToValueAtTime(0.16, t0 + 0.08);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + 3.4);
  g.connect(master);
  [0, 0.8].forEach(det => {
    const o = ctx.createOscillator();
    o.frequency.value = freq + det;
    o.connect(g); o.start(t0); o.stop(t0 + 3.5);
  });
  return { stop: (n = ctx.currentTime) => g.gain.setTargetAtTime(0.0001, n, 0.08), hold: false };
}

function playChimes(freq) {
  const t0 = ctx.currentTime;
  const g = ctx.createGain();
  g.gain.setValueAtTime(0.18, t0);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + 3.6);
  g.connect(master);
  [1, 2.758, 5.404].forEach((r, i) => {
    const o = ctx.createOscillator();
    o.frequency.value = freq * r;
    const hg = ctx.createGain(); hg.gain.value = 1 / (i + 1);
    o.connect(hg); hg.connect(g); o.start(t0); o.stop(t0 + 3.7);
  });
  return { stop: (n = ctx.currentTime) => g.gain.setTargetAtTime(0.0001, n, 0.08), hold: false };
}

function playRhodes(freq) {
  return playTone({ freq, type: "sine", dur: 1.8, attack: 0.004, gain: 0.18, noise: 0.08, filter: { type: "lowpass", freq: 2400 } });
}
function playBox(freq) {
  return playTone({ freq, type: "triangle", dur: 0.9, attack: 0.002, gain: 0.16, noise: 0.05 });
}
function playPad(freq) {
  return playTone({ freq, type: "sine", dur: 3, attack: 0.16, decay: 0.2, gain: 0.14, hold: true, filter: { type: "lowpass", freq: 900 } });
}

function playDrum(index) {
  const t0 = ctx.currentTime;
  const src = ctx.createBufferSource();
  src.buffer = noiseBuffer(0.4);
  const g = ctx.createGain();
  const f = ctx.createBiquadFilter();
  if (index === 0) { // kick
    return playTone({ freq: 48, type: "sine", dur: 0.45, attack: 0.001, gain: 0.5, filter: { type: "lowpass", freq: 400 } });
  }
  if (index === 1) { // snare
    f.type = "bandpass"; f.frequency.value = 1800;
    g.gain.setValueAtTime(0.35, t0); g.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.18);
    src.connect(f); f.connect(g); g.connect(master); src.start(t0); src.stop(t0 + 0.2);
    playTone({ freq: 180, type: "triangle", dur: 0.12, attack: 0.001, gain: 0.2 });
    return { stop() {}, hold: false };
  }
  if (index === 2 || index === 3) {
    f.type = "highpass"; f.frequency.value = index === 3 ? 5000 : 7000;
    g.gain.setValueAtTime(0.2, t0); g.gain.exponentialRampToValueAtTime(0.0001, t0 + (index === 3 ? 0.22 : 0.05));
    src.connect(f); f.connect(g); g.connect(master); src.start(t0); src.stop(t0 + 0.25);
    return { stop() {}, hold: false };
  }
  if (index === 4) {
    f.type = "bandpass"; f.frequency.value = 1400;
    g.gain.setValueAtTime(0.3, t0); g.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.16);
    src.connect(f); f.connect(g); g.connect(master); src.start(t0); src.stop(t0 + 0.18);
    return { stop() {}, hold: false };
  }
  const freqs = [92, 128, 176, 780, 240, 600, 540];
  return playTone({ freq: freqs[Math.min(index - 5, freqs.length - 1)] || 200, type: "sine", dur: 0.28, attack: 0.001, gain: 0.28, noise: 0.06 });
}

function playThump(freq) {
  const t0 = ctx.currentTime;
  const o = ctx.createOscillator();
  o.frequency.setValueAtTime(freq * 3.2, t0);
  o.frequency.exponentialRampToValueAtTime(freq, t0 + 0.06);
  const g = ctx.createGain();
  g.gain.setValueAtTime(0.55, t0);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.5);
  o.connect(g); g.connect(master);
  o.start(t0); o.stop(t0 + 0.55);
  return { stop: (n = ctx.currentTime) => g.gain.setTargetAtTime(0.0001, n, 0.04), hold: false };
}

function startVoice(id, midi) {
  const freq = midiToHz(midi);
  switch (id) {
    case "alto": case "tenor": case "bari": case "youtube": return playSax(freq, id);
    case "piano": return playPiano(freq);
    case "guitar": return playGuitar(freq);
    case "kalimba": return playKalimba(freq);
    case "glass": return playGlass(freq);
    case "chimes": return playChimes(freq);
    case "rhodes": return playRhodes(freq);
    case "musicBox": return playBox(freq);
    case "pad": return playPad(freq);
    case "drums": return playDrum(Math.abs(midi - 36) % DRUMS.length);
    case "thump": return playThump(freq);
    default: return playPiano(freq);
  }
}

function showLetter(ch, color) {
  const el = document.getElementById("letter");
  el.textContent = ch === " " ? "␣" : ch;
  el.style.color = color || "#e0b259";
  el.classList.add("show");
  clearTimeout(showLetter._t);
  showLetter._t = setTimeout(() => el.classList.remove("show"), 280);
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
  showLetter(ch, v.accent);
  if (recording) hits.push({ t: ctx.currentTime - recStart, ch, color: v.accent, keyId });
}

function noteOff(keyId) {
  const slot = live.get(keyId);
  if (!slot) return;
  if (!sustain || slot.voice.hold) slot.voice.stop();
  live.delete(keyId);
  document.querySelector(`[data-key="${keyId}"]`)?.classList.remove("on");
}

function spaceOn() {
  if (!ctx) unlock();
  if (live.has("space")) return;
  const pc = 0;
  live.set("space", { voice: playThump(midiToHz(24 + pc)), hold: false });
  document.getElementById("space").classList.add("on");
  showLetter(" ", "#6b5cc7");
  if (recording) hits.push({ t: ctx.currentTime - recStart, ch: " ", color: "#6b5cc7", keyId: "space" });
}
function spaceOff() {
  const s = live.get("space");
  if (s) s.voice.stop();
  live.delete("space");
  document.getElementById("space").classList.remove("on");
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
    VOICES.forEach(voice => {
      if (voice.group !== group) {
        group = voice.group;
        const og = document.createElement("optgroup");
        og.label = group; sel.append(og);
      }
      const o = document.createElement("option");
      o.value = voice.id; o.textContent = voice.title;
      if (voice.id === row.voice) o.selected = true;
      sel.append(o);
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

function startRec() {
  recording = true; hits.length = 0; recChunks = []; recStart = ctx.currentTime;
  recProc = ctx.createScriptProcessor(2048, 1, 1);
  master.connect(recProc);
  const mute = ctx.createGain(); mute.gain.value = 0; recProc.connect(mute); mute.connect(ctx.destination);
  recProc.onaudioprocess = e => { if (recording) recChunks.push(new Float32Array(e.inputBuffer.getChannelData(0))); };
  document.getElementById("record").classList.add("rec");
  document.getElementById("record").textContent = "Stop";
  document.getElementById("status").textContent = "Recording…";
}
function stopRec() {
  recording = false;
  try { recProc.disconnect(); } catch (_) {}
  document.getElementById("record").classList.remove("rec");
  document.getElementById("record").textContent = "Record";
  pending = {
    wav: wavFromFloat(recChunks, ctx.sampleRate),
    hits: hits.slice(),
    sentence: hits.map(h => h.ch).join(""),
    dur: ctx.currentTime - recStart
  };
  document.getElementById("sentence-preview").textContent = pending.sentence || "(no letters)";
  document.getElementById("export").hidden = false;
}

function downloadBlob(blob, name) {
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = name;
  a.click();
}

function makeLetterCanvas(hit, sentence) {
  const c = document.createElement("canvas");
  c.width = 720; c.height = 720;
  const g = c.getContext("2d");
  g.fillStyle = "#0d0908"; g.fillRect(0, 0, 720, 720);
  if (sentence) {
    g.fillStyle = "#f4ece2";
    g.font = "600 48px system-ui";
    g.textAlign = "center"; g.textBaseline = "middle";
    wrapText(g, sentence, 360, 360, 560, 56);
  } else if (hit) {
    g.fillStyle = hit.color + "29"; g.fillRect(0, 0, 720, 720);
    g.fillStyle = hit.color;
    g.font = "800 280px system-ui";
    g.textAlign = "center"; g.textBaseline = "middle";
    g.fillText(hit.ch === " " ? "␣" : hit.ch, 360, 360);
  }
  return c;
}
function wrapText(g, text, x, y, max, lh) {
  const words = text.split(" ");
  const lines = [];
  let line = "";
  words.forEach(w => {
    const t = line ? line + " " + w : w;
    if (g.measureText(t).width > max) { lines.push(line); line = w; }
    else line = t;
  });
  if (line) lines.push(line);
  const top = y - (lines.length - 1) * lh / 2;
  lines.forEach((l, i) => g.fillText(l, x, top + i * lh));
}

async function exportKind(kind) {
  document.getElementById("export").hidden = true;
  if (!pending) return;
  if (kind === "audioOnly") {
    downloadBlob(pending.wav, "keysax.wav");
    return;
  }
  const frames = [];
  const fps = 15;
  const letterDur = (kind === "sentenceVideo") ? 0 : pending.dur;
  const tail = (kind === "sentenceAudio" || kind === "sentenceVideo") ? 3 : 0;
  const total = Math.max(0.4, letterDur + tail);
  const n = Math.ceil(total * fps);
  for (let i = 0; i < n; i++) {
    const t = i / fps;
    const showS = t >= letterDur && tail > 0;
    const hit = showS ? null : [...pending.hits].reverse().find(h => t >= h.t && t < h.t + 0.3);
    frames.push(makeLetterCanvas(hit, showS ? pending.sentence : null));
  }
  const stream = frames[0].captureStream(fps);
  const rec = new MediaRecorder(stream, { mimeType: MediaRecorder.isTypeSupported("video/webm") ? "video/webm" : "video/mp4" });
  const bits = [];
  rec.ondataavailable = e => bits.push(e.data);
  const done = new Promise(res => rec.onstop = res);
  rec.start();
  let i = 0;
  await new Promise(res => {
    const id = setInterval(() => {
      const g = frames[0].getContext("2d");
      g.drawImage(frames[Math.min(i, frames.length - 1)], 0, 0);
      i++;
      if (i >= frames.length) { clearInterval(id); rec.stop(); res(); }
    }, 1000 / fps);
  });
  await done;
  let blob = new Blob(bits, { type: rec.mimeType });
  if (kind === "lettersAudio" || kind === "sentenceAudio") {
    downloadBlob(pending.wav, "keysax.wav");
  }
  downloadBlob(blob, kind.includes("sentence") ? "keysax-sentence.webm" : "keysax-letters.webm");
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
