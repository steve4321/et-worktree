# 项目骨架搭建 + Core 基础层 实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 搭建基于 ET 8 + HybridCLR 的可运行项目骨架，实现 Core 基础层（属性系统、事件定义、配置表加载），配置 YooAsset/FairyGUI/Luban 工具链，建立 git worktree 并行开发环境。

**架构：** 基于 ET 8 release8.1 的四程序集体系（Model/Hotfix/ModelView/HotfixView），游戏代码嵌入 ET 8 的 Module 文件夹结构中。遵循 ET 8 的 Component-System 扩展方法模式。服务端使用 DotNet/ 独立进程。**命名空间约定：** 遵循 ET 8 规范使用 `ET` / `ET.Client` / `ET.Server`，通过文件夹路径实现模块隔离（非 `Game.*` 命名空间）。

**技术栈：** Unity 2022 LTS / ET 8.1 (.NET 8) / HybridCLR / YooAsset / FairyGUI / Luban / MongoDB / Spine

**设计规格：** `docs/superpowers/specs/2026-04-17-idle-game-design.md`

---

## 文件结构总览

以下为本计划创建/修改的所有文件：

### ET 8 框架文件（从 GitHub 获取，不手动创建）

| 文件 | 说明 |
|------|------|
| `Unity/Assets/Scripts/Core/` | ET 8 框架核心，不修改 |
| `Unity/Assets/Scripts/Loader/CodeLoader.cs` | 热更 dll 加载入口，可能需要微调 |
| `DotNet/` | 服务端独立进程 |

### 游戏代码文件（本计划创建）

**Model 层（数据定义）：**

| 文件 | 职责 |
|------|------|
| `Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericType.cs` | 属性类型常量 + 5 槽位（Base/Add/Pct/FinalAdd/FinalPct） |
| `Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifierRecord.cs` | 属性修饰记录结构体（来源管理用） |
| `Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifierComponent.cs` | 属性修饰来源管理组件 |
| `Unity/Assets/Scripts/Model/Share/Module/Event/GameEventDefine.cs` | 游戏事件结构体定义 |

**注：** `NumericComponent` 及其 System 已由 ET 8 框架内置，无需重新创建。

**Hotfix 层（逻辑实现）：**

| 文件 | 职责 |
|------|------|
| `Unity/Assets/Scripts/Hotfix/Share/Module/Numeric/NumericModifierComponentSystem.cs` | 属性修饰来源管理逻辑（Add/Remove/Replace） |

### 第三方工具配置

| 文件 | 职责 |
|------|------|
| `Unity/Packages/manifest.json` | 添加 YooAsset、FairyGUI 包引用 |
| `Config/Luban/Defines/__tables__.xlsx` | Luban 表定义文件 |
| `Config/Luban/Datas/numeric.xlsx` | NumericType 配置表 |
| `Config/Luban/gen.bat` | Luban 代码生成脚本 |

### 测试文件

| 文件 | 职责 |
|------|------|
| `Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests/NumericTestRunner.cs` | 属性系统单元测试 |

---

## 任务 1：项目初始化 — 克隆 ET 8 + Git 配置

**文件：**
- 创建：`.gitignore`
- 创建：`README.md`（简要说明）

- [ ] **步骤 1：初始化 Git 仓库**

```bash
cd /Users/stevezhu/work/et-worktree
git init
```

- [ ] **步骤 2：克隆 ET 8 release8.1**

```bash
# 将 ET 8 release8.1 克隆为子目录（不使用 submodule，方便修改）
git clone --branch release8.1 --depth 1 https://github.com/egametang/ET.git temp_et
# 移动内容到当前目录
cp -r temp_et/* ./
cp -r temp_et/.* ./ 2>/dev/null || true
rm -rf temp_et
```

- [ ] **步骤 3：创建 .gitignore**

```gitignore
# Unity
Unity/Library/
Unity/Temp/
Unity/Obj/
Unity/Build/
Unity/Builds/
Unity/UserSettings/

# IDE
.idea/
.vs/
.vscode/
*.csproj
*.unityproj
*.sln
*.suo
*.tmp
*.user
*.pidb
*.booproj

# OS
.DS_Store
Thumbs.db

# Build
Build/
output/

# Luban
Config/Luban/Output/

# YooAsset
Unity/Assets/StreamingAssets/
```

- [ ] **步骤 4：初始 commit**

```bash
git add -A
git commit -m "chore: 初始化项目，导入 ET 8.1 框架"
```

---

## 任务 2：Unity 项目配置

**说明：** 此任务包含需要在 Unity 编辑器中手动操作的步骤。

- [ ] **步骤 1：用 Unity 2022 打开项目**

手动操作：
1. 打开 Unity Hub
2. Add 项目：`/Users/stevezhu/work/et-worktree/Unity`
3. 选择 Unity 2022 LTS 版本打开
4. 等待首次编译完成

- [ ] **步骤 2：确认 ET 8 编译通过**

在 Unity Console 窗口确认无编译错误。如果有错误，根据提示修复。

- [ ] **步骤 3：配置 Unity 构建目标为 Android**

手动操作：
1. File → Build Settings
2. 切换平台到 Android
3. Player Settings 中配置：
   - Scripting Backend: IL2CPP
   - API Compatibility Level: .NET Standard 2.1
   - Target API Level: Android 13 (API 33)

- [ ] **步骤 4：Commit**

```bash
git add -A
git commit -m "chore: 配置 Unity 构建目标为 Android/IL2CPP"
```

---

## 任务 3：HybridCLR 配置

**说明：** ET 8 已内置 HybridCLR 支持，需要安装和初始化。

- [ ] **步骤 1：安装 HybridCLR**

手动操作（在 Unity 编辑器中）：
1. 打开菜单：HybridCLR → Installer...
2. 点击 "Install" 按钮
3. 等待安装完成，Console 无报错

