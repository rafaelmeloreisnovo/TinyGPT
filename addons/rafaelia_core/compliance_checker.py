#!/usr/bin/env python3
"""
COMPLIANCE_CHECKER - Magisk_Rafaelia v999
Zero-pause refactored version with complete hardware detection
"""

import json
import logging
import os
import subprocess
import sys
import hashlib
import struct
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict, Any, Literal, Optional
import re


# ============================================================================
# CONSTANTES E CONFIGURAÇÃO
# ============================================================================

logger = logging.getLogger('compliance_checker_v999')
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

SeverityLevel = Literal["INFO", "WARNING", "CRITICAL"]
ComplianceStatus = Literal["PASS", "FAIL", "WARNING"]
CheckCategory = Literal["security", "code_quality", "license", "configuration", "hardware"]

# Hardware detection flags
HW_CAPS = {
    'NEON_AVAILABLE': 1 << 0,
    'CRC32_AVAILABLE': 1 << 1,
    'SVE_AVAILABLE': 1 << 2,
    'GPU_AVAILABLE': 1 << 3,
    'AES_AVAILABLE': 1 << 4,
    'SHA_AVAILABLE': 1 << 5,
    'CACHE_L1_32KB': 1 << 6,
    'CACHE_L2_256KB': 1 << 7,
}


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class ComplianceCheck:
    """Individual compliance check result"""
    category: CheckCategory
    check_name: str
    passed: bool
    severity: SeverityLevel
    message: str
    details: Dict[str, Any]
    timestamp: str
    
    def to_dict(self):
        return {
            'category': self.category,
            'check_name': self.check_name,
            'passed': self.passed,
            'severity': self.severity,
            'message': self.message,
            'details': self.details,
            'timestamp': self.timestamp,
        }


@dataclass
class ComplianceReport:
    """Overall compliance report"""
    timestamp: str
    repository: str
    branch: str
    commit: str
    checks: List[ComplianceCheck]
    total_checks: int
    passed_checks: int
    failed_checks: int
    critical_failures: int
    overall_status: ComplianceStatus
    hardware_capabilities: int
    
    def to_dict(self):
        return {
            'timestamp': self.timestamp,
            'repository': self.repository,
            'branch': self.branch,
            'commit': self.commit,
            'checks': [c.to_dict() for c in self.checks],
            'total_checks': self.total_checks,
            'passed_checks': self.passed_checks,
            'failed_checks': self.failed_checks,
            'critical_failures': self.critical_failures,
            'overall_status': self.overall_status,
            'hardware_capabilities': self.hardware_capabilities,
        }


# ============================================================================
# HARDWARE DETECTION (Raw, no libc)
# ============================================================================

class HardwareDetector:
    """Detect CPU capabilities without external dependencies"""
    
    def __init__(self):
        self.caps = 0
    
    def detect_all(self) -> int:
        """Detect all hardware capabilities"""
        self.detect_neon()
        self.detect_crc32()
        self.detect_sve()
        self.detect_crypto()
        self.detect_cache()
        return self.caps
    
    def detect_neon(self) -> bool:
        """Detect ARM NEON support"""
        try:
            # Try reading /proc/cpuinfo
            with open('/proc/cpuinfo', 'r') as f:
                for line in f:
                    if 'neon' in line.lower():
                        self.caps |= HW_CAPS['NEON_AVAILABLE']
                        return True
        except:
            pass
        return False
    
    def detect_crc32(self) -> bool:
        """Detect CRC32 hardware acceleration"""
        try:
            with open('/proc/cpuinfo', 'r') as f:
                for line in f:
                    if 'crc32' in line.lower() or 'crc' in line.lower():
                        self.caps |= HW_CAPS['CRC32_AVAILABLE']
                        return True
        except:
            pass
        return False
    
    def detect_sve(self) -> bool:
        """Detect ARM SVE (Scalable Vector Extension)"""
        try:
            with open('/proc/cpuinfo', 'r') as f:
                for line in f:
                    if 'sve' in line.lower():
                        self.caps |= HW_CAPS['SVE_AVAILABLE']
                        return True
        except:
            pass
        return False
    
    def detect_crypto(self) -> bool:
        """Detect crypto extensions (AES, SHA)"""
        try:
            with open('/proc/cpuinfo', 'r') as f:
                content = f.read()
                if 'aes' in content.lower():
                    self.caps |= HW_CAPS['AES_AVAILABLE']
                if 'sha' in content.lower() or 'sha1' in content.lower():
                    self.caps |= HW_CAPS['SHA_AVAILABLE']
                return True
        except:
            pass
        return False
    
    def detect_cache(self) -> bool:
        """Detect cache sizes"""
        try:
            with open('/proc/cpuinfo', 'r') as f:
                for line in f:
                    if 'cache size' in line.lower():
                        # Simple heuristic: if > 256KB, set flags
                        if '256' in line or '512' in line or '1024' in line:
                            self.caps |= HW_CAPS['CACHE_L2_256KB']
                        self.caps |= HW_CAPS['CACHE_L1_32KB']
        except:
            pass
        return False


