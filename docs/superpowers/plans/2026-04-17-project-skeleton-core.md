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
| `Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericType.cs` | 属性类型枚举 |
| `Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifier.cs` | 属性修饰结构体 |
| `Unity/Assets/Scripts/Model/Share/Module/Event/GameEventDefine.cs` | 游戏事件结构体定义 |
| `Unity/Assets/Scripts/Model/Client/Module/Numeric/NumericComponent.cs` | 属性组件（客户端） |
| `Unity/Assets/Scripts/Model/Server/Module/Numeric/NumericComponent.cs` | 属性组件（服务端） |

**Hotfix 层（逻辑实现）：**

| 文件 | 职责 |
|------|------|
| `Unity/Assets/Scripts/Hotfix/Client/Module/Numeric/NumericComponentSystem.cs` | 属性系统逻辑（客户端） |
| `Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/NumericComponentSystem.cs` | 属性系统逻辑（服务端） |

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

## 任务 7：属性修饰结构体 — NumericModifier

**文件：**
- 创建：`Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifier.cs`

- [ ] **步骤 1：编写失败的测试**

先在 Hotfix 中创建测试文件，定义期望行为。

```csharp
// 文件: Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests/NumericModifierTest.cs
using System;
using System.Collections.Generic;
using ET;

namespace ET.Server
{
    [EntitySystemOf(typeof(NumericComponentTestRunner))]
    public static partial class NumericComponentTestRunnerSystem
    {
        [EntitySystem]
        private static void Awake(this NumericComponentTestRunner self)
        {
            self.RunAllTests();
        }
    }

    [ComponentOf(typeof(Scene))]
    public class NumericComponentTestRunner : Entity, IAwake
    {
        private int passed;
        private int failed;

        public void RunAllTests()
        {
            passed = 0;
            failed = 0;

            TestModifierAdd();
            TestModifierReplace();
            TestModifierRemove();

            Log.Info($"[NumericTest] Passed: {passed}, Failed: {failed}");
        }

        private void Assert(bool condition, string message)
        {
            if (condition)
            {
                ++passed;
            }
            else
            {
                ++failed;
                Log.Error($"[NumericTest] FAIL: {message}");
            }
        }

        private void TestModifierAdd()
        {
            // 测试：添加绝对值加成后，最终属性值正确
            var comp = this.AddComponent<NumericComponent>();
            comp.Set(NumericType.MaxHP, 1000f);
            comp.AddModifier(NumericType.MaxHP, new NumericModifier
            {
                SourceTag = "test_equip_1",
                ModifyType = NumericModifyType.Absolute,
                Value = 200f
            });
            Assert(Math.Abs(comp.Get(NumericType.MaxHP) - 1200f) < 0.01f,
                $"AddModifier absolute: expected 1200, got {comp.Get(NumericType.MaxHP)}");
            comp.Dispose();
        }

        private void TestModifierReplace()
        {
            // 测试：相同 SourceTag 的修饰会替换旧值
            var comp = this.AddComponent<NumericComponent>();
            comp.Set(NumericType.ATK, 100f);
            comp.AddModifier(NumericType.ATK, new NumericModifier
            {
                SourceTag = "test_equip_1",
                ModifyType = NumericModifyType.Absolute,
                Value = 50f
            });
            comp.AddModifier(NumericType.ATK, new NumericModifier
            {
                SourceTag = "test_equip_1",
                ModifyType = NumericModifyType.Absolute,
                Value = 80f
            });
            Assert(Math.Abs(comp.Get(NumericType.ATK) - 180f) < 0.01f,
                $"ReplaceModifier: expected 180, got {comp.Get(NumericType.ATK)}");
            comp.Dispose();
        }

        private void TestModifierRemove()
        {
            // 测试：移除修饰后恢复原始值
            var comp = this.AddComponent<NumericComponent>();
            comp.Set(NumericType.DEF, 50f);
            comp.AddModifier(NumericType.DEF, new NumericModifier
            {
                SourceTag = "test_buff_1",
                ModifyType = NumericModifyType.Percent,
                Value = 0.2f
            });
            Assert(Math.Abs(comp.Get(NumericType.DEF) - 60f) < 0.01f,
                $"AddModifier percent: expected 60, got {comp.Get(NumericType.DEF)}");
            comp.RemoveModifier(NumericType.DEF, "test_buff_1");
            Assert(Math.Abs(comp.Get(NumericType.DEF) - 50f) < 0.01f,
                $"RemoveModifier: expected 50, got {comp.Get(NumericType.DEF)}");
            comp.Dispose();
        }
    }
}
```

