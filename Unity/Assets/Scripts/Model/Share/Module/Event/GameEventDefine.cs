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
        public int CollectibleType; // 1=宝物, 2=宠物, 3=时装
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
