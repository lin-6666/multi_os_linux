#!/usr/bin/env python3
"""
多平台兼容系统 (Multi-OS Compatibility System) - 主入口
"""

import sys
import os
import argparse
from pathlib import Path

# 添加项目路径
sys.path.insert(0, str(Path(__file__).parent))

from src.core.config.config_manager import get_config_manager
from src.core.logging.logger import get_logger, setup_logging_from_config


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description='Multi-OS Compatibility System',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s launch /path/to/app.exe          # Launch an application
  %(prog)s config set system.log_level debug  # Configure the system
  %(prog)s build                           # Build components
        """
    )
    
    # 子命令
    subparsers = parser.add_subparsers(title='Commands', dest='command')
    
    # launch 命令
    launch_parser = subparsers.add_parser('launch', help='Launch an application')
    launch_parser.add_argument('app_path', help='Path to application')
    launch_parser.add_argument('app_args', nargs='*', help='Application arguments')
    launch_parser.add_argument('--type', choices=['linux', 'windows', 'macos'], 
                            help='Force application type')
    launch_parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    # config 命令
    config_parser = subparsers.add_parser('config', help='Manage configuration')
    config_subparsers = config_parser.add_subparsers(dest='config_command')
    
    config_get_parser = config_subparsers.add_parser('get', help='Get configuration value')
    config_get_parser.add_argument('key', help='Configuration key (dot-separated)')
    
    config_set_parser = config_subparsers.add_parser('set', help='Set configuration value')
    config_set_parser.add_argument('key', help='Configuration key (dot-separated)')
    config_set_parser.add_argument('value', help='Configuration value')
    
    config_list_parser = config_subparsers.add_parser('list', help='List all configuration')
    
    # build 命令
    build_parser = subparsers.add_parser('build', help='Build system components')
    build_parser.add_argument('phase', nargs='*', 
                            choices=['dependencies', 'configure', 'compile', 'test', 'install', 'clean', 'all'],
                            default=['all'], help='Build phases')
    build_parser.add_argument('--jobs', '-j', type=int, help='Parallel jobs')
    build_parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    # test 命令
    test_parser = subparsers.add_parser('test', help='Run tests')
    test_parser.add_argument('test_type', nargs='?', choices=['unit', 'integration', 'all'],
                           default='all', help='Test type')
    
    args = parser.parse_args()
    
    # 初始化
    config = get_config_manager()
    logger = get_logger('mos')
    setup_logging_from_config(config)
    
    if args.command == 'launch':
        # 启动应用
        from src.launcher.app_launcher import AppLauncher
        
        launcher = AppLauncher()
        if args.verbose:
            launcher.logger.set_level(10)
        
        if args.type:
            # 强制类型
            from src.launcher.app_launcher import AppType
            type_map = {
                'linux': AppType.LINUX,
                'windows': AppType.WINDOWS,
                'macos': AppType.MACOS,
            }
            app_type = type_map[args.type]
            launch_funcs = {
                AppType.LINUX: launcher.launch_linux_app,
                AppType.WINDOWS: launcher.launch_windows_app,
                AppType.MACOS: launcher.launch_macos_app,
            }
            return_code = launch_funcs[app_type](args.app_path, args.app_args)
        else:
            return_code = launcher.launch(args.app_path, args.app_args)
        sys.exit(return_code)
    
    elif args.command == 'config':
        # 配置管理
        if args.config_command == 'get':
            value = config.get(args.key)
            print(f"{args.key} = {value}")
        elif args.config_command == 'set':
            config.set(args.key, args.value)
            print(f"Set {args.key} = {args.value}")
            config.save_user_config()
        elif args.config_command == 'list':
            import json
            print(json.dumps(config.config, indent=2, ensure_ascii=False))
    
    elif args.command == 'build':
        # 构建
        from scripts.build.build_system import BuildSystem
        build_system = BuildSystem('.')
        
        if args.verbose:
            build_system.logger.set_level(10)
        
        if args.jobs:
            build_system.build_config['parallel_jobs'] = args.jobs
        
        if 'clean' in args.phase:
            build_system.clean()
        else:
            phases = None if 'all' in args.phase else args.phase
            success = build_system.build(phases)
            sys.exit(0 if success else 1)
    
    elif args.command == 'test':
        # 测试
        import unittest
        
        loader = unittest.TestLoader()
        start_dir = 'tests'
        
        if args.test_type == 'unit':
            start_dir = 'tests/unit'
        elif args.test_type == 'integration':
            start_dir = 'tests/integration'
        
        suite = loader.discover(start_dir)
        runner = unittest.TextTestRunner(verbosity=2)
        result = runner.run(suite)
        sys.exit(0 if result.wasSuccessful() else 1)
    
    else:
        # 默认显示帮助
        parser.print_help()


if __name__ == '__main__':
    main()
