# Contributing to CardShow Pro

Thank you for your interest in contributing to CardShow Pro! This document provides guidelines and best practices for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the project
- Show empathy towards other contributors

### Unacceptable Behavior

- Harassment or discrimination of any kind
- Trolling or insulting comments
- Publishing others' private information
- Other conduct inappropriate in a professional setting

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Xcode** 16.0 or later
- **macOS** Sonoma (14.0) or later
- **Git** installed and configured
- **GitHub account** (for pull requests)

### Initial Setup

1. **Fork the repository** on GitHub

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/CardshowPro.git
   cd CardshowPro
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/CardshowPro.git
   ```

4. **Verify setup**
   ```bash
   git remote -v
   # origin    https://github.com/YOUR_USERNAME/CardshowPro.git (fetch)
   # origin    https://github.com/YOUR_USERNAME/CardshowPro.git (push)
   # upstream  https://github.com/ORIGINAL_OWNER/CardshowPro.git (fetch)
   # upstream  https://github.com/ORIGINAL_OWNER/CardshowPro.git (push)
   ```

5. **Open workspace in Xcode**
   ```bash
   open CardShowPro.xcworkspace
   ```

## Development Process

### Workflow Overview

```
1. Create issue (if one doesn't exist)
   ↓
2. Create feature branch
   ↓
3. Make changes in CardShowProPackage
   ↓
4. Write tests
   ↓
5. Commit changes
   ↓
6. Push to your fork
   ↓
7. Create pull request
   ↓
8. Address review feedback
   ↓
9. Merge (by maintainer)
```

### Creating Issues

Before starting work:

1. **Check existing issues** to avoid duplicates
2. **Create a new issue** describing:
   - What you want to change/add
   - Why it's needed
   - How you plan to implement it
3. **Wait for approval** from maintainers (for major changes)

### Branch Naming

Use descriptive branch names following this pattern:

- **Features**: `feature/card-recognition`
- **Bug fixes**: `bugfix/camera-crash-on-ios17`
- **Documentation**: `docs/update-architecture`
- **Refactoring**: `refactor/simplify-camera-manager`
- **Performance**: `perf/optimize-vision-requests`

### Making Changes

#### Where to Make Changes

- ✅ **Do**: Make changes in `CardShowProPackage/Sources/CardShowProFeature/`
- ✅ **Do**: Update tests in `CardShowProPackage/Tests/`
- ✅ **Do**: Update documentation files (README, TODO, etc.)
- ❌ **Don't**: Modify files in `CardShowPro/` app target (except assets)
- ❌ **Don't**: Change project structure without discussion
- ❌ **Don't**: Modify XCConfig files without approval

#### Development Guidelines

1. **Follow existing patterns**
   - Use MV (Model-View) architecture, not MVVM
   - Use @Observable for shared state
   - Use Swift Concurrency (async/await)
   - See [CLAUDE.md](./CLAUDE.md) for detailed standards

2. **Keep views small**
   - Extract complex UI into separate components
   - Maximum ~200 lines per view file
   - Use `// MARK: -` to organize code

3. **Make code testable**
   - Keep business logic separate from views
   - Use dependency injection where needed
   - Avoid tight coupling

4. **Handle errors properly**
   - Never use `try!` or `force unwrap (!)`
   - Provide meaningful error messages
   - Log errors appropriately

## Coding Standards

### Swift Style Guide

Follow these conventions:

#### Naming

```swift
// Types: UpperCamelCase
struct CardView: View { }
class CameraManager { }
enum ScanMode { }

// Properties and functions: lowerCamelCase
var isLoading: Bool
func fetchCardData() async throws { }

// Constants: lowerCamelCase
let maxCardsPerSession = 100

// Private members: use private keyword
private var apiClient: APIClient
private func processImage() { }
```

#### Code Organization

```swift
import SwiftUI

struct MyView: View {
    // MARK: - Properties
    @Environment(AppState.self) private var appState
    @State private var isLoading = false

    // MARK: - Body
    var body: some View {
        // View code
    }

    // MARK: - Subviews
    private var headerSection: some View {
        // Component code
    }

    // MARK: - Methods
    private func loadData() async {
        // Logic
    }
}

// MARK: - Supporting Types
extension MyView {
    enum ViewState {
        case loading
        case loaded(data: [Item])
        case error(String)
    }
}
```

#### SwiftUI Best Practices

```swift
// ✅ Good: Use .task for async work
.task {
    await loadData()
}

// ❌ Bad: Using Task in onAppear (doesn't cancel)
.onAppear {
    Task {
        await loadData()
    }
}

// ✅ Good: Use @Observable
@Observable
final class AppState {
    var items: [Item] = []
}

// ❌ Bad: Using ViewModels
class MyViewModel: ObservableObject {
    @Published var items: [Item] = []
}

// ✅ Good: Environment injection
.environment(appState)

// ❌ Bad: Singleton pattern
class AppState {
    static let shared = AppState()
}
```

### Documentation

Add documentation for public APIs:

```swift
/// Represents a scanned trading card with AI-recognized metadata
///
/// This model stores both the physical card image and the recognized
/// card information from the AI/API service.
public struct ScannedCard: Identifiable, Sendable {
    /// Unique identifier for the scanned card
    public let id: UUID

    /// The captured image of the physical card
    public let image: UIImage

    // ... more properties
}
```

## Commit Guidelines

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, no logic change)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