注意：此测试暂时无法编译，因为 NumericModifier、NumericComponent 等类型还未定义。这是预期行为。

- [ ] **步骤 2：编写 NumericModifier 结构体**

```csharp
// 文件: Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifier.cs
namespace ET
{
    /// <summary>
    /// 属性修饰类型
    /// </summary>
    public enum NumericModifyType
    {
        /// <summary>绝对值加成（如 +200 HP）</summary>
        Absolute = 0,
        /// <summary>百分比加成（如 +20% ATK，计算为 base * value）</summary>
        Percent = 1,
    }

    /// <summary>
    /// 属性修饰结构体。通过 SourceTag 标识来源，便于替换和移除。
    /// </summary>
    public struct NumericModifier
    {
        /// <summary>来源标识（如 "equip_1001"、"buff_2003"、"fashion_fire"）</summary>
        public string SourceTag;

        /// <summary>修饰类型：绝对值 or 百分比</summary>
        public NumericModifyType ModifyType;

        /// <summary>修饰值（绝对值为具体数值，百分比为小数比例如 0.2 = 20%）</summary>
        public float Value;
    }
}
```

- [ ] **步骤 3：确认编译通过**

等待 Unity 自动编译，确认 NumericModifier 和 NumericModifyType 无错误。

- [ ] **步骤 4：Commit**

```bash
git add Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericModifier.cs \
       Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests/NumericModifierTest.cs
git commit -m "feat: 添加 NumericModifier 属性修饰结构体 + 测试用例"
```

---

## 任务 8：属性组件 — NumericComponent

**文件：**
- 创建：`Unity/Assets/Scripts/Model/Client/Module/Numeric/NumericComponent.cs`
- 创建：`Unity/Assets/Scripts/Model/Server/Module/Numeric/NumericComponent.cs`

- [ ] **步骤 1：编写共享 NumericComponent 数据定义**

由于 ET 8 的 Client 和 Server 使用不同命名空间的 Component 定义，
在 Share 层创建一个共享的数据存储类：

