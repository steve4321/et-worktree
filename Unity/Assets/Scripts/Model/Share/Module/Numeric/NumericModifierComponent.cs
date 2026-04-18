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
