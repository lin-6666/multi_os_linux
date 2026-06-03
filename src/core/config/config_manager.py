#!/usr/bin/env python3
"""
多平台兼容系统 - 统一配置管理器
实现配置的层级加载、验证和访问
"""

import os
import yaml
import json
from typing import Dict, Any, Optional, List
from pathlib import Path


class ConfigManager:
    """统一配置管理器"""
    
    # 配置层级优先级 (从低到高)
    CONFIG_PATHS = [
        ('system', '/etc/multi-os/config.yaml'),
        ('project', 'config/defaults/config.yaml'),
        ('user', os.path.expanduser('~/.multi-os/config.yaml')),
    ]
    
    def __init__(self, config_file: Optional[str] = None):
        self.config: Dict[str, Any] = {}
        self.config_sources: Dict[str, Dict[str, Any]] = {}
        self._load_configs(config_file)
    
    def _load_configs(self, override_file: Optional[str] = None):
        """加载所有层级的配置"""
        # 加载默认配置
        self._load_defaults()
        
        # 加载各层级配置
        for source_name, config_path in self.CONFIG_PATHS:
            if os.path.exists(config_path):
                try:
                    with open(config_path, 'r', encoding='utf-8') as f:
                        config_data = yaml.safe_load(f)
                        if config_data:
                            self.config_sources[source_name] = config_data
                            self._merge_config(config_data)
                except Exception as e:
                    print(f"[WARN] Failed to load {source_name} config: {e}")
        
        # 加载覆盖配置
        if override_file and os.path.exists(override_file):
            try:
                with open(override_file, 'r', encoding='utf-8') as f:
                    override_data = yaml.safe_load(f)
                    if override_data:
                        self._merge_config(override_data)
            except Exception as e:
                print(f"[WARN] Failed to load override config: {e}")
    
    def _load_defaults(self):
        """加载默认配置"""
        self.config = {
            'system': {
                'log_level': 'info',
                'data_dir': '/var/lib/multi-os',
                'temp_dir': '/tmp/multi-os',
            },
            'platforms': {
                'windows': {
                    'enabled': True,
                    'prefix': '~/.multi-os/wine',
                    'audio_driver': 'pulse,alsa,oss',
                    'video_memory': 1024,
                },
                'macos': {
                    'enabled': True,
                    'prefix': '~/.multi-os/darling',
                },
                'linux': {
                    'enabled': True,
                }
            },
            'performance': {
                'esync': True,
                'fsync': True,
                'dxvk': True,
            },
            'logging': {
                'file': '~/.multi-os/logs/multi-os.log',
                'max_size': '10M',
                'backup_count': 5,
            }
        }
    
    def _merge_config(self, source: Dict[str, Any]):
        """递归合并配置"""
        def merge_dict(target: Dict, src: Dict):
            for key, value in src.items():
                if key in target and isinstance(target[key], dict) and isinstance(value, dict):
                    merge_dict(target[key], value)
                else:
                    target[key] = value
        
        merge_dict(self.config, source)
    
    def get(self, key_path: str, default: Any = None) -> Any:
        """获取配置值，支持点号路径"""
        keys = key_path.split('.')
        value = self.config
        
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default
        
        return value
    
    def set(self, key_path: str, value: Any):
        """设置配置值"""
        keys = key_path.split('.')
        config = self.config
        
        for key in keys[:-1]:
            if key not in config:
                config[key] = {}
            config = config[key]
        
        config[keys[-1]] = value
    
    def get_platform_config(self, platform: str) -> Dict[str, Any]:
        """获取特定平台的配置"""
        return self.get(f'platforms.{platform}', {})
    
    def save_user_config(self) -> bool:
        """保存用户配置"""
        user_config_path = os.path.expanduser('~/.multi-os/config.yaml')
        os.makedirs(os.path.dirname(user_config_path), exist_ok=True)
        
        try:
            with open(user_config_path, 'w', encoding='utf-8') as f:
                yaml.dump(self.config, f, default_flow_style=False, allow_unicode=True)
            return True
        except Exception as e:
            print(f"[ERROR] Failed to save config: {e}")
            return False
    
    def export_to_env(self) -> Dict[str, str]:
        """导出配置为环境变量"""
        env_vars = {}
        
        def flatten_dict(prefix: str, d: Dict):
            for key, value in d.items():
                full_key = f"{prefix}_{key.upper()}" if prefix else key.upper()
                if isinstance(value, dict):
                    flatten_dict(full_key, value)
                elif isinstance(value, bool):
                    env_vars[full_key] = '1' if value else '0'
                else:
                    env_vars[full_key] = str(value)
        
        flatten_dict('MOS', self.config)
        return env_vars
    
    def validate(self) -> List[str]:
        """验证配置，返回错误列表"""
        errors = []
        
        # 验证必要的配置
        required_platforms = ['windows', 'macos', 'linux']
        for platform in required_platforms:
            if not self.get(f'platforms.{platform}'):
                errors.append(f"Missing config for platform: {platform}")
        
        # 验证路径
        data_dir = self.get('system.data_dir')
        if data_dir and not os.path.isabs(os.path.expanduser(data_dir)):
            errors.append("Data directory must be absolute path")
        
        return errors


# 全局配置管理器实例
_config_manager: Optional[ConfigManager] = None


def get_config_manager(config_file: Optional[str] = None) -> ConfigManager:
    """获取全局配置管理器实例"""
    global _config_manager
    if _config_manager is None:
        _config_manager = ConfigManager(config_file)
    return _config_manager


if __name__ == '__main__':
    # 简单的测试代码
    config = get_config_manager()
    print("=== Configuration ===")
    print(f"Log level: {config.get('system.log_level')}")
    print(f"Windows enabled: {config.get('platforms.windows.enabled')}")
    print(f"Esync enabled: {config.get('performance.esync')}")
    
    errors = config.validate()
    if errors:
        print("\n=== Validation Errors ===")
        for error in errors:
            print(f"- {error}")
    else:
        print("\nValidation passed!")
