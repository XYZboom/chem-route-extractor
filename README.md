# ChemRouteExtractor

一个基于OpenChemIE的自动化工具，用于从化学文献PDF中提取反应合成路线，并生成结构化的Word文档。

## 功能特点

- **文本信息提取**：自动提取实验部分、化合物编号、物理性质数据
- **化学反应提取**：使用OpenChemIE从图表中提取化学反应信息
- **图像生成**：使用RDKit将SMILES转换为化学结构图像
- **文档生成**：生成包含原文、中文翻译、反应图和谱图信息的Word文档
- **批量处理**：支持批量处理多个PDF文件
- **可配置选项**：支持多种参数配置，满足不同需求

## 安装要求

### 系统依赖
- Python 3.8+
- pip（Python包管理器）

### Python依赖
- OpenChemIE（需要从源代码安装）
- torch >= 2.0.0
- pdfplumber >= 0.10.0
- python-docx >= 0.8.11
- rdkit >= 2022.9.5
- pandas >= 1.5.0（可选，用于更好的时间戳格式）

### OpenChemIE安装
由于OpenChemIE尚未发布到PyPI，需要从源代码安装。我们已经fork了OpenChemIE仓库到您的账户下：

```bash
# 从您的fork安装OpenChemIE
git clone https://github.com/XYZboom/OpenChemIE.git
cd OpenChemIE
pip install -e .
```

**注意**：OpenChemIE有多个子模块依赖（MolScribe、RxnScribe、ChemRxnExtractor、ChemIENER），安装过程可能较复杂。如果遇到依赖问题，请参考以下步骤：

1. **安装系统依赖**：
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install python3-dev libpoppler-cpp-dev
   
   # macOS
   brew install poppler
   ```

2. **手动安装子模块**（如果自动安装失败）：
   ```bash
   # 克隆子模块
   git submodule update --init --recursive
   
   # 手动安装每个模块（在OpenChemIE目录下）
   pip install -e ChemIENER-local/
   pip install -e MolDetect-local/
   pip install -e MolScribe-local/
   pip install -e ChemRxnExtractor-local/
   ```

3. **常见问题解决**：
   - **PyTorch版本冲突**：修改各模块的`setup.py`，移除`torch<2.0`限制
   - **模型下载失败**：确保网络连接，或手动下载模型文件
   - **LayoutParser错误**：代码中已包含回退机制，不影响核心功能

更多安装细节请参考[OpenChemIE原始文档](https://github.com/CrystalEye42/OpenChemIE)。

## 🚀 一键安装（推荐）

我们提供了一个一键安装脚本，自动安装所有依赖：

```bash
# 克隆仓库
git clone https://github.com/XYZboom/chem-route-extractor.git
cd chem-route-extractor

# 运行安装脚本
./install.sh
```

安装脚本会自动：
1. 检查系统环境（Python 3.8+）
2. 安装系统依赖（Linux/macOS）
3. 创建 Python 虚拟环境
4. 克隆并安装 OpenChemIE（从您的 fork）
5. 安装所有 Python 依赖包
6. 验证安装结果

**手动安装**（如果自动安装失败）：
```bash
# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装 OpenChemIE
git clone https://github.com/XYZboom/OpenChemIE.git
cd OpenChemIE
pip install -e .
cd ..

# 安装其他依赖
pip install torch pdfplumber python-docx rdkit pandas
```

## 快速开始

### 1. 克隆或下载本工具
```bash
git clone <repository-url>
cd ChemRouteExtractor
```

### 2. 安装依赖
```bash
pip install -r requirements.txt
```

### 3. 基本使用
处理单个PDF文件：
```bash
python chem_route_extractor.py --input literature.pdf --output ./results
```

批量处理目录中的所有PDF文件：
```bash
python chem_route_extractor.py --input ./pdfs --output ./results --max-pages 10
```

### 4. 查看帮助
```bash
python chem_route_extractor.py --help
```

## 命令行参数

| 参数 | 简写 | 默认值 | 说明 |
|------|------|---------|------|
| `--input` | `-i` | 必需 | 输入PDF文件或目录 |
| `--output` | `-o` | `./results` | 输出目录 |
| `--max-pages` |  | `5` | 每个PDF处理的最大页数 |
| `--no-images` |  | `False` | 不生成反应图像 |
| `--include-si` |  | `False` | 同时处理SI（补充信息）文件 |
| `--language` |  | `both` | 输出语言：`zh`(中文)、`en`(英文)、`both`(中英双语) |
| `--template` |  | 无 | 自定义Word模板文档路径 |
| `--config` |  | 无 | JSON配置文件路径 |
| `--debug` |  | `False` | 启用调试模式 |

## 🧪 测试

我们提供了全面的测试套件，确保工具可靠性。运行测试：

```bash
# 安装测试依赖（如果尚未安装）
pip install pytest pytest-mock

