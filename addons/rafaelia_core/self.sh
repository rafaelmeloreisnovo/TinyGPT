#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# TESTE SISTEMÁTICO - Versão Termux (tolerante a falhas)
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_result() {
    local name="$1"
    local status="$2"
    local msg="$3"
    case $status in
        PASS) echo -e "${GREEN}[PASS]${NC} $name"; ((PASS++)) ;;
        FAIL) echo -e "${RED}[FAIL]${NC} $name - $msg"; ((FAIL++)) ;;
        WARN) echo -e "${YELLOW}[WARN]${NC} $name - $msg"; ((WARN++)) ;;
    esac
}

echo "================================================================"
echo "   TESTE SISTEMÁTICO - Magisk_Rafaelia v999 (Termux)"
echo "================================================================"
echo

echo "------------------------------------------------------------"
echo "1. Verificação dos 38 arquivos"
echo "------------------------------------------------------------"

EXPECTED_FILES=(
    "native/src/asm/01_arm32v7_neon_core.S"
    "native/src/asm/02_arm64v8_neon_core.S"
    "native/src/asm/03_x86_64_avx2_core.S"
    "native/src/asm/04_i386_sse42_core.S"
    "native/src/asm/05_rafaelia_10x10.S"
    "native/src/asm/06_rafaelia_7d_final.S"
    "native/src/asm/07_rafaelia_7d_gyro.S"
    "native/src/asm/08_rafaelia_7d_shapes.S"
    "native/src/asm/09_rafaelia_8way.S"
    "native/src/asm/10_rafaelia_999_logsin.S"
    "native/src/asm/11_rafaelia_abs.S"
    "native/src/asm/12_rafaelia_avalanche_v2.S"
    "native/cpio/13_cpio_parser_complete.c"
    "native/src/14_simd_optimizer.c"
    "native/src/15_termux_native_bridge.c"
    "native/src/16_VmCore.cpp"
    "native/src/17_qemu_bridge.c"
    "native/src/core/18_simd_intrinsics.rs"
    "native/src/core/19_error_handler.rs"
    "native/src/core/20_hw_detect.rs"
    "native/src/init/21_init_complete.rs"
    "native/src/22_vm_optimization.rs"
    "native/src/23_git_operations.rs"
    "app/src/main/java/com/topjohnwu/magisk/core/error/24_ErrorHandlerUtil.kt"
    "app/src/main/java/com/termux/nativebridge/25_NativeTerminalBridge.kt"
    "app/src/main/java/com/termux/nativeoptimizer/26_TermuxNativeOptimizer.kt"
    "app/src/main/java/com/topjohnwu/magisk/core/error/27_ErrorCategory.kt"
    "app/src/main/java/com/topjohnwu/magisk/core/error/28_ErrorContext.kt"
    "app/src/main/java/com/topjohnwu/magisk/core/29_Result.kt"
    "build_refactored.py"
    "compliance_checker.py"
    "jni_bridge.py"
    "rafaelia/core/33_formulas_complete.py"
    "jvm_eliminator.py"
    "build_optimized.mk"
    "optimize.mk"
    "metal_vulkan_build.sh"
    "optimize_metal.sh"
)

for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_result "Arquivo: $file" "PASS" ""
    else
        check_result "Arquivo: $file" "FAIL" "não encontrado"
    fi
done

echo
echo "------------------------------------------------------------"
echo "2. Teste de sintaxe Python (se python3 disponível)"
echo "------------------------------------------------------------"

if command -v python3 &> /dev/null; then
    for pyfile in build_refactored.py compliance_checker.py jni_bridge.py rafaelia/core/33_formulas_complete.py jvm_eliminator.py; do
        if [ -f "$pyfile" ]; then
            if python3 -m py_compile "$pyfile" 2>/dev/null; then
                check_result "Sintaxe: $pyfile" "PASS" ""
            else
                check_result "Sintaxe: $pyfile" "FAIL" "erro de compilação"
            fi
        fi
    done
else
    check_result "Python3" "WARN" "não instalado - pulando testes"
fi

echo
echo "------------------------------------------------------------"
echo "3. Verificação básica de Assembly"
echo "------------------------------------------------------------"

for asm in native/src/asm/*.S; do
    if [ -f "$asm" ]; then
        if grep -q "\.text" "$asm" 2>/dev/null && grep -q "\.global" "$asm" 2>/dev/null; then
            check_result "ASM: $(basename $asm)" "PASS" ""
        else
            check_result "ASM: $(basename $asm)" "WARN" "sem diretivas esperadas"
        fi
    fi
done

echo
echo "------------------------------------------------------------"
echo "4. Teste rápido das fórmulas Rafaelia"
echo "------------------------------------------------------------"

if command -v python3 &> /dev/null && [ -f "rafaelia/core/33_formulas_complete.py" ]; then
    cd rafaelia/core
    cat > _test_formulas.py << 'EOF'
import sys
sys.path.insert(0, '.')
from importlib import util
spec = util.spec_from_file_location("formulas", "33_formulas_complete.py")
mod = util.module_from_spec(spec)
spec.loader.exec_module(mod)
collection = mod.FormulaCollection()
try:
    assert collection.compute(0, 0.8, 0.2, 0.6)['total'] == 1.0
    assert abs(collection.compute(1, 10) - 88.9918) < 0.001
    roots = collection.compute(4, 1, -5, 6)
    assert roots[0] == 3.0 and roots[1] == 2.0
    sys.exit(0)
except Exception as e:
    print(e)
    sys.exit(1)
EOF
    if python3 _test_formulas.py > /dev/null 2>&1; then
        check_result "Fórmulas Rafaelia" "PASS" ""
    else
        check_result "Fórmulas Rafaelia" "FAIL" "execução falhou"
    fi
    rm -f _test_formulas.py
    cd - > /dev/null
else
    check_result "Fórmulas Rafaelia" "WARN" "python3 não disponível"
fi

echo
echo "------------------------------------------------------------"
echo "5. Makefiles e scripts shell"
echo "------------------------------------------------------------"

for mk in build_optimized.mk optimize.mk; do
    if [ -f "$mk" ]; then
        check_result "Makefile: $mk" "PASS" "(existe)"
    else
        check_result "Makefile: $mk" "FAIL" "faltando"
    fi
done

for sh in metal_vulkan_build.sh optimize_metal.sh; do
    if [ -f "$sh" ]; then
        if bash -n "$sh" 2>/dev/null; then
            check_result "Shell: $sh" "PASS" ""
        else
            check_result "Shell: $sh" "WARN" "erro de sintaxe"
        fi
    else
        check_result "Shell: $sh" "FAIL" "faltando"
    fi
done

echo
echo "================================================================"
echo "                   SUMÁRIO FINAL"
echo "================================================================"
echo -e "${GREEN}Pass: $PASS${NC}"
echo -e "${YELLOW}Warn: $WARN${NC}"
echo -e "${RED}Fail: $FAIL${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "\n${GREEN}✓ Estrutura de arquivos OK.${NC}"
else
    echo -e "\n${RED}✗ Alguns arquivos essenciais estão faltando.${NC}"
    echo "Execute novamente os comandos 'cat' para criar os que faltam."
fi
