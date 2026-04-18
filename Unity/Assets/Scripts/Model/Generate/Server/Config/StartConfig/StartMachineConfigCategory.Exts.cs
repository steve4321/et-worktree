//------------------------------------------------------------------------------
// Extension methods for StartMachineConfigCategory
//------------------------------------------------------------------------------

using System.Collections.Generic;

namespace ET
{
    public partial class StartMachineConfigCategory
    {
        /// <summary>
        /// Get all machine configs as a dictionary
        /// </summary>
        public Dictionary<int, StartMachineConfig> GetAll() => DataMap;
    }
}
