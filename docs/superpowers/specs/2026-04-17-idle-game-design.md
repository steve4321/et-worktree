# 纯挂机网络游戏 — 设计规格说明

## 项目概述

| 维度 | 决策 |
|------|------|
| 引擎 | Unity 2022 LTS |
| 框架 | ET 8.x (.NET 8) |
| 渲染 | 2D + Spine/龙骨动画 |
| 网络架构 | 经典 C/S，服务端权威 |
| 数据库 | MongoDB |
| 战斗模式 | 纯自动战斗，玩家负责搭配策略 |
| 美术资源 | Asset Store 购买/免费素材 |
| 目标平台 | 移动端 (iOS/Android) |
| 热更新 | HybridCLR（C# 热更） |
| 开发模式 | 单人 + git worktree 并行开发 |

## 核心玩法

- **技能搭配**：4 主动 + 4 被动技能槽，自由组合构建 Build
- **装备搭配**：6 部位装备，品质/词条/套装深度组合
- **推图打 Boss**：章-关-Boss 结构，挂机收益驱动

## 辅助玩法

- **时装**：商城成套售卖，购买即激活属性 + 解锁幻化外观
- **宝物**：收集类，提供全局被动加成，图鉴组合奖励
- **宠物**：收集类，战斗被动效果 + 视觉跟随

---

## 模块划分与 Worktree 策略

| 分组 | 包含模块 | worktree |
|------|---------|----------|
| Core | 基础框架、事件接口、属性系统、通用工具 | 主分支 |
| Combat | Battle + Skill + Stage | worktree-combat |
| Equipment | 装备系统、属性加成 | worktree-equip |
| Collection | Fashion + Treasure + Pet | worktree-collection |

模块间通过 ET 8 EventSystem 通信。所有玩法模块在同一个热更 Assembly（Game.Hotfix）中，通过文件夹和命名空间做逻辑隔离。

---

## 1. Core 基础层

### 1.1 程序集结构（基于 ET 8 四程序集体系）

ET 8 原生使用 Model/Hotfix/ModelView/HotfixView 四程序集体系，游戏代码嵌入其中。

```
Unity/Assets/Scripts/
├── Core/                           # ET 8 框架核心（不修改）
├── Model/                          # Unity.Model 程序集（纯数据定义）
│   ├── Client/Module/              # 客户端数据定义
│   │   ├── Numeric/                #   命名空间: ET.Client
│   │   │   └── NumericComponent.cs       属性组件（数据）
│   │   ├── Battle/
│   │   │   └── BattleComponent.cs        战斗组件（数据）
│   │   ├── Skill/
│   │   │   └── SkillComponent.cs         技能组件（数据）
│   │   ├── Stage/
│   │   ├── Equipment/
│   │   ├── Fashion/
│   │   ├── Treasure/
│   │   └── Pet/
│   ├── Server/Module/              # 服务端数据定义
│   └── Share/Module/               # 客户端服务端共享
│       └── Numeric/
│           └── NumericType.cs            属性类型枚举
├── Hotfix/                         # Unity.Hotfix 程序集（逻辑实现）
│   ├── Client/Module/
│   │   ├── Numeric/
│   │   │   └── NumericComponentSystem.cs 属性系统（逻辑）
│   │   ├── Battle/
│   │   ├── Skill/
│   │   ├── Stage/
│   │   ├── Equipment/
│   │   ├── Fashion/
│   │   ├── Treasure/
│   │   ├── Pet/
│   │   └── UI/
│   ├── Server/Module/
│   └── Share/Module/
├── ModelView/Client/Module/        # Unity.ModelView（Unity 绑定数据）
└── HotfixView/Client/Module/       # Unity.HotfixView（表现逻辑）

DotNet/                             # 独立服务端
├── App/
├── Model/                          # 引用 Unity.Model
├── Hotfix/                         # 引用 Unity.Hotfix
└── Config/Luban/                   # Luban 配置定义
```

**ET 8 四程序集与热更新关系：**

| 程序集 | 内容 | 依赖 Unity API | 热更方式 |
|--------|------|---------------|---------|
| Unity.Model | 组件数据定义 | 否 | HybridCLR 热更 dll |
| Unity.Hotfix | 逻辑实现 | 否 | HybridCLR 热更 dll |
| Unity.ModelView | Unity 绑定数据 | 是 | HybridCLR 热更 dll |
| Unity.HotfixView | 表现逻辑（UI/动画） | 是 | HybridCLR 热更 dll |

