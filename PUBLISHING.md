# Publishing to pub.dev

This document outlines the steps to publish the meAi Assistant plugin to pub.dev.

## Prerequisites

1. **pub.dev Account**: Create an account at https://pub.dev if you don't have one
2. **Google Account**: pub.dev uses Google OAuth for authentication
3. **Verified Email**: Ensure your email is verified on pub.dev

## Pre-Publication Checklist

### 1. Update Repository URLs

Before publishing, update the following in `pubspec.yaml`:
- `homepage`: Your actual GitHub repository URL
- `repository`: Your actual GitHub repository URL
- `issue_tracker`: Your actual GitHub issues URL

### 2. Verify Package Name

The package name `meai_assistant` must be available on pub.dev. Check availability at:
https://pub.dev/packages/meai_assistant

If the name is taken, you'll need to choose a different name and update:
- `pubspec.yaml` - `name` field
- All import statements in the code
- README.md documentation

### 3. Review Files

Ensure these files are present and correct:
- ✅ `pubspec.yaml` - Package metadata
- ✅ `README.md` - Comprehensive documentation
- ✅ `CHANGELOG.md` - Version history
- ✅ `LICENSE` - MIT License (or your chosen license)
- ✅ `.gitignore` - Excludes build artifacts

### 4. Test the Package

Run the following commands to verify the package:

```bash
# Navigate to package directory
cd meAiProject/meai

# Analyze the code
flutter analyze

# Run tests (if any)
flutter test

# Dry run publish (checks for issues without publishing)
flutter pub publish --dry-run
```

### 5. Update Version

Before each publication, update the version in `pubspec.yaml` following semantic versioning:
- **MAJOR.MINOR.PATCH** (e.g., 1.0.0)
- Increment MAJOR for breaking changes
- Increment MINOR for new features (backward compatible)
- Increment PATCH for bug fixes

Also update `CHANGELOG.md` with the new version and changes.

## Publishing Steps

### 1. Login to pub.dev

```bash
flutter pub publish --dry-run
# This will prompt you to login if not already logged in
```

Or login explicitly:
```bash
dart pub login
```

### 2. Final Verification

```bash
# Run dry-run to catch any issues
flutter pub publish --dry-run
```

This will check for:
- Missing required files
- Invalid package structure
- Missing dependencies
- Formatting issues
- Platform compatibility

### 3. Publish

Once dry-run passes without errors:

```bash
flutter pub publish
```

**Note**: Publishing is permanent! Make sure you're ready.

### 4. Verify Publication

After publishing, verify your package appears at:
https://pub.dev/packages/meai_assistant

## Post-Publication

1. **Update Documentation**: Ensure README examples use the published version
2. **Create Release**: Create a GitHub release tag matching the version
3. **Announce**: Share the package on social media, forums, etc.

## Updating the Package

For subsequent versions:

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Test thoroughly
4. Run `flutter pub publish --dry-run`
5. Run `flutter pub publish`

## Common Issues

### Package Name Already Taken
- Choose a different name
- Update all references in code and documentation

### Missing Files
- Ensure all required files are present
- Check `.gitignore` doesn't exclude necessary files

### Dependency Issues
- Verify all dependencies are available on pub.dev
- Check for version conflicts

### Formatting Issues
- Run `dart format .` to format code
- Ensure `analysis_options.yaml` is properly configured

## Resources

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Semantic Versioning](https://semver.org/)
- [pub.dev Package Guidelines](https://dart.dev/tools/pub/package-layout)

