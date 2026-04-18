//------------------------------------------------------------------------------
// Extension methods for AIConfigCategory
//------------------------------------------------------------------------------

using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace ET
{
    /// <summary>
    /// Wrapper class to provide .Values interface for AI config groups
    /// </summary>
    [EnableClass]
    public class AIConfigGroup : IEnumerable<AIConfig>
    {
        public List<AIConfig> Values { get; }

        public AIConfigGroup(List<AIConfig> values)
        {
            Values = values;
        }

        public IEnumerator<AIConfig> GetEnumerator() => Values.GetEnumerator();
        IEnumerator IEnumerable.GetEnumerator() => Values.GetEnumerator();
    }

    public partial class AIConfigCategory
    {
        private Dictionary<int, AIConfigGroup> _aiConfigGroups;

        /// <summary>
        /// AI configs grouped by AIConfigId
        /// </summary>
        public Dictionary<int, AIConfigGroup> AIConfigs
        {
            get
            {
                if (_aiConfigGroups == null)
                {
                    _aiConfigGroups = DataList
                        .GroupBy(x => x.AIConfigId)
                        .ToDictionary(
                            g => g.Key,
                            g => new AIConfigGroup(g.OrderBy(x => x.Order).ToList())
                        );
                }
                return _aiConfigGroups;
            }
        }
    }
}
