This is a small plugin to enable note and task taking. Many commands are exposed by default, but it is recommended to
add a mapping on the main user modes instead for a quicker onboarding.

# Commands and user modes

Commands are listed below, along with the user-mode and keybinding they are available from.

| Command                         | User mode              | Default mappings           | Notes                                                            |
| =======                         | =========              | ================           | ====                                                             |
| `kak-notes-journal-open-daily`  | `kak-notes`            | `<J>`                      | Open the daily journal, which is the same file for the same day. |
| `kak-notes-journal-open`        | `kak-notes`            | `<j>`                      | Open a journal via a _prompt_.                                   |
| `kak-notes-open`                | `kak-notes`            | `<n>`                      | Open a notes via a _prompt_.                                     |
| `kak-notes-new-note`            | `kak-notes`            | `<N>`                      | Create a new note.                                               |
| `kak-notes-archive-note`        | `kak-notes`            | `<A>`                      | Archive a note via a _prompt_.                                   |
| `kak-notes-archive-open`        | `kak-notes`            | `<a>`                      | Open an archived note via a _prompt_.                            |
| `kak-notes-capture`             | `kak-notes-`           | `<C>`                      | Capture a note via a one-line _prompt_.                          |
| `kak-notes-open-capture`        | `kak-notes`            | `<c>`                      | Open the capture file.                                           |
| `kak-notes-task-switch-status`  | `kak-notes-tasks`      | `<t>`, `<w>`, `<d>`, `<n>` | Switch the status of the task on the current line to `%arg{1}`.  |
| `kak-notes-task-gh-open-issue`  | `kak-notes-tasks`      | `<i>`                      | Open GitHub issue under the cursor (see GitHub integration).     |
| `kak-notes-tasks-list-by-regex` |                        |                            | List tasks by regex `%arg{1}`.                                   |
| `kak-notes-tasks-list-all`      | `kak-notes-tasks-list` | `<a>`                      | List all tasks.                                                  |
| `kak-notes-search`              | `kak-notes`            | `</>`                      | Search notes (not archived ones).                                |
| `kak-notes-sync`                | `kak-notes`            | `<S>`                      | Synchronize notes via Git (see synchronization section).         |

# Highlighters

The plugin inserts two highlighters in the `shared` scope:

- `kak-notes-tasks`, used to highlight tasks like `- TODO stuff` or `- WIP blabla`, as well subtask lists like
  `- [ ] Do this` or `- [x] Done`.
- `kak-notes-tasks-list`, used for the list view (similar to the `*grep*` buffer).

# Configure

Options:

| Option                   |  Default   | Notes                                     |
| ======                   |  =======   | =====                                     |
| `kak_notes_root_dir`     |            | Root directory where to hold all notes.   |
| `kak_notes_dir`          |            | Notes directory.                          |
| `kak_notes_archives_dir` |            | Archives directory.                       |
| `kak_notes_journal_dir`  |            | Journal directory.                        |
| `kak_notes_capture_file` |            | Capture file path.                        |
| `kak_notes_sym_todo`     | `'TODO'`   | Text to use for todo tasks.               |
| `kak_notes_sym_wip`      | `'WIP'`    | Text to use for on-going tasks.           |
| `kak_notes_sym_done`     | `'DONE'`   | Text to use for done tasks.               |
| `kak_notes_sym_wontdo`   | `'WONTDO'` | Text to use for tasks that won’t be done. |
