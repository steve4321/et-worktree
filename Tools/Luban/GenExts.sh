#!/bin/bash
# Script to regenerate Exts files after Luban generation
# These files provide ET framework specific extensions that Luban cannot generate

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXT_DIR="$WORKSPACE/Unity/Assets/Scripts/Model/Generate/Server/Config"

echo "===================== Regenerating Exts Files ===================="

# StartSceneConfig.Exts.cs
cat > "$EXT_DIR/StartConfig/StartSceneConfig.Exts.cs" << 'EOF'
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
EOF
echo "Created StartSceneConfig.Exts.cs"

# StartSceneConfigCategory.Exts.cs
cat > "$EXT_DIR/StartConfig/StartSceneConfigCategory.Exts.cs" << 'EOF'
//------------------------------------------------------------------------------
// Extension methods for StartSceneConfigCategory
// This file provides ET framework specific computed properties and lookup methods
//------------------------------------------------------------------------------

using System;
using System.Collections.Generic;
using System.Linq;

namespace ET
{
    public partial class StartSceneConfigCategory
    {
        private Dictionary<int, List<StartSceneConfig>> _gates;
        private List<StartSceneConfig> _realms;
        private List<StartSceneConfig> _routers;
        private List<StartSceneConfig> _maps;
        private StartSceneConfig _match;
        private StartSceneConfig _locationConfig;
        private StartSceneConfig _benchmark;

        /// <summary>
        /// Get all scenes by process id
        /// </summary>
        public List<StartSceneConfig> GetByProcess(int processId)
        {
            return DataList.FindAll(s => s.Process == processId);
        }

        /// <summary>
        /// Get scene by scene name within a zone
        /// </summary>
        public StartSceneConfig GetBySceneName(int zone, string name)
        {
            return DataList.Find(s => s.Zone == zone && s.Name == name);
        }

        /// <summary>
        /// All gate scenes grouped by zone
        /// </summary>
        public Dictionary<int, List<StartSceneConfig>> Gates
        {
            get
            {
                if (_gates == null)
                {
                    _gates = new Dictionary<int, List<StartSceneConfig>>();
                    foreach (var scene in DataList)
                    {
                        if (scene.SceneType == "Gate")
                        {
                            if (!_gates.TryGetValue(scene.Zone, out var list))
                            {
                                list = new List<StartSceneConfig>();
                                _gates[scene.Zone] = list;
                            }
                            list.Add(scene);
                        }
                    }
                }
                return _gates;
            }
        }

        /// <summary>
        /// All realm scenes
        /// </summary>
        public List<StartSceneConfig> Realms
        {
            get
            {
                if (_realms == null)
                {
                    _realms = DataList.FindAll(s => s.SceneType == "Realm");
                }
                return _realms;
            }
        }

        /// <summary>
        /// All router scenes
        /// </summary>
        public List<StartSceneConfig> Routers
        {
            get
            {
                if (_routers == null)
                {
                    _routers = DataList.FindAll(s => s.SceneType == "Router");
                }
                return _routers;
            }
        }

        /// <summary>
        /// All map scenes
        /// </summary>
        public List<StartSceneConfig> Maps
        {
            get
            {
                if (_maps == null)
                {
                    _maps = DataList.FindAll(s => s.SceneType == "Map");
                }
                return _maps;
            }
        }

        /// <summary>
        /// Match scene
        /// </summary>
        public StartSceneConfig Match
        {
            get
            {
                if (_match == null)
                {
                    _match = DataList.Find(s => s.SceneType == "Match");
                }
                return _match;
            }
        }

        /// <summary>
        /// Location config scene
        /// </summary>
        public StartSceneConfig LocationConfig
        {
            get
            {
                if (_locationConfig == null)
                {
                    _locationConfig = DataList.Find(s => s.SceneType == "Location");
                }
                return _locationConfig;
            }
        }

        /// <summary>
        /// Benchmark scene
        /// </summary>
        public StartSceneConfig Benchmark
        {
            get
            {
                if (_benchmark == null)
                {
                    _benchmark = DataList.Find(s => s.SceneType == "Benchmark");
                }
                return _benchmark;
            }
        }
    }
}
EOF
echo "Created StartSceneConfigCategory.Exts.cs"

# StartProcessConfig.Exts.cs
cat > "$EXT_DIR/StartConfig/StartProcessConfig.Exts.cs" << 'EOF'
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
EOF
echo "Created StartProcessConfig.Exts.cs"

# StartProcessConfigCategory.Exts.cs
cat > "$EXT_DIR/StartConfig/StartProcessConfigCategory.Exts.cs" << 'EOF'
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
EOF
echo "Created StartProcessConfigCategory.Exts.cs"

# StartMachineConfigCategory.Exts.cs
cat > "$EXT_DIR/StartConfig/StartMachineConfigCategory.Exts.cs" << 'EOF'
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
EOF
echo "Created StartMachineConfigCategory.Exts.cs"

# AIConfigCategory.Exts.cs
cat > "$EXT_DIR/AIConfigCategory.Exts.cs" << 'EOF'
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
EOF
echo "Created AIConfigCategory.Exts.cs"

echo "===================== Exts Files Regenerated ===================="
