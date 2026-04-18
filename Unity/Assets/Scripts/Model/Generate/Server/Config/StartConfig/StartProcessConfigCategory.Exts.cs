//------------------------------------------------------------------------------
// Extension methods for StartProcessConfigCategory
//------------------------------------------------------------------------------

using System.Collections.Generic;

namespace ET
{
    public partial class StartProcessConfigCategory
    {
        /// <summary>
        /// Get all process configs as a dictionary
        /// </summary>
        public Dictionary<int, StartProcessConfig> GetAll() => DataMap;
    }
}
