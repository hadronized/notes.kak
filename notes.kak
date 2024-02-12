# A simple plugin to add visual task management ot Markdown files.

declare-option str kak_notes_root_dir
declare-option str kak_notes_dir
declare-option str kak_notes_archives_dir
declare-option str kak_notes_journal_dir
declare-option str kak_notes_capture_file
declare-option str kak_notes_sym_todo 'TODO'
declare-option str kak_notes_sym_wip 'WIP'
declare-option str kak_notes_sym_done 'DONE'
declare-option str kak_notes_sym_wontdo 'WONTDO'
declare-option str kak_notes_sym_idea 'IDEA'
declare-option str kak_notes_sym_question 'QUESTION'
declare-option str kak_notes_sym_hold 'HOLD'
declare-option str kak_notes_find 'fd -t file .md'
declare-option str kak_notes_find_dir 'fd -t directory .'
declare-option -hidden str kak_notes_tasks_list_current_line

declare-user-mode kak-notes
declare-user-mode kak-notes-tasks
declare-user-mode kak-notes-tasks-list

set-face global kak_notes_todo green
set-face global kak_notes_wip magenta
set-face global kak_notes_done black
set-face global kak_notes_done_text black
set-face global kak_notes_wontdo black
set-face global kak_notes_wontdo_text black+s
set-face global kak_notes_idea green
set-face global kak_notes_question cyan
set-face global kak_notes_hold magenta
set-face global kak_notes_issue cyan+u
set-face global kak_notes_task_list_delimiter black
set-face global kak_notes_task_list_path blue
set-face global kak_notes_task_list_line white
set-face global kak_notes_task_list_col white
set-face global kak_notes_subtask_uncheck green
set-face global kak_notes_subtask_check black
set-face global kak_notes_subtask_text_check black
set-face global kak_notes_tag green

define-command kak-notes-journal-open-daily -docstring 'open daily journal' %{
  nop %sh{
    mkdir -p "$kak_opt_kak_notes_journal_dir/$(date +%Y/%b)"
  }

  edit "%opt{kak_notes_journal_dir}/%sh{ date '+%Y/%b/%a %d' }.md"
}

define-command kak-notes-journal-open -docstring 'open journal' %{
  prompt -menu -shell-script-candidates "$kak_opt_kak_notes_find $kak_opt_kak_notes_journal_dir" 'open journal:' %{
    edit "%val{text}"
  }
}

define-command kak-notes-open -docstring 'open note' %{
  prompt -menu -shell-script-candidates "$kak_opt_kak_notes_find $kak_opt_kak_notes_dir" 'open note:' %{
    edit %sh{
      echo "${kak_text%.md}.md"
    }
  }
}

define-command kak-notes-new-note -docstring 'new note' %{
  prompt note: %{
    edit %sh{
      echo "$kak_opt_kak_notes_dir/${kak_text%.md}.md"
    }
  }
}

define-command kak-notes-archive-note -docstring 'archive note' %{
  prompt -menu -shell-script-candidates "$kak_opt_kak_notes_find $kak_opt_kak_notes_dir" archive: %{
    nop %sh{
      mkdir -p "$kak_opt_kak_notes_archives_dir"
      mv "$kak_text" "$kak_opt_kak_notes_archives_dir/"
    }
  }
}

define-command kak-notes-archive-open -docstring 'open archive' %{
  prompt -menu -shell-script-candidates "$kak_opt_kak_notes_find $kak_opt_kak_notes_archives_dir" 'open archive:' %{
    edit %sh{
      echo "${kak_text%.md}.md"
    }
  }
}

define-command kak-notes-capture -docstring 'capture' %{
  prompt capture: %{
    nop %sh{
      echo "> $(date '+%a %b %d %Y, %H:%M:%S')\n$kak_text\n" >> "$kak_opt_kak_notes_capture_file"
    }
  }
}

define-command kak-notes-open-capture -docstring 'open capture' %{
  edit %opt{kak_notes_capture_file}
}

define-command kak-notes-task-switch-status -params 1 -docstring 'switch task' %{
  execute-keys -draft "gif<space>e_c%arg{1}"
}

define-command kak-notes-task-gh-open-issue -docstring 'open GitHub issue' %{
  evaluate-commands -save-regs 'il' %{
    try %{
      execute-keys -draft '<a-i>w"iy'
      execute-keys -draft '%sgithub_project: <ret>;<a-W>_"ly'
      nop %sh{
        open "https://github.com/$kak_reg_l/issues/$kak_reg_i"
      }
    }
  }
}