**命名空间规则：**
- 遵循 ET 8 约定：客户端用 `ET.Client`，服务端用 `ET.Server`，共享用 `ET`
- 模块通过文件夹路径区分，命名空间保持 ET 原生风格
- 模块间通过事件通信，不直接调用其他模块的内部类

**ET 8 代码模式三件套：**
1. Model 层定义 Component（纯数据，继承 Entity，标记 [ComponentOf]）
2. Hotfix 层编写 System（扩展方法，标记 [EntitySystemOf]）
3. 事件处理使用 AEvent<T> 基类

### 1.2 事件总线

利用 ET 8 原生 EventSystem，事件结构体定义在 Core（AOT）中，各模块在 Game.Hotfix 内订阅。

关键事件定义：

```
UnitSpawnedEvent    → 角色创建时触发，各模块注入初始属性
EquipChangedEvent   → 装备变更时触发，更新属性修饰
BattleEndEvent      → 战斗结束时触发，驱动掉落和进度
CollectibleActivatedEvent → 收集品激活时触发，注入属性
```

### 1.3 属性系统 (NumericSystem)

统一的数值管理系统，所有模块通过它注入属性加成。

```
NumericType 枚举: HP, MaxHP, ATK, DEF, Speed, CritRate, CritDmg, ...
属性修饰来源: 装备、技能 Buff、宝物被动、宠物加成、时装套装
计算公式: 最终值 = (基础值 + Σ(绝对值加成)) * (1 + Σ(百分比加成))
```

每个修饰带有来源标识（SourceTag），便于同一来源的属性替换（如换装备时移除旧加成再添加新加成）。

### 1.4 配置表系统 (Luban)

基于 Luban 管理所有游戏配置，Excel/JSON 编辑 → 自动生成 C# 代码 + bytes 数据。

**核心配置表：**

| 配置表 | 说明 | 消费方 |
|--------|------|--------|
| TbEquip | 装备定义（品质、部位、基础属性、副词条池） | Equipment |
| TbEquipSuit | 套装定义（2/4/6 件效果） | Equipment |
| TbSkill | 技能定义（类型、冷却、目标策略、效果列表） | Skill |
| TbBuff | Buff 定义（持续时间、叠加规则、属性修改） | Skill |
| TbStage | 关卡定义（怪物配置、掉落表、解锁条件） | Stage |
| TbChapter | 章节定义（关卡列表、Boss 关卡、挂机收益） | Stage |
| TbMonster | 怪物定义（属性、AI、技能列表） | Battle |
| TbTreasure | 宝物定义（品质、属性加成、图鉴组） | Treasure |
| TbPet | 宠物定义（品质、被动技能、孵化概率） | Pet |
| TbFashion | 时装定义（套装属性、外观资源路径、价格） | Fashion |
| TbDrop | 掉落表（权重、物品ID、数量范围） | Battle |
| TbNumeric | 属性类型定义（枚举 ID、名称、上限值） | Core |
| TbUI | UI 面板配置（面板名、FairyGUI 包/组件路径） | Core UI |

**Luban 工作流：**

```
策划/开发者在 Excel/JSON 中编辑配置
        ↓
Luban CLI 生成：
├── C# 代码（TbXxx 类 + 数据结构）→ 放入 Game.Hotfix/Config/
└── bytes 数据文件 → 作为 YooAsset 资源打包，支持热更
        ↓
服务端：启动时加载 bytes 到内存
客户端：通过 YooAsset 下载 → Luban 加载器读取
```

**Luban 生成代码组织（统一放在 Game.Hotfix/Config/）：**

```
Game/Hotfix/Config/
├── TbNumeric.cs, TbUI.cs       → 通用配置
├── TbSkill.cs, TbBuff.cs       → 技能配置
├── TbMonster.cs                → 怪物配置
├── TbStage.cs, TbChapter.cs, TbDrop.cs → 关卡配置
├── TbEquip.cs, TbEquipSuit.cs  → 装备配置
└── TbTreasure.cs, TbPet.cs, TbFashion.cs → 收集配置
```

**配置热更新：**

- 配置数据作为 YooAsset 资源打包，随资源版本热更
- 新增装备/技能/关卡只需更新配置表 + 资源，无需发版
- Luban 支持多表分组加载，按模块按需加载配置