- [ ] **步骤 2：确认热更 Assembly 配置**

检查文件 `Unity/ProjectSettings/HybridCLRSettings.asset`，确认 hotUpdateAssemblies 包含：
```yaml
hotUpdateAssemblies:
  - Unity.Model
  - Unity.Hotfix
  - Unity.ModelView
  - Unity.HotfixView
```

- [ ] **步骤 3：生成 AOT 泛型引用**

手动操作：
1. 打开菜单：HybridCLR → Generate → AOTGenericReferences
2. 等待生成完成

- [ ] **步骤 4：Commit**

```bash
git add -A
git commit -m "chore: 配置 HybridCLR 热更新环境"
```

---

## 任务 4：安装第三方工具 — YooAsset + FairyGUI + Luban

**文件：**
- 修改：`Unity/Packages/manifest.json`

- [ ] **步骤 1：安装 YooAsset**

手动操作：
1. 打开 Unity Package Manager（Window → Package Manager）
2. 点击 "+" → Add package from git URL
3. 输入：`https://github.com/tuyoogame/YooAsset.git#package`
4. 等待安装完成

- [ ] **步骤 2：安装 FairyGUI**

手动操作：
1. 从 FairyGUI 官网下载最新 Unity SDK：`https://www.fairygui.com/docs/guide/unity`
2. 将下载的 `FairyGUI-unity` 插件导入到 `Unity/Assets/Plugins/` 下
3. 确认编译无错误

- [ ] **步骤 3：配置 Luban 工具链**

```bash
# 创建 Luban 配置目录
mkdir -p Config/Luban/Defines
mkdir -p Config/Luban/Datas
mkdir -p Config/Luban/Output

# 下载 Luban 工具（Luban.CLI）
# 访问 https://github.com/focus-creative-games/luban/releases 下载最新版
# 解压到 Tools/Luban/ 目录
mkdir -p Tools/Luban
```

- [ ] **步骤 4：安装 Spine Unity Runtime**

手动操作：
1. 从 Asset Store 或 Spine 官网下载 `spine-unity` 运行时
2. 导入到 `Unity/Assets/Plugins/Spine/`
3. 确认编译无错误

- [ ] **步骤 5：Commit**

```bash
git add -A
git commit -m "chore: 安装 YooAsset + FairyGUI + Luban + Spine"
```

---

## 任务 5：创建游戏模块目录结构

**文件：**
- 创建：Model/Hotfix 各模块文件夹

- [ ] **步骤 1：创建 Model 层目录**

```bash
# 共享 Model（客户端服务端共用）
mkdir -p Unity/Assets/Scripts/Model/Share/Module/Numeric
mkdir -p Unity/Assets/Scripts/Model/Share/Module/Event

# 客户端 Model
mkdir -p Unity/Assets/Scripts/Model/Client/Module/Numeric
mkdir -p Unity/Assets/Scripts/Model/Client/Module/Battle
mkdir -p Unity/Assets/Scripts/Model/Client/Module/Skill
mkdir -p Unity/Assets/Scripts/Model/Client/Module/Stage
mkdir -p Unity/Assets/Scripts/Model/Client/Module/Equipment
mkdir -p Unity/Assets/Scripts/Model/Client/Module/Fashion
mkdir -p Unity/Assets/Scripts/Model/Client/Module/Treasure
mkdir -p Unity/Assets/Scripts/Model/Client/Module/Pet
mkdir -p Unity/Assets/Scripts/Model/Client/Module/UI

# 服务端 Model
mkdir -p Unity/Assets/Scripts/Model/Server/Module/Numeric
mkdir -p Unity/Assets/Scripts/Model/Server/Module/Battle
mkdir -p Unity/Assets/Scripts/Model/Server/Module/Skill
mkdir -p Unity/Assets/Scripts/Model/Server/Module/Stage
mkdir -p Unity/Assets/Scripts/Model/Server/Module/Equipment
mkdir -p Unity/Assets/Scripts/Model/Server/Module/Fashion
mkdir -p Unity/Assets/Scripts/Model/Server/Module/Treasure
mkdir -p Unity/Assets/Scripts/Model/Server/Module/Pet
```

- [ ] **步骤 2：创建 Hotfix 层目录**

```bash
# 共享 Hotfix
mkdir -p Unity/Assets/Scripts/Hotfix/Share/Module/Numeric

# 客户端 Hotfix
mkdir -p Unity/Assets/Scripts/Hotfix/Client/Module/Numeric
mkdir -p Unity/Assets/Scripts/Hotfix/Client/Module/Battle
mkdir -p Unity/Assets/Scripts/Hotfix/Client/Module/Skill
mkdir -p Unity/Assets/Scripts/Hotfix/Client/Module/Stage
mkdir -p Unity/Assets/Scripts/Hotfix/Client/Module/Equipment
mkdir -p Unity/Assets/Scripts/Hotfix/Client/Module/Fashion
mkdir -p Unity/Assets/Scripts/Hotfix/Client/Module/Treasure
mkdir -p Unity/Assets/Scripts/Hotfix/Client/Module/Pet
mkdir -p Unity/Assets/Scripts/Hotfix/Client/Module/UI

# 服务端 Hotfix
mkdir -p Unity/Assets/Scripts/Hotfix/Server/Module/Numeric
mkdir -p Unity/Assets/Scripts/Hotfix/Server/Module/Battle
mkdir -p Unity/Assets/Scripts/Hotfix/Server/Module/Skill
mkdir -p Unity/Assets/Scripts/Hotfix/Server/Module/Stage
mkdir -p Unity/Assets/Scripts/Hotfix/Server/Module/Equipment
mkdir -p Unity/Assets/Scripts/Hotfix/Server/Module/Fashion
mkdir -p Unity/Assets/Scripts/Hotfix/Server/Module/Treasure
mkdir -p Unity/Assets/Scripts/Hotfix/Server/Module/Pet

# 服务端测试
mkdir -p Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests
```

