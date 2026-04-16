#!/usr/bin/env python3
"""
JVM Eliminator v2.0 - RafaelIA Edition
Identifies JVM overhead and suggests Native SIMD bypass
"""

import re
from pathlib import Path
from typing import List, Dict

class JvmEliminator:
    """Identifies JVM overhead patterns and Native candidates"""

    EXPENSIVE_PATTERNS = {
        'reflection': r'(\.javaClass|\.class|Class\.forName|getMethod|invoke)',
        'boxing': r'(Integer\.|Long\.|Boolean\.|Double\.|Float\.)',
        'string_ops': r'(\.split|\.replace|\.substring|\.format)',
        'collections': r'(ArrayList|HashMap|LinkedList|HashSet)',
        'exceptions': r'(try\s*\{|catch\s*\(|throw\s+new)',
        'gc_pressure': r'(new\s+\w+\[\]|Collections\.)',
        'simd_candidate': r'(for.*in.*step|while.*\{.*\[i\].*\}|\.map\s*\{|\.forEach\s*\{)',
    }

    def __init__(self, root_path: Path):
        self.root_path = root_path
        self.findings: Dict[str, List] = {cat: [] for cat in self.EXPENSIVE_PATTERNS.keys()}

    def scan_project(self):
        """Scan all Java/Kotlin files in the repository"""
        files = list(self.root_path.rglob("*.kt")) + list(self.root_path.rglob("*.java"))
        for filepath in files:
            self._analyze_file(filepath)

    def _analyze_file(self, filepath: Path):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            for category, pattern in self.EXPENSIVE_PATTERNS.items():
                matches = list(re.finditer(pattern, content))
                if matches:
                    self.findings[category].append({
                        'file': str(filepath.relative_to(self.root_path)),
                        'count': len(matches),
                        'line_numbers': self._get_line_numbers(content, matches),
                    })
        except Exception as e:
            print(f"Error analyzing {filepath}: {e}")

    def _get_line_numbers(self, content: str, matches) -> List[int]:
        line_numbers = []
        for match in matches[:5]:
            line_num = content[:match.start()].count('\n') + 1
            line_numbers.append(line_num)
        return line_numbers

    def generate_report(self) -> str:
        report = "# JVM Elimination & Native Integration Report\n\n"
        for category, items in self.findings.items():
            if items:
                report += f"## {category.upper()}\n"
                report += f"Detected in {len(items)} files:\n\n"
                for item in items[:3]:
                    report += f"- **{item['file']}** ({item['count']} matches) -> Lines: {item['line_numbers']}\n"
                report += "\n"
        return report

    def generate_optimization_suggestions(self) -> str:
        suggestions = "# Strategic Optimization Roadmap\n\n"
        
        if self.findings['simd_candidate']:
            suggestions += """## ⚡ High Performance: SIMD Bypass
Heavy loops or functional mappings detected. 
**Action:** Replace with calls to `02_arm64v8_neon_core.S` or `03_x86_64_avx2_core.S`.
```kotlin
// Use JNI/Native to call your optimized Ergodic Mix
external fun neon_ergodic_mix_arm64(ptr: Long, size: Int)
```\n\n"""

        if self.findings['boxing']:
            suggestions += "## 📦 Boxing Alert\nUse primitive arrays (IntArray, LongArray) instead of generic Collections.\n\n"
            
        return suggestions

if __name__ == "__main__":
    project_root = Path(".")
    eliminator = JvmEliminator(project_root)
    eliminator.scan_project()
    print(eliminator.generate_report())
    print(eliminator.generate_optimization_suggestions())
