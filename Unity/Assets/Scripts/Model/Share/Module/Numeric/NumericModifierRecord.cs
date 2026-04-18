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
