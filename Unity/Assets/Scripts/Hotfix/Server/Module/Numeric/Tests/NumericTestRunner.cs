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

            // 创建 UnitComponent 作为 Unit 容器
            var unitComponent = self.Scene().AddComponent<UnitComponent>();

            // Test 1: ET 8 内置 5 槽位计算
            // 公式: ((base + add) * (100 + pct) / 100 + finalAdd) * (100 + finalPct) / 100
            // pct 槽位：20 表示 +20%，即公式中 (100 + 20) / 100 = 1.2
            {
                var unit = unitComponent.AddChildWithId<Unit, int>(IdGenerater.Instance.GenerateInstanceId(), 1001);
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
                var unit = unitComponent.AddChildWithId<Unit, int>(IdGenerater.Instance.GenerateInstanceId(), 1001);
                unit.AddComponent<NumericComponent>();
                var modComp = unit.AddComponent<NumericModifierComponent>();

                unit.GetComponent<NumericComponent>().Set(NumericType.ATKBase, 100f);

                modComp.Add("equip_weapon_1", NumericType.ATKAdd, (long)(80f * 10000));

                float result = unit.GetComponent<NumericComponent>().GetAsFloat(NumericType.ATK);
                if (Math.Abs(result - 180f) < 0.1f) { ++passed; Log.Info("[NumericTest] PASS: ModifierComponent add"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: ModifierComponent add, expected 180 got {result}"); }
                unit.Dispose();
            }

            // Test 3: NumericModifierComponent 替换来源修饰
            {
                var unit = unitComponent.AddChildWithId<Unit, int>(IdGenerater.Instance.GenerateInstanceId(), 1001);
                unit.AddComponent<NumericComponent>();
                var modComp = unit.AddComponent<NumericModifierComponent>();

                unit.GetComponent<NumericComponent>().Set(NumericType.ATKBase, 100f);

                modComp.Add("equip_weapon_1", NumericType.ATKAdd, (long)(50f * 10000));
                modComp.Add("equip_weapon_1", NumericType.ATKAdd, (long)(80f * 10000));

                float result = unit.GetComponent<NumericComponent>().GetAsFloat(NumericType.ATK);
                if (Math.Abs(result - 180f) < 0.1f) { ++passed; Log.Info("[NumericTest] PASS: ModifierComponent replace"); }
                else { ++failed; Log.Error($"[NumericTest] FAIL: ModifierComponent replace, expected 180 got {result}"); }
                unit.Dispose();
            }

            // Test 4: NumericModifierComponent 移除来源修饰
            {
                var unit = unitComponent.AddChildWithId<Unit, int>(IdGenerater.Instance.GenerateInstanceId(), 1001);
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
                var unit = unitComponent.AddChildWithId<Unit, int>(IdGenerater.Instance.GenerateInstanceId(), 1001);
                unit.AddComponent<NumericComponent>();
                var modComp = unit.AddComponent<NumericModifierComponent>();

                unit.GetComponent<NumericComponent>().Set(NumericType.ATKBase, 100f);

                var records = new List<NumericModifierRecord>
                {
                    new NumericModifierRecord { NumericType = NumericType.ATK, SlotType = NumericType.ATKAdd, Value = (long)(20f * 10000) },
                    new NumericModifierRecord { NumericType = NumericType.ATK, SlotType = NumericType.ATKPct, Value = (long)(50f * 10000) },
                };
                modComp.Add("equip_ring_1", records);

                // (100 + 20) * (100 + 50) / 100 = 120 * 1.5 = 180
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
