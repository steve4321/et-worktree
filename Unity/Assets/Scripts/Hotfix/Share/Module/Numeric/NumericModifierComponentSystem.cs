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
            int finalType = slotType / 10;

            var numericComp = self.GetParent<Unit>().GetComponent<NumericComponent>();
            if (numericComp == null) return;

            // 如果该来源已有修饰记录，先移除旧的
            if (self.Modifiers.TryGetValue(sourceTag, out var oldRecords))
            {
                foreach (var record in oldRecords)
                {
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