- [ ] **步骤 3：创建 ModelView / HotfixView 目录**

```bash
mkdir -p Unity/Assets/Scripts/ModelView/Client/Module/Battle
mkdir -p Unity/Assets/Scripts/ModelView/Client/Module/Equipment
mkdir -p Unity/Assets/Scripts/ModelView/Client/Module/Fashion
mkdir -p Unity/Assets/Scripts/ModelView/Client/Module/UI

mkdir -p Unity/Assets/Scripts/HotfixView/Client/Module/Battle
mkdir -p Unity/Assets/Scripts/HotfixView/Client/Module/Equipment
mkdir -p Unity/Assets/Scripts/HotfixView/Client/Module/Fashion
mkdir -p Unity/Assets/Scripts/HotfixView/Client/Module/UI
```

- [ ] **步骤 4：创建服务端 DotNet 对应目录**

```bash
# DotNet 目录已由 ET 8 创建，确认存在
ls DotNet/App/
ls DotNet/Model/
ls DotNet/Hotfix/
```

- [ ] **步骤 5：Commit**

```bash
git add -A
git commit -m "chore: 创建游戏模块目录结构（Model/Hotfix/ModelView/HotfixView）"
```

---

## 任务 6：属性类型枚举 — NumericType

**文件：**
- 创建：`Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericType.cs`

- [ ] **步骤 1：编写 NumericType 枚举**

```csharp
// 文件: Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericType.cs
namespace ET
{
    /// <summary>
    /// 属性类型枚举。对应 Luban 配置表 TbNumeric 的 Id 字段。
    /// </summary>
    public static class NumericType
    {
        public const int MaxHP = 1001;
        public const int HP = 1002;
        public const int ATK = 1003;
        public const int DEF = 1004;
        public const int Speed = 1005;
        public const int CritRate = 1006;
        public const int CritDmg = 1007;
        public const int HitRate = 1008;
        public const int DodgeRate = 1009;
        public const int MaxMP = 1010;
        public const int MP = 1011;

        // 百分比加成基础值（实际值 = 基础值 + 加成值）
        // 加成类型通过 NumericModifier 的 ModifyType 区分
    }
}
```

- [ ] **步骤 2：确认编译通过**

在 Unity 中等待自动编译，确认 Console 无错误。

- [ ] **步骤 3：Commit**

```bash
git add Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericType.cs
git commit -m "feat: 添加 NumericType 属性类型枚举"
```

---

## 任务 7：属性修饰来源管理 — NumericModifierComponent

**背景：** ET 8 已内置完整的属性系统（`NumericComponent` + 5 槽位 Base/Add/Pct/FinalAdd/FinalPct），支持自动计算最终值和事件分发。但内置系统缺少"按来源管理修饰"的能力——换装备时需要知道该清掉哪个 Add/Pct 的值。本任务添加一个辅助组件，用 SourceTag 跟踪每个来源注入的属性值，便于替换和移除。

**文件：**
- 创建：`Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifierRecord.cs`
- 创建：`Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifierComponent.cs`

- [ ] **步骤 1：编写 NumericModifierRecord 数据结构**

```csharp
// 文件: Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifierRecord.cs
using System.Collections.Generic;

namespace ET
{
    /// <summary>
    /// 记录一个来源（SourceTag）对某个属性的修饰值。
    /// 用于在移除/替换修饰时精确还原 NumericComponent 的 Add/Pct 槽位。
    /// 存储值为 long 类型，与 NumericComponent.NumericDic 一致（float 值需 * 10000）。
    /// </summary>
    public struct NumericModifierRecord
    {
        /// <summary>修饰的最终属性类型（如 NumericType.ATK = 1010）</summary>
        public int NumericType;

        /// <summary>修饰的槽位类型（如 NumericType.ATKAdd = 10102 或 NumericType.ATKPct = 10103）</summary>
        public int SlotType;

        /// <summary>修饰值（long，与 NumericComponent.NumericDic 一致）</summary>
        public long Value;
    }
}
```

- [ ] **步骤 2：编写 NumericModifierComponent**

```csharp
// 文件: Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifierComponent.cs
using System.Collections.Generic;

namespace ET
{
    /// <summary>
    /// 属性修饰来源管理组件。挂载在 Unit 上，与 NumericComponent 配合使用。
    /// 职责：跟踪每个 SourceTag 注入了哪些属性修饰，支持按来源添加/移除/替换。
    /// 内部结构：SourceTag → List&lt;NumericModifierRecord&gt;
    /// </summary>
    [ComponentOf(typeof(Unit))]
    public class NumericModifierComponent : Entity, IAwake, IDestroy
    {
        /// <summary>来源标签 → 该来源的所有修饰记录</summary>
        public Dictionary<string, List<NumericModifierRecord>> Modifiers = new();
    }
}
```

- [ ] **步骤 3：确认编译通过**

等待 Unity 自动编译，确认无错误。

- [ ] **步骤 4：Commit**

```bash
git add Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifierRecord.cs \
       Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifierComponent.cs
git commit -m "feat: 添加 NumericModifierRecord + NumericModifierComponent（属性修饰来源管理）"
```

---

## 任务 8：属性修饰来源管理逻辑 — NumericModifierComponentSystem

**文件：**
- 创建：`Unity/Assets/Scripts/Hotfix/Share/Module/Numeric/NumericModifierComponentSystem.cs`

- [ ] **步骤 1：编写 NumericModifierComponentSystem**