### 1.5 UI 系统 (FairyGUI + 代码组装)

基于 FairyGUI 实现 UI 层，采用**原子组件模板 + 代码组装面板**的策略，最小化手动拼界面工作。

**设计原则：** FairyGUI 编辑器只拼原子组件和面板框架，完整面板通过代码组装生成。

**UI 模式归纳（挂机游戏的 5 种核心模式）：**

| 模式 | 举例 | 结构 |
|------|------|------|
| 属性面板 | 装备详情、角色面板 | 标题 + N 行"属性名: 数值" |
| 卡片列表 | 背包、技能列表、图鉴 | 网格列表 + 每项是图标+名字+品质框 |
| 槽位面板 | 装备穿戴、技能搭配 | N 个槽位 + 点击弹选择 |
| 标签页 | 商城、图鉴分类 | 顶栏 Tab + 内容区切换 |
| 弹窗 | 奖励、确认、提示 | 标题 + 内容 + 按钮 |

**FairyGUI 原子组件（手动拼一次，永久复用）：**

```
原子组件：
├── ItemCard       → 图标 + 品质框 + 名字 + 等级
├── StatRow        → 属性名 + 数值 + 变化箭头
├── SlotWidget     → 槽位框 + 图标 + 品质边框
├── TabBar         → 横向 Tab 按钮组
├── PopupDialog    → 通用弹窗壳（标题 + 内容区 + 按钮）
└── SectionHeader  → 分区标题栏

面板框架：
├── ListPanel      → 标题栏 + TabBar + 滚动列表区
├── DetailPanel    → 标题栏 + 左侧图 + 右侧属性列表 + 底部按钮
└── SlotPanel      → 标题栏 + N×M 槽位网格 + 底部按钮
```

**代码层面板组装：**

```csharp
// 示例：用代码组装装备详情面板
var panel = new DetailPanelBuilder()
    .SetTitle("装备详情")
    .SetLeftIcon(equip.Icon, equip.Quality)
    .AddStatRow("攻击力", equip.ATK)
    .AddStatRow("防御力", equip.DEF)
    .AddButton("装备", OnEquip)
    .Build();
```

**实际工作流：**

1. FairyGUI 编辑器：拼 6-8 个原子组件 + 3 个面板框架（一次性，1-2 天）
2. Asset Store 购买 UI 套件 → 导入 FairyGUI 资源 → 绑定到原子组件
3. 新界面：写 10-20 行组装代码 → 自动生成完整面板
4. UI 风格变更：只改原子组件模板，全局生效

**代码生成：**

- FairyGUI 导出时自动生成 C# 绑定代码（组件名 → 变量映射）
- 面板组装器 Builder 类由工具自动生成或手写（取决于复杂度）
- 数据绑定：属性系统 NumericSystem 变更 → 自动刷新关联 UI 组件

### 1.6 资源管理系统 (YooAsset)

基于 YooAsset 管理所有游戏资源，与 HybridCLR 配合实现代码+资源双热更。

**资源包（Package）划分：**

| Package | 内容 | 加载时机 | 更新策略 |
|---------|------|---------|---------|
| **BuiltinPackage** | 基础 UI 框架、通用特效、启动画面 | 随包内置 | 随版本更新 |
| **CommonPackage** | 角色 Spine 动画、通用怪物动画、技能特效 | 首次启动下载 | 增量更新 |
| **StagePackage** | 各关卡背景、Boss 特效、精英怪动画 | 进入章节时按需下载 | 按章节增量 |
| **FashionPackage** | 时装 Spine 动画、幻化外观 | 购买/解锁时下载 | 新增时装时更新 |
| **UIPackage** | 各界面贴图、图集 | 进入对应界面时加载 | 增量更新 |

**资源加载策略：**

```
游戏启动
├── YooAsset 初始化 → 加载 BuiltinPackage（内置）
├── 静默更新 CommonPackage（后台下载差异资源）
├── 预加载角色动画 + 通用技能特效（内存常驻）
└── 进入主界面

推图/打 Boss
├── 进入章节 → 检查 StagePackage 该章节资源版本
│   ├── 有更新 → 弹窗提示下载（带进度条）
│   └── 无更新 → 直接加载
├── 战斗中 → 按需加载技能特效（引用计数，战斗结束释放）
└── 退出战斗 → 释放 Stage 级别资源

时装/幻化
├── 商城浏览 → 按需加载时装预览资源
├── 购买后 → 下载 FashionPackage 对应资源（永久缓存）
└── 幻化切换 → 异步加载目标外观
```