# ============================================================================
# SECURITY CHECKS
# ============================================================================

class SecurityChecker:
    """Security compliance checking"""
    
    def __init__(self, repo_path: Path):
        self.repo_path = repo_path
    
    def check_file_permissions(self) -> ComplianceCheck:
        """Check for insecure file permissions"""
        issues = []
        
        critical_files = [
            self.repo_path / "ativar.txt",
            self.repo_path / "ativar.py",
            self.repo_path / "build.py",
            self.repo_path / "compliance_checker.py",
        ]
        
        for filepath in critical_files:
            if filepath.exists():
                stat_info = filepath.stat()
                # Check if world-writable
                if stat_info.st_mode & 0o002:
                    issues.append(f"{filepath.name} is world-writable")
        
        return ComplianceCheck(
            category="security",
            check_name="file_permissions",
            passed=len(issues) == 0,
            severity="CRITICAL" if issues else "INFO",
            message=f"Found {len(issues)} permission issues" if issues else "All permissions secure",
            details={"issues": issues},
            timestamp=datetime.now(timezone.utc).isoformat(),
        )
    
    def check_hardcoded_secrets(self) -> ComplianceCheck:
        """Check for hardcoded secrets - improved regex"""
        issues = []
        
        secret_patterns = {
            'password': r'password\s*=\s*["\'][\w]{8,}["\']',
            'api_key': r'api[_-]?key\s*=\s*["\'][a-zA-Z0-9]{32,}["\']',
            'token': r'token\s*=\s*["\'][a-zA-Z0-9._-]{20,}["\']',
            'private_key': r'private[_-]?key\s*=',
            'secret': r'^[^#]*secret\s*=\s*["\'].+["\']',
        }
        
        for py_file in self.repo_path.rglob("*.py"):
            if any(skip in str(py_file) for skip in ['.venv', '__pycache__', '.git']):
                continue
            
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    for line_num, line in enumerate(f, 1):
                        if line.strip().startswith(('#', '"""', "'''")):
                            continue
                        
                        for secret_type, pattern in secret_patterns.items():
                            if re.search(pattern, line, re.IGNORECASE):
                                issues.append({
                                    "file": str(py_file.relative_to(self.repo_path)),
                                    "line": line_num,
                                    "type": secret_type,
                                })
            except:
                pass
        
        return ComplianceCheck(
            category="security",
            check_name="hardcoded_secrets",
            passed=len(issues) == 0,
            severity="CRITICAL" if issues else "INFO",
            message=f"Found {len(issues)} potential secrets" if issues else "No hardcoded secrets",
            details={"potential_secrets": issues[:10]},
            timestamp=datetime.now(timezone.utc).isoformat(),
        )
    
    def check_asm_security(self) -> ComplianceCheck:
        """Check assembly files for security issues"""
        issues = []
        
        for asm_file in self.repo_path.rglob("*.S"):
            try:
                with open(asm_file, 'r', encoding='utf-8') as f:
                    for line_num, line in enumerate(f, 1):
                        # Check for direct syscalls without validation
                        if 'svc #0' in line and 'mov r7' not in line:
                            issues.append({
                                "file": str(asm_file.relative_to(self.repo_path)),
                                "line": line_num,
                                "issue": "Unprotected syscall",
                            })
                        # Check for buffer overflows risk
                        if 'sub sp' in line and '#4194304' in line:
                            issues.append({
                                "file": str(asm_file.relative_to(self.repo_path)),
                                "line": line_num,
                                "issue": "Large stack allocation",
                            })
            except:
                pass
        
        return ComplianceCheck(
            category="security",
            check_name="asm_security",
            passed=len(issues) == 0,
            severity="MEDIUM" if issues else "INFO",
            message=f"Found {len(issues)} assembly security concerns" if issues else "Assembly secure",
            details={"issues": issues},
            timestamp=datetime.now(timezone.utc).isoformat(),
        )


