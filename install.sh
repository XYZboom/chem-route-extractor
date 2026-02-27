#!/bin/bash
# ChemRouteExtractor 一键安装脚本
# 自动安装所有依赖，包括 OpenChemIE 和 Python 包

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 输出带颜色的消息
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if command -v $1 &> /dev/null; then
        log_info "找到命令: $1"
        return 0
    else
        log_error "未找到命令: $1"
        return 1
    fi
}

# 检查 Python 版本
check_python_version() {
    local python_cmd=$1
    local version
    
    if check_command "$python_cmd"; then
        version=$($python_cmd -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            log_info "Python 版本: $version"
            
            # 解析主版本和次版本
            local major=$($python_cmd -c "import sys; print(sys.version_info.major)" 2>/dev/null)
            local minor=$($python_cmd -c "import sys; print(sys.version_info.minor)" 2>/dev/null)
            
            if [[ $major -ge 3 && $minor -ge 8 ]]; then
                log_success "Python 版本满足要求 (>= 3.8)"
                return 0
            else
                log_error "Python 版本过低 ($version)，需要 3.8 或更高版本"
                return 1
            fi
        fi
    fi
    return 1
}

# 安装系统依赖
install_system_deps() {
    log_info "安装系统依赖..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux (Ubuntu/Debian)
        if command -v apt-get &> /dev/null; then
            log_info "检测到 Debian/Ubuntu 系统"
            sudo apt-get update
            sudo apt-get install -y python3-dev python3-pip python3-venv libpoppler-cpp-dev
        elif command -v yum &> /dev/null; then
            log_info "检测到 RHEL/CentOS 系统"
            sudo yum install -y python3-devel python3-pip poppler-cpp-devel
        elif command -v dnf &> /dev/null; then
            log_info "检测到 Fedora 系统"
            sudo dnf install -y python3-devel python3-pip poppler-cpp-devel
        else
            log_warning "未知的 Linux 发行版，请手动安装: python3-dev, python3-pip, libpoppler-cpp-dev"
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        log_info "检测到 macOS 系统"
        
        # 检查是否安装了 Homebrew
        if ! command -v brew &> /dev/null; then
            log_error "未找到 Homebrew。请先安装 Homebrew:"
            log_error "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            return 1
        fi
        
        brew install python poppler
        brew link --overwrite python
        
    else
        log_warning "未知的操作系统: $OSTYPE"
        log_warning "请手动安装系统依赖:"
        log_warning "  - Python 3.8+ 和 pip"
        log_warning "  - libpoppler-cpp-dev (Linux) 或 poppler (macOS)"
    fi
    
    return 0
}

# 创建 Python 虚拟环境
setup_venv() {
    local venv_dir=$1
    
    log_info "创建 Python 虚拟环境: $venv_dir"
    
    if [[ ! -d "$venv_dir" ]]; then
        python3 -m venv "$venv_dir"
        if [[ $? -ne 0 ]]; then
            log_error "创建虚拟环境失败"
            return 1
        fi
    fi
    
    # 激活虚拟环境
    if [[ -f "$venv_dir/bin/activate" ]]; then
        source "$venv_dir/bin/activate"
        log_success "虚拟环境已激活"
    else
        log_error "无法激活虚拟环境"
        return 1
    fi
    
    # 升级 pip
    log_info "升级 pip..."
    pip install --upgrade pip
    
    return 0
}

# 安装 OpenChemIE
install_openchemie() {
    log_info "安装 OpenChemIE..."
    
    local openchemie_dir="OpenChemIE"
    
    # 克隆 OpenChemIE 仓库 (从用户 fork)
    if [[ ! -d "$openchemie_dir" ]]; then
        log_info "克隆 OpenChemIE 仓库..."
        git clone https://github.com/XYZboom/OpenChemIE.git "$openchemie_dir"
        if [[ $? -ne 0 ]]; then
            log_error "克隆 OpenChemIE 失败"
            return 1
        fi
    fi
    
    cd "$openchemie_dir"
    
    # 初始化子模块
    log_info "初始化 OpenChemIE 子模块..."
    git submodule update --init --recursive
    
    # 安装 OpenChemIE
    log_info "安装 OpenChemIE 核心包..."
    pip install -e .
    
    # 安装子模块（备用方案）
    log_info "安装 OpenChemIE 子模块..."
    for module in ChemIENER-local MolDetect-local MolScribe-local ChemRxnExtractor-local; do
        if [[ -d "$module" ]]; then
            log_info "安装 $module..."
            pip install -e "$module/" || log_warning "$module 安装失败（可能已安装）"
        fi
    done
    
    cd ..
    
    log_success "OpenChemIE 安装完成"
    return 0
}

# 安装 Python 依赖
install_python_deps() {
    log_info "安装 Python 依赖..."
    
    # 检查是否有 requirements.txt
    if [[ -f "requirements.txt" ]]; then
        log_info "从 requirements.txt 安装依赖..."
        pip install -r requirements.txt
    else
        log_info "手动安装核心依赖..."
        pip install torch>=2.0.0
        pip install pdfplumber>=0.10.0
        pip install python-docx>=0.8.11
        pip install rdkit>=2022.9.5
        pip install pytest>=7.0.0  # 测试框架
        pip install pytest-mock>=3.10.0
    fi
    
    # 额外依赖
    log_info "安装额外依赖..."
    pip install pillow>=9.0.0  # 图像处理
    pip install numpy>=1.21.0
    pip install pandas>=1.5.0  # 可选，用于更好的时间戳格式
    
    return 0
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    # 检查 Python 包
    local packages=("torch" "pdfplumber" "docx" "rdkit" "openchemie")
    
    for pkg in "${packages[@]}"; do
        if python3 -c "import $pkg" 2>/dev/null; then
            log_success "✓ $pkg 导入成功"
        else
            log_warning "⚠ $pkg 导入失败"
        fi
    done
    
    # 检查主程序
    if [[ -f "chem_route_extractor.py" ]]; then
        log_info "测试主程序导入..."
        if python3 -c "import sys; sys.path.insert(0, '.'); from chem_route_extractor import setup_argparse; print('主程序导入成功')" 2>/dev/null; then
            log_success "✓ 主程序导入成功"
        else
            log_warning "⚠ 主程序导入测试失败"
        fi
    fi
    
    return 0
}

# 显示使用说明
show_usage() {
    echo -e "\n${GREEN}ChemRouteExtractor 安装完成！${NC}"
    echo -e "\n${BLUE}使用方法：${NC}"
    echo "1. 激活虚拟环境:"
    echo "   source venv/bin/activate"
    echo ""
    echo "2. 运行工具:"
    echo "   python chem_route_extractor.py --input literature.pdf --output ./results"
    echo ""
    echo "3. 查看帮助:"
    echo "   python chem_route_extractor.py --help"
    echo ""
    echo "4. 运行测试:"
    echo "   python -m pytest tests/ -v"
    echo ""
    echo "5. 退出虚拟环境:"
    echo "   deactivate"
    echo ""
    echo "${YELLOW}注意：${NC}"
    echo "- 首次运行时可能需要下载模型文件，请保持网络连接"
    echo "- OpenChemIE 需要从图表中提取反应，请确保 PDF 包含清晰的化学结构图"
}

# 主函数
main() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}  ChemRouteExtractor 一键安装脚本${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    # 检查是否在项目目录中
    if [[ ! -f "chem_route_extractor.py" ]]; then
        log_warning "未在项目根目录中运行"
        log_warning "请切换到包含 chem_route_extractor.py 的目录"
        return 1
    fi
    
    # 检查 Python
    log_info "检查 Python 环境..."
    if ! check_python_version "python3"; then
        if check_python_version "python"; then
            log_info "使用 'python' 命令"
            python_cmd="python"
        else
            log_error "未找到合适的 Python 版本"
            return 1
        fi
    else
        python_cmd="python3"
    fi
    
    # 安装系统依赖
    install_system_deps
    
    # 设置虚拟环境
    local venv_dir="venv"
    setup_venv "$venv_dir"
    
    # 安装 OpenChemIE
    install_openchemie
    
    # 安装 Python 依赖
    install_python_deps
    
    # 验证安装
    verify_installation
    
    # 显示使用说明
    show_usage
    
    log_success "\n安装完成！"
    echo -e "\n${GREEN}现在可以开始使用 ChemRouteExtractor 了！${NC}"
}

# 运行主函数
main "$@"