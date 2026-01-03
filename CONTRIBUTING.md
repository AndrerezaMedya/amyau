# Contributing to Amal Syarafi

Thank you for considering contributing to Amal Syarafi! This document provides guidelines and instructions for contributing.

## 🎯 Code of Conduct

- Be respectful and inclusive
- Welcome new contributors
- Focus on constructive feedback
- Report issues responsibly

## 🚀 Getting Started

### 1. Fork & Clone
```bash
git clone https://github.com/YOUR_USERNAME/amyau.git
cd amyau
git remote add upstream https://github.com/AndrerezaMedya/amyau.git
```

### 2. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

Use descriptive names:
- `feature/add-dark-mode`
- `fix/prayer-time-calculation`
- `docs/update-api-docs`
- `refactor/improve-sync-logic`

### 3. Development Setup
```bash
flutter pub get
flutter analyze
dart format lib/
```

## 📋 Before You Commit

### Run Quality Checks
```bash
# Code analysis
flutter analyze

# Format code
dart format lib/

# Run tests (if available)
flutter test

# Build check
flutter build apk --debug
```

### Commit Message Format
```
<type>: <description>

<detailed explanation if needed>

Fixes #<issue_number>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `style:` - Code style (formatting)
- `perf:` - Performance improvement

**Examples:**
```
feat: add dark mode theme

Implement Material Design 3 dark color scheme with system preference detection.

Fixes #123
```

```
fix: prevent data loss on sync failure

Add retry logic with exponential backoff to sync_service.dart

Fixes #456
```

## 📝 Pull Request Process

1. **Update main branch**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create Pull Request**
   - Title: Concise description
   - Description: What & why
   - Link related issues
   - Add screenshots if UI changes

4. **PR Template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   How to test the changes
   
   ## Screenshots/Demo
   If applicable, add screenshots
   
   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Tests pass locally
   - [ ] Documentation updated
   - [ ] No new warnings
   ```

## 🏗 Architecture Guidelines

### File Organization
```
feature/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers.dart
├── domain/
│   └── models.dart
└── data/
    └── services.dart
```

### Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Methods/Variables**: `camelCase`
- **Constants**: `lowerCamelCase` (or `UPPER_CASE` for compile-time)
- **Widgets**: `*Widget` or `*Screen` suffix

### Example
```dart
// ✅ Good
class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  static const double defaultPadding = 16.0;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text(activity.name),
    );
  }
}

// ❌ Bad
class activity_card extends StatelessWidget {
  final activity;
  const defaultPadding = 16.0;
  
  @override
  Widget build(context) {
    return Card(child: Text(activity.name));
  }
}
```

## 🔒 Security Guidelines

- **Never commit secrets**: API keys, tokens, credentials
- **Use environment variables**: Store in `.env` or constants file
- **Validate user input**: Sanitize before processing
- **Review RLS policies**: Check Supabase security
- **Encrypt sensitive data**: Use Hive encryption for local storage

### Secrets Management
```dart
// ❌ Never do this
const String apiKey = 'sk-abc123xyz789';

// ✅ Do this
// Read from environment or config file
final apiKey = String.fromEnvironment('GEMINI_API_KEY');
```

## 🧪 Testing

### Test Structure
```dart
void main() {
  group('DailyLogsProvider', () {
    test('should load logs from local storage', () {
      // Arrange
      final mockStorage = MockLocalStorageService();
      
      // Act
      final provider = DailyLogsProvider('user123');
      
      // Assert
      expect(provider.state.logs, isNotEmpty);
    });
  });
}
```

## 📚 Documentation

### Code Comments
```dart
/// Describes what this does
/// 
/// Multi-line explanation if needed
void functionName() {}

// Implementation detail comments
int calculateScore() {
  // Weight calculation: 70% frequency + 30% quality
  return (frequency * 0.7 + quality * 0.3).toInt();
}
```

### README Updates
- Add features to "Features" section
- Update architecture if modified
- Document new endpoints/APIs
- Include screenshots for UI changes

## 🐛 Bug Reports

### Include
- Description of bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots/logs
- Device info (OS, Flutter version)

### Template
```markdown
## Bug Description
What happened?

## Steps to Reproduce
1. Open app
2. Click on...
3. See error

## Expected
App should show activity list

## Actual
App crashes with error: [error message]

## Environment
- Flutter: 3.x.x
- Device: Android 14
- Package: com.amalsyarafi.app
```

## ⚡ Performance Tips

- **Use `const` constructors** when possible
- **Minimize rebuilds**: Use `selector` in Riverpod
- **Lazy loading**: Load data only when needed
- **Proper disposal**: Close streams and resources
- **Profile app**: Use DevTools for bottlenecks

## 🔗 Useful Resources

- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart)
- [Riverpod Documentation](https://riverpod.dev)
- [Supabase Documentation](https://supabase.com/docs)

## ❓ Questions?

- Open a [discussion](https://github.com/AndrerezaMedya/amyau/discussions)
- Check existing [issues](https://github.com/AndrerezaMedya/amyau/issues)
- Create an [issue](https://github.com/AndrerezaMedya/amyau/issues/new) for bugs

---

**Thank you for contributing! 🙏**