```csharp
// 文件: Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericData.cs
using System.Collections.Generic;

namespace ET
{
    /// <summary>
    /// 属性数据存储。由 NumericComponent 持有，客户端服务端共用计算逻辑。
    /// 计算公式：最终值 = (基础值 + Σ绝对值加成) * (1 + Σ百分比加成)
    /// </summary>
    public class NumericData
    {
        /// <summary>基础值（角色等级、配置表定义的原始值）</summary>
        private readonly Dictionary<int, float> baseValues = new();

        /// <summary>属性修饰器：NumericType → SourceTag → Modifier</summary>
        private readonly Dictionary<int, Dictionary<string, NumericModifier>> modifiers = new();

        /// <summary>缓存最终值，脏标记时重算</summary>
        private readonly Dictionary<int, float> finalValues = new();

        /// <summary>脏标记：哪些 NumericType 需要重算</summary>
        private readonly HashSet<int> dirtySet = new();

        public void SetBase(int numericType, float value)
        {
            baseValues[numericType] = value;
            dirtySet.Add(numericType);
        }

        public float GetBase(int numericType)
        {
            return baseValues.TryGetValue(numericType, out float v) ? v : 0f;
        }

        public void AddModifier(int numericType, NumericModifier modifier)
        {
            if (!modifiers.TryGetValue(numericType, out var dict))
            {
                dict = new Dictionary<string, NumericModifier>();
                modifiers[numericType] = dict;
            }
            dict[modifier.SourceTag] = modifier;
            dirtySet.Add(numericType);
        }

        public void RemoveModifier(int numericType, string sourceTag)
        {
            if (modifiers.TryGetValue(numericType, out var dict))
            {
                dict.Remove(sourceTag);
                dirtySet.Add(numericType);
            }
        }

        public float GetFinal(int numericType)
        {
            if (dirtySet.Remove(numericType))
            {
                finalValues[numericType] = Calculate(numericType);
            }
            return finalValues.TryGetValue(numericType, out float v) ? v : 0f;
        }

        private float Calculate(int numericType)
        {
            float baseVal = GetBase(numericType);
            float absoluteSum = 0f;
            float percentSum = 0f;

            if (modifiers.TryGetValue(numericType, out var dict))
            {
                foreach (var kv in dict)
                {
                    if (kv.Value.ModifyType == NumericModifyType.Absolute)
                        absoluteSum += kv.Value.Value;
                    else
                        percentSum += kv.Value.Value;
                }
            }

            return (baseVal + absoluteSum) * (1f + percentSum);
        }

        public void Reset()
        {
            baseValues.Clear();
            modifiers.Clear();
            finalValues.Clear();
            dirtySet.Clear();
        }
    }
}
```

- [ ] **步骤 2：编写客户端 NumericComponent**

```csharp
// 文件: Unity/Assets/Scripts/Model/Client/Module/Numeric/NumericComponent.cs
namespace ET.Client
{
    [ComponentOf(typeof(Unit))]
    public class NumericComponent : Entity, IAwake, IDestroy
    {
        public NumericData Data { get; set; }
    }
}
```

- [ ] **步骤 3：编写服务端 NumericComponent**

```csharp
// 文件: Unity/Assets/Scripts/Model/Server/Module/Numeric/NumericComponent.cs
namespace ET.Server
{
    [ComponentOf(typeof(Unit))]
    public class NumericComponent : Entity, IAwake, IDestroy
    {
        public NumericData Data { get; set; }
    }
}
```

- [ ] **步骤 4：确认编译通过**

等待 Unity 自动编译，确认无错误。

- [ ] **步骤 5：Commit**

```bash
git add Unity/Assets/Scripts/Model/Share/Module/Numeric/NumericData.cs \
       Unity/Assets/Scripts/Model/Client/Module/Numeric/NumericComponent.cs \
       Unity/Assets/Scripts/Model/Server/Module/Numeric/NumericComponent.cs
git commit -m "feat: 添加 NumericData 属性存储 + Client/Server NumericComponent"
```

---

## 任务 9：属性系统逻辑 — NumericComponentSystem

**文件：**
- 创建：`Unity/Assets/Scripts/Hotfix/Client/Module/Numeric/NumericComponentSystem.cs`
- 创建：`Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/NumericComponentSystem.cs`

- [ ] **步骤 1：编写客户端 NumericComponentSystem**

```csharp
// 文件: Unity/Assets/Scripts/Hotfix/Client/Module/Numeric/NumericComponentSystem.cs
using System;

namespace ET.Client
{
    [EntitySystemOf(typeof(NumericComponent))]
    [FriendOf(typeof(NumericComponent))]
    public static partial class NumericComponentSystem
    {
        [EntitySystem]
        private static void Awake(this NumericComponent self)
        {
            self.Data = new NumericData();
        }

        [EntitySystem]
        private static void Destroy(this NumericComponent self)
        {
            self.Data?.Reset();
            self.Data = null;
        }

        /// <summary>设置基础值</summary>
        public static void Set(this NumericComponent self, int numericType, float value)
        {
            self.Data.SetBase(numericType, value);
        }

        /// <summary>获取最终值</summary>
        public static float Get(this NumericComponent self, int numericType)
        {
            return self.Data.GetFinal(numericType);
        }

        /// <summary>添加属性修饰</summary>
        public static void AddModifier(this NumericComponent self, int numericType, NumericModifier modifier)
        {
            self.Data.AddModifier(numericType, modifier);
        }

        /// <summary>移除属性修饰</summary>
        public static void RemoveModifier(this NumericComponent self, int numericType, string sourceTag)
        {
            self.Data.RemoveModifier(numericType, sourceTag);
        }
    }
}
```

