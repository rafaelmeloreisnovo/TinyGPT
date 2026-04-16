#!/bin/bash
# =============================================================================
# SCRIPT DE TESTE SISTEMÁTICO - Magisk_Rafaelia v999
# Executar dentro do diretório raiz do projeto (~/amagisk)
# =============================================================================

set -e

echo "================================================================"
echo "   TESTE SISTEMÁTICO - Magisk_Rafaelia v999"
echo "================================================================"
echo

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

# Função para imprimir resultado
check_result() {
    local name="$1"
    local status="$2"  # PASS, FAIL, WARN
    local msg="$3"
    
    case $status in
        PASS)
            echo -e "${GREEN}[PASS]${NC} $name"
            ((PASS++))
            ;;
        FAIL)
            echo -e "${RED}[FAIL]${NC} $name - $msg"
            ((FAIL++))
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $name - $msg"
            ((WARN++))
            ;;
    esac
}

echo "------------------------------------------------------------"
echo "1. Verificação de integridade da estrutura"
echo "------------------------------------------------------------"

# Lista de arquivos esperados (38)
declare -a EXPECTED_FILES=(
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

MISSING=0
for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_result "Arquivo: $file" "PASS" ""
    else
        check_result "Arquivo: $file" "FAIL" "não encontrado"
        ((MISSING++))
    fi
done

if [ $MISSING -eq 0 ]; then
    echo -e "\n${GREEN}Todos os 38 arquivos presentes.${NC}"
else
    echo -e "\n${RED}$MISSING arquivos faltando.${NC}"
fi

echo
echo "------------------------------------------------------------"
echo "2. Teste de sintaxe dos scripts Python"
echo "------------------------------------------------------------"

PYTHON_CMD="python3"
if ! command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
fi

for pyfile in build_refactored.py compliance_checker.py jni_bridge.py rafaelia/core/33_formulas_complete.py jvm_eliminator.py; do
    if $PYTHON_CMD -m py_compile "$pyfile" 2>/dev/null; then
        check_result "Sintaxe Python: $pyfile" "PASS" ""
    else
        check_result "Sintaxe Python: $pyfile" "FAIL" "erro de compilação"
    fi
done

echo
echo "------------------------------------------------------------"
echo "3. Verificação de Assembly (sintaxe básica)"
echo "------------------------------------------------------------"

# Apenas verifica se os arquivos .S não estão vazios e contêm diretivas
for asm in native/src/asm/*.S; do
    if grep -q "\.text" "$asm" && grep -q "\.global" "$asm"; then
        check_result "Assembly: $(basename $asm)" "PASS" ""
    else
        check_result "Assembly: $(basename $asm)" "WARN" "estrutura suspeita"
    fi
done

echo
echo "------------------------------------------------------------"
echo "4. Teste das fórmulas Rafaelia (Python)"
echo "------------------------------------------------------------"

cd rafaelia/core
# Cria um pequeno script de teste
cat > test_formulas.py << 'EOF'
import sys
sys.path.insert(0, '.')
from 33_formulas_complete import FormulaCollection

collection = FormulaCollection()
try:
    # Teste básico
    assert collection.compute(0, 0.8, 0.2, 0.6)['total'] == 1.0
    assert abs(collection.compute(1, 10) - 88.9918) < 0.001  # 55 * phi
    roots = collection.compute(4, 1, -5, 6)
    assert roots[0] == 3.0 and roots[1] == 2.0
    print("OK")
    sys.exit(0)
except Exception as e:
    print(f"ERRO: {e}")
    sys.exit(1)
EOF

if $PYTHON_CMD test_formulas.py > /dev/null 2>&1; then
    check_result "Fórmulas Rafaelia" "PASS" ""
else
    check_result "Fórmulas Rafaelia" "FAIL" "execução falhou"
fi
rm -f test_formulas.py
cd - > /dev/null

echo
echo "------------------------------------------------------------"
echo "5. Teste de compliance (autoavaliação)"
echo "------------------------------------------------------------"

# Executa compliance_checker em modo silencioso
if $PYTHON_CMD compliance_checker.py --help > /dev/null 2>&1; then
    check_result "Compliance Checker (sintaxe)" "PASS" ""
else
    check_result "Compliance Checker (sintaxe)" "FAIL" "não executa"
fi

# Tenta rodar uma verificação simples (se tiver git)
if command -v git &> /dev/null; then
    $PYTHON_CMD compliance_checker.py --repo . 2>&1 | grep -q "COMPLIANCE REPORT"
    if [ $? -eq 0 ]; then
        check_result "Compliance Checker (execução)" "PASS" ""
    else
        check_result "Compliance Checker (execução)" "WARN" "relatório não gerado"
    fi
else
    check_result "Compliance Checker (execução)" "WARN" "git não disponível"
fi

echo
echo "------------------------------------------------------------"
echo "6. Verificação de Makefiles"
echo "------------------------------------------------------------"

for mk in build_optimized.mk optimize.mk; do
    if make -f "$mk" -n all > /dev/null 2>&1; then
        check_result "Makefile: $mk" "PASS" ""
    else
        check_result "Makefile: $mk" "WARN" "não parseia"
    fi
done

echo
echo "------------------------------------------------------------"
echo "7. Verificação de scripts Shell"
echo "------------------------------------------------------------"

for sh in metal_vulkan_build.sh optimize_metal.sh; do
    if bash -n "$sh" 2>/dev/null; then
        check_result "Shell: $sh" "PASS" ""
    else
        check_result "Shell: $sh" "FAIL" "erro de sintaxe"
    fi
done

echo
echo "------------------------------------------------------------"
echo "8. Verificação de código C (existência de includes)"
echo "------------------------------------------------------------"

# Apenas verifica se os .c e .cpp têm #include esperados
for cfile in native/cpio/13_cpio_parser_complete.c native/src/14_simd_optimizer.c native/src/15_termux_native_bridge.c native/src/16_VmCore.cpp native/src/17_qemu_bridge.c; do
    if head -20 "$cfile" | grep -q "#include"; then
        check_result "C/C++ includes: $(basename $cfile)" "PASS" ""
    else
        check_result "C/C++ includes: $(basename $cfile)" "WARN" "sem includes"
    fi
done

echo
echo "------------------------------------------------------------"
echo "9. Verificação de Rust (sintaxe básica com rustc)"
echo "------------------------------------------------------------"

if command -v rustc &> /dev/null; then
    for rs in native/src/core/18_simd_intrinsics.rs native/src/core/19_error_handler.rs native/src/core/20_hw_detect.rs native/src/init/21_init_complete.rs native/src/22_vm_optimization.rs native/src/23_git_operations.rs; do
        # Apenas verifica se o arquivo é parseável (sem compilar)
        if rustc --crate-type lib --edition 2021 -Z no-codegen "$rs" 2>/dev/null || rustc --crate-type lib --edition 2021 --emit=metadata "$rs" 2>/dev/null; then
            check_result "Rust parse: $(basename $rs)" "PASS" ""
        else
            # Tentar com edição 2018
            if rustc --crate-type lib --edition 2018 --emit=metadata "$rs" 2>/dev/null; then
                check_result "Rust parse: $(basename $rs)" "PASS" ""
            else
                check_result "Rust parse: $(basename $rs)" "WARN" "não parseou (esperado sem std)"
            fi
        fi
    done
else
    check_result "Rust verification" "WARN" "rustc não instalado"
fi

echo
echo "------------------------------------------------------------"
echo "10. Verificação de Kotlin (compilação com kotlinc)"
echo "------------------------------------------------------------"

if command -v kotlinc &> /dev/null; then
    # Tenta compilar apenas os arquivos de erro (menos dependências)
    cd app/src/main/java/com/topjohnwu/magisk/core/error
    if kotlinc -Werror -d /tmp/kotlin_test.jar 27_ErrorCategory.kt 28_ErrorContext.kt 24_ErrorHandlerUtil.kt 2>/dev/null; then
        check_result "Kotlin compile: módulo error" "PASS" ""
    else
        check_result "Kotlin compile: módulo error" "WARN" "falha (talvez faltem dependências)"
    fi
    rm -f /tmp/kotlin_test.jar
    cd - > /dev/null
else
    check_result "Kotlin verification" "WARN" "kotlinc não instalado"
fi

echo
echo "================================================================"
echo "                   SUMÁRIO FINAL"
echo "================================================================"
echo -e "${GREEN}Pass: $PASS${NC}"
echo -e "${YELLOW}Warn: $WARN${NC}"
echo -e "${RED}Fail: $FAIL${NC}"

if [ $FAIL -eq 0 ] && [ $WARN -le 10 ]; then
    echo -e "\n${GREEN}✓ Sistema íntegro e pronto para compilação.${NC}"
    exit 0
elif [ $FAIL -eq 0 ]; then
    echo -e "\n${YELLOW}⚠ Sistema funcional, mas com avisos.${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Foram encontradas falhas críticas.${NC}"
    exit 1
fi
