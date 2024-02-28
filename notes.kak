# A simple plugin to add visual task management ot Markdown files.

declare-option str notes_root_dir
declare-option str notes_dir
declare-option str notes_archives_dir
declare-option str notes_journal_dir
declare-option str notes_capture_file
declare-option str notes_sym_todo 'TODO'
declare-option str notes_sym_wip 'WIP'
declare-option str notes_sym_done 'DONE'
declare-option str notes_sym_wontdo 'WONTDO'
declare-option str notes_sym_idea 'IDEA'
declare-option str notes_sym_question 'QUESTION'
declare-option str notes_sym_hold 'HOLD'
declare-option str notes_find 'fd -t file .md'
declare-option str notes_find_dir 'fd -t directory .'
declare-option -hidden str notes_tasks_list_current_line
declare-option -hidden str notes_journal_now

declare-user-mode notes
declare-user-mode notes-tasks
declare-user-mode notes-tasks-list
declare-user-mode notes-journal-nav
declare-user-mode notes-journal-nav-last

set-face global notes_todo green
set-face global notes_wip magenta
set-face global notes_done black
set-face global notes_done_text black
set-face global notes_wontdo black
set-face global notes_wontdo_text black+s
set-face global notes_idea green
set-face global notes_question cyan
set-face global notes_hold magenta
set-face global notes_issue cyan+u
set-face global notes_task_list_delimiter black
set-face global notes_task_list_path blue
set-face global notes_task_list_line white
set-face global notes_task_list_col white
set-face global notes_subtask_uncheck green
set-face global notes_subtask_check black
set-face global notes_subtask_text_check black
set-face global notes_tag green

define-command notes-journal-open -docstring 'open daily journal' %{
  nop %sh{
    mkdir -p "$kak_opt_notes_journal_dir/$(date +%Y/%b)"
  }

	evaluate-commands %{
    edit "%opt{notes_journal_dir}/%sh{ date '+%Y/%b/%a %d' }.md"
    set-option buffer notes_journal_now %sh{ date }
	}
}

define-command notes-journal-open-rel -params -1 %{
  nop %sh{
    mkdir -p "$kak_opt_notes_journal_dir/$(date -d ""$kak_opt_notes_journal_now $1"" +%Y/%b)"
  }

	evaluate-commands %{
    edit -existing "%opt{notes_journal_dir}/%sh{ date -d ""$kak_opt_notes_journal_now $1"" ""+%Y/%b/%a %d"" }.md"
    set-option buffer notes_journal_now %sh{ date -d """$kak_opt_notes_journal_now $1""" }
	}
}

define-command notes-open -docstring 'open note' %{
  prompt -menu -shell-script-candidates "$kak_opt_notes_find $kak_opt_notes_dir" 'open note:' %{
    edit %sh{
      echo "${kak_text%.md}.md"
    }
  }
}

define-command notes-new-note -docstring 'new note' %{
  prompt note: %{
    edit %sh{
      echo "$kak_opt_notes_dir/${kak_text%.md}.md"
    }
  }
}

define-command notes-archive-note -docstring 'archive note' %{
  prompt -menu -shell-script-candidates "$kak_opt_notes_find $kak_opt_notes_dir" archive: %{
    nop %sh{
      mkdir -p "$kak_opt_notes_archives_dir"
      mv "$kak_text" "$kak_opt_notes_archives_dir/"
    }
  }
}

define-command notes-archive-open -docstring 'open archive' %{
  prompt -menu -shell-script-candidates "$kak_opt_notes_find $kak_opt_notes_archives_dir" 'open archive:' %{
    edit %sh{
      echo "${kak_text%.md}.md"
    }
  }
}

define-command notes-capture -docstring 'capture' %{
  prompt capture: %{
    nop %sh{
      echo "> $(date '+%a %b %d %Y, %H:%M:%S')\n$kak_text\n" >> "$kak_opt_notes_capture_file"
    }
  }
}

define-command notes-open-capture -docstring 'open capture' %{
  edit %opt{notes_capture_file}
}

define-command notes-task-switch-status -params 1 -docstring 'switch task' %{
  execute-keys -draft "gif<space>e_c%arg{1}"
}

