# Clean presentation widgets and atomic UI

Design rules for maintainable, reusable, and performant Flutter presentation widgets.

---

## Widget responsibilities diagram

```text
+--------------------------------------------------------------+
|                       Screen / Page                          |
|  - Connects to state (ConsumerWidget)                        |
|  - Maps state models to presentation properties              |
|  - Handles navigation and user feedback                      |
+------------------------------+-------------------------------+
                               | passes immutable data & callbacks
                               v
+--------------------------------------------------------------+
|                      Component Widget                        |
|  - Stateless & const constructor                             |
|  - Renders UI based solely on passed parameters              |
|  - Emits user intent via callbacks (VoidCallback)            |
+--------------------------------------------------------------+
```

---

## Core rules

### 1. No private build helper methods

Avoid breaking widget lifecycle optimizations with helper methods like `_buildHeader()`:

```dart
// Bad: Creates layout thrashing and prevents sub-tree caching
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildHeader(),
      _buildContent(),
    ],
  );
}
Widget _buildHeader() => Container(...);

// Good: Independent const classes allow Flutter to skip unchanged subtrees
Widget build(BuildContext context) {
  return const Column(
    children: [
      HeaderSection(),
      ContentSection(),
    ],
  );
}
```

### 2. Ubiquitous const constructors

- Always declare `const` constructors on widgets whose parameters are immutable.
- Use `const` on static children in padding, columns, and container layouts to eliminate unnecessary garbage collection pressure.

### 3. Reusable components depend on data, not providers

Dumb presentation widgets should accept domain entities or primitives and emit callbacks:

```dart
// Good: Pure, isolated component suitable for unit and golden tests
class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.item,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final TaskItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.title),
        trailing: Checkbox(
          value: item.isCompleted,
          onChanged: (val) => onToggle(val ?? false),
        ),
      ),
    );
  }
}
```

---

## Quality checklist

- [ ] Are widgets under 150 lines of code?
- [ ] Are all static child instances instantiated with `const`?
- [ ] Are private `_buildXxx()` methods refactored into dedicated classes?
- [ ] Are callbacks used instead of passing business logic into dumb widgets?

---

## References

- Flutter performance best practices: https://docs.flutter.dev/perf/best-practices
- Flutter layout fundamentals: https://docs.flutter.dev/ui/layout
- Atomic presentation widgets reference: https://github.com/sgaabdu4/building-flutter-apps/blob/master/skills/building-flutter-apps/references/atomic-design.md