```csharp
// 文件: Unity/Assets/Scripts/Hotfix/Share/Module/Numeric/NumericModifierComponentSystem.cs
using System.Collections.Generic;

namespace ET
{
    [EntitySystemOf(typeof(NumericModifierComponent))]
    [FriendOf(typeof(NumericModifierComponent))]
    public static partial class NumericModifierComponentSystem
    {
        [EntitySystem]
        private static void Awake(this NumericModifierComponent self)
        {
        }

        [EntitySystem]
        private static void Destroy(this NumericModifierComponent self)
        {
            self.RemoveAll();
            self.Modifiers.Clear();
        }

        /// <summary>
        /// 添加来源修饰。自动将值写入 NumericComponent 对应槽位，并记录修饰来源。
        /// 如果该 SourceTag 已有修饰，先移除旧的再添加新的（替换语义）。
        /// </summary>
        public static void Add(this NumericModifierComponent self, string sourceTag, int slotType, long value)
        {
            // 获取该属性对应的最终属性类型，用于查找 NumericComponent
            int finalType = slotType / 10;

            var numericComp = self.GetParent<Unit>().GetComponent<NumericComponent>();
            if (numericComp == null) return;

            // 如果该来源已有修饰记录，先移除旧的
            if (self.Modifiers.TryGetValue(sourceTag, out var oldRecords))
            {
                foreach (var record in oldRecords)
                {
                    // 将旧值从对应槽位减去
                    long oldSlotValue = numericComp.GetByKey(record.SlotType);
                    long newSlotValue = oldSlotValue - record.Value;
                    numericComp.Insert(record.SlotType, newSlotValue);
                }
            }

            // 将新值加到槽位上
            long currentSlotValue = numericComp.GetByKey(slotType);
            numericComp.Insert(slotType, currentSlotValue + value);

            // 记录新修饰
            var newRecords = new List<NumericModifierRecord>
            {
                new NumericModifierRecord
                {
                    NumericType = finalType,
                    SlotType = slotType,
                    Value = value
                }
            };
            self.Modifiers[sourceTag] = newRecords;
        }

        /// <summary>
        /// 添加来源修饰（一次添加多个槽位，如装备同时加 Add 和 Pct）。
        /// </summary>
        public static void Add(this NumericModifierComponent self, string sourceTag, List<NumericModifierRecord> records)
        {
            var numericComp = self.GetParent<Unit>().GetComponent<NumericComponent>();
            if (numericComp == null) return;

            // 先移除该来源的旧修饰
            if (self.Modifiers.TryGetValue(sourceTag, out var oldRecords))
            {
                foreach (var record in oldRecords)
                {
                    long oldSlotValue = numericComp.GetByKey(record.SlotType);
                    numericComp.Insert(record.SlotType, oldSlotValue - record.Value);
                }
            }

            // 添加新修饰
            foreach (var record in records)
            {
                long currentSlotValue = numericComp.GetByKey(record.SlotType);
                numericComp.Insert(record.SlotType, currentSlotValue + record.Value);
            }

            self.Modifiers[sourceTag] = records;
        }

        /// <summary>
        /// 移除指定来源的所有修饰。
        /// </summary>
        public static void Remove(this NumericModifierComponent self, string sourceTag)
        {
            if (!self.Modifiers.TryGetValue(sourceTag, out var records)) return;

            var numericComp = self.GetParent<Unit>().GetComponent<NumericComponent>();
            if (numericComp != null)
            {
                foreach (var record in records)
                {
                    long oldSlotValue = numericComp.GetByKey(record.SlotType);
                    numericComp.Insert(record.SlotType, oldSlotValue - record.Value);
                }
            }

            self.Modifiers.Remove(sourceTag);
        }

        /// <summary>
        /// 移除所有来源的修饰。
        /// </summary>
        public static void RemoveAll(this NumericModifierComponent self)
        {
            var numericComp = self.GetParent<Unit>().GetComponent<NumericComponent>();
            if (numericComp != null)
            {
                foreach (var kv in self.Modifiers)
                {
                    foreach (var record in kv.Value)
                    {
                        long oldSlotValue = numericComp.GetByKey(record.SlotType);
                        numericComp.Insert(record.SlotType, oldSlotValue - record.Value);
                    }
                }
            }
            self.Modifiers.Clear();
        }
    }
}
```

- [ ] **步骤 2：确认编译通过**

等待 Unity 自动编译，确认无错误。

- [ ] **步骤 3：Commit**

```bash
git add Unity/Assets/Scripts/Hotfix/Share/Module/Numeric/NumericModifierComponentSystem.cs
git commit -m "feat: 实现 NumericModifierComponentSystem（来源修饰管理逻辑）"
```

---

## 任务 9：属性系统测试 — NumericTestRunner

**文件：**
- 创建：`Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests/NumericTestRunner.cs`

**说明：** 测试 ET 8 内置 NumericComponent 的 5 槽位计算，以及 NumericModifierComponent 的来源管理能力。

- [ ] **步骤 1：编写测试运行器**

