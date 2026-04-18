//------------------------------------------------------------------------------
// Extension methods for StartProcessConfig
//------------------------------------------------------------------------------

using System.Net;

namespace ET
{
    public partial class StartProcessConfig
    {
        /// <summary>
        /// IP endpoint for this process (InnerIP:Port)
        /// </summary>
        public IPEndPoint IPEndPoint => new IPEndPoint(IPAddress.Parse(MachineConfig.InnerIP), Port);

        /// <summary>
        /// Inner IP address (delegated from machine config)
        /// </summary>
        public string InnerIP => MachineConfig.InnerIP;

        /// <summary>
        /// Outer IP address (delegated from machine config)
        /// </summary>
        public string OuterIP => MachineConfig.OuterIP;

        /// <summary>
        /// Reference to the machine config for this process
        /// </summary>
        public StartMachineConfig MachineConfig => StartMachineConfigCategory.Instance.Get(MachineId);
    }
}