define-command kak-notes-tasks-list-by-regex -params 1 -docstring 'list tasks by status' %{
  edit -scratch *kak-notes-tasks-list*
  unset-option buffer kak_notes_tasks_list_current_line
  execute-keys "%%d|rg -n --column -e '%arg{1}' %opt{kak_notes_dir} %opt{kak_notes_journal_dir} %opt{kak_notes_capture_file}<ret>|sort<ret>gg"
}

define-command kak-notes-tasks-list-all -docstring 'list all tasks' %{
  kak-notes-tasks-list-by-regex "%opt{kak_notes_sym_todo}\|%opt{kak_notes_sym_wip}\|%opt{kak_notes_sym_done}\|%opt{kak_notes_sym_wontdo}\|%opt{kak_notes_sym_idea}\|%opt{kak_notes_sym_question}\|opt{kak_notes_sym_hold}"
}

# Command executed when pressing <ret> in a *kak-notes-tasks-list* buffer.
define-command -hidden kak-notes-tasks-list-open %{
  set-option buffer kak_notes_tasks_list_current_line %val{cursor_line}
  execute-keys -with-hooks -save-regs 'flc' 'giT:"fyllT:"lyllT:"cy:edit "%reg{f}" %reg{l} %reg{c}<ret>'
}

# Run a grepper with the provided arguments as search query.
define-command kak-notes-grepcmd -params 2 %{
  # Initial implementation based on rg <pattern> <path>.
  execute-keys ":grep %arg{2} %arg{1}<ret>"
}

define-command kak-notes-search -docstring 'search notes' %{
  prompt 'search notes:' %{
    kak-notes-grepcmd %opt{kak_notes_root_dir} %val{text}
  }
}

define-command kak-notes-sync -docstring 'synchronize notes' %{
  # First, we always check-in new modifications; then, we check whether we have anything else to send
  info -title 'kak-notes' 'starting synchronizing…'

  nop %sh{
    cd $kak_opt_kak_notes_root_dir
    git fetch --prune origin
    git rebase --autostash origin/master
    git add -A .
    git commit -m "$(date +'Sync update %a %b %d %Y')"
    git push origin
  }

  info -title 'kak-notes' 'finished synchronizing'
}

add-highlighter shared/kak-notes-tasks group
add-highlighter shared/kak-notes-tasks/todo regex "(%opt{kak_notes_sym_todo})"         0:kak_notes_todo
add-highlighter shared/kak-notes-tasks/wip regex "(%opt{kak_notes_sym_wip})"           0:kak_notes_wip
add-highlighter shared/kak-notes-tasks/done regex "(%opt{kak_notes_sym_done})"         0:kak_notes_done
add-highlighter shared/kak-notes-tasks/wontdo regex "(%opt{kak_notes_sym_wontdo})"     0:kak_notes_wontdo
add-highlighter shared/kak-notes-tasks/idea regex "(%opt{kak_notes_sym_idea})"         0:kak_notes_idea
add-highlighter shared/kak-notes-tasks/question regex "(%opt{kak_notes_sym_question})" 0:kak_notes_question
add-highlighter shared/kak-notes-tasks/hold regex "(%opt{kak_notes_sym_hold})"         0:kak_notes_hold
add-highlighter shared/kak-notes-tasks/issue regex " (#[0-9]+)"                        0:kak_notes_issue
add-highlighter shared/kak-notes-tasks/subtask-uncheck regex "-\s* (\[ \])[^\n]*"      0:kak_notes_subtask_uncheck
add-highlighter shared/kak-notes-tasks/subtask-check regex "-\s* (\[x\])\s*([^\n]*)"\
  1:kak_notes_subtask_check 2:kak_notes_subtask_text_check
add-highlighter shared/kak-notes-tasks/tag regex " (:[^:]+:)" 0:kak_notes_tag

add-highlighter shared/kak-notes-tasks-list group
add-highlighter shared/kak-notes-tasks-list/path regex "^((?:\w:)?[^:\n]+):(\d+):(\d+)?" 1:cyan 2:green 3:green
add-highlighter shared/kak-notes-tasks-list/current-line line %{%opt{kak_notes_tasks_list_current_line}} default+b