```csharp
// 文件: Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests/NumericTestRunner.cs
using System;
using System.Collections.Generic;

namespace ET.Server
{
    /// <summary>
    /// 属性系统测试运行器。挂载到 Scene 上后自动运行所有测试并输出结果。
    /// 使用方式：在服务端启动流程中临时添加 self.Scene.AddComponent<NumericTestRunner>();
    /// </summary>
    [ComponentOf(typeof(Scene))]
    public class NumericTestRunner : Entity, IAwake
    {
    }

    [EntitySystemOf(typeof(NumericTestRunner))]
    [FriendOf(typeof(NumericTestRunner))]
    public static partial class NumericTestRunnerSystem
    {
        [EntitySystem]
        private static void Awake(this NumericTestRunner self)
        {
            self.RunAllTests();
        }

        private static void RunAllTests(this NumericTestRunner self)
        {
            int passed = 0;
            int failed = 0;

            // Test 1: ET 8 内置 5 槽位计算
            // 公式: ((base + add) * (100 + pct) / 100 + finalAdd) * (100 + finalPct) / 100
            // pct 槽位：20 表示 +20%，即公式中 (100 + 20) / 100 = 1.2
            {
                var unit = self.Scene.AddChild<Unit>();
                var comp = unit.AddComponent<NumericComponent>();

                comp.Set(NumericType.ATKBase, 100f);
                comp.Set(NumericType.ATKAdd, 50f);
                comp.Set(NumericType.ATKPct, 20f); // +20%

                // (100 + 50) * (100 + 20) / 100 = 150 * 1.2 = 180
                float result = comp.GetAsFloat(NumericType.ATK);
                if (Math.Abs(result - 180f) < 0.1f) { ++passed; Log.Info("[NumericTest] PASS: 5-slot calculation"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: 5-slot, expected 180 got {result}"); }
                unit.Dispose();
            }

            // Test 2: NumericModifierComponent 添加来源修饰
            {
                var unit = self.Scene.AddChild<Unit>();
                unit.AddComponent<NumericComponent>();
                var modComp = unit.AddComponent<NumericModifierComponent>();

                // 设置基础值
                unit.GetComponent<NumericComponent>().Set(NumericType.ATKBase, 100f);

                // 通过 ModifierComponent 添加装备加成：+80 攻击力
                // ATKAdd 内部存储为 long，80.0f * 10000 = 800000
                modComp.Add("equip_weapon_1", NumericType.ATKAdd, (long)(80f * 10000));

                float result = unit.GetComponent<NumericComponent>().GetAsFloat(NumericType.ATK);
                // 100 + 80 = 180
                if (Math.Abs(result - 180f) < 0.1f) { ++passed; Log.Info("[NumericTest] PASS: ModifierComponent add"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: ModifierComponent add, expected 180 got {result}"); }
                unit.Dispose();
            }

            // Test 3: NumericModifierComponent 替换来源修饰
            {
                var unit = self.Scene.AddChild<Unit>();
                unit.AddComponent<NumericComponent>();
                var modComp = unit.AddComponent<NumericModifierComponent>();

                unit.GetComponent<NumericComponent>().Set(NumericType.ATKBase, 100f);

                // 先加 +50
                modComp.Add("equip_weapon_1", NumericType.ATKAdd, (long)(50f * 10000));
                // 替换为 +80（相同 sourceTag 自动替换）
                modComp.Add("equip_weapon_1", NumericType.ATKAdd, (long)(80f * 10000));

                float result = unit.GetComponent<NumericComponent>().GetAsFloat(NumericType.ATK);
                // 100 + 80 = 180（不是 100 + 50 + 80 = 230）
                if (Math.Abs(result - 180f) < 0.1f) { ++passed; Log.Info("[NumericTest] PASS: ModifierComponent replace"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: ModifierComponent replace, expected 180 got {result}"); }
                unit.Dispose();
            }

            // Test 4: NumericModifierComponent 移除来源修饰
            {
                var unit = self.Scene.AddChild<Unit>();
                unit.AddComponent<NumericComponent>();
                var modComp = unit.AddComponent<NumericModifierComponent>();

                unit.GetComponent<NumericComponent>().Set(NumericType.DEFBase, 50f);

                modComp.Add("buff_shield", NumericType.DEFAdd, (long)(20f * 10000));
                float withBuff = unit.GetComponent<NumericComponent>().GetAsFloat(NumericType.DEF);
                if (Math.Abs(withBuff - 70f) < 0.1f) { ++passed; Log.Info("[NumericTest] PASS: ModifierComponent add buff"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: ModifierComponent add buff, expected 70 got {withBuff}"); }

                modComp.Remove("buff_shield");
                float removed = unit.GetComponent<NumericComponent>().GetAsFloat(NumericType.DEF);
                if (Math.Abs(removed - 50f) < 0.1f) { ++passed; Log.Info("[NumericTest] PASS: ModifierComponent remove"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: ModifierComponent remove, expected 50 got {removed}"); }
                unit.Dispose();
            }

            // Test 5: 多槽位同时修饰（装备同时加 Add 和 Pct）
            {
                var unit = self.Scene.AddChild<Unit>();
                unit.AddComponent<NumericComponent>();
                var modComp = unit.AddComponent<NumericModifierComponent>();

                unit.GetComponent<NumericComponent>().Set(NumericType.ATKBase, 100f);

                // 装备同时加 20 ATK 和 50% ATK
                var records = new List<NumericModifierRecord>
                {
                    new NumericModifierRecord { NumericType = NumericType.ATK, SlotType = NumericType.ATKAdd, Value = (long)(20f * 10000) },
                    new NumericModifierRecord { NumericType = NumericType.ATK, SlotType = NumericType.ATKPct, Value = (long)(0.5f * 10000) },
                };
                modComp.Add("equip_ring_1", records);

                // 公式: (100 + 20) * (100 + 50) / 100 = 120 * 1.5 = 180
                float result = unit.GetComponent<NumericComponent>().GetAsFloat(NumericType.ATK);
                if (Math.Abs(result - 180f) < 0.1f) { ++passed; Log.Info("[NumericTest] PASS: Multi-slot modifier"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: Multi-slot, expected 180 got {result}"); }
                unit.Dispose();
            }

            Log.Info($"[NumericTest] === Results: {passed} passed, {failed} failed ===");
            self.Dispose();
        }
    }
}
```

- [ ] **步骤 2：确认编译通过**

等待 Unity 自动编译，确认无错误。

- [ ] **步骤 3：Commit**

```bash
git add Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests/NumericTestRunner.cs
git commit -m "feat: 添加属性系统测试用例（ET 8 内置 5 槽位 + NumericModifierComponent 来源管理）"
```

---

## 任务 10：运行属性系统测试并验证

- [ ] **步骤 1：在服务端启动流程中临时添加测试**

找到 ET 8 的服务端启动代码（`Hotfix/Server/Demo/` 下），
在 Unit 创建后临时添加：

