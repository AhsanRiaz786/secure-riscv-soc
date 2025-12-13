# Contributing to Secure RISC-V SoC

Thank you for your interest in contributing to the Secure RISC-V SoC project! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Requirements](#testing-requirements)
- [Submission Guidelines](#submission-guidelines)

## 📜 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors. We pledge to:

- Be respectful and considerate of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment, discriminatory language, or personal attacks
- Trolling, insulting comments, or hostile behavior
- Publishing others' private information without permission
- Other conduct that could reasonably be considered inappropriate

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Development Environment Setup**
   - RISC-V toolchain installed
   - Verilog simulator (Icarus Verilog)
   - Python 3 for build scripts
   - Git for version control

2. **Project Understanding**
   - Read the main [README.md](README.md)
   - Understand the project architecture
   - Review existing code and tests

### Setting Up Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/secure-riscv-soc.git
   cd secure-riscv-soc
   ```

2. **Create Development Branch**
   ```bash
   git checkout -b dev/your-feature-name
   ```

3. **Verify Build**
   ```bash
   cd software
   make clean all
   cd ..
   ./scripts/simulate.sh
   ```

## 🔄 Development Process

### Workflow

1. **Choose an Issue**
   - Check existing issues or create a new one
   - Assign yourself or ask for assignment
   - Discuss approach if needed

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/feature-name
   # or
   git checkout -b fix/bug-description
   ```

3. **Make Changes**
   - Write code following style guidelines
   - Add/update tests
   - Update documentation

4. **Test Your Changes**
   ```bash
   # Run all tests
   ./scripts/test_anti_replay_quick.sh
   ./scripts/test_secure_boot_attacks.sh
   ./scripts/test_replay_attacks.sh
   ```

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

6. **Push and Create PR**
   ```bash
   git push origin feature/feature-name
   # Then create Pull Request on GitHub
   ```

### Branch Naming Convention

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `test/description` - Test additions/updates
- `refactor/description` - Code refactoring

## 📝 Code Style Guidelines

### Verilog Code

**Naming Conventions:**
- Modules: `snake_case` (e.g., `monotonic_counter`)
- Signals: `snake_case` (e.g., `mem_addr`, `mem_valid`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `KEY_STORE_BASE`)

**Formatting:**
```verilog
// Use 4-space indentation
module example (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] data,
    output reg         valid
);

    // Use blank lines between logical sections
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 1'b0;
        end else begin
            valid <= data_valid;
        end
    end

endmodule
```

**Comments:**
- Document all module interfaces
- Explain complex logic
- Add section headers for large blocks

### C Code

**Naming Conventions:**
- Functions: `snake_case` (e.g., `uart_puts`)
- Variables: `snake_case` (e.g., `counter_value`)
- Macros: `UPPER_SNAKE_CASE` (e.g., `KEY_STORE_BASE`)

**Formatting:**
```c
// Use 4-space indentation
void example_function(uint32_t value) {
    // Use braces even for single-line blocks
    if (value > 0) {
        process_value(value);
    }
}
```

**Comments:**
- Document function purposes
- Explain complex algorithms
- Add header comments for test functions

### File Organization

- One module per file
- Group related files in directories
- Keep file sizes reasonable (< 1000 lines)

## ✅ Testing Requirements

### Test Coverage

All contributions must include:

1. **Unit Tests** (for new modules)
   - Test individual module functionality
   - Cover edge cases
   - Verify error handling

2. **Integration Tests**
   - Test module interactions
   - Verify system behavior
   - Test attack scenarios

3. **Regression Tests**
   - Ensure existing functionality still works
   - Run full test suite before submission

### Writing Tests

**Example Test Structure:**
```c
void test_feature_name(void) {
    uart_puts("TEST: Feature Name\n");
    
    // Setup
    initialize_hardware();
    
    // Test case
    perform_operation();
    
    // Verify
    if (verify_result()) {
        uart_puts("  ✓ PASS\n");
    } else {
        uart_puts("  ✗ FAIL\n");
        test_failed = 1;
    }
}
```

### Running Tests

```bash
# Run all tests
./scripts/test_anti_replay_quick.sh

# Run specific test suite
cd software
# Edit Makefile to use specific test
make clean all && cd .. && ./scripts/simulate.sh
```

## 📤 Submission Guidelines

### Pull Request Process

1. **Before Submitting**
   - [ ] Code follows style guidelines
   - [ ] All tests pass
   - [ ] Documentation updated
   - [ ] No build warnings/errors
   - [ ] Commit messages are clear

2. **Pull Request Description**
   - Clear title describing the change
   - Detailed description of what changed and why
   - Reference related issues
   - List any breaking changes

3. **Review Process**
   - Address review comments promptly
   - Update PR based on feedback
   - Ensure CI checks pass

### Commit Message Guidelines

**Format:**
```
Type: Brief description

Detailed explanation of the change (optional)

Fixes #issue-number
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions/changes
- `refactor`: Code refactoring
- `style`: Code style changes
- `chore`: Maintenance tasks

**Examples:**
```
feat: Add AES encryption support to crypto accelerator

Implements AES-128 encryption/decryption modes in the
crypto accelerator module. Includes unit tests and
integration with existing HMAC-SHA256 functionality.

Closes #42
```

```
fix: Correct MPU address calculation for instruction memory

Fixed bug where instruction memory address calculation
was incorrectly using byte offsets instead of word addresses.
This caused incorrect memory reads during firmware execution.

Fixes #38
```

## 🐛 Reporting Bugs

### Bug Report Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Run '...'
2. See error

**Expected behavior**
What you expected to happen.

**Environment:**
- OS: [e.g., Ubuntu 22.04]
- Toolchain version: [e.g., riscv64-unknown-elf-gcc 12.2.0]
- Simulator: [e.g., Icarus Verilog 12.0]

**Additional context**
Any other relevant information.
```

## 💡 Suggesting Features

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Other solutions or features you've thought about.

**Additional context**
Any other relevant information or context.
```

## 📚 Documentation

### Updating Documentation

When adding features:

1. **Update README.md** if needed
2. **Add code comments** for new modules
3. **Update memory map** if addresses change
4. **Document APIs** in header files

## 🔍 Code Review Guidelines

### For Reviewers

- Be constructive and respectful
- Explain reasoning for requested changes
- Approve when code meets standards
- Test changes locally when possible

### For Contributors

- Respond to all review comments
- Don't take feedback personally
- Ask questions if unclear
- Update PR based on feedback

## 🙏 Recognition

Contributors will be:
- Listed in project credits
- Acknowledged in release notes
- Appreciated by the community!

## 📞 Questions?

- Open an issue for questions
- Check existing documentation
- Review closed PRs for examples

Thank you for contributing! 🎉