- [ ] **步骤 2：编写服务端 NumericComponentSystem**

```csharp
// 文件: Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/NumericComponentSystem.cs
using System;

namespace ET.Server
{
    [EntitySystemOf(typeof(NumericComponent))]
    [FriendOf(typeof(NumericComponent))]
    public static partial class NumericComponentSystem
    {
        [EntitySystem]
        private static void Awake(this NumericComponent self)
        {
            self.Data = new NumericData();
        }

        [EntitySystem]
        private static void Destroy(this NumericComponent self)
        {
            self.Data?.Reset();
            self.Data = null;
        }

        /// <summary>设置基础值</summary>
        public static void Set(this NumericComponent self, int numericType, float value)
        {
            self.Data.SetBase(numericType, value);
        }

        /// <summary>获取最终值</summary>
        public static float Get(this NumericComponent self, int numericType)
        {
            return self.Data.GetFinal(numericType);
        }

        /// <summary>添加属性修饰</summary>
        public static void AddModifier(this NumericComponent self, int numericType, NumericModifier modifier)
        {
            self.Data.AddModifier(numericType, modifier);
        }

        /// <summary>移除属性修饰</summary>
        public static void RemoveModifier(this NumericComponent self, int numericType, string sourceTag)
        {
            self.Data.RemoveModifier(numericType, sourceTag);
        }
    }
}
```

- [ ] **步骤 3：确认编译通过**

等待 Unity 自动编译，确认无错误。

- [ ] **步骤 4：Commit**

```bash
git add Unity/Assets/Scripts/Hotfix/Client/Module/Numeric/NumericComponentSystem.cs \
       Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/NumericComponentSystem.cs
git commit -m "feat: 实现 Client/Server NumericComponentSystem"
```

---

## 任务 10：运行属性系统测试

**文件：**
- 修改：`Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests/NumericModifierTest.cs`

- [ ] **步骤 1：修复测试文件以使用实际 API**