```csharp
// 临时测试代码，验证完成后移除
self.Scene.AddComponent<NumericTestRunner>();
```

手动操作：
1. 找到服务端 Entry 或 Map 场景启动位置
2. 添加上述测试组件
3. 运行服务端

- [ ] **步骤 2：运行服务端，检查 Console 输出**

预期输出：
```
[NumericTest] PASS: 5-slot calculation
[NumericTest] PASS: ModifierComponent add
[NumericTest] PASS: ModifierComponent replace
[NumericTest] PASS: ModifierComponent add buff
[NumericTest] PASS: ModifierComponent remove
[NumericTest] PASS: Multi-slot modifier
[NumericTest] === Results: 6 passed, 0 failed ===
```

- [ ] **步骤 3：移除临时测试调用，保留测试代码**

从启动入口中移除 `AddComponent<NumericTestRunner>()` 的临时调用。
测试类 `NumericTestRunner` 保留在代码中，后续可通过专门的测试入口运行。

- [ ] **步骤 4：Commit**

```bash
git add -A
git commit -m "chore: 属性系统测试验证通过（6 项全 PASS），移除临时测试调用"
```

---

## 任务 11：游戏事件定义

**文件：**
- 创建：`Unity/Assets/Scripts/Model/Share/Module/Event/GameEventDefine.cs`

- [ ] **步骤 1：编写游戏事件结构体**

```csharp
// 文件: Unity/Assets/Scripts/Model/Share/Module/Event/GameEventDefine.cs
namespace ET
{
    /// <summary>
    /// 角色/单位创建完成事件。
    /// 各模块监听此事件，注入初始属性（装备加成、宝物加成等）。
    /// </summary>
    public struct UnitSpawnedEvent
    {
        public Unit Unit;
    }

    /// <summary>
    /// 装备变更事件。
    /// 监听方：NumericSystem（更新属性修饰）、UI（刷新界面）
    /// </summary>
    public struct EquipChangedEvent
    {
        public long UnitId;
        public int SlotType;
        public long OldEquipId;
        public long NewEquipId;
    }

    /// <summary>
    /// 战斗结束事件。
    /// 监听方：Equipment（掉落装备）、Treasure（掉落宝物）、Pet（掉落宠物蛋）、Stage（更新进度）
    /// </summary>
    public struct BattleEndEvent
    {
        public long StageId;
        public int Result; // 0=失败, 1=胜利
    }

    /// <summary>
    /// 收集品激活事件。
    /// 监听方：NumericSystem（注入属性）
    /// </summary>
    public struct CollectibleActivatedEvent
    {
        public int CollectibleType; // 宝物/宠物/时装
        public int CollectibleId;
    }

    /// <summary>
    /// 技能配置变更事件。
    /// 监听方：Battle（重新计算技能池）
    /// </summary>
    public struct SkillChangedEvent
    {
        public long UnitId;
        public int SlotIndex;
        public int OldSkillId;
        public int NewSkillId;
    }
}
```

- [ ] **步骤 2：确认编译通过**

等待 Unity 自动编译，确认无错误。

- [ ] **步骤 3：Commit**

```bash
git add Unity/Assets/Scripts/Model/Share/Module/Event/GameEventDefine.cs
git commit -m "feat: 定义游戏核心事件（UnitSpawned/EquipChanged/BattleEnd/CollectibleActivated/SkillChanged）"
```

---

## 任务 12：Luban 初始配置 — NumericType 配置表

**文件：**
- 创建：`Config/Luban/Datas/numeric.xlsx`（Excel 文件，手动创建）
- 创建：`Config/Luban/gen.sh`（代码生成脚本）

- [ ] **步骤 1：创建 Luban 配置定义文件**

参考 Luban 官方文档创建配置定义。在 `Config/Luban/` 下创建 `__tables__.xlsx` 或使用 luban 的 json 定义方式。

创建文件 `Config/Luban/Defines/numeric.json`：

```json
{
  "name": "TbNumeric",
  "comment": "属性类型配置表",
  "define": "NumericRecord",
  "input": "Datas/numeric.xlsx",
  "index": [
    "Id"
  ],
  "fields": [
    { "name": "Id", "type": "int", "comment": "属性类型ID，对应 NumericType 常量" },
    { "name": "Name", "type": "string", "comment": "属性名称" },
    { "name": "MaxValue", "type": "float", "comment": "最大值上限" },
    { "name": "DefaultValue", "type": "float", "comment": "默认值" }
  ]
}
```

- [ ] **步骤 2：创建配置数据 Excel**

手动创建 `Config/Luban/Datas/numeric.xlsx`，内容：

| Id | Name | MaxValue | DefaultValue |
|----|------|----------|-------------|
| 1001 | MaxHP | 99999 | 0 |
| 1002 | HP | 99999 | 0 |
| 1003 | ATK | 99999 | 0 |
| 1004 | DEF | 99999 | 0 |
| 1005 | Speed | 1000 | 100 |
| 1006 | CritRate | 1.0 | 0 |
| 1007 | CritDmg | 10.0 | 1.5 |
| 1008 | HitRate | 1.0 | 1.0 |
| 1009 | DodgeRate | 1.0 | 0 |
| 1010 | MaxMP | 9999 | 0 |
| 1011 | MP | 9999 | 0 |

- [ ] **步骤 3：创建代码生成脚本**

```bash
# 文件: Config/Luban/gen.sh
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LUBAN_TOOL="${SCRIPT_DIR}/../Tools/Luban/Luban.CLI"

# 生成 C# 代码
${LUBAN_TOOL} \
  -t client \
  -c cs-simple \
  -d json \
  --conf "${SCRIPT_DIR}/luban.conf" \
  -o "${SCRIPT_DIR}/Output"

# 将生成代码复制到项目中
cp -r "${SCRIPT_DIR}/Output/codes/" \
  "${SCRIPT_DIR}/../../Unity/Assets/Scripts/Hotfix/Client/Module/Config/Luban/"

echo "Luban code generation complete."
```