map global kak-notes / ':kak-notes-search<ret>'                     -docstring 'search in notes'
map global kak-notes A ':kak-notes-archive-note<ret>'               -docstring 'archive note'
map global kak-notes C ':kak-notes-capture<ret>'                    -docstring 'capture'
map global kak-notes J ':kak-notes-journal-open-daily<ret>'         -docstring 'open daily'
map global kak-notes N ':kak-notes-new-note<ret>'                   -docstring 'new note'
map global kak-notes S ':kak-notes-sync<ret>'                       -docstring 'synchronize notes'
map global kak-notes a ':kak-notes-archive-open<ret>'               -docstring 'open archived note'
map global kak-notes c ':kak-notes-open-capture<ret>'               -docstring 'open capture'
map global kak-notes j ':kak-notes-journal-open<ret>'               -docstring 'open past journal'
map global kak-notes l ':enter-user-mode kak-notes-tasks-list<ret>' -docstring 'tasks list'
map global kak-notes n ':kak-notes-open<ret>'                       -docstring 'open note'
map global kak-notes t ':enter-user-mode kak-notes-tasks<ret>'      -docstring 'tasks'

map global kak-notes-tasks-list a ":kak-notes-tasks-list-all<ret>"                                   -docstring 'list all tasks'
map global kak-notes-tasks-list d ":kak-notes-tasks-list-by-regex %opt{kak_notes_sym_done}<ret>"     -docstring 'list done tasks'
map global kak-notes-tasks-list h ":kak-notes-tasks-list-by-regex %opt{kak_notes_sym_hold}<ret>"     -docstring 'list hold tasks'
map global kak-notes-tasks-list i ":kak-notes-tasks-list-by-regex %opt{kak_notes_sym_idea}<ret>"     -docstring 'list ideas'
map global kak-notes-tasks-list l ":kak-notes-tasks-list-by-regex '\ :[^:]+:'<ret>"                  -docstring 'list tasks by labels'
map global kak-notes-tasks-list n ":kak-notes-tasks-list-by-regex %opt{kak_notes_sym_wontdo}<ret>"   -docstring 'list wontdo tasks'
map global kak-notes-tasks-list q ":kak-notes-tasks-list-by-regex %opt{kak_notes_sym_question}<ret>" -docstring 'list questions'
map global kak-notes-tasks-list t ":kak-notes-tasks-list-by-regex %opt{kak_notes_sym_todo}<ret>"     -docstring 'list todo tasks'
map global kak-notes-tasks-list w ":kak-notes-tasks-list-by-regex %opt{kak_notes_sym_wip}<ret>"      -docstring 'list wip tasks'

hook -group kak-notes-tasks global WinCreate \*kak-notes-tasks-list\* %{
  map buffer normal '<ret>' ':kak-notes-tasks-list-open<ret>'
  add-highlighter window/ ref kak-notes-tasks
  add-highlighter window/ ref kak-notes-tasks-list
}

hook -group kak-notes-tasks global WinCreate .*\.md %{
  add-highlighter window/ ref kak-notes-tasks

  map window kak-notes-tasks <ret> ":kak-notes-task-gh-open-issue<ret>"                          -docstring 'open GitHub issue'
  map window kak-notes-tasks d ":kak-notes-task-switch-status %opt{kak_notes_sym_done}<ret>"     -docstring 'switch task to done'
  map window kak-notes-tasks i ":kak-notes-task-switch-status %opt{kak_notes_sym_idea}<ret>"     -docstring 'switch task to idea'
  map window kak-notes-tasks h ":kak-notes-task-switch-status %opt{kak_notes_sym_hold}<ret>"     -docstring 'switch task to hold'
  map window kak-notes-tasks q ":kak-notes-task-switch-status %opt{kak_notes_sym_question}<ret>" -docstring 'switch task to question'
  map window kak-notes-tasks n ":kak-notes-task-switch-status %opt{kak_notes_sym_wontdo}<ret>"   -docstring 'switch task to wontdo'
  map window kak-notes-tasks t ":kak-notes-task-switch-status %opt{kak_notes_sym_todo}<ret>"     -docstring 'switch task to todo'
  map window kak-notes-tasks w ":kak-notes-task-switch-status %opt{kak_notes_sym_wip}<ret>"      -docstring 'switch task to wip'
}