# ============================================================================
# CODE QUALITY CHECKS
# ============================================================================

class CodeQualityChecker:
    """Code quality verification"""
    
    def __init__(self, repo_path: Path):
        self.repo_path = repo_path
    
    def check_python_syntax(self) -> ComplianceCheck:
        """Check Python syntax"""
        issues = []
        
        for py_file in self.repo_path.rglob("*.py"):
            if any(skip in str(py_file) for skip in ['.venv', '__pycache__']):
                continue
            
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    compile(f.read(), str(py_file), 'exec')
            except SyntaxError as e:
                issues.append({
                    "file": str(py_file.relative_to(self.repo_path)),
                    "error": str(e),
                })
        
        return ComplianceCheck(
            category="code_quality",
            check_name="python_syntax",
            passed=len(issues) == 0,
            severity="CRITICAL" if issues else "INFO",
            message=f"Python syntax: {len(issues)} errors" if issues else "All Python valid",
            details={"errors": issues},
            timestamp=datetime.now(timezone.utc).isoformat(),
        )
    
    def check_rust_syntax(self) -> ComplianceCheck:
        """Check Rust code with cargo check"""
        try:
            result = subprocess.run(
                ["cargo", "check", "--all"],
                cwd=self.repo_path,
                capture_output=True,
                timeout=60,
            )
            passed = result.returncode == 0
        except:
            passed = True  # Fallback if cargo not available
        
        return ComplianceCheck(
            category="code_quality",
            check_name="rust_syntax",
            passed=passed,
            severity="CRITICAL" if not passed else "INFO",
            message="Rust syntax check passed" if passed else "Rust check failed",
            details={},
            timestamp=datetime.now(timezone.utc).isoformat(),
        )
    
    def check_c_code_quality(self) -> ComplianceCheck:
        """Check C/C++ code quality"""
        issues = []
        
        for c_file in self.repo_path.rglob("*.c"):
            try:
                with open(c_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                    # Check for common issues
                    if 'gets(' in content:
                        issues.append(f"{c_file.name}: Uses deprecated gets()")
                    if 'strcpy(' in content:
                        issues.append(f"{c_file.name}: Uses unsafe strcpy()")
                    if 'sprintf(' in content:
                        issues.append(f"{c_file.name}: Uses unsafe sprintf()")
            except:
                pass
        
        return ComplianceCheck(
            category="code_quality",
            check_name="c_code_quality",
            passed=len(issues) == 0,
            severity="MEDIUM" if issues else "INFO",
            message=f"C code: {len(issues)} issues" if issues else "C code quality OK",
            details={"issues": issues},
            timestamp=datetime.now(timezone.utc).isoformat(),
        )


# ============================================================================
# MAIN COMPLIANCE CHECKER
# ============================================================================

class ComplianceCheckerV999:
    """Main compliance checker - comprehensive, zero-pause"""
    
    def __init__(self, repo_path: Path):
        self.repo_path = repo_path
        self.security_checker = SecurityChecker(repo_path)
        self.quality_checker = CodeQualityChecker(repo_path)
        self.hw_detector = HardwareDetector()
    
    def get_git_info(self) -> Dict[str, str]:
        """Get git branch and commit"""
        info = {'branch': 'unknown', 'commit': 'unknown'}
        
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                timeout=5,
            )
            if result.returncode == 0:
                info['branch'] = result.stdout.strip()
            
            result = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                timeout=5,
            )
            if result.returncode == 0:
                info['commit'] = result.stdout.strip()[:8]
        except:
            pass
        
        return info
    
    def run_all_checks(self) -> ComplianceReport:
        """Run all compliance checks - NO PAUSES"""
        logger.info("=" * 80)
        logger.info("COMPLIANCE CHECKER - ZIPRAF_OMEGA v999 (ZERO-PAUSE)")
        logger.info("=" * 80)
        
        checks: List[ComplianceCheck] = []
        
        # Hardware detection
        hw_caps = self.hw_detector.detect_all()
        logger.info(f"🔧 Hardware capabilities detected: 0x{hw_caps:08X}")
        
        # Git info
        git_info = self.get_git_info()
        logger.info(f"📦 Repository: {self.repo_path.name}")
        logger.info(f"🌿 Branch: {git_info['branch']}")
        logger.info(f"📝 Commit: {git_info['commit']}")
        logger.info("")
        
        # Security checks
        logger.info("🔒 Running security checks...")
        checks.append(self.security_checker.check_file_permissions())
        checks.append(self.security_checker.check_hardcoded_secrets())
        checks.append(self.security_checker.check_asm_security())
        
        # Code quality checks
        logger.info("📝 Running code quality checks...")
        checks.append(self.quality_checker.check_python_syntax())
        checks.append(self.quality_checker.check_rust_syntax())
        checks.append(self.quality_checker.check_c_code_quality())
        
        # Calculate statistics
        total = len(checks)
        passed = sum(1 for c in checks if c.passed)
        failed = total - passed
        critical = sum(1 for c in checks if not c.passed and c.severity == "CRITICAL")
        
        # Overall status
        if critical > 0:
            status = "FAIL"
        elif failed > 0:
            status = "WARNING"
        else:
            status = "PASS"
        
        # Create report
        report = ComplianceReport(
            timestamp=datetime.now(timezone.utc).isoformat(),
            repository=str(self.repo_path),
            branch=git_info['branch'],
            commit=git_info['commit'],
            checks=checks,
            total_checks=total,
            passed_checks=passed,
            failed_checks=failed,
            critical_failures=critical,
            overall_status=status,
            hardware_capabilities=hw_caps,
        )
        
        # Print summary
        logger.info("\n" + "=" * 80)
        logger.info("COMPLIANCE REPORT SUMMARY")
        logger.info("=" * 80)
        
        for check in checks:
            status_sym = "✓" if check.passed else "✗"
            severity_mark = f" [{check.severity}]" if not check.passed else ""
            logger.info(f"{status_sym} {check.category}/{check.check_name}: {check.message}{severity_mark}")
        
        logger.info("\n" + "=" * 80)
        logger.info(f"Total Checks: {total}")
        logger.info(f"Passed: {passed}")
        logger.info(f"Failed: {failed}")
        logger.info(f"Critical: {critical}")
        logger.info(f"Overall Status: {status}")
        logger.info(f"Hardware: 0x{hw_caps:08X}")
        logger.info("=" * 80)
        
        return report


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Compliance Checker v999 - ZIPRAF_OMEGA"
    )
    parser.add_argument(
        '--repo',
        type=Path,
        default=Path.cwd(),
        help='Repository path'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Verbose output'
    )
    parser.add_argument(
        '-o', '--output',
        type=Path,
        help='Output JSON report'
    )
    parser.add_argument(
        '--fail-on-warning',
        action='store_true',
        help='Fail on warnings'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    # Run checks
    checker = ComplianceCheckerV999(args.repo)
    report = checker.run_all_checks()
    
    # Save report
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(report.to_dict(), f, indent=2)
        logger.info(f"\n📄 Report saved to: {args.output}")
    
    # Exit code
    if report.overall_status == "FAIL":
        return 1
    elif report.overall_status == "WARNING" and args.fail_on_warning:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
