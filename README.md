# 青苔牧场 / Mossfield v0.2

一个 **Godot 4.6 的俯视角 2D 像素种田游戏原型**。角色可在农场与河畔小镇自由行走，靠近田块翻土、播种、浇水、收获；通过杂货铺、出货箱和小禾的委托构成可玩的日常循环。

![游戏实机画面](docs/gameplay.png)

上图使用成熟作物展示场景；新游戏从空田开始。

## 下载并运行（Windows / macOS / Linux）

1. 下载仓库根目录 `mossfield-godot.zip` 并解压。
2. 使用 Godot 4.6 标准版（无需 .NET），点击 **导入**。
3. 选择解压后的 `mossfield/godot/project.godot`，点击 **导入并编辑**。
4. 等待资源导入完毕，按 **F5** 开始游戏。

没有 Godot 时可从 [Godot 官网](https://godotengine.org/download/) 下载。压缩包是源码工程，需要 Godot，不是独立 EXE。已嵌入中文字体和全部像素美术，运行不依赖网络或第三方插件。

## 操作

| 操作 | 按键 |
| --- | --- |
| 移动 | WASD / 方向键 |
| 使用面对的田块 | 空格 |
| 使用近处指定田块 | 鼠标左键 |
| 选择锄头 / 种子 / 水壶 / 收获 | 1 / 2 / 3 / 4，或点击工具栏 |
| 切换萝卜 / 胡萝卜 / 番茄种子 | Q，或点击左下角种子按钮 |
| 小屋休息、商店购物、出货、NPC 聊天 | 走近相应地点，按 E |
| 查看背包 | I |
| 暂停 / 关闭菜单 | Esc |

农田入口在左侧栅栏的中间缺口。河流不能直接穿过，请走木桥。小屋门口休息会进入下一天，恢复体力；22:00 自动回家休息。菜单打开时时间与移动暂停。

## 玩法

- 48 块可耕田、三种数据驱动作物：萝卜 3 天、胡萝卜 4 天、番茄 5 天。
- 作物只在浇过水的那天结束时生长；每第 4 天为雨天，自动浇水。
- 翻土、播种、浇水消耗 5 体力；体力不足后仍可以收获、出货与睡觉。
- 买种子、出售作物，并完成“小禾：收获 3 颗作物”的一次性 100 G 奖励。
- 四方向行走动画、镜头跟随、深度排序、房屋 / 河流 / 栅栏碰撞、昼夜光照与雨滴。
- 小鸡是环境装饰，尚未实现养殖；房屋使用门口交互，尚无室内地图。

## 存档

自动存档：劳作和交易后、每 15 秒、睡觉后与正常关窗时保存。也可在暂停菜单手动保存。存储在 Godot 的 `user://farm-save.json`，不写入源码目录。v0.1 的 24 田块存档可自动迁移到 v0.2 的 48 田块。

JSON 数据经过范围、类型和作物标识检查；写入采用临时文件后替换，降低半写入风险。损坏存档不会导致崩溃，界面会提示从新农场开始。

## 架构

```text
godot/
  scenes/main.tscn        游戏入口
  scripts/main.gd        场景编排、输入、HUD、菜单
  scripts/player.gd      CharacterBody2D、移动、碰撞、像素动画、镜头
  scripts/world.gd       地图、物件、碰撞、近距离交互、特效
  scripts/farm_state.gd  游戏规则、经济、天气、任务、存档迁移
  scripts/crop_spec.gd   CropSpec 资源定义
  scripts/save_store.gd  原子文件保存与恢复
  scripts/atmosphere.gd  昼夜与雨滴
  scripts/chicken.gd     小鸡装饰动画
  resources/crops/       三种作物 .tres
  assets/                原创像素图和嵌入式中文字体
  licenses/              第三方代码与字体许可
  tests/                 规则、实际场景与截图验证
```

模板检索、选型、固定源码版本和许可说明见 [docs/TEMPLATE_RESEARCH.md](docs/TEMPLATE_RESEARCH.md)。后续可以扩展季节、多地图、动物、钓鱼、矿洞和 NPC 好感度；目前实现的是核心垂直切片。

## 开发与验证

```sh
# Linux 云环境：使用可写的数据、缓存和配置目录
cd /workspace/123
./scripts/godot.sh --editor
./scripts/godot.sh

# 独立测试存档，不影响游戏进度；检查 Godot 的错误输出及退出码
python scripts/test_game.py
```

规则测试包含三种作物完整循环、雨天、经济、体力、任务、防损坏存档和旧版迁移；场景测试实际模拟移动、河流碰撞、桥梁通行、操作距离、菜单暂停和地点交互。

`./scripts/godot.sh` 默认使用仓库父目录的 `.runtime/`，可用 `MOSSFIELD_RUNTIME_DIR` 覆盖。直接通过 Godot 编辑器运行时，使用系统标准的 Godot 存档目录。

根目录 `src/` 为保留的早期 Vite 网页原型（`npm ci && npm run dev`），不属于 Godot 主工程，存档也互不共享。

可选：重新生成原创美术需 Python + Pillow，执行 `python scripts/generate_art.py`。游戏运行不需要 Python 或 Pillow。

若 Linux 解压工具未保留执行权限，可用 `sh scripts/godot.sh --editor` 启动；测试脚本也兼容这种情况。
