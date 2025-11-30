#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Recursive dependency builder for Conan packages.

This script reads a conanfile.py, extracts its dependencies,
checks if each dependency is installed, and recursively builds
missing dependencies.
"""

import os
import sys
import re
import subprocess
import ast
from pathlib import Path
from typing import List, Set, Tuple, Optional


class ConanDependencyBuilder:
    """Recursively builds Conan package dependencies."""
    
    def __init__(self, conanfile_path: str, create_dir: str = None):
        """
        Initialize the builder.
        
        Args:
            conanfile_path: Path to the conanfile.py file
            create_dir: Directory containing conan recipes (default: same as script dir)
        """
        self.conanfile_path = os.path.abspath(conanfile_path)
        if create_dir is None:
            # Default to the directory containing this script
            self.create_dir = os.path.dirname(os.path.abspath(__file__))
        else:
            self.create_dir = os.path.abspath(create_dir)
        
        self.built_packages: Set[str] = set()
        self.visited_packages: Set[str] = set()
        
    def extract_dependencies(self, conanfile_path: str) -> List[str]:
        """
        Extract dependencies from a conanfile.py file.
        
        Args:
            conanfile_path: Path to conanfile.py
            
        Returns:
            List of dependency strings (e.g., ["eigen/3.4.0", "jsoncpp/1.9.4"])
        """
        dependencies = []
        
        try:
            with open(conanfile_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Parse the Python file
            tree = ast.parse(content, filename=conanfile_path)
            
            # Find the ConanFile class
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    # Look for requirements method
                    for item in node.body:
                        if isinstance(item, ast.FunctionDef) and item.name == 'requirements':
                            # Extract self.requires() calls
                            for stmt in ast.walk(item):
                                if isinstance(stmt, ast.Call):
                                    if (isinstance(stmt.func, ast.Attribute) and 
                                        stmt.func.attr == 'requires' and
                                        len(stmt.args) > 0):
                                        if isinstance(stmt.args[0], ast.Constant):
                                            dep = stmt.args[0].value
                                            if isinstance(dep, str):
                                                dependencies.append(dep)
        except Exception as e:
            print(f"Warning: Failed to parse {conanfile_path}: {e}")
            # Fallback: use regex to find self.requires() calls
            with open(conanfile_path, 'r', encoding='utf-8') as f:
                content = f.read()
            pattern = r'self\.requires\(["\']([^"\']+)["\']\)'
            matches = re.findall(pattern, content)
            dependencies.extend(matches)
        
        return dependencies
    
    def parse_package_reference(self, dep_str: str) -> Tuple[str, Optional[str]]:
        """
        Parse a dependency string into package name and version.
        
        Args:
            dep_str: Dependency string (e.g., "eigen/3.4.0" or "zlib/[>=1.2.11 <2]")
            
        Returns:
            Tuple of (package_name, version) where version may be None for version ranges
        """
        # Handle version ranges like "zlib/[>=1.2.11 <2]"
        if '/' in dep_str:
            parts = dep_str.split('/', 1)
            name = parts[0]
            version_str = parts[1] if len(parts) > 1 else None
            
            if version_str:
                # If it's a version range like [>=1.2.11 <2], we can't use exact version
                if version_str.startswith('[') or version_str.startswith('('):
                    # Version range - we'll need to find a compatible version
                    return name, None
                else:
                    # Exact version
                    return name, version_str
            return name, None
        return dep_str, None
    
    def _has_error_in_output(self, text: str) -> bool:
        """
        Check if output contains error messages indicating package not found.
        
        Args:
            text: Output text to check
            
        Returns:
            True if error is detected, False otherwise
        """
        if not text:
            return False
        
        text_lower = text.lower()
        # Check for common error patterns
        error_patterns = [
            'error: recipe',
            'recipe.*not found',
            'no package',
            'not available',
            'not found',
        ]
        
        # Check for "ERROR: Recipe 'package/version' not found" pattern
        if 'error' in text_lower and 'recipe' in text_lower and 'not found' in text_lower:
            return True
        
        # Check for other error patterns
        for pattern in error_patterns:
            if pattern.replace('.*', '') in text_lower:
                return True
        
        return False
    
    def check_package_exists(self, package_name: str, version: str = None) -> bool:
        """
        Check if a Conan package is installed.
        
        Args:
            package_name: Name of the package
            version: Version of the package (optional)
            
        Returns:
            True if package exists, False otherwise
        """
        try:
            if version:
                ref = f"{package_name}/{version}"
            else:
                ref = package_name
            
            # Use conan list to check if package exists
            cmd = ['conan', 'list', ref, '--format=json']
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            # Check for errors in stderr or stdout
            if self._has_error_in_output(result.stderr) or self._has_error_in_output(result.stdout):
                return False
            
            # Only proceed if return code is 0 and no errors detected
            if result.returncode == 0 and result.stdout.strip():
                # Try to parse JSON output
                import json
                try:
                    data = json.loads(result.stdout)
                    # Check if we have any packages
                    if isinstance(data, dict):
                        # New format: {"local": [...], "remote": [...]}
                        for key in data:
                            if isinstance(data[key], list) and len(data[key]) > 0:
                                # Verify the list contains actual package data
                                return True
                    elif isinstance(data, list) and len(data) > 0:
                        return True
                except json.JSONDecodeError:
                    # If JSON parsing fails, don't assume package exists
                    # This is safer than checking for package name in output
                    pass
            
            # Also try conan search as fallback (but check for errors)
            cmd = ['conan', 'search', ref]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            # Check for errors
            if self._has_error_in_output(result.stderr) or self._has_error_in_output(result.stdout):
                return False
            
            # Only return True if command succeeded and output contains package info
            if result.returncode == 0 and result.stdout.strip():
                # Check if package name appears in output (but not in error message)
                if package_name in result.stdout:
                    # Make sure it's not in an error message
                    if not self._has_error_in_output(result.stdout):
                        return True
            
            return False
        except subprocess.TimeoutExpired:
            print(f"Warning: Timeout checking package {package_name}")
            return False
        except Exception as e:
            print(f"Warning: Error checking package {package_name}: {e}")
            return False
    
    def find_conanfile(self, package_name: str, version: str = None) -> Optional[str]:
        """
        Find the conanfile.py for a package in the create directory.
        
        Args:
            package_name: Name of the package
            version: Version of the package (optional)
            
        Returns:
            Path to conanfile.py if found, None otherwise
        """
        # Try different directory structures:
        # 1. package_name/version/conanfile.py (e.g., assimp/5.x/conanfile.py)
        # 2. package_name/all/conanfile.py
        # 3. package_name/conanfile.py
        
        search_paths = []
        
        if version:
            # Try exact version path
            search_paths.append(os.path.join(self.create_dir, package_name, version, 'conanfile.py'))
            # Also try with major version only (e.g., 5.x for 5.4.2)
            if '.' in version:
                major_version = version.split('.')[0]
                search_paths.append(os.path.join(self.create_dir, package_name, f"{major_version}.x", 'conanfile.py'))
        
        # Try 'all' version path (most common in this project)
        search_paths.append(os.path.join(self.create_dir, package_name, 'all', 'conanfile.py'))
        
        # Try direct path
        search_paths.append(os.path.join(self.create_dir, package_name, 'conanfile.py'))
        
        # Also search in subdirectories if package_name directory exists
        package_dir = os.path.join(self.create_dir, package_name)
        if os.path.isdir(package_dir):
            # Look for any version subdirectory
            for item in os.listdir(package_dir):
                item_path = os.path.join(package_dir, item)
                if os.path.isdir(item_path):
                    conanfile_path = os.path.join(item_path, 'conanfile.py')
                    if os.path.exists(conanfile_path):
                        search_paths.append(conanfile_path)
        
        for path in search_paths:
            if os.path.exists(path):
                return path
        
        return None
    
    def _extract_version_from_conanfile(self, conanfile_path: str) -> Optional[str]:
        """
        Extract version from conanfile.py.
        
        Args:
            conanfile_path: Path to conanfile.py
            
        Returns:
            Version string if found, None otherwise
        """
        try:
            with open(conanfile_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Try to find version = "x.x.x" pattern
            pattern = r'version\s*=\s*["\']([^"\']+)["\']'
            match = re.search(pattern, content)
            if match:
                return match.group(1)
            
            # Try to find self.version = "x.x.x" pattern
            pattern = r'self\.version\s*=\s*["\']([^"\']+)["\']'
            match = re.search(pattern, content)
            if match:
                return match.group(1)
        except Exception as e:
            print(f"Warning: Failed to extract version from {conanfile_path}: {e}")
        
        return None
    
    def _get_version_from_config(self, package_root: str) -> Optional[str]:
        """
        Get version from config.yml file.
        
        Args:
            package_root: Root directory of the package
            
        Returns:
            Version string if found, None otherwise
        """
        config_file = os.path.join(package_root, 'config.yml')
        if not os.path.exists(config_file):
            return None
        
        try:
            import yaml
            with open(config_file, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
                if data and 'versions' in data:
                    versions = data['versions']
                    # Return the first version found
                    if versions:
                        return list(versions.keys())[0]
        except Exception as e:
            print(f"Warning: Failed to read config.yml: {e}")
        
        return None
    
    def _get_package_root(self, conanfile_path: str) -> str:
        """
        Get the root directory of the package from conanfile path.
        
        Args:
            conanfile_path: Path to conanfile.py
            
        Returns:
            Root directory of the package
        """
        # conanfile_path is like: create_dir/package_name/version/conanfile.py
        # or: create_dir/package_name/all/conanfile.py
        # We need to find the package root (package_name directory)
        
        path = Path(conanfile_path)
        current = path.parent
        
        # Go up until we find a directory that contains config.yml
        # This should be the package root (e.g., yojimbo/)
        while current != current.parent:  # Stop at filesystem root
            config_file = current / 'config.yml'
            if config_file.exists():
                return str(current)
            current = current.parent
        
        # If no config.yml found, assume the parent of the conanfile's parent is the root
        # (e.g., yojimbo/all/conanfile.py -> yojimbo)
        # But make sure we don't go beyond create_dir
        parent = path.parent.parent
        if str(parent).startswith(str(Path(self.create_dir))):
            return str(parent)
        
        # Fallback: return the directory containing the conanfile
        return str(path.parent)
    
    def build_package(self, conanfile_path: str, package_name: str, version: str = None) -> bool:
        """
        Build a Conan package using create.py script.
        
        Args:
            conanfile_path: Path to conanfile.py
            package_name: Name of the package
            version: Version of the package (optional)
            
        Returns:
            True if build succeeded, False otherwise
        """
        # Get package root directory
        package_root = self._get_package_root(conanfile_path)
        
        # Try to get version if not provided
        if not version:
            version = self._extract_version_from_conanfile(conanfile_path)
            if not version:
                version = self._get_version_from_config(package_root)
        
        if not version:
            print(f"Warning: Could not determine version for {package_name}, using 'all'")
            version = "all"
        
        print(f"\n{'='*60}")
        print(f"Building package: {package_name}/{version}")
        print(f"Conanfile: {conanfile_path}")
        print(f"Package root: {package_root}")
        print(f"{'='*60}")
        
        # Get path to create.py script
        create_script = os.path.join(self.create_dir, 'create.py')
        if not os.path.exists(create_script):
            print(f"Error: create.py not found at {create_script}")
            return False
        
        # Build command: python create.py package_name version
        cmd = [sys.executable, create_script, package_name]
        if version:
            cmd.append(version)
        
        print(f"\nExecuting: {' '.join(cmd)}")
        print(f"Working directory: {package_root}")
        
        try:
            result = subprocess.run(
                cmd,
                cwd=package_root,
                timeout=3600,  # 1 hour timeout
                text=True
            )
            
            if result.returncode != 0:
                print(f"Error: Failed to build {package_name}/{version}")
                if result.stdout:
                    print(f"Command output:\n{result.stdout}")
                if result.stderr:
                    print(f"Command error:\n{result.stderr}")
                return False
            else:
                print(f"Successfully built {package_name}/{version}")
                if result.stdout:
                    print(f"Output:\n{result.stdout}")
                return True
        except subprocess.TimeoutExpired:
            print(f"Error: Timeout building {package_name}/{version}")
            return False
        except Exception as e:
            print(f"Error: Exception building {package_name}/{version}: {e}")
            return False
    
    def process_dependencies(self, conanfile_path: str, depth: int = 0) -> bool:
        """
        Recursively process dependencies of a conanfile.py.
        
        Args:
            conanfile_path: Path to conanfile.py
            depth: Current recursion depth (for indentation)
            
        Returns:
            True if all dependencies were processed successfully
        """
        indent = "  " * depth
        
        print(f"{indent}Processing: {conanfile_path}")
        
        # Extract dependencies
        dependencies = self.extract_dependencies(conanfile_path)
        
        if not dependencies:
            print(f"{indent}No dependencies found")
            return True
        
        print(f"{indent}Found {len(dependencies)} dependencies: {', '.join(dependencies)}")
        
        success = True
        
        # Process each dependency
        for dep_str in dependencies:
            package_name, version = self.parse_package_reference(dep_str)
            
            # Create a unique identifier for this package
            package_id = f"{package_name}/{version}" if version else package_name
            
            # Skip if already visited (to avoid infinite loops)
            if package_id in self.visited_packages:
                print(f"{indent}Skipping {package_id} (already visited)")
                continue
            
            self.visited_packages.add(package_id)
            
            print(f"\n{indent}Checking dependency: {package_id}")
            
            # Check if package exists
            if self.check_package_exists(package_name, version):
                print(f"{indent}✓ Package {package_id} is already installed")
                continue
            
            print(f"{indent}✗ Package {package_id} is missing, need to build")
            
            # Find conanfile for this package
            dep_conanfile = self.find_conanfile(package_name, version)
            
            if not dep_conanfile:
                print(f"{indent}✗ Warning: Could not find conanfile.py for {package_id}")
                print(f"{indent}  Searched in: {self.create_dir}")
                # Continue with other dependencies
                success = False
                continue
            
            print(f"{indent}Found conanfile: {dep_conanfile}")
            
            # Recursively process dependencies of this package first
            if not self.process_dependencies(dep_conanfile, depth + 1):
                print(f"{indent}✗ Failed to process dependencies of {package_id}")
                success = False
                continue
            
            # Build the package
            if package_id not in self.built_packages:
                if self.build_package(dep_conanfile, package_name, version):
                    self.built_packages.add(package_id)
                    print(f"{indent}✓ Successfully built {package_id}")
                else:
                    print(f"{indent}✗ Failed to build {package_id}")
                    success = False
            else:
                print(f"{indent}✓ Package {package_id} was already built in this session")
        
        return success
    
    def build(self) -> bool:
        """
        Main entry point: process the conanfile and build all missing dependencies.
        
        Returns:
            True if all dependencies were built successfully
        """
        if not os.path.exists(self.conanfile_path):
            print(f"Error: Conanfile not found: {self.conanfile_path}")
            return False
        
        print(f"Starting recursive dependency build")
        print(f"Conanfile: {self.conanfile_path}")
        print(f"Create directory: {self.create_dir}")
        print()
        
        return self.process_dependencies(self.conanfile_path)


def main():
    """Main entry point for the script."""
    if len(sys.argv) < 2:
        print("Usage: python recursive_build_deps.py <conanfile.py> [create_dir]")
        print("  conanfile.py: Path to the conanfile.py file")
        print("  create_dir:   Optional directory containing conan recipes")
        print("                (default: same directory as this script)")
        sys.exit(1)
    
    conanfile_path = sys.argv[1]
    create_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    builder = ConanDependencyBuilder(conanfile_path, create_dir)
    success = builder.build()
    
    if success:
        print("\n" + "="*60)
        print("✓ All dependencies processed successfully!")
        print("="*60)
        sys.exit(0)
    else:
        print("\n" + "="*60)
        print("✗ Some dependencies failed to build")
        print("="*60)
        sys.exit(1)


if __name__ == '__main__':
    main()

