enum TaskSortOption {
  time('Scheduled Time'),
  priority('Priority (High to Low)'),
  creation('Date Created (Newest)'),
  category('Category');

  final String label;
  const TaskSortOption(this.label);
}