```bash
chmod +x Config/Luban/gen.sh
```

- [ ] **步骤 4：运行生成脚本（在 Luban 完整安装后）**

```bash
cd Config/Luban && ./gen.sh
```

注意：需要先下载 Luban.CLI 到 Tools/Luban/ 目录。如果还没下载，跳过此步骤，后续补充。

- [ ] **步骤 5：Commit**

```bash
git add Config/Luban/
git commit -m "feat: 添加 Luban 配置定义和 numeric 配置表"
```

---

## 任务 13：YooAsset Package 配置

**说明：** 此任务需要在 Unity 编辑器中手动配置。

- [ ] **步骤 1：创建 YooAsset Package 结构**

手动操作（Unity 编辑器中）：
1. 打开 YooAsset 设置窗口：Window → YooAsset → Asset Collector
2. 创建 Package：
   - BuiltinPackage（内置）
   - CommonPackage（通用资源）
   - StagePackage（关卡资源）
   - FashionPackage（时装资源）
   - UIPackage（UI 资源）

- [ ] **步骤 2：创建初始资源收集组**

在每个 Package 下创建收集组（Group），配置资源收集规则。
暂时只需创建空 Group，后续开发中逐步填充。

- [ ] **步骤 3：Commit**

```bash
git add -A
git commit -m "feat: 配置 YooAsset 五个 Package（Builtin/Common/Stage/Fashion/UI）"
```

---

## 任务 14：FairyGUI 原子组件模板

**说明：** 此任务在 FairyGUI 编辑器中完成。

- [ ] **步骤 1：创建 FairyGUI 项目**

手动操作：
1. 打开 FairyGUI 编辑器
2. 新建项目，路径设在 `Unity/Assets/FairyGUI/` 下
3. 创建包（Package）：`Common`（通用组件）

- [ ] **步骤 2：创建原子组件**

在 `Common` 包中创建以下组件（每个是一个 Component）：

| 组件名 | 结构 |
|--------|------|
| ItemCard | 图标（Loader）+ 品质框（Graph）+ 名字（TextField）+ 等级（TextField） |
| StatRow | 属性名（TextField）+ 数值（TextField）+ 变化箭头（Loader） |
| SlotWidget | 槽位框（Graph）+ 图标（Loader）+ 品质边框（Graph） |
| TabBar | 横向 List，每项一个 Button |
| PopupDialog | 背景遮罩（Graph）+ 标题（TextField）+ 内容区（容器）+ 确认/取消按钮 |
| SectionHeader | 标题文字（TextField）+ 分割线（Graph） |

- [ ] **步骤 3：创建面板框架**

| 组件名 | 结构 |
|--------|------|
| ListPanel | 标题栏 + TabBar 容器 + 滚动列表区（GList） |
| DetailPanel | 标题栏 + 左侧图区 + 右侧 StatRow 列表 + 底部按钮区 |
| SlotPanel | 标题栏 + N×M 槽位网格 + 底部按钮区 |

- [ ] **步骤 4：导出到 Unity**

手动操作：
1. FairyGUI 编辑器中点击 "发布"
2. 确认 Unity 中 `Assets/FairyGUI/Common` 下生成了对应的素材文件

- [ ] **步骤 5：生成 C# 绑定代码**

手动操作：
1. FairyGUI 编辑器 → 设置 → 勾选 "生成代码"
2. 重新发布，确认 `Assets/Scripts/Hotfix/Client/Module/UI/Binding/` 下生成了绑定类

- [ ] **步骤 6：Commit**

```bash
git add -A
git commit -m "feat: 创建 FairyGUI 原子组件模板（ItemCard/StatRow/SlotWidget/TabBar/PopupDialog）+ 面板框架"
```

---

## 任务 15：面板组装器基础框架

**文件：**
- 创建：`Unity/Assets/Scripts/Hotfix/Client/Module/UI/PanelBuilder.cs`
- 创建：`Unity/Assets/Scripts/Hotfix/Client/Module/UI/DetailPanelBuilder.cs`

- [ ] **步骤 1：编写 PanelBuilder 基类**

```csharp
// 文件: Unity/Assets/Scripts/Hotfix/Client/Module/UI/PanelBuilder.cs
using FairyGUI;

namespace ET.Client
{
    /// <summary>
    /// 面板组装器基类。提供从 FairyGUI 组件创建面板并填充数据的能力。
    /// </summary>
    public abstract class PanelBuilder
    {
        protected GComponent root;

        /// <summary>从 FairyGUI 包创建面板实例</summary>
        protected GComponent CreatePanel(string packageName, string componentName)
        {
            var obj = UIPackage.CreateObject(packageName, componentName);
            root = obj.asCom;
            return root;
        }

        /// <summary>获取组件并添加到舞台</summary>
        public void Show()
        {
            GRoot.inst.AddChild(root);
        }

        /// <summary>从舞台移除并销毁</summary>
        public void Dispose()
        {
            if (root != null)
            {
                root.Dispose();
                root = null;
            }
        }
    }
}
```

- [ ] **步骤 2：编写 DetailPanelBuilder**

