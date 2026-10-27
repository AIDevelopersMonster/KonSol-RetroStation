"use strict";
// KonSol RetroStation · native Tang Nano 9K gaming dashboard / SRAM programmer.
// YoWASP openFPGALoader runtime is a same-origin, SHA-pinned build dependency.
// No operation in this file writes/erases configuration Flash.
const $ = id => document.getElementById(id);
const encoder = new TextEncoder();
const decoder = new TextDecoder();
const BOARD_USB = [{vendorId: 0x0403, productId: 0x6010}];
const FIXED_PROGRAM_ARGS = Object.freeze(["-c", "ft2232", "-b", "tangnano9k", "game.fs"]);
const MAX_LOG = 110000;
let profiles = [];
let availability = new Map();
let current = null;
let loaded = null;
let jtag = null;
let serial = null;
let serialQueue = Promise.resolve();
let held = new Map();
let programming = false;
let downloading = false;
let loader = null;

function log(message) {
  const line = `[${new Date().toLocaleTimeString("ru-RU")}] ${message}`;
  const el = $("log");
  el.textContent += `${line}\n`;
  if (el.textContent.length > MAX_LOG) el.textContent = el.textContent.slice(-90000);
  el.scrollTop = el.scrollHeight;
}
function status(id, message, type = "neutral") {
  const el = $(id);
  el.textContent = message;
  el.className = `result ${type}`;
}
function indicator(id, value, state = "") {
  const el = $(id);
  el.textContent = value;
  el.className = state;
}
function hex(data) { return Array.from(new Uint8Array(data), b => b.toString(16).padStart(2, "0")).join(""); }
function validateProfile(p) {
  return p && /^[a-z][a-z0-9-]{1,30}$/.test(p.id) &&
    /^[a-z0-9_-]+\.fs$/i.test(p.filename) &&
    /^[a-f0-9]{64}$/i.test(p.sha256) &&
    Number.isInteger(p.size_bytes) && p.size_bytes >= 10000 && p.size_bytes < 12582912;
}
function remoteReady(p) {
  const r = availability.get(p.id);
  return !!(r && r.published === true && r.sha256 === p.sha256 && r.filename === p.filename);
}
function refreshButtons() {
  const active = Boolean(current) && !programming && !downloading;
  $("download-button").disabled = !active || !remoteReady(current);
  $("local-button").disabled = !active;
  $("connect-jtag").disabled = programming || downloading;
  $("program-button").disabled = programming || downloading || !loaded || !jtag || !current ||
    loaded.profileId !== current.id || !window.crossOriginIsolated || !navigator.usb;
  document.querySelectorAll(".game-card").forEach(b => { b.disabled = programming || downloading; });
  $("connect-serial").disabled = Boolean(serial) || programming;
  $("disconnect-serial").disabled = !serial;
  document.querySelectorAll(".quick-cmd").forEach(b => {
    b.disabled = !serial || !current || (current.id === "pong" && b.dataset.command === "p");
  });
}
function renderCards() {
  const area = $("game-grid");
  area.replaceChildren();
  for (const p of profiles) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = `game-card ${p.id === current?.id ? "active" : ""}`;
    btn.setAttribute("role", "radio");
    btn.setAttribute("aria-checked", String(p.id === current?.id));
    btn.style.setProperty("--card-color", p.color);
    const swatch = document.createElement("div"); swatch.className = "swatch";
    const mark = document.createElement("div"); mark.className = "game-mark"; mark.textContent = p.mode;
    const title = document.createElement("div"); title.className = "game-title"; title.textContent = p.name;
    const version = document.createElement("div"); version.className = "game-version"; version.textContent = p.version;
    const sub = document.createElement("div"); sub.className = "game-sub"; sub.textContent = p.subtitle;
    const state = document.createElement("div");
    state.className = `game-state ${remoteReady(p) ? "ready" : "local"}`;
    state.textContent = remoteReady(p) ? "● GitHub .fs проверен" : "○ Проверенный локальный .fs";
    btn.append(swatch, mark, title, version, sub, state);
    btn.addEventListener("click", () => selectProfile(p.id));
    area.append(btn);
  }
  refreshButtons();
}
function selectProfile(id) {
  if (programming || downloading) return;
  const p = profiles.find(x => x.id === id);
  if (!p) return;
  if (current && current.id !== p.id) releaseAllKeys();
  current = p;
  loaded = null;
  $("local-file").value = "";
  $("selected-game").textContent = `${p.name} ${p.version}`;
  $("selected-file").textContent = p.filename;
  $("game-description").textContent = p.description;
  $("expected-sha").textContent = p.sha256.toUpperCase();
  $("actual-sha").textContent = "Файл не выбран";
  $("release-link").href = p.release_url;
  $("source-link").href = p.source_url;
  $("controls-description").textContent = p.controller_notes;
  const published = remoteReady(p);
  const r = $("remote-status");
  r.textContent = published ? "GitHub READY" : "LOCAL .fs";
  r.className = `status-pill ${published ? "ready" : "local"}`;
  status("verification-status", `Выбрана ${p.name}. Нужен файл SHA-256 ${p.sha256.slice(0, 12).toUpperCase()}…`);
  status("program-status", "Ожидается проверенная прошивка и разрешение на JTAG.");
  renderCards();
  log(`PROFILE ${p.id} (${p.filename}); source=${published ? "github" : "local-only"}`);
}
async function loadVerified(buffer, name, source, profileId) {
  const p = profiles.find(x => x.id === profileId);
  if (!p || current?.id !== profileId) throw Error("Профиль изменён — выберите файл повторно.");
  if (!name.toLowerCase().endsWith(".fs")) throw Error("Допустим только Gowin .fs.");
  if (buffer.byteLength !== p.size_bytes) throw Error(`Размер .fs неверен: ${buffer.byteLength}; требуется ${p.size_bytes} байт.`);
  if (!crypto.subtle || !window.isSecureContext) throw Error("SHA-256 требует HTTPS.");
  const digest = hex(await crypto.subtle.digest("SHA-256", buffer));
  $("actual-sha").textContent = digest.toUpperCase();
  if (digest !== p.sha256) {
    loaded = null;
    refreshButtons();
    throw Error(`SHA-256 FAIL: выбранный файл не совпадает с профилем ${p.name}. Программирование запрещено.`);
  }
  loaded = {bytes: new Uint8Array(buffer), sha256: digest, profileId};
  status("verification-status", `SHA-256 PASS · ${p.name} · ${p.size_bytes.toLocaleString("ru-RU")} байт · источник: ${source}`, "ok");
  status("program-status", "Хеш прошивки подтверждён. Выберите JTAG Debugger, затем SRAM.");
  log(`SHA256_PASS ${p.filename} ${digest} source=${source}`);
  refreshButtons();
}
async function loadFromGithub() {
  if (!current || !remoteReady(current) || downloading) return;
  const p = current;
  downloading = true;
  refreshButtons();
  status("verification-status", `Загрузка ${p.filename} с GitHub Pages…`);
  try {
    const res = await fetch(`./firmware/${p.filename}`, {cache: "no-store"});
    if (!res.ok) throw Error(`HTTP ${res.status}`);
    const data = await res.arrayBuffer();
    await loadVerified(data, p.filename, "GitHub Pages", p.id);
  } catch (e) {
    loaded = null;
    status("verification-status", `GitHub .fs: ${e.message}. Можно загрузить точный локальный файл.`, "error");
    log(`GITHUB_ERROR ${p.id}: ${e.message}`);
  } finally { downloading = false; refreshButtons(); }
}
async function loadLocal() {
  const file = $("local-file").files?.[0];
  if (!file || !current || downloading || programming) return;
  const profileId = current.id;
  downloading = true;
  refreshButtons();
  try {
    await loadVerified(await file.arrayBuffer(), file.name, "local", profileId);
  } catch (e) {
    loaded = null;
    status("verification-status", `Локальный .fs: ${e.message}`, "error");
    log(`LOCAL_ERROR ${profileId}: ${e.message}`);
  } finally { downloading = false; refreshButtons(); }
}
async function connectJtag() {
  if (!navigator.usb) {
    status("program-status", "WebUSB недоступен. Используйте Chrome/Edge через HTTPS.", "error"); return;
  }
  try {
    const d = await navigator.usb.requestDevice({filters: BOARD_USB});
    jtag = d;
    indicator("jtag-status", "Выбрано FT2232 ✓", "pass");
    $("device-description").textContent = `Выбрано: ${d.productName || "FT2232"} · VID 0403 / PID 6010. USB-разрешение есть; JTAG будет проверен программатором.`;
    log(`JTAG device selected: ${d.productName || "FT2232"}. No programming yet.`);
    status("program-status", "JTAG-устройство выбрано. Выберите точный .fs и запускайте SRAM.");
  } catch (e) {
    jtag = null;
    indicator("jtag-status", "Не подключён", "fail");
    status("program-status", `Выбор JTAG отменён: ${e.message}`, "error");
    log(`JTAG_SELECT_FAIL: ${e.message}`);
  }
  refreshButtons();
}
function logBytes(chunk, channel) {
  if (chunk == null) return;
  const message = typeof chunk === "string" ? chunk : decoder.decode(chunk);
  if (message.trim()) log(`[${channel}] ${message.trimEnd()}`);
}
async function program() {
  if (programming || downloading || !loaded || !jtag || !current || loaded.profileId !== current.id) return;
  if (!navigator.usb || !window.crossOriginIsolated) {
    status("program-status", "WebUSB/WASM изоляция не готова. На GitHub Pages обновите страницу после установки сервис-воркера.", "error"); return;
  }
  programming = true;
  releaseAllKeys();
  refreshButtons();
  const p = current;
  const start = performance.now();
  status("program-status", `Программирование SRAM: ${p.name}. Не отключайте USB.`);
  log(`SRAM_START ${p.id} sha256=${loaded.sha256} args=${FIXED_PROGRAM_ARGS.join(" ")}`);
  try {
    if (!loader) {
      log("Loading pinned same-origin WebUSB/WASM runtime…");
      const module = await import("./vendor/bundle.js");
      if (typeof module.runOpenFPGALoader !== "function") throw Error("YoWASP runtime does not export runOpenFPGALoader");
      loader = module.runOpenFPGALoader;
    }
    await loader([...FIXED_PROGRAM_ARGS], {"game.fs": loaded.bytes}, {
      stdout: data => logBytes(data, "stdout"),
      stderr: data => logBytes(data, "stderr")
    });
    indicator("jtag-status", "SRAM записана ✓", "pass");
    status("program-status", `openFPGALoader EXIT 0 · ${p.name}. Проверьте реальную игру на HDMI.`, "ok");
    log(`SRAM_EXIT_0 elapsed_ms=${Math.round(performance.now() - start)} game=${p.id}`);
  } catch (e) {
    status("program-status", `Ошибка JTAG/программатора: ${e.message}. Проверьте журнал и драйвер WinUSB A.`, "error");
    log(`SRAM_ERROR: ${e.message}`);
  } finally { programming = false; refreshButtons(); }
}
function keyProtocol(key) {
  if (!current) return null;
  const k = key.toLowerCase();
  if (current.id === "pong") {
    if (["w", "s", "i", "k"].includes(k)) return {down:k, up:k.toUpperCase(), action:`pong-${k}`};
    if (["a", "r", "1", "2", "3", "4", "5", "6", "7"].includes(k)) return {once:k};
    return null;
  }
  if (current.id === "breakout") {
    if (key === "ArrowLeft" || k === "a") return {down:"w",up:"W",action:"left"};
    if (key === "ArrowRight" || k === "d") return {down:"s",up:"S",action:"right"};
    if (["p", "r", "1", "2", "3", "4", " ", "enter"].includes(k)) return {once:k === "enter" || k === " " ? "p" : k};
    return null;
  }
  if (current.id === "spacepatrol") {
    if (key === "ArrowLeft" || k === "a") return {down:"a",up:"A",action:"left"};
    if (key === "ArrowRight" || k === "d") return {down:"d",up:"D",action:"right"};
    if (k === "f" || k === " ") return {down:"f",up:"F",action:"fire"};
    if (["p","r","1","2","3","4","enter"].includes(k)) return {once:k === "enter" ? "p" : k};
    return null;
  }
  if (current.id === "lightcycles") {
    if (["w", "a", "s", "d", "i", "j", "k", "l", "p", "r", "t", "1", "2", "3", "4", " ", "enter"].includes(k)) return {once:k === "enter" || k === " " ? "p" : k};
    if (key === "ArrowUp") return {once:"w"};
    if (key === "ArrowLeft") return {once:"a"};
    if (key === "ArrowDown") return {once:"s"};
    if (key === "ArrowRight") return {once:"d"};
    return null;
  }
  if (current.id === "kblocks") {
    if (key === "ArrowLeft" || k === "a") return {down:"a",up:"A",action:"left"};
    if (key === "ArrowRight" || k === "d") return {down:"d",up:"D",action:"right"};
    if (key === "ArrowDown" || k === "s") return {down:"s",up:"S",action:"down"};
    if (key === "ArrowUp" || k === "w") return {once:"w"};
    if (["p", "r", "1", "2", "3", "4", " ", "enter"].includes(k)) return {once:k === "enter" || k === " " ? "p" : k};
    return null;
  }
  return null;
}
function sendChar(c) {
  if (!serial || !serial.writable) return Promise.resolve();
  const payload = encoder.encode(c);
  serialQueue = serialQueue.catch(() => {}).then(async () => {
    if (!serial || !serial.writable) return;
    const writer = serial.writable.getWriter();
    try { await writer.write(payload); }
    finally { writer.releaseLock(); }
  }).catch(e => { log(`UART_WRITE_ERROR: ${e.message}`); });
  return serialQueue;
}
function releaseAllKeys() {
  if (!held.size) return;
  held.clear();
  void sendChar("x");
}
function handleKeyDown(e) {
  if (!serial || e.repeat) return;
  const mapping = keyProtocol(e.key);
  if (!mapping) return;
  e.preventDefault();
  if (mapping.once) { void sendChar(mapping.once); return; }
  const key = e.key.toLowerCase();
  if (held.has(key)) return;
  if (![...held.values()].some(v => v.action === mapping.action)) void sendChar(mapping.down);
  held.set(key, mapping);
}
function handleKeyUp(e) {
  if (!serial) return;
  const key = e.key.toLowerCase();
  const binding = held.get(key);
  if (!binding) return;
  e.preventDefault();
  held.delete(key);
  if (![...held.values()].some(v => v.action === binding.action)) void sendChar(binding.up);
}
async function connectSerial() {
  if (!navigator.serial) { log("Web Serial недоступен: нужен Chrome/Edge через HTTPS."); return; }
  try {
    const p = await navigator.serial.requestPort();
    await p.open({baudRate:115200, dataBits:8, stopBits:1, parity:"none",flowControl:"none"});
    serial = p;
    indicator("serial-status", "UART 115200 ✓", "pass");
    log("UART connected to selected FT2232 channel B, 115200 8N1");
    refreshButtons();
    $("gamepad").focus();
  } catch (e) {
    serial = null;
    indicator("serial-status", "Не подключён", "fail");
    log(`UART_CONNECT_FAIL: ${e.message}`);
    refreshButtons();
  }
}
async function disconnectSerial() {
  if (!serial) return;
  releaseAllKeys();
  await serialQueue.catch(() => {});
  const p = serial;
  serial = null;
  try { await p.close(); } catch (e) { log(`UART_CLOSE_ERROR: ${e.message}`); }
  indicator("serial-status", "Не подключён");
  log("UART disconnected");
  refreshButtons();
}
function saveLog() {
  const blob = new Blob([$("log").textContent], {type:"text/plain;charset=utf-8"});
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `konsol-retrostation-${new Date().toISOString().slice(0,10)}.txt`;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1500);
}
async function start() {
  $("download-button").addEventListener("click", loadFromGithub);
  $("local-button").addEventListener("click", () => $("local-file").click());
  $("local-file").addEventListener("change", loadLocal);
  $("connect-jtag").addEventListener("click", connectJtag);
  $("program-button").addEventListener("click", program);
  $("connect-serial").addEventListener("click", connectSerial);
  $("disconnect-serial").addEventListener("click", disconnectSerial);
  $("gamepad").addEventListener("keydown", handleKeyDown);
  window.addEventListener("keyup", handleKeyUp);
  $("gamepad").addEventListener("blur", releaseAllKeys);
  window.addEventListener("blur", releaseAllKeys);
  document.addEventListener("visibilitychange", () => { if (document.hidden) releaseAllKeys(); });
  $("clear-log").addEventListener("click", () => { $("log").textContent = ""; });
  $("download-log").addEventListener("click", saveLog);
  document.querySelectorAll(".quick-cmd").forEach(b => b.addEventListener("click", () => {
    if (serial && current && !(current.id === "pong" && b.dataset.command === "p")) void sendChar(b.dataset.command);
    $("gamepad").focus();
  }));
  navigator.usb?.addEventListener("disconnect", e => {
    if (e.device === jtag) {
      jtag = null;
      indicator("jtag-status", "Отключён", "fail");
      status("program-status", "JTAG отключён.", "error");
      refreshButtons();
      log("JTAG DISCONNECT");
    }
  });
  navigator.serial?.addEventListener("disconnect", e => {
    if (e.target === serial || e.port === serial) {
      held.clear();
      serial = null;
      indicator("serial-status", "Отключён", "fail");
      refreshButtons();
      log("UART DISCONNECT");
    }
  });
  const usbReady = window.isSecureContext && "usb" in navigator;
  indicator("usb-status", usbReady ? "Доступен ✓" : "Недоступен", usbReady ? "pass" : "fail");
  indicator("isolation-status", window.crossOriginIsolated ? "Готово ✓" : "Ожидание COOP/COEP", window.crossOriginIsolated ? "pass" : "fail");
  log(`BROWSER WebUSB=${usbReady} crossOriginIsolated=${window.crossOriginIsolated} WebSerial=${!!navigator.serial}`);
  if (usbReady && !window.crossOriginIsolated) log("GitHub Pages may reload once after coi-serviceworker registration.");
  try {
    const response = await fetch("./profiles.json", {cache:"no-store"});
    if (!response.ok) throw Error(`Profiles HTTP ${response.status}`);
    const data = await response.json();
    if (data.schema_version !== 1 || !Array.isArray(data.profiles) || data.profiles.length !== 5 ||
        !data.profiles.every(validateProfile) || new Set(data.profiles.map(p => p.id)).size !== 5) {
      throw Error("Неверный список прошивок или SHA-256");
    }
    profiles = data.profiles;
    try {
      const response2 = await fetch("./firmware/manifest.json", {cache:"no-store"});
      if (!response2.ok) throw Error(`manifest HTTP ${response2.status}`);
      const manifest = await response2.json();
      if (manifest.schema_version !== 1) throw Error("manifest schema mismatch");
      availability = new Map(manifest.profiles.map(p => [p.id, p]));
      log("GitHub Pages manifest loaded; exact release availability follows SHA-256 and size checks.");
    } catch(e) { log(`GITHUB_MANIFEST_UNAVAILABLE: ${e.message}. Local .fs remains supported.`); }
    selectProfile("kblocks");
  } catch(e) {
    $("game-grid").textContent = "Каталог игр недоступен: " + e.message;
    log(`CONSOLE_PROFILE_ERROR: ${e.message}`);
    status("verification-status", e.message, "error");
  }
  refreshButtons();
}
void start();
