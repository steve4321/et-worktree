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
