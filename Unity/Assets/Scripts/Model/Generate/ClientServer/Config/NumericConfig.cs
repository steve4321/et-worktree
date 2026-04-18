using System;
using System.Collections.Generic;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Bson.Serialization.Options;
using System.ComponentModel;

namespace ET
{
    [Config]
    public partial class NumericConfigCategory : Singleton<NumericConfigCategory>, IMerge
    {
        [BsonElement]
        [BsonDictionaryOptions(DictionaryRepresentation.ArrayOfArrays)]
        private Dictionary<int, NumericConfig> dict = new();

        public void Merge(object o)
        {
            NumericConfigCategory s = o as NumericConfigCategory;
            foreach (var kv in s.dict)
            {
                this.dict.Add(kv.Key, kv.Value);
            }
        }

        public NumericConfig Get(int id)
        {
            this.dict.TryGetValue(id, out NumericConfig item);

            if (item == null)
            {
                throw new Exception($"配置找不到，配置表名: {nameof(NumericConfig)}，配置id: {id}");
            }

            return item;
        }

        public bool Contain(int id)
        {
            return this.dict.ContainsKey(id);
        }

        public Dictionary<int, NumericConfig> GetAll()
        {
            return this.dict;
        }
    }

    public partial class NumericConfig : ProtoObject, IConfig
    {
        /// <summary>属性类型ID，对应 NumericType 常量</summary>
        public int Id { get; set; }
        /// <summary>属性名称</summary>
        public string Name { get; set; }
        /// <summary>最大值上限</summary>
        public float MaxValue { get; set; }
        /// <summary>默认值</summary>
        public float DefaultValue { get; set; }
    }
}
