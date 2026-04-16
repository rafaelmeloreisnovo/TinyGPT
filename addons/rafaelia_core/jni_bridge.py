#!/usr/bin/env python3
"""
JNI Bridge Generator - Elimina overhead de Kotlin puro
Gera stubs C e Rust para operações críticas
"""

import os
import re
from pathlib import Path
from typing import List, Dict

class JNIBridgeGenerator:
    """Generates JNI bridges from Kotlin interfaces"""
    
    def __init__(self, kotlin_file: Path):
        self.kotlin_file = kotlin_file
        self.interface_name = kotlin_file.stem
        self.methods: List[Dict] = []
    
    def parse_kotlin_interface(self):
        """Parse Kotlin interface and extract methods"""
        with open(self.kotlin_file, 'r') as f:
            content = f.read()
        
        # Extract interface methods
        pattern = r'fun\s+(\w+)\s*\((.*?)\)\s*:\s*(\w+)'
        matches = re.finditer(pattern, content)
        
        for match in matches:
            method_name = match.group(1)
            params = match.group(2)
            return_type = match.group(3)
            
            self.methods.append({
                'name': method_name,
                'params': params,
                'return': return_type
            })
    
    def generate_c_header(self) -> str:
        """Generate C header for JNI binding"""
        header = f"""
#ifndef JNI_{self.interface_name.upper()}_H
#define JNI_{self.interface_name.upper()}_H

#include <jni.h>
#include <stdint.h>

/* Native implementations */
"""
        for method in self.methods:
            c_type = self._kotlin_to_c_type(method['return'])
            params = self._parse_params(method['params'])
            param_str = ', '.join([f"{self._kotlin_to_c_type(p[0])} {p[1]}" for p in params])
            
            header += f"\n{c_type} native_{method['name']}({param_str});"
        
        header += "\n\n#endif\n"
        return header
    
    def generate_jni_wrapper(self) -> str:
        """Generate JNI wrapper glue code"""
        wrapper = f"""
#include "jni_{self.interface_name}.h"
#include <jni.h>

/* JNI bridge implementations */
"""
        for method in self.methods:
            c_return = self._kotlin_to_c_type(method['return'])
            jni_return = self._kotlin_to_jni_type(method['return'])
            params = self._parse_params(method['params'])
            
            wrapper += f"""
JNIEXPORT {jni_return} JNICALL
Java_{self.interface_name}_{method['name']}(JNIEnv *env, jobject thiz"""
            
            for p_type, p_name in params:
                jni_p_type = self._kotlin_to_jni_type(p_type)
                wrapper += f", {jni_p_type} {p_name}"
            
            wrapper += f""") {{
    return ({jni_return})native_{method['name']}("""
            wrapper += ', '.join([p_name for _, p_name in params])
            wrapper += ");\n}\n"
        
        return wrapper
    
    def generate_rust_module(self) -> str:
        """Generate Rust FFI module"""
        rust = f"""
// Rust FFI module for {self.interface_name}

#[repr(C)]
pub struct {self.interface_name} {{
    // Native implementations
}}

impl {self.interface_name} {{
"""
        for method in self.methods:
            rust_return = self._kotlin_to_rust_type(method['return'])
            params = self._parse_params(method['params'])
            param_str = ', '.join([f"{p_name}: {self._kotlin_to_rust_type(p_type)}" for p_type, p_name in params])
            
            rust += f"""
    pub fn {method['name']}(&self, {param_str}) -> {rust_return} {{
        // Implementation
    }}
"""
        
        rust += "\n}\n"
        return rust
    
    def _kotlin_to_c_type(self, kotlin_type: str) -> str:
        mapping = {
            'Int': 'int32_t',
            'Long': 'int64_t',
            'Float': 'float',
            'Double': 'double',
            'Boolean': 'uint8_t',
            'String': 'const char*',
            'ByteArray': 'const uint8_t*',
        }
        return mapping.get(kotlin_type, 'void*')
    
    def _kotlin_to_jni_type(self, kotlin_type: str) -> str:
        mapping = {
            'Int': 'jint',
            'Long': 'jlong',
            'Float': 'jfloat',
            'Double': 'jdouble',
            'Boolean': 'jboolean',
            'String': 'jstring',
            'ByteArray': 'jbyteArray',
        }
        return mapping.get(kotlin_type, 'jobject')
    
    def _kotlin_to_rust_type(self, kotlin_type: str) -> str:
        mapping = {
            'Int': 'i32',
            'Long': 'i64',
            'Float': 'f32',
            'Double': 'f64',
            'Boolean': 'u8',
            'String': '&str',
            'ByteArray': '&[u8]',
        }
        return mapping.get(kotlin_type, '()')
    
    def _parse_params(self, params: str) -> List[tuple]:
        """Parse parameter list"""
        if not params.strip():
            return []
        
        result = []
        for param in params.split(','):
            parts = param.strip().split(':')
            if len(parts) == 2:
                p_name = parts[0].strip()
                p_type = parts[1].strip()
                result.append((p_type, p_name))
        
        return result

# Usage
if __name__ == "__main__":
    kotlin_file = Path("src/main/kotlin/GitTools.kt")
    gen = JNIBridgeGenerator(kotlin_file)
    gen.parse_kotlin_interface()
    
    # Generate files
    with open("jni_bridge.h", "w") as f:
        f.write(gen.generate_c_header())
    
    with open("jni_bridge.c", "w") as f:
        f.write(gen.generate_jni_wrapper())
    
    with open("src/lib.rs", "w") as f:
        f.write(gen.generate_rust_module())
    
    print("✓ JNI bridges generated successfully")
