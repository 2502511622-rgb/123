export const CROPS = { turnip: { name: '小萝卜', days: 3, price: 35, seed: 8, color: '#f7dad5' } };
export function createState() { return { version: 1, day: 1, money: 120, energy: 100, seeds: 8, harvest: 0, plots: Array.from({ length: 24 }, () => ({ tilled: false, crop: null, growth: 0, watered: false })) }; }
export function act(state, index, tool) {
 const p = state.plots[index]; if (!p) return '请走进田地再试试。';
 if (tool === 'harvest') { if (!p.crop || p.growth < CROPS[p.crop].days) return '作物还没成熟，记得每天浇水。'; state.harvest++; Object.assign(p, { crop: null, growth: 0, watered: false }); return '收获了一颗小萝卜！'; }
 if (state.energy < 5) return '体力不足了，回小屋休息吧。';
 if (tool === 'hoe') { if (p.tilled || p.crop) return '这块土地已经翻好了。'; p.tilled = true; }
 else if (tool === 'seed') { if (!p.tilled || p.crop) return '先翻土，再在空地上播种。'; if (!state.seeds) return '种子用完了，可以在商店购买。'; state.seeds--; p.crop = 'turnip'; }
 else if (tool === 'water') { if (!p.crop) return '这里还没有作物。'; if (p.watered) return '今天已经浇过水啦。'; p.watered = true; }
 else return '请选择一个工具。';
 state.energy -= 5; return ({ hoe: '松软的土地，准备好了。', seed: '播下种子，期待新的生命。', water: '浇水完成，作物会在明天生长。' })[tool];
}
export function nextDay(state) { state.day++; state.energy = 100; for (const p of state.plots) { if (p.crop && p.watered) p.growth = Math.min(CROPS[p.crop].days, p.growth + 1); p.watered = false; } }
export function buySeeds(state) { if (state.money < 40) return '金币不足，需要 40 G。'; state.money -= 40; state.seeds += 5; return '购买了 5 包小萝卜种子。'; }
export function sell(state) { if (!state.harvest) return '背包里还没有可出售的萝卜。'; const earned = state.harvest * 35; state.money += earned; state.harvest = 0; return `出货完成，获得 ${earned} G！`; }