**内存管理：**

- 使用 YooAsset 的引用计数（AssetHandle.Release()）自动管理生命周期
- 战斗场景资源战斗结束后统一释放
- Spine 动画使用 SkeletonAnimation 而非 SkeletonGraphic（减少 DrawCall）
- UI 图集按模块分组，避免加载无关界面资源
- 大图（Boss 背景、章节地图）使用异步加载 + 渐显过渡

**资源热更新流程：**

1. 编辑器中收集资源标记（AssetBundleCollector）+ 配置收集规则
2. 构建时生成资源清单（Manifest）+ 资源包（AssetBundle）
3. 上传到 CDN / OSS，记录资源版本号
4. 客户端启动时请求资源版本 → 比对 Manifest → 下载差异资源
5. 新增资源（新关卡、新时装）无需发版，通过 YooAsset 远程加载
6. 支持边玩边下载：优先下载必要资源，非必要资源后台静默下载

**YooAsset 与 HybridCLR 配合：**

- 热更 dll 作为 YooAsset 资源打包，随资源包一起热更
- 加载流程：YooAsset 下载热更 dll → HybridCLR 加载 Assembly → 执行游戏逻辑
- 同一版本管理：资源版本号和代码版本号统一，避免代码资源不匹配

### 1.7 热更新架构 (HybridCLR)

**三层热更新策略：**

| 层 | 内容 | 更新方式 |
|------|------|---------|
| **AOT 层** | Unity 引擎、ET 框架核心、HybridCLR Runtime、ET.Core | 应用商店更新（极少变更） |
| **热更代码层** | Game.Hotfix（一个 dll，包含所有游戏逻辑） | HybridCLR 热更，通过 YooAsset 下发 |
| **资源层** | Spine 动画、UI 贴图、配置表、音效 | YooAsset 远程加载 |

**Assembly 划分：**

```
AOT（不可热更）：
├── Unity.Engine                   # 引擎本身
├── Unity.Core                     # ET 8 框架核心（Entity/Fiber/Network 等）
└── Unity.Loader                   # 加载器（CodeLoader/HybridCLR 初始化）

HybridCLR 热更（4 个 dll，通过 YooAsset 下发）：
├── Unity.Model                    # 组件数据定义（含游戏模块）
├── Unity.Hotfix                   # 逻辑实现（含游戏模块）
├── Unity.ModelView                # Unity 绑定数据
└── Unity.HotfixView               # 表现逻辑
```

**热更新流程：**

1. 客户端启动 → 请求服务端获取版本号
2. 对比本地版本 → 下载差异热更 dll + 资源
3. HybridCLR 加载热更 dll → 进入游戏
4. 配置表通过 Excel 导出为 bytes，随热更资源一起下发

**关键规则：**

- ET 8 的 Model/Hotfix/ModelView/HotfixView 四个 dll 均可热更
- 遵循 ET 8 的数据-逻辑分离：Component（数据）在 Model，System（逻辑）在 Hotfix
- 新增组件只需在 Model 对应文件夹添加类，Hotfix 添加 System，均可热更
- ET 8 的 CodeLoader 自动处理热更 dll 的加载和系统扫描注册

---

## 2. Combat 组（Battle + Skill + Stage）

在 `worktree-combat` 中开发。

### 2.1 战斗引擎 (Battle)

**架构：** 服务端驱动，客户端回放。

**战斗流程：**

1. 玩家配置阵容 → 进入关卡
2. 服务端初始化战斗实体
3. 战斗循环（每 Tick，默认 10 TPS）：
   - AI 决策（自动选择目标 + 技能）
   - 技能释放 + 伤害计算
   - Buff/Debuff 持续效果处理
   - 检查胜负条件
4. 战斗结束 → 发布 BattleEndEvent → 掉落奖励

**战斗 Tick 设计：**

```csharp
public class BattleComponent : Entity
{
    public int TickRate = 10;
    public List<Unit> Allies;
    public List<Unit> Enemies;
    public int CurrentTick;
    public int MaxTick;
}
```

**速度系统：** 支持 1x / 2x / 4x，客户端加快回放速度，服务端不受影响。

**离线收益：** 服务端计算离线期间的战斗结果，客户端上线时一次性领取。

