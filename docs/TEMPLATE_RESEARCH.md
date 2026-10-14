# 模板检索与选型

检索方式：GitHub repository search `godot farming game`，随后下载下列三个仓库，阅读项目配置、README、许可与相关脚本。GitHub API 和 Kenney 官网受到当前网络域名策略限制；没有将不可访问网页作为已验证资料。

| 项目 | 实际检查的内容 | 在本项目中的用途 |
| --- | --- | --- |
| [Harvest Moon 2.0](https://github.com/Kenny-Haworth/Harvest-Moon-2.0) | README 说明种植、商店、出货、睡觉、时间、天气和体力；Godot 3 项目；根目录 MIT | 借鉴每日劳作、睡觉推进和雨天浇水的玩法结构，不复制项目和素材 |
| [Seasons Gone](https://github.com/elliotfontaine/untitled-farming-sim) | Godot 4.1；根目录 MIT；强调氮循环和轮作 | 参考作物按阶段表示及地图组织思路，不引入其系统或美术 |
| [Farmworld 教程](https://github.com/gadget-hq/2d-farming-game) | Godot 4.4；代码 MIT；`Scripts/player_controller.gd` 和 `crop_resource.gd`；README 对 Sprout Lands、Kenney 美术单独署名 | 下载模板后改写 CharacterBody2D 移动控制器，改为物理帧、四方向像素动画、地图碰撞和菜单暂停；保留 MIT 许可 |

检查时的源码版本：

- Harvest Moon 2.0：`8d9ccc4e49ad86b22eb38a9e00ddfa60150cd00c`
- Seasons Gone：`c509cab1614eab245e5bc7a4c27034cfa318f7e8`
- Farmworld：`13d602e259fde7fdebaefae132121ecf7e5eae2d`

## 选择

保留青苔牧场既有的种植规则与可迁移存档，接入改写的 Farmworld 玩家控制模式。整包替换旧模板会丢失原工程和存档，因此只采用需要的模块。Godot 3 模板升级工作与完整模拟氮循环都超出当前垂直切片目标。

本次借鉴类《星露谷物语》的俯视角、四方向移动、近距离田块工具、时间和体力管理、种子经济、NPC 小委托。未复制其角色、音乐、地图、素材或剧情。

## 美术与字体

- PNG 图块、角色、房屋、树木、工具、作物均为本项目原创程序化像素美术，生成源为 `scripts/generate_art.py`，没有引入 Sprout Lands 的美术。
- 中文字体为 Noto Sans CJK SC 的字符子集，SIL Open Font License；署名与许可见 `godot/licenses/Noto-CJK-copyright.txt`。子集使用独立文件名 `mossfield-font.ttf`。
- 改写的玩家控制器许可见 `godot/licenses/Farmworld-MIT.txt`。

## 《阴田录》版本

本版沿用已验证的 Godot 工程、改写后的 MIT 玩家移动模块与原创美术生成流程，重新设计四种阴植、遗骸、役灵与即时战斗。没有再次导入其他游戏的角色、场景、音轨或专有素材。原模板许可仍完整保留。

## 用户指定的全程序参考（v0.4）

后续已按 [JevonLee/Stardew](https://github.com/JevonLee/Stardew) 的模块组织独立重构，实际版本 `f238436b44c1a433f4d9e27c5d073637607c9107`。完整对应与许可范围见 [STARDEW_REFERENCE.md](STARDEW_REFERENCE.md)。
