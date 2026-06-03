#!/usr/bin/env python3
"""
多平台兼容系统 - 统一日志系统
提供结构化的日志记录功能
"""

import os
import sys
import logging
import logging.handlers
from datetime import datetime
from typing import Optional, Dict, Any
from pathlib import Path


class LogLevel:
    """日志级别常量"""
    DEBUG = logging.DEBUG
    INFO = logging.INFO
    WARNING = logging.WARNING
    ERROR = logging.ERROR
    CRITICAL = logging.CRITICAL


class MOSLogger:
    """多平台兼容系统日志器"""
    
    _instances: Dict[str, 'MOSLogger'] = {}
    _root_logger: Optional[logging.Logger] = None
    
    def __init__(self, name: str = 'multi-os'):
        self.name = name
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.DEBUG)
        self.logger.propagate = False
        self._handlers: Dict[str, logging.Handler] = {}
        self._setup_default_handlers()
    
    @classmethod
    def get_logger(cls, name: str = 'multi-os') -> 'MOSLogger':
        """获取或创建日志器实例"""
        if name not in cls._instances:
            cls._instances[name] = MOSLogger(name)
        return cls._instances[name]
    
    def _setup_default_handlers(self):
        """设置默认的日志处理器"""
        # 控制台处理器
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        console_formatter = logging.Formatter(
            '[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        console_handler.setFormatter(console_formatter)
        self.logger.addHandler(console_handler)
        self._handlers['console'] = console_handler
    
    def add_file_handler(
        self,
        file_path: str,
        level: int = LogLevel.INFO,
        max_bytes: int = 10 * 1024 * 1024,  # 10MB
        backup_count: int = 5
    ):
        """添加文件日志处理器"""
        file_path = os.path.expanduser(file_path)
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        file_handler = logging.handlers.RotatingFileHandler(
            file_path,
            maxBytes=max_bytes,
            backupCount=backup_count,
            encoding='utf-8'
        )
        file_handler.setLevel(level)
        file_formatter = logging.Formatter(
            '[%(asctime)s] [%(levelname)s] [%(name)s] [%(module)s:%(lineno)d] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        file_handler.setFormatter(file_formatter)
        self.logger.addHandler(file_handler)
        self._handlers['file'] = file_handler
    
    def set_level(self, level: int):
        """设置日志级别"""
        self.logger.setLevel(level)
        for handler in self.logger.handlers:
            handler.setLevel(level)
    
    def debug(self, msg: str, *args, **kwargs):
        """记录调试日志"""
        self.logger.debug(msg, *args, **kwargs)
    
    def info(self, msg: str, *args, **kwargs):
        """记录信息日志"""
        self.logger.info(msg, *args, **kwargs)
    
    def warning(self, msg: str, *args, **kwargs):
        """记录警告日志"""
        self.logger.warning(msg, *args, **kwargs)
    
    def error(self, msg: str, *args, **kwargs):
        """记录错误日志"""
        self.logger.error(msg, *args, **kwargs)
    
    def critical(self, msg: str, *args, **kwargs):
        """记录严重错误日志"""
        self.logger.critical(msg, *args, **kwargs)
    
    def exception(self, msg: str, *args, **kwargs):
        """记录异常日志"""
        self.logger.exception(msg, *args, **kwargs)


class StructuredLogger(MOSLogger):
    """结构化日志器，支持键值对日志"""
    
    def _format_structured(self, msg: str, **kwargs) -> str:
        """格式化结构化日志"""
        if kwargs:
            kv_pairs = ' '.join(f'{k}={v}' for k, v in kwargs.items())
            return f'{msg} | {kv_pairs}'
        return msg
    
    def debug(self, msg: str, *args, **kwargs):
        structured_msg = self._format_structured(msg, **kwargs)
        super().debug(structured_msg, *args)
    
    def info(self, msg: str, *args, **kwargs):
        structured_msg = self._format_structured(msg, **kwargs)
        super().info(structured_msg, *args)
    
    def warning(self, msg: str, *args, **kwargs):
        structured_msg = self._format_structured(msg, **kwargs)
        super().warning(structured_msg, *args)
    
    def error(self, msg: str, *args, **kwargs):
        structured_msg = self._format_structured(msg, **kwargs)
        super().error(structured_msg, *args)


# 便捷函数
def get_logger(name: str = 'multi-os') -> MOSLogger:
    """获取默认日志器"""
    return MOSLogger.get_logger(name)


def setup_logging_from_config(config_manager):
    """从配置管理器设置日志"""
    logger = get_logger()
    
    # 设置日志级别
    log_level_str = config_manager.get('system.log_level', 'info').lower()
    log_level_map = {
        'debug': LogLevel.DEBUG,
        'info': LogLevel.INFO,
        'warning': LogLevel.WARNING,
        'error': LogLevel.ERROR,
        'critical': LogLevel.CRITICAL,
    }
    logger.set_level(log_level_map.get(log_level_str, LogLevel.INFO))
    
    # 添加文件日志处理器
    log_file = config_manager.get('logging.file')
    if log_file:
        max_size = config_manager.get('logging.max_size', '10M')
        backup_count = config_manager.get('logging.backup_count', 5)
        
        # 解析大小
        size_multipliers = {'K': 1024, 'M': 1024*1024, 'G': 1024*1024*1024}
        max_bytes = 10 * 1024 * 1024  # 默认10MB
        if max_size[-1].upper() in size_multipliers:
            try:
                size_value = int(max_size[:-1])
                max_bytes = size_value * size_multipliers[max_size[-1].upper()]
            except ValueError:
                pass
        
        logger.add_file_handler(
            log_file,
            level=log_level_map.get(log_level_str, LogLevel.INFO),
            max_bytes=max_bytes,
            backup_count=backup_count
        )
    
    return logger


# 全局默认日志器
_default_logger: Optional[MOSLogger] = None


def get_default_logger() -> MOSLogger:
    """获取全局默认日志器"""
    global _default_logger
    if _default_logger is None:
        _default_logger = get_logger()
    return _default_logger


# 便捷日志函数
def debug(msg: str, *args, **kwargs):
    get_default_logger().debug(msg, *args, **kwargs)


def info(msg: str, *args, **kwargs):
    get_default_logger().info(msg, *args, **kwargs)


def warning(msg: str, *args, **kwargs):
    get_default_logger().warning(msg, *args, **kwargs)


def error(msg: str, *args, **kwargs):
    get_default_logger().error(msg, *args, **kwargs)


def critical(msg: str, *args, **kwargs):
    get_default_logger().critical(msg, *args, **kwargs)


if __name__ == '__main__':
    # 简单测试
    logger = get_logger('test')
    logger.add_file_handler('/tmp/multi-os-test.log')
    
    logger.debug('This is a debug message')
    logger.info('This is an info message')
    logger.warning('This is a warning message')
    logger.error('This is an error message')
    
    # 测试结构化日志
    struct_logger = StructuredLogger('test-structured')
    struct_logger.info('Application started', app='test', version='1.0.0')
    struct_logger.warning('Low disk space', path='/', available='10G')
    
    print("\nTest completed!")
