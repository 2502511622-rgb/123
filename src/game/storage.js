import { createState } from './state.js';
const KEY = 'mossfield-save-v1';
export function load() { try { const s = JSON.parse(localStorage.getItem(KEY)); if (s?.version === 1 && Array.isArray(s.plots) && s.plots.length === 24 && [s.day,s.money,s.energy,s.seeds,s.harvest].every(Number.isFinite) && s.plots.every(p => p && typeof p.tilled === 'boolean' && (p.crop === null || p.crop === 'turnip') && Number.isFinite(p.growth) && typeof p.watered === 'boolean')) return s; } catch {} return createState(); }
export function save(state) { try { localStorage.setItem(KEY, JSON.stringify(state)); return true; } catch { return false; } }
