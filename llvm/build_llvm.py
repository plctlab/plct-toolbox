#!/usr/bin/env python

"""
Copyright 2022 PLCTLAB. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

"""
The configuration file build_llvm.json should be placed under the same folder as well.

This program aims to simplify the configuration process to build the llvm project.
"""

import json
import os
import subprocess
import sys
from optparse import OptionParser
from pathlib import Path

class Platform(object):
    """Copyright 2001 Google Inc. All Rights Reserved. Apache License 2.0"""
    """Represents a host/target platform and its specific build attributes."""
    def __init__(self, platform=None):
        self._platform = platform
        if self._platform is not None:
            return
        self._platform = sys.platform
        if self._platform.startswith('linux'):
            self._platform = 'linux'
        elif self._platform.startswith('freebsd'):
            self._platform = 'freebsd'
        elif self._platform.startswith('gnukfreebsd'):
            self._platform = 'freebsd'
        elif self._platform.startswith('openbsd'):
            self._platform = 'openbsd'
        elif self._platform.startswith('solaris') or self._platform == 'sunos5':
            self._platform = 'solaris'
        elif self._platform.startswith('mingw'):
            self._platform = 'mingw'
        elif self._platform.startswith('win'):
            self._platform = 'msvc'
        elif self._platform.startswith('bitrig'):
            self._platform = 'bitrig'
        elif self._platform.startswith('netbsd'):
            self._platform = 'netbsd'
        elif self._platform.startswith('aix'):
            self._platform = 'aix'
        elif self._platform.startswith('os400'):
            self._platform = 'os400'
        elif self._platform.startswith('dragonfly'):
            self._platform = 'dragonfly'

    @staticmethod
    def known_platforms():
      return ['linux', 'darwin', 'freebsd', 'openbsd', 'solaris', 'sunos5',
              'mingw', 'msvc', 'gnukfreebsd', 'bitrig', 'netbsd', 'aix',
              'dragonfly']

    def platform(self):
        return self._platform

    def is_linux(self):
        return self._platform == 'linux'

    def is_mingw(self):
        return self._platform == 'mingw'

    def is_msvc(self):
        return self._platform == 'msvc'

    def is_windows(self):
        return self.is_mingw() or self.is_msvc()

    def is_solaris(self):
        return self._platform == 'solaris'

    def is_aix(self):
        return self._platform == 'aix'

    def is_os400_pase(self):
        return self._platform == 'os400' or os.uname().sysname.startswith('OS400')

class Task(object):
    def __init__(self, cmd):
        try:
            with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'build_llvm.json'), 'r') as fp:
                self._config = json.load(fp)
        except FileNotFoundError:
            print('ERROR: no configuration file found')
            sys.exit(1)
        try:
            self._llvm_project = self._config['llvm_project_path']
            self._llvm_dir = os.path.join(self._llvm_project, 'llvm')
            self._task = self._init_task(cmd)
            self._target_dir = self._init_target_dir()
            self._label = self._task.get('label', 'Unknown task')
            self._type = self._task['type']
            if self._type == 'configure':
                self._gen = self._task.get('generator', 'Ninja')
                self._vars = self._task['vars']
            elif self._type == 'build':
                self._target = self._task.get('targets', 'all')
        except KeyError as e:
            print('ERROR: not a valid configuration file', e)

    def _init_task(self, cmd):
        for task in self._config['tasks']:
            if task['command'] == cmd:
                return task

    def _init_target_dir(self):
        if Path(self._task['target_dir']).is_absolute():
            return self._task['target_dir']
        return os.path.join(self._llvm_project, self._task['target_dir'])

    def _path_escape(self, path):
        return '"%s"' % path if ' ' in path else path

    def _cmake_escape(self, s):
        return s

    def _configure_check(self):
        if 'CMAKE_CROSSCOMPILING' in self._vars:
            print('-- Warning: CMAKE_CROSSCOMPILING should not be set here')
        if 'CMAKE_SYSTEM_NAME' in self._vars:
            print('-- Note: The tblgen used for cross-compiling should be on the SAME commit')
        if 'LLVM_PARALLEL_LINK_JOBS' not in self._vars:
            print('-- Warning: The memory may not be enough to build the project')
            print('   Please specify LLVM_PARALLEL_LINK_JOBS if OOM')
            return
        platform = Platform()
        if not platform.is_linux():
            return
        out = subprocess.check_output(['free --giga | grep Mem | awk \'{print int($2 / 16)}\''], shell=True).decode('utf-8').strip()
        if int(out) < int(self._vars['LLVM_PARALLEL_LINK_JOBS']):
            print('-- Warning: The memory may not be enough to build the project')
            print('   Please specify LLVM_PARALLEL_LINK_JOBS to %s if OOM' % out)
            return

    def _build_configure_command(self):
        self._configure_check()
        command = ['cmake']
        for key, value in self._vars.items():
            if isinstance(value, int) or isinstance(value, float) or isinstance(value, bool):
                value = str(value)
            elif isinstance(value, list):
                temp = ''
                for v in value:
                    temp += str(v) + ';'
                value = temp.strip(';')
            command.append('-D' + key + '=' + self._cmake_escape(value))
        command.append('-H' + self._path_escape(self._llvm_dir))
        command.append('-B' + self._path_escape(self._target_dir))
        command.append('-G')
        command.append(self._gen)
        return command

    def _build_build_command(self):
        command = ['cmake']
        command.append('--build')
        command.append(self._path_escape(self._target_dir))
        command.append('--target')
        if isinstance(self._target, list):
            for target in self._target:
                command.append(target)
        else:
            command.append(self._target)
        return command

    def build_command(self):
        if self._type == 'configure':
            return self._build_configure_command()
        elif self._type == 'build':
            return self._build_build_command()

    def exec(self):
        print('> Executing task:', self._label)
        popen = subprocess.Popen(self.build_command())
        ret = popen.wait()
        if ret != 0:
            sys.exit(ret)

if __name__ == '__main__':
    parser = OptionParser()
    (options, args) = parser.parse_args()
    if not args:
        print('ERROR: no task to do')
        sys.exit(1)
    t = Task(args[0])
    t.exec()