# 运行所有测试
python -m pytest tests/ -v

# 运行特定测试文件
python -m pytest tests/test_argparse.py -v

# 运行带有覆盖率的测试
python -m pytest tests/ -v --cov=chem_route_extractor --cov-report=html
```

### 测试覆盖范围
- ✅ 命令行参数解析
- ✅ 文件查找功能  
- ✅ PDF文本提取
- ✅ 化学反应提取（模拟OpenChemIE）
- ✅ Word文档生成
- ✅ 错误处理和异常场景
- ✅ 集成测试

### 测试文件结构
```
tests/
├── __init__.py
├── conftest.py          # 共享fixtures
├── test_argparse.py     # 命令行参数测试
├── test_file_finding.py # 文件查找测试
├── test_text_extraction.py # 文本提取测试
├── test_reaction_extraction.py # 反应提取测试
├── test_word_document.py # Word文档生成测试
├── test_error_handling.py # 错误处理测试
└── test_integration.py  # 集成测试
```

## 配置文件示例

创建`config.json`：
```json
{
  "save_raw_data": true,
  "image_size": 300,
  "default_language": "both",
  "experimental_patterns": [
    "Experimental",
    "Materials and Methods",
    "Synthesis"
  ]
}
```

使用配置文件：
```bash
python chem_route_extractor.py --input literature.pdf --config config.json
```

## 输出结构

```
输出目录/
├── processing_report.json          # 处理报告
├── 文献1_合成路线/                 # 每个PDF的输出目录
│   ├── 文献1_合成路线.docx        # 生成的Word文档
│   ├── reaction_images/           # 反应图像目录
│   │   ├── reaction_1_reactant.png
│   │   ├── reaction_1_product.png
│   │   └── ...
│   └── 文献1_raw_data.json        # 原始提取数据（如果配置保存）
├── 文献2_合成路线/
│   └── ...
└── ...
```

## Word文档结构

生成的Word文档包含以下部分：

1. **标题**：化合物合成路线
2. **原文**：从PDF提取的实验部分（英文）
3. **物理性质数据**：熔点、NMR、HRMS等数据
4. **中文**：中文翻译占位符（待翻译）
5. **反应图**：通过OpenChemIE提取的化学反应结构图
   - 每个反应包含反应物和产物的SMILES及结构图像
6. **谱图**：谱图信息占位符（待补充）
7. **文档生成信息**：处理元数据

## 示例

### 输入文件
- `literature.pdf`：化学文献PDF文件

### 运行命令
```bash
python chem_route_extractor.py --input literature.pdf --output ./results --max-pages 5
```

### 输出文档
生成的`literature_合成路线.docx`将包含：
- 从PDF提取的实验步骤
- 提取的化合物信息
- 从图表中自动提取的化学反应图像
- 物理性质数据

## 高级用法

### 使用自定义模板
创建自定义Word模板，包含特定的样式和格式：
```bash
python chem_route_extractor.py --input literature.pdf --template my_template.docx
```

### 处理SI文件
同时处理主文件和SI文件：
```bash
python chem_route_extractor.py --input ./pdfs --include-si
```

### 仅生成英文文档
```bash
python chem_route_extractor.py --input literature.pdf --language en
```

### 禁用图像生成
```bash
python chem_route_extractor.py --input literature.pdf --no-images
```

## 故障排除

### 1. OpenChemIE导入失败
确保OpenChemIE已正确安装，并且Python路径包含OpenChemIE模块。

### 2. RDKit安装失败
RDKit可能需要从conda安装：
```bash
conda install -c conda-forge rdkit
```

### 3. 内存不足
对于大型PDF文件，使用`--max-pages`限制处理页数。

### 4. 图像生成失败
检查RDKit是否正确安装，并且SMILES格式有效。

## 性能建议

- **GPU加速**：如果有NVIDIA GPU，OpenChemIE运行速度会显著提升
- **分批处理**：对于大量PDF文件，建议分批处理
- **限制页数**：对于长文档，使用`--max-pages`限制处理页数
- **禁用图像**：如果不需要图像，使用`--no-images`加快处理速度

## 许可证

本项目基于MIT许可证开源。

## 贡献

欢迎提交Issue和Pull Request。

## 致谢

- **OpenChemIE**：提供化学反应提取功能
- **RDKit**：提供化学信息学功能
- **pdfplumber**：提供PDF文本提取功能
- **python-docx**：提供Word文档生成功能

## 联系

如有问题或建议，请通过GitHub Issues联系我们。