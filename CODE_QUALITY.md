# Code Quality Standards - Hallify

## Preventing Analysis Issues

### Before Every Commit
```bash
# Run analysis locally first
flutter analyze --no-fatal-infos

# Fix formatting issues
dart format --set-exit-if-changed .

# Check for unused imports
flutter pub get
```

### What Gets Checked Automatically

**On every push to GitHub:**
1. ✅ **Dart Analysis** - No errors allowed
2. ✅ **Code Formatting** - Must follow Dart style guide
3. ✅ **Dependency Validation** - No unused packages
4. ✅ **Security Scan** - Detects exposed secrets
5. ✅ **Code Metrics** - Analyzes complexity (warning only)

### Common Errors & Fixes

| Error | Fix |
|-------|-----|
| `undefined_method` | Check Flutter/Dart SDK version compatibility |
| `unused_import` | Remove unused imports |
| `dead_code` | Remove or use the dead code |
| `deprecated_member_use` | Update to newer API (info level - optional) |
| `avoid_print` | Use proper logging instead (info level - optional) |

### Running Pre-commit Hook Locally

```bash
# Install husky (run once)
npm install husky --save-dev

# It will automatically run flutter analyze before commits
# If analysis fails, commit is blocked
```

### Analysis Configuration

- **File**: `analysis_options.yaml`
- **CI/CD Config**: `.github/workflows/code_quality.yml`
- **Ignored Files**: `analysis_options.yaml` → `analyzer.exclude`

### Best Practices

✅ **DO:**
- Run `flutter analyze` before pushing
- Keep SDK dependencies up to date
- Use proper logging, not print()
- Add type annotations
- Remove unused imports immediately

❌ **DON'T:**
- Commit with analysis errors
- Ignore deprecation warnings
- Have unused dependencies
- Use debug print statements in production code
- Suppress lints without reason

---

**Last Updated**: Jan 5, 2026  
**Flutter Version**: 3.24.0  
**Dart Version**: 3.2.5+
