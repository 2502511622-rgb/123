# v0.22 开源研究与素材来源

本轮通过 Git 读取以下仓库的实际源码与授权文件。普通网页访问受代理限制，未将搜索摘要作为源码依据，也没有运行所有参考项目。研究的是可借鉴的结构，不能据此认定它们代表全部优秀 ARPG。

| 项目与固定提交 | 读取内容 | 本项目采用的思路 |
|---|---|---|
| [HeartBeast Action RPG](https://github.com/uheartbeast/youtube-tutorials/tree/87eba5bf8f7796029c39033b107b064e2969bbad/Action%20RPG) · MIT | Player、Bat、SoftCollision、Hurtbox、Camera2D | 移动、攻击、受击职责分离；将动作阶段与碰撞反馈联动。Godot 3 教程，未直接移植整套工程。 |
| [Flare](https://github.com/flareteam/flare-engine/tree/1969baeb89ebf94cf22e2bc2ed4e3d8413714d4f) · GPL-3.0-or-later | Entity、EntityBehavior、PowerManager | 研究战斗状态、施法延迟与数据化技能。本项目仅参考概念，没有复制其 GPL 源码。 |
| [GDQuest OpenRPG](https://github.com/GDQuest/godot-open-rpg/tree/d59f2f71bc046ac53239a4e590861269e7100a36) · MIT | Inventory、FieldCamera、AreaTransition、宝箱交互、CREDITS | 资源与界面通知、地图边界、交互事务。它是回合制项目，参考结构；其声明的 Godot 版本高于本项目，未宣称在本机运行通过。 |
| [Godot 官方演示](https://github.com/godotengine/godot-demo-projects/tree/b761b4cd5718a7118f2c95eb55f181d0a5f004f1) · MIT | 2d/navigation_astar/pathfind_astar.gd | 参考格网边界、阻挡与对角移动约束；随从改为复用本游戏现有寻路缓存。 |

## 美术与音效

研究 OpenRPG 收录的 Kenney Tiny Town、Tiny Dungeon 像素包，查看实际图集和上游 CREDITS。地面与城镇图集用于分析尺寸、轮廓与明暗，没有直接替换为这些城镇素材。

实际收录的 Kenney CC0 文件仅为交互感叹号、两个木质打击音与确认音。位于 `godot/assets/third_party/kenney/`，`manifest.json` 记录上游提交、SHA-256 与许可；完整来源和上游署名见 [Kenney-CC0-SOURCES.md](../godot/licenses/Kenney-CC0-SOURCES.md)。打击音接入实际命中反馈，确认音为备用素材。本轮同时保存参考项目的 MIT 许可文本。

本轮新生成并集成九张原创图集：男女主角四向八帧行走、双预设六阶段攻击、怪物集合、NPC、大天狗、场景物件、地面、武器。素材经过自动图集索引、最近邻归一与怪物分层烘焙；39 个怪物姿态的分层重组逐像素校验通过。

《八方旅人》仅作为像素比例、景深、布景与光色的视觉方向。没有使用其商业贴图、角色、源码或音效，也没有声称获得其授权。新资源属于生成素材，不冒充手工像素画或第三方付费美术包。

## 对应实现

- `strike_timeline.gd`：集中定义轻重击时长、命中点与六阶段姿态；重击有更长蓄力和收招。
- `aim_resolver.gd`：将屏幕事件转换到世界坐标，统一瞄准与出手方向。
- `region_style.gd`：十个区域的地面、石材、雾光与植被配置。
- `wall_face.gd`：佛寺实体墙的立面按脚底位置参与角色层深度排序。
- `region_composition.gd`：佛寺台阶、岛国码头、剧场木台与墓地场景层次。
- 随从复用怪物关节表现和按体积分类的寻路缓存，避免每个随从建立整张导航网格。