```csharp
// 文件: Unity/Assets/Scripts/Hotfix/Client/Module/UI/DetailPanelBuilder.cs
using System.Collections.Generic;
using FairyGUI;

namespace ET.Client
{
    /// <summary>
    /// 详情面板组装器。用于组装装备详情、角色面板等属性展示面板。
    /// </summary>
    public class DetailPanelBuilder : PanelBuilder
    {
        private string title;
        private string iconRes;
        private int quality;
        private readonly List<(string name, float value)> stats = new();
        private readonly List<(string text, EventCallback0 callback)> buttons = new();

        public DetailPanelBuilder SetTitle(string titleText)
        {
            title = titleText;
            return this;
        }

        public DetailPanelBuilder SetLeftIcon(string resourcePath, int itemQuality)
        {
            iconRes = resourcePath;
            quality = itemQuality;
            return this;
        }

        public DetailPanelBuilder AddStatRow(string statName, float statValue)
        {
            stats.Add((statName, statValue));
            return this;
        }

        public DetailPanelBuilder AddButton(string buttonText, EventCallback0 onClick)
        {
            buttons.Add((buttonText, onClick));
            return this;
        }

        /// <summary>组装面板：创建 DetailPanel 实例并填充数据</summary>
        public DetailPanelBuilder Build()
        {
            CreatePanel("Common", "DetailPanel");

            // 设置标题
            var titleText = root.GetChild("title");
            if (titleText != null)
                titleText.text = title ?? "";

            // 设置左侧图标
            var icon = root.GetChild("icon") as GLoader;
            if (icon != null && iconRes != null)
                icon.url = iconRes;

            // 填充属性列表
            var statList = root.GetChild("statList") as GList;
            if (statList != null)
            {
                statList.RemoveChildrenToPool();
                foreach (var (name, value) in stats)
                {
                    var item = statList.AddItemFromPool().asCom;
                    var nameField = item.GetChild("name");
                    var valueField = item.GetChild("value");
                    if (nameField != null) nameField.text = name;
                    if (valueField != null) valueField.text = value.ToString();
                }
            }

            // 添加按钮
            var buttonArea = root.GetChild("buttonArea") as GComponent;
            if (buttonArea != null)
            {
                buttonArea.RemoveChildren();
                foreach (var (text, callback) in buttons)
                {
                    var btn = buttonArea.AddChild(UIPackage.CreateObject("Common", "Button").asCom);
                    var titleBtn = btn.GetChild("title");
                    if (titleBtn != null) titleBtn.text = text;
                    btn.onClick.Set(callback);
                }
            }

            return this;
        }
    }
}
```

- [ ] **步骤 3：确认编译通过**

等待 Unity 自动编译，确认无错误。
注意：此步骤需要 FairyGUI 组件已发布到 Unity 项目中。

- [ ] **步骤 4：Commit**

```bash
git add Unity/Assets/Scripts/Hotfix/Client/Module/UI/PanelBuilder.cs \
       Unity/Assets/Scripts/Hotfix/Client/Module/UI/DetailPanelBuilder.cs
git commit -m "feat: 添加面板组装器基础框架（PanelBuilder + DetailPanelBuilder）"
```

---

## 任务 16：Git Worktree 并行开发环境搭建

- [ ] **步骤 1：确认 main 分支状态**

```bash
git status
git log --oneline -5
```

确认所有之前的 commit 都在 main 分支上。

- [ ] **步骤 2：创建功能分支**

```bash
# 创建各模块功能分支
git branch feat/combat
git branch feat/equipment
git branch feat/collection
```

- [ ] **步骤 3：创建 worktree**

```bash
# 创建 3 个 worktree，分别对应三个模块组
git worktree add ../et-worktree-combat feat/combat
git worktree add ../et-worktree-equip feat/equipment
git worktree add ../et-worktree-collection feat/collection
```

这会在项目同级目录创建 3 个独立的工作目录：
```
/Users/stevezhu/work/
├── et-worktree/                ← 主分支（main）
├── et-worktree-combat/         ← worktree-combat（feat/combat）
├── et-worktree-equip/          ← worktree-equip（feat/equipment）
└── et-worktree-collection/     ← worktree-collection（feat/collection）
```

- [ ] **步骤 4：验证 worktree 状态**

```bash
git worktree list
```

预期输出：
```
/Users/stevezhu/work/et-worktree              abc1234 [main]
/Users/stevezhu/work/et-worktree-combat       abc1234 [feat/combat]
/Users/stevezhu/work/et-worktree-equip        abc1234 [feat/equipment]
/Users/stevezhu/work/et-worktree-collection   abc1234 [feat/collection]
```

- [ ] **步骤 5：验证各 worktree 可独立编译**

手动操作：
1. 用另一个 Unity 实例打开 `et-worktree-combat`
2. 确认编译通过
3. 关闭（如果许可证限制不能同时打开多个 Unity 实例，可以跳过此验证）

- [ ] **步骤 6：Commit**

```bash
git add -A
git commit -m "chore: 创建 git worktree 并行开发环境（combat/equipment/collection）"
```

---

## 任务 17：端到端集成验证

- [ ] **步骤 1：运行服务端**

```bash
cd DotNet/App
dotnet run
```

确认服务端启动无错误。

- [ ] **步骤 2：运行客户端**

手动操作：
1. Unity 编辑器中打开 Login 场景（ET 8 自带）
2. 点击 Play
3. 确认客户端能连接服务端

- [ ] **步骤 3：确认所有系统正常**

检查清单：
- [ ] Unity 编译无错误
- [ ] 服务端启动无错误
- [ ] 客户端能连接服务端
- [ ] HybridCLR 热更 dll 正常加载
- [ ] NumericComponent 可正常创建和使用
- [ ] YooAsset 初始化正常
- [ ] FairyGUI 组件可正常创建

- [ ] **步骤 4：最终 Commit**

```bash
git add -A
git commit -m "chore: 端到端集成验证通过，项目骨架搭建完成"
```

---

## 后续计划预告

本计划完成后，项目骨架就绪，后续计划为：

| 计划 | 内容 | worktree |
|------|------|---------|
| 计划 2 | Combat 组（Battle + Skill + Stage） | worktree-combat |
| 计划 3 | Equipment 装备系统 | worktree-equip |
| 计划 4 | Collection 收集玩法（Fashion + Treasure + Pet） | worktree-collection |

每个计划独立产出可工作、可测试的模块。