#### Examples

```bash
# Simple feature
git commit -m "feat: add card recognition API integration"

# Bug fix with scope
git commit -m "fix(camera): resolve crash when permissions denied"

# With body and footer
git commit -m "feat(inventory): add search and filter functionality

Implements full-text search across card names and sets.
Adds filter options for price range, date added, and card type.

Closes #42"
```

### Commit Best Practices

- **Make atomic commits**: One logical change per commit
- **Commit often**: Small, focused commits are easier to review
- **Write meaningful messages**: Explain WHY, not just WHAT
- **Reference issues**: Use "Closes #123" or "Fixes #456"

## Pull Request Process

### Before Submitting

Ensure your PR meets these requirements:

- [ ] Code compiles without errors or warnings
- [ ] All tests pass (`Cmd+U`)
- [ ] New features have tests
- [ ] Code follows project style guidelines
- [ ] Documentation is updated (if needed)
- [ ] No unnecessary files committed (.DS_Store, etc.)
- [ ] Commits are clean and well-organized

### Creating the Pull Request

1. **Push your branch**
   ```bash
   git push origin feature/my-feature
   ```

2. **Go to GitHub** and create a pull request

3. **Fill out the PR template** (see below)

4. **Request review** from maintainers

### Pull Request Template

```markdown
## Description
Brief description of what this PR does and why.

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Related Issue
Closes #(issue number)

## Changes Made
- List key changes
- Be specific and concise
- Group related changes

## Testing
Describe the tests you ran:
- [ ] Unit tests pass
- [ ] Tested on iPhone 15 Pro simulator
- [ ] Tested on physical device (iPhone 14)
- [ ] Tested in dark mode
- [ ] Tested edge cases

## Screenshots (if applicable)
Add screenshots showing before/after for UI changes.

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] PROJECT_STATUS.md updated (if needed)

## Additional Notes
Any other information relevant to the review.
```

### Review Process

1. **Automated checks** run (if CI/CD configured)
2. **Maintainers review** your code
3. **Address feedback**:
   - Make requested changes
   - Push new commits to the same branch
   - Respond to comments
4. **Approval**: Maintainer approves PR
5. **Merge**: Maintainer merges to main branch

### After Merge

1. **Update your local main**
   ```bash
   git checkout main
   git pull upstream main
   ```

2. **Delete your feature branch** (optional)
   ```bash
   git branch -d feature/my-feature
   git push origin --delete feature/my-feature
   ```

## Testing Requirements

### Unit Tests (Required)

All new features must have unit tests:

```swift
import Testing
@testable import CardShowProFeature

@Suite("ScanSession Tests")
struct ScanSessionTests {
    @Test func addingCardIncreasesCount() async throws {
        let session = ScanSession()
        let card = ScannedCard(
            image: UIImage(),
            cardName: "Test Card",
            estimatedValue: 100
        )

        session.addCard(card)

        #expect(session.cardCount == 1)
    }

    @Test func removingCardDecreasesCount() async throws {
        let session = ScanSession()
        let card = ScannedCard(image: UIImage())
        session.addCard(card)

        session.removeCard(card)

        #expect(session.cardCount == 0)
    }
}
```

### Coverage Goals

- **Minimum**: 70% code coverage
- **Target**: 80%+ code coverage
- **Views**: Focus on logic, not UI rendering

### Running Tests

```bash
# From Xcode
# Press Cmd+U or Product → Test

# From command line (if using XcodeBuildMCP)
# Use test_sim tool with workspace path
```

## Documentation

### When to Update Docs

Update documentation when:

- Adding new features
- Changing architecture
- Modifying APIs
- Fixing significant bugs
- Adding dependencies

### Which Files to Update

- **README.md**: Project overview, getting started
- **PROJECT_STATUS.md**: Current state, completed features
- **ARCHITECTURE.md**: Design patterns, architectural decisions
- **TODO.md**: Mark tasks complete, add new tasks
- **DEVELOPMENT.md**: Development workflows (if changed)
- **CLAUDE.md**: Coding standards (rarely changed)

### Documentation Standards

- Use clear, concise language
- Include code examples where helpful
- Keep documentation up-to-date with code
- Use proper Markdown formatting
- Add table of contents for long documents

## Questions or Need Help?

- **Check existing documentation**: README, PROJECT_STATUS, ARCHITECTURE
- **Search existing issues**: Someone may have asked already
- **Create an issue**: Describe your question clearly
- **Be patient**: Maintainers will respond when available

## Recognition

Contributors will be recognized in:

- Project README
- Release notes
- GitHub contributors page

Thank you for contributing to CardShow Pro!

---

**Note**: These guidelines may evolve as the project grows. Check back periodically for updates.