### 2.2 技能系统 (Skill)

**8 个技能槽位：**

| 槽位 | 类型 | 说明 |
|------|------|------|
| 1 | 普攻 | 固定，自动释放 |
| 2-4 | 主动技能 | 冷却轮转，自动释放，玩家负责搭配选择 |
| 5-8 | 被动技能 | 永久生效或条件触发 |

**被动技能触发类型：**

- 常驻型：持续增加属性（如 +10% 暴击率）
- 条件触发型：HP 低于阈值时触发效果
- 计数触发型：每 N 次攻击触发额外效果
- 事件触发型：击杀/受击时触发

**技能结构：**

```
Skill
├── 触发条件（被动）或 冷却时间（主动）
├── 目标选择策略（单体/群体/随机/血量最低）
├── 效果列表 SkillEffect[]
│   ├── 造成伤害（物理/魔法/真实）
│   ├── 施加 Buff/Debuff
│   ├── 治疗
│   └── 召唤
└── 技能等级 → 影响数值倍率
```

**Buff 系统：**

```csharp
public struct BuffData
{
    public int BuffId;
    public long SourceId;
    public long TargetId;
    public int RemainTick;
    public int StackCount;
    public NumericModifier[] Modifiers;
}
```

**Build 方向示例：**

- 暴击流：主动高伤技能 + 被动叠暴击率/暴击伤害
- 续航流：主动群攻 + 被动吸血/护盾
- 爆发流：主动单体高伤 + 被动增伤/破甲

### 2.3 关卡系统 (Stage)

**结构：**

```
Chapter（章）
├── Stage 1-10（普通怪）
├── Stage 11（精英怪）
├── Stage 12-20（普通怪）
└── Stage 21（Boss）
```

**规则：**

- 挂机收益 = 当前通关最高关卡决定的每分钟收益
- 通关前一关解锁下一关
- Boss 拥有独特机制（反伤、护盾、狂暴）和多阶段（血量 50% 进入 P2）
- Boss 掉落高级装备和宝物

### 2.4 文件夹结构

```
Game/Hotfix/                  # 统一在 Game.Hotfix Assembly 中
├── Battle/                   # Game.Battle 命名空间
├── Skill/                    # Game.Skill 命名空间
└── Stage/                    # Game.Stage 命名空间
```

Skill 和 Stage 依赖 Battle 的类，但通过编码规范约束依赖方向（Battle 不引用 Skill/Stage）。

---

## 3. Equipment 装备系统

在 `worktree-equip` 中开发。

### 3.1 装备结构

```
Equipment
├── 品质：白/绿/蓝/紫/橙/红
├── 部位：武器/头盔/铠甲/鞋子/项链/戒指（6 槽位）
├── 主词条：固定，由部位决定（武器=ATK, 铠甲=DEF, ...）
├── 副词条：随机，品质越高条数越多
├── 强化等级：提升主词条数值
└── 套装效果：2件/4件/6件 → 额外被动加成
```

### 3.2 属性注入

通过 Core 的 NumericSystem 注入，不依赖 Combat 模块：

```
监听 UnitSpawnedEvent → 读取角色装备 → 注入 NumericModifier
监听 EquipChangedEvent → 移除旧修饰 → 添加新修饰
```

### 3.3 装备获取

| 来源 | 说明 |
|------|------|
| 推图掉落 | 挂机收益的主要来源 |
| Boss 掉落 | 高品质装备主要来源 |
| 宝物兑换 | Collection 组的联动点 |

### 3.4 文件夹结构

```
Game/Hotfix/                  # 统一在 Game.Hotfix Assembly 中
└── Equipment/                # Game.Equipment 命名空间
    ├── Model/                # 实体 + 组件
    ├── Handler/              # 事件处理器
    └── UI/                   # 装备界面逻辑
```

通过编码规范约束不直接引用 Combat 或 Collection 命名空间下的类。

---

## 4. Collection 收集玩法组

在 `worktree-collection` 中开发。

### 4.1 通用收集模式（宝物和宠物共用）

```
Collectible
├── ID + 品质 + 名称 + 图标
├── 获取条件（关卡解锁/Boss 掉落/活动）
├── 激活状态（未拥有/已拥有/已激活）
├── 属性加成（激活后通过 NumericSystem 注入）
└── 图鉴进度（收集越多，额外奖励越高）
```

