#!/usr/bin/env python3
"""
多平台兼容系统 - 统一应用启动器
自动检测应用类型并路由到相应的兼容层
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path
from typing import Optional, Dict, Any
import platform


# 添加核心模块导入
sys.path.insert(0, str(Path(__file__).parent.parent))
from src.core.config.config_manager import get_config_manager
from src.core.logging.logger import get_logger, setup_logging_from_config


class AppType:
    """应用类型枚举"""
    LINUX = 'linux'
    WINDOWS = 'windows'
    MACOS = 'macos'
    UNKNOWN = 'unknown'


class AppLauncher:
    """统一应用启动器"""
    
    def __init__(self):
        self.config = get_config_manager()
        self.logger = get_logger('launcher')
        setup_logging_from_config(self.config)
    
    def detect_app_type(self, app_path: str) -> AppType:
        """检测应用类型"""
        if not os.path.exists(app_path):
            self.logger.error(f'Application not found', path=app_path)
            return AppType.UNKNOWN
        
        path = Path(app_path)
        
        # 检查文件扩展名
        ext = path.suffix.lower()
        
        ext_map = {
            '.exe': AppType.WINDOWS,
            '.msi': AppType.WINDOWS,
            '.bat': AppType.WINDOWS,
            '.app': AppType.MACOS,
            '.dmg': AppType.MACOS,
            '.pkg': AppType.MACOS,
        }
        
        if ext in ext_map:
            return ext_map[ext]
        
        # 检查 Linux ELF 检测
        if self._is_elf_binary(app_path):
            return AppType.LINUX
        
        # 检查 Windows PE 检测
        if self._is_pe_binary(app_path):
            return AppType.WINDOWS
        
        # 检查 macOS Mach-O
        if self._is_macho_binary(app_path):
            return AppType.MACOS
        
        # 检查是否为目录
        if path.is_dir():
            # 检查是否为 macOS .app bundle
            if (path / 'Contents' / 'Info.plist').exists():
                return AppType.MACOS
        
        return AppType.UNKNOWN
    
    def _is_elf_binary(self, path: str) -> bool:
        """检查是否为 ELF 二进制文件"""
        try:
            with open(path, 'rb') as f:
                magic = f.read(4)
                return magic == b'\x7fELF'
        except:
            return False
    
    def _is_pe_binary(self, path: str) -> bool:
        """检查是否为 PE 二进制文件"""
        try:
            with open(path, 'rb') as f:
                magic = f.read(2)
                return magic == b'MZ'
        except:
            return False
    
    def _is_macho_binary(self, path: str) -> bool:
        """检查是否为 Mach-O 二进制文件"""
        try:
            with open(path, 'rb') as f:
                magic = f.read(4)
                macho_magics = [
                    b'\xca\xfe\xba\xbe',  # 32-bit
                    b'\xcf\xfa\xed\xfe',  # 64-bit
                    b'\xca\xfe\xba\xbf',  # 32-bit big-endian
                    b'\xcf\xfa\xed\xfe',  # 64-bit big-endian
                ]
                return magic in macho_magics
        except:
            return False
    
    def launch_linux_app(self, app_path: str, args: list) -> int:
        """启动 Linux 原生应用"""
        self.logger.info('Launching Linux application', path=app_path, args=args)
        
        try:
            # 确保可执行
            if not os.access(app_path, os.X_OK):
                os.chmod(app_path, 0o755)
            
            # 构建环境
            env = os.environ.copy()
            env.update(self.config.export_to_env())
            
            # 启动应用
            process = subprocess.Popen([app_path] + args, env=env)
            return process.wait()
            
        except Exception as e:
            self.logger.error('Failed to launch Linux app', error=str(e))
            return 1
    
    def launch_windows_app(self, app_path: str, args: list) -> int:
        """启动 Windows 应用 (使用 Wine)"""
        self.logger.info('Launching Windows application', path=app_path, args=args)
        
        windows_config = self.config.get_platform_config('windows')
        prefix = os.path.expanduser(windows_config.get('prefix', '~/.wine'))
        
        # 构建 Wine 环境
        env = os.environ.copy()
        env['WINEPREFIX'] = prefix
        
        # 性能优化
        if windows_config.get('esync', True):
            env['WINEESYNC'] = '1'
        if windows_config.get('fsync', True):
            env['WINEFSYNC'] = '1'
        
        # DXVK
        if self.config.get('performance.dxvk', True):
            env['DXVK_STATE_CACHE'] = '1'
        
        # 音频配置
        audio_driver = windows_config.get('audio_driver', 'pulse')
        env['WINE_DRIVER'] = audio_driver
        
        try:
            # 使用 Wine 启动
            wine_cmd = ['wine']
            if app_path.lower().endswith('.msi'):
                wine_cmd = ['msiexec', '/i']
            
            process = subprocess.Popen(wine_cmd + [app_path] + args, env=env)
            return process.wait()
            
        except Exception as e:
            self.logger.error('Failed to launch Windows app', error=str(e))
            return 1
    
    def launch_macos_app(self, app_path: str, args: list) -> int:
        """启动 macOS 应用 (使用 Darling)"""
        self.logger.info('Launching macOS application', path=app_path, args=args)
        
        macos_config = self.config.get_platform_config('macos')
        prefix = os.path.expanduser(macos_config.get('prefix', '~/.darling'))
        
        env = os.environ.copy()
        env['DPREFIX'] = prefix
        
        try:
            darling_cmd = ['darling']
            
            # 如果是 .app bundle
            path = Path(app_path)
            if path.is_dir() and path.suffix == '.app':
                # 使用 open 命令
                darling_cmd.extend(['open', app_path])
            else:
                darling_cmd.extend([app_path])
            
            darling_cmd.extend(args)
            process = subprocess.Popen(darling_cmd, env=env)
            return process.wait()
            
        except Exception as e:
            self.logger.error('Failed to launch macOS app', error=str(e))
            return 1
    
    def launch(self, app_path: str, args: list = None) -> int:
        """启动应用的主入口"""
        if args is None:
            args = []
        
        # 检测应用类型
        app_type = self.detect_app_type(app_path)
        
        if app_type == AppType.UNKNOWN:
            self.logger.error('Could not detect application type', path=app_path)
            print(f"Error: Could not detect application type for {app_path}")
            return 1
        
        # 根据类型启动
        launch_functions = {
            AppType.LINUX: self.launch_linux_app,
            AppType.WINDOWS: self.launch_windows_app,
            AppType.MACOS: self.launch_macos_app,
        }
        
        launch_func = launch_functions.get(app_type)
        if launch_func:
            return launch_func(app_path, args)
        
        return 1


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description='Multi-OS Compatibility System - Unified App Launcher',
        epilog='Example: %(prog)s /path/to/application.exe arg1 arg2'
    )
    parser.add_argument(
        'app_path',
        help='Path to the application to launch'
    )
    parser.add_argument(
        'app_args',
        nargs='*',
        help='Arguments to pass to the application'
    )
    parser.add_argument(
        '--config',
        help='Path to custom configuration file'
    )
    parser.add_argument(
        '--type',
        choices=['linux', 'windows', 'macos'],
        help='Force application type (auto-detected if not specified)'
    )
    parser.add_argument(
        '--verbose',
        '-v',
        action='store_true',
        help='Enable verbose logging'
    )
    
    args = parser.parse_args()
    
    # 初始化
    launcher = AppLauncher()
    
    if args.verbose:
        launcher.logger.set_level(10)  # DEBUG
    
    # 强制类型
    if args.type:
        # 绕过检测，直接指定类型
        type_map = {
            'linux': AppType.LINUX,
            'windows': AppType.WINDOWS,
            'macos': AppType.MACOS,
        }
        
        app_type = type_map[args.type]
        launcher.logger.info('Forced application type', type=app_type)
        
        # 直接调用对应启动函数
        launch_functions = {
            AppType.LINUX: launcher.launch_linux_app,
            AppType.WINDOWS: launcher.launch_windows_app,
            AppType.MACOS: launcher.launch_macos_app,
        }
        
        launch_func = launch_functions[app_type]
        return_code = launch_func(args.app_path, args.app_args)
    else:
        # 自动检测并启动
        return_code = launcher.launch(args.app_path, args.app_args)
    
    sys.exit(return_code)


if __name__ == '__main__':
    main()
