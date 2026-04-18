//------------------------------------------------------------------------------
// Extension methods for StartSceneConfig
// This file provides ET framework specific computed properties
//------------------------------------------------------------------------------

using System;
using System.Net;

namespace ET
{
    public partial class StartSceneConfig
    {
        /// <summary>
        /// ActorId for this scene, used for actor messaging
        /// </summary>
        public ActorId ActorId => new ActorId(Process, Id);

        /// <summary>
        /// SceneType as enum (converted from string)
        /// </summary>
        public SceneType Type => Enum.Parse<SceneType>(SceneType);

        /// <summary>
        /// Inner IP endpoint (IP:Port) for internal network communication
        /// </summary>
        public IPEndPoint InnerIPPort
        {
            get
            {
                var processConfig = StartProcessConfig;
                var machineConfig = processConfig.MachineConfig;
                return new IPEndPoint(IPAddress.Parse(machineConfig.InnerIP), processConfig.Port);
            }
        }

        /// <summary>
        /// Outer IP endpoint (IP:Port) for external network communication
        /// </summary>
        public IPEndPoint OuterIPPort
        {
            get
            {
                var processConfig = StartProcessConfig;
                var machineConfig = processConfig.MachineConfig;
                return new IPEndPoint(IPAddress.Parse(machineConfig.OuterIP), Port);
            }
        }

        /// <summary>
        /// Reference to the process config for this scene
        /// </summary>
        public StartProcessConfig StartProcessConfig => StartProcessConfigCategory.Instance.Get(Process);
    }
}