### 4.2 时装系统 (Fashion)

**纯商城投放，成套售卖：**

- 商城直接售卖整套时装（不分件，买即全套）
- 购买后自动激活该套装属性加成
- 不需要收集、不掉落、不碎片合成
- 少量免费时装通过推图里程碑赠送

**幻化系统：**

- 独立于时装的纯外观系统
- 玩家在任何装备上选择已拥有装备的外观
- 纯视觉效果，零属性影响
- 解锁条件：曾经拥有过该装备即可永久幻化

### 4.3 宝物系统 (Treasure)

- 每个宝物提供全局被动加成（如"全队攻击力+5%"）
- 宝物有品质和等级，消耗重复宝物升星
- 图鉴系统：集齐特定组合 → 解锁额外效果
- 获取途径：Boss 掉落、关卡宝箱、成就奖励

### 4.4 宠物系统 (Pet)

- 宠物在战斗中提供额外被动效果 + 视觉跟随
- 每个宠物 1 个被动技能，增加策略维度
- 宠物可消耗材料升级，提升被动效果数值
- 获取途径：关卡掉落蛋 → 孵化 → 随机品质宠物

### 4.5 文件夹结构

```
Game/Hotfix/                  # 统一在 Game.Hotfix Assembly 中
├── Fashion/                  # Game.Fashion 命名空间
├── Treasure/                 # Game.Treasure 命名空间
├── Pet/                      # Game.Pet 命名空间
└── Collection/Common/        # 收集品通用基类（如需要）
```

三个子模块互相独立，通过编码规范约束不交叉引用。

### 4.6 模块间联动（通过事件）

```
Combat 发布 BattleEndEvent
  → Equipment 监听 → 掉落装备
  → Treasure 监听 → 掉落宝物碎片
  → Pet 监听 → 掉落宠物蛋

Collection 发布 CollectibleActivatedEvent
  → Core NumericSystem → 更新角色属性
  → Combat 下次战斗自动应用新属性
```

---

## 5. Git Worktree 并行开发策略

### 5.1 分支结构

```
main                    ← 稳定集成分支，可运行版本
├── feat/core           ← Core 基础层开发
├── feat/combat         ← Combat 组开发
├── feat/equipment      ← Equipment 模块开发
└── feat/collection     ← Collection 组开发
```

### 5.2 开发流程

1. **Core 优先**：在 feat/core 开发基础层，合并到 main
2. **并行展开**：从 main 创建三个 worktree：
   - `worktree-combat` → feat/combat
   - `worktree-equip` → feat/equipment
   - `worktree-collection` → feat/collection
3. **单人实战策略**：
   - 专注一个 worktree 开发，编译通过后合并到 main
   - 切换 worktree 开发另一模块，互不影响
   - 每个 worktree 独立编译测试
4. **集成节奏**：
   - Core 变更 → 各 worktree rebase
   - 模块完成 → 合并到 main → 集成测试

### 5.3 并行开发实战

**同时打开多个 worktree 窗口，并行推进：**

```
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│  IDE Window 1       │  │  IDE Window 2       │  │  IDE Window 3       │
│  worktree-combat    │  │  worktree-equip     │  │  worktree-collection│
│                     │  │                     │  │                     │
│  写技能系统代码      │  │  Unity 编译中…      │  │  跑装备掉落测试     │
│                     │  │                     │  │                     │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘

场景 A：写代码的同时
  → worktree-combat 里写技能逻辑
  → worktree-equip 在后台编译装备模块
  → 互不阻塞

场景 B：编译/测试的同时
  → worktree-combat 在跑战斗单元测试
  → worktree-collection 里继续写宠物系统
  → 测试失败直接去 combat 修，不影响 collection

场景 C：灵感切换
  → 战斗引擎卡住了？直接切到 worktree-equip 写装备逻辑
  → 不需要 stash、不需要 commit 半成品
  → 两个 worktree 各自保持独立状态
```

**模块独立编译保证：**

- 每个 worktree 编辑不同的文件夹（Battle/、Equipment/、Collection/），合并冲突最小化
- 命名空间隔离提供逻辑边界，同一 Assembly 内可编译通过
- 单个 worktree 内的修改不影响其他 worktree 的代码

**集成节奏：**

- 模块在 worktree 中完成一个功能点 → 合并到 main
- main 分支随时保持可运行状态
- Core 变更时各 worktree rebase 同步
