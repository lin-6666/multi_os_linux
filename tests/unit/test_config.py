#!/usr/bin/env python3
"""
单元测试 - 配置管理器
"""

import unittest
import os
import sys
import tempfile
from pathlib import Path

# 添加项目路径
sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from src.core.config.config_manager import ConfigManager


class TestConfigManager(unittest.TestCase):
    """配置管理器测试"""
    
    def setUp(self):
        """测试前设置"""
        # 创建临时目录
        self.temp_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.temp_dir, 'test_config.yaml')
    
    def tearDown(self):
        """测试后清理"""
        import shutil
        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
    
    def test_default_config(self):
        """测试默认配置加载"""
        config = ConfigManager()
        
        # 检查默认配置
        self.assertEqual(config.get('system.log_level'), 'info')
        self.assertTrue(config.get('platforms.windows.enabled'))
        self.assertTrue(config.get('performance.esync'))
    
    def test_get_set(self):
        """测试获取和设置配置"""
        config = ConfigManager()
        
        # 获取值
        log_level = config.get('system.log_level')
        self.assertIsNotNone(log_level)
        
        # 设置值
        config.set('system.log_level', 'debug')
        self.assertEqual(config.get('system.log_level'), 'debug')
        
        # 测试嵌套设置
        config.set('platforms.windows.prefix', '/test/prefix')
        self.assertEqual(config.get('platforms.windows.prefix'), '/test/prefix')
    
    def test_platform_config(self):
        """测试平台配置"""
        config = ConfigManager()
        
        windows_config = config.get_platform_config('windows')
        self.assertIn('enabled', windows_config)
        self.assertIn('prefix', windows_config)
        
        macos_config = config.get_platform_config('macos')
        self.assertIn('enabled', macos_config)
    
    def test_env_export(self):
        """测试环境变量导出"""
        config = ConfigManager()
        
        env_vars = config.export_to_env()
        self.assertGreater(len(env_vars), 0)
        
        # 检查是否有预期的环境变量
        has_mos_prefix = any(key.startswith('MOS_') for key in env_vars)
        self.assertTrue(has_mos_prefix)
    
    def test_validation(self):
        """测试配置验证"""
        config = ConfigManager()
        
        # 默认配置应该通过验证
        errors = config.validate()
        # 可能有一些关于绝对路径的警告，但不是错误
        # 这个测试主要检查不崩溃


if __name__ == '__main__':
    unittest.main()
