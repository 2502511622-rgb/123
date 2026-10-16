# 地域布景素材 v0.26

source.png 为生成原稿，12 张独立 PNG 为 Godot 归一化后的游戏素材。采用透明背景、最近邻像素采样和统一的俯视角。

尺寸、名称见 `scripts/art/biome_art.gd`。脚点在每张画布的底部中央。完整复现可运行 `tools/bake_biome_art.gd`。

建筑碰撞与军事通道在 `scripts/continent/continent_world.gd` 单独定义；材质天气由 `shaders/biome_surface.gdshader` 提供。枯松使用共享风动树木材质。