define-command notes-task-gh-open-issue -docstring 'open GitHub issue' %{
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

define-command notes-tasks-list-by-regex -params 1 -docstring 'list tasks by status' %{
  edit -scratch *notes-tasks-list*
  unset-option buffer notes_tasks_list_current_line
  execute-keys "%%d|rg -n --column -e '%arg{1}' %opt{notes_dir} %opt{notes_journal_dir} %opt{notes_capture_file}<ret>|sort<ret>gg"
}

define-command notes-tasks-list-all -docstring 'list all tasks' %{
  notes-tasks-list-by-regex "%opt{notes_sym_todo}\|%opt{notes_sym_wip}\|%opt{notes_sym_done}\|%opt{notes_sym_wontdo}\|%opt{notes_sym_idea}\|%opt{notes_sym_question}\|opt{notes_sym_hold}"
}

# Command executed when pressing <ret> in a *notes-tasks-list* buffer.
define-command -hidden notes-tasks-list-open %{
  set-option buffer notes_tasks_list_current_line %val{cursor_line}
  execute-keys -with-hooks -save-regs 'flc' 'giT:"fyllT:"lyllT:"cy:edit "%reg{f}" %reg{l} %reg{c}<ret>'
}

# Run a grepper with the provided arguments as search query.
define-command notes-grepcmd -params 2 %{
  # Initial implementation based on rg <pattern> <path>.
  execute-keys ":grep %arg{2} %arg{1}<ret>"
}

define-command notes-search -docstring 'search notes' %{
  prompt 'search notes:' %{
    notes-grepcmd %opt{notes_root_dir} %val{text}
  }
}

define-command notes-sync -docstring 'synchronize notes' %{
  # First, we always check-in new modifications; then, we check whether we have anything else to send
  info -title 'notes' 'starting synchronizing…'

  nop %sh{
    cd $kak_opt_notes_root_dir
    git fetch --prune origin
    git rebase --autostash origin/master
    git add -A .
    git commit -m "$(date +'Sync update %a %b %d %Y')"
    git push origin
  }

  info -title 'notes' 'finished synchronizing'
}

add-highlighter shared/notes-tasks group
add-highlighter shared/notes-tasks/todo regex "(%opt{notes_sym_todo})"         1:notes_todo
add-highlighter shared/notes-tasks/wip regex "(%opt{notes_sym_wip})"           1:notes_wip
add-highlighter shared/notes-tasks/done regex "(%opt{notes_sym_done})"         1:notes_done
add-highlighter shared/notes-tasks/wontdo regex "(%opt{notes_sym_wontdo})"     1:notes_wontdo
add-highlighter shared/notes-tasks/idea regex "(%opt{notes_sym_idea})"         1:notes_idea
add-highlighter shared/notes-tasks/question regex "(%opt{notes_sym_question})" 1:notes_question
add-highlighter shared/notes-tasks/hold regex "(%opt{notes_sym_hold})"         1:notes_hold
add-highlighter shared/notes-tasks/issue regex " (#[0-9]+)"                    1:notes_issue
add-highlighter shared/notes-tasks/subtask-uncheck regex "-\s* (\[ \])[^\n]*"  1:notes_subtask_uncheck
add-highlighter shared/notes-tasks/subtask-check regex "-\s* (\[x\])\s*([^\n]*)"\
  1:notes_subtask_check 2:notes_subtask_text_check
add-highlighter shared/notes-tasks/tag regex " (:[^:]+:)" 0:notes_tag

add-highlighter shared/notes-tasks-list group
add-highlighter shared/notes-tasks-list/path regex "^((?:\w:)?[^:\n]+):(\d+):(\d+)?" 1:cyan 2:green 3:green
add-highlighter shared/notes-tasks-list/current-line line %{%opt{notes_tasks_list_current_line}} default+b

map global notes A ':notes-archive-note<ret>'                -docstring 'archive note'
map global notes a ':notes-archive-open<ret>'                -docstring 'open archived note'
map global notes C ':notes-capture<ret>'                     -docstring 'capture'
map global notes c ':notes-open-capture<ret>'                -docstring 'open capture'
map global notes j ':notes-journal-open<ret>'                -docstring 'open journal'
map global notes J ':enter-user-mode notes-journal-nav<ret>' -docstring 'navigate journals'
map global notes l ':enter-user-mode notes-tasks-list<ret>'  -docstring 'tasks list'
map global notes N ':notes-new-note<ret>'                    -docstring 'new note'
map global notes n ':notes-open<ret>'                        -docstring 'open note'
map global notes / ':notes-search<ret>'                      -docstring 'search in notes'
map global notes S ':notes-sync<ret>'                        -docstring 'synchronize notes'
map global notes t ':enter-user-mode notes-tasks<ret>'       -docstring 'tasks'

map global notes-journal-nav l ':enter-user-mode notes-journal-nav-last<ret>' -docstring 'last…'
map global notes-journal-nav d ':notes-journal-open-rel "-1 day"<ret>'        -docstring 'day before'
map global notes-journal-nav D ':notes-journal-open-rel "+1 day"<ret>'        -docstring 'day after'
map global notes-journal-nav w ':notes-journal-open-rel "-1 week"<ret>'       -docstring 'week before'
map global notes-journal-nav W ':notes-journal-open-rel "+1 week"<ret>'       -docstring 'week after'
map global notes-journal-nav m ':notes-journal-open-rel "-1 month"<ret>'      -docstring 'month before'
map global notes-journal-nav M ':notes-journal-open-rel "+1 month"<ret>'      -docstring 'month after'

map global notes-journal-nav-last m ':notes-journal-open-rel "last monday"<ret>'    -docstring 'monday'
map global notes-journal-nav-last t ':notes-journal-open-rel "last tuesday"<ret>'   -docstring 'tuesday'
map global notes-journal-nav-last w ':notes-journal-open-rel "last wednesday"<ret>' -docstring 'wednesday'
map global notes-journal-nav-last h ':notes-journal-open-rel "last thursday"<ret>'  -docstring 'thursday'
map global notes-journal-nav-last f ':notes-journal-open-rel "last friday"<ret>'    -docstring 'friday'
map global notes-journal-nav-last T ':notes-journal-open-rel "last saturday"<ret>'  -docstring 'saturday'
map global notes-journal-nav-last S ':notes-journal-open-rel "last sunday"<ret>'    -docstring 'sunday'

map global notes-tasks-list a ":notes-tasks-list-all<ret>"                               -docstring 'list all tasks'
map global notes-tasks-list d ":notes-tasks-list-by-regex %opt{notes_sym_done}<ret>"     -docstring 'list done tasks'
map global notes-tasks-list h ":notes-tasks-list-by-regex %opt{notes_sym_hold}<ret>"     -docstring 'list hold tasks'
map global notes-tasks-list i ":notes-tasks-list-by-regex %opt{notes_sym_idea}<ret>"     -docstring 'list ideas'
map global notes-tasks-list l ":notes-tasks-list-by-regex '\ :[^:]+:'<ret>"              -docstring 'list tasks by labels'
map global notes-tasks-list n ":notes-tasks-list-by-regex %opt{notes_sym_wontdo}<ret>"   -docstring 'list wontdo tasks'
map global notes-tasks-list q ":notes-tasks-list-by-regex %opt{notes_sym_question}<ret>" -docstring 'list questions'
map global notes-tasks-list t ":notes-tasks-list-by-regex %opt{notes_sym_todo}<ret>"     -docstring 'list todo tasks'
map global notes-tasks-list w ":notes-tasks-list-by-regex %opt{notes_sym_wip}<ret>"      -docstring 'list wip tasks'

hook -group notes-tasks global WinCreate \*notes-tasks-list\* %{
  map buffer normal '<ret>' ':notes-tasks-list-open<ret>'
  add-highlighter window/ ref notes-tasks
  add-highlighter window/ ref notes-tasks-list
}

hook -group notes-tasks global WinCreate .*\.md %{
  add-highlighter window/ ref notes-tasks

  map window notes-tasks d ":notes-task-switch-status %opt{notes_sym_done}<ret>"     -docstring 'switch task to done'
  map window notes-tasks h ":notes-task-switch-status %opt{notes_sym_hold}<ret>"     -docstring 'switch task to hold'
  map window notes-tasks i ":notes-task-switch-status %opt{notes_sym_idea}<ret>"     -docstring 'switch task to idea'
  map window notes-tasks n ":notes-task-switch-status %opt{notes_sym_wontdo}<ret>"   -docstring 'switch task to wontdo'
  map window notes-tasks q ":notes-task-switch-status %opt{notes_sym_question}<ret>" -docstring 'switch task to question'
  map window notes-tasks <ret> ":notes-task-gh-open-issue<ret>"                      -docstring 'open GitHub issue'
  map window notes-tasks t ":notes-task-switch-status %opt{notes_sym_todo}<ret>"     -docstring 'switch task to todo'
  map window notes-tasks w ":notes-task-switch-status %opt{notes_sym_wip}<ret>"      -docstring 'switch task to wip'
}
