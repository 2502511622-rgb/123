# 青苔牧场 / Mossfield

主工程是 `godot/`，使用环境内已有的 **Godot 4.6.3**。这是从零搭建的原创牧场游戏原型。

## 开发和运行

```sh
cd /workspace/123
./scripts/godot.sh --editor
# 直接运行
./scripts/godot.sh
# 首次导入和无窗口验证
./scripts/godot.sh --headless --editor --import --quit
./scripts/godot.sh --headless --script res://tests/test_farm.gd
```

点击田块劳作，1–4 切换翻土、播种、浇水、收获。每日浇水后睡觉推动生长，3 次生长可收获。种子商店、出货和体力构成基础循环。操作自动保存到 Godot 的 `user://farm-save.json`。游戏无需服务端或密钥。

## 架构

- `godot/scenes/main.tscn`：入口场景。
- `godot/scripts/main.gd`：界面、输入与地图表现。
- `godot/scripts/farm_state.gd`：独立于场景的种植、日期、体力和经济规则。
- `godot/scripts/save_store.gd`：版本化 JSON 本地存档。
- `godot/tests/test_farm.gd`：完整种植循环和存档校验。

下一阶段可加入 CharacterBody2D 移动、TileMapLayer 地图、数据驱动的多品种作物、NPC 对话、动物与季节。当前使用代码绘制的占位图形，没有使用《牧场物语》的素材。

根目录还保留早期 Vite 网页原型，可 `npm ci && npm run dev` 运行；它不是 Godot 主工程，也不共享存档。

云环境请通过 `scripts/godot.sh` 启动：它将 Godot 数据、配置和缓存放在可写的 `/workspace/.runtime/`，避免默认用户目录的写入限制。