```csharp
// 文件: Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests/NumericModifierTest.cs
using System;
using ET;

namespace ET.Server
{
    /// <summary>
    /// 属性系统测试运行器。挂载到 Scene 上后自动运行所有测试并输出结果。
    /// 使用方式：在服务端启动流程中临时添加 this.Scene.AddComponent<NumericTestRunner>();
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

            // Test 1: 绝对值加成
            {
                var unit = self.Scene.AddChild<Unit>();
                var comp = unit.AddComponent<NumericComponent>();
                comp.Set(NumericType.MaxHP, 1000f);
                comp.AddModifier(NumericType.MaxHP, new NumericModifier
                {
                    SourceTag = "test_equip_1",
                    ModifyType = NumericModifyType.Absolute,
                    Value = 200f
                });
                float result = comp.Get(NumericType.MaxHP);
                if (Math.Abs(result - 1200f) < 0.01f) { ++passed; Log.Info("[NumericTest] PASS: AddModifier absolute"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: AddModifier absolute, expected 1200 got {result}"); }
                unit.Dispose();
            }

            // Test 2: 相同 SourceTag 替换
            {
                var unit = self.Scene.AddChild<Unit>();
                var comp = unit.AddComponent<NumericComponent>();
                comp.Set(NumericType.ATK, 100f);
                comp.AddModifier(NumericType.ATK, new NumericModifier
                {
                    SourceTag = "test_equip_1",
                    ModifyType = NumericModifyType.Absolute,
                    Value = 50f
                });
                comp.AddModifier(NumericType.ATK, new NumericModifier
                {
                    SourceTag = "test_equip_1",
                    ModifyType = NumericModifyType.Absolute,
                    Value = 80f
                });
                float result = comp.Get(NumericType.ATK);
                if (Math.Abs(result - 180f) < 0.01f) { ++passed; Log.Info("[NumericTest] PASS: ReplaceModifier"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: ReplaceModifier, expected 180 got {result}"); }
                unit.Dispose();
            }

            // Test 3: 百分比加成 + 移除
            {
                var unit = self.Scene.AddChild<Unit>();
                var comp = unit.AddComponent<NumericComponent>();
                comp.Set(NumericType.DEF, 50f);
                comp.AddModifier(NumericType.DEF, new NumericModifier
                {
                    SourceTag = "test_buff_1",
                    ModifyType = NumericModifyType.Percent,
                    Value = 0.2f
                });
                float withBuff = comp.Get(NumericType.DEF);
                if (Math.Abs(withBuff - 60f) < 0.01f) { ++passed; Log.Info("[NumericTest] PASS: AddModifier percent"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: AddModifier percent, expected 60 got {withBuff}"); }

                comp.RemoveModifier(NumericType.DEF, "test_buff_1");
                float removed = comp.Get(NumericType.DEF);
                if (Math.Abs(removed - 50f) < 0.01f) { ++passed; Log.Info("[NumericTest] PASS: RemoveModifier"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: RemoveModifier, expected 50 got {removed}"); }
                unit.Dispose();
            }

            // Test 4: 绝对值 + 百分比叠加
            {
                var unit = self.Scene.AddChild<Unit>();
                var comp = unit.AddComponent<NumericComponent>();
                comp.Set(NumericType.Speed, 100f);
                comp.AddModifier(NumericType.Speed, new NumericModifier
                {
                    SourceTag = "equip_speed",
                    ModifyType = NumericModifyType.Absolute,
                    Value = 20f
                });
                comp.AddModifier(NumericType.Speed, new NumericModifier
                {
                    SourceTag = "buff_speed",
                    ModifyType = NumericModifyType.Percent,
                    Value = 0.5f
                });
                // (100 + 20) * (1 + 0.5) = 120 * 1.5 = 180
                float result = comp.Get(NumericType.Speed);
                if (Math.Abs(result - 180f) < 0.01f) { ++passed; Log.Info("[NumericTest] PASS: Absolute + Percent combined"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: Absolute + Percent, expected 180 got {result}"); }
                unit.Dispose();
            }

            Log.Info($"[NumericTest] === Results: {passed} passed, {failed} failed ===");
            self.Dispose();
        }
    }
}
```

- [ ] **步骤 2：在服务端启动流程中临时添加测试**

找到 ET 8 的服务端 Entry 场景启动代码（通常在 `Hotfix/Server/Demo/Entry/` 下），
在合适位置临时添加测试运行器。具体位置需要查看 ET 8 源码确认。

手动操作：
1. 找到服务端启动入口
2. 添加 `scene.AddComponent<NumericTestRunner>();`
3. 运行服务端，查看 Console 输出

- [ ] **步骤 3：运行测试并确认通过**

启动服务端，检查 Console 输出：
```
[NumericTest] PASS: AddModifier absolute
[NumericTest] PASS: ReplaceModifier
[NumericTest] PASS: AddModifier percent
[NumericTest] PASS: RemoveModifier
[NumericTest] PASS: Absolute + Percent combined
[NumericTest] === Results: 5 passed, 0 failed ===
```

- [ ] **步骤 4：移除临时测试调用，保留测试代码**

从启动入口中移除 `AddComponent<NumericTestRunner>()` 的临时调用。
测试类本身保留在代码中，后续可通过专门的测试入口运行。

- [ ] **步骤 5：Commit**

```bash
git add Unity/Assets/Scripts/Hotfix/Server/Module/Numeric/Tests/NumericModifierTest.cs
git commit -m "feat: 完善属性系统测试用例，5 项测试全部通过"
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
