; -*-Emacs-Lisp-*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; File:         xcscope.el
; RCS:          $RCSfile: xcscope.el,v $ $Revision: 1.11 $ $Date: 2000/05/22 17:13:27 $ $Author: darrylo $
; Description:  cscope interface for XEmacs
; Author:       Darryl Okahata
; Created:      Wed Apr 19 17:03:38 2000
; Modified:     Wed May 31 14:11:44 2000 (Darryl Okahata) darrylo@soco.agilent.com
; Language:     Emacs-Lisp
; Package:      N/A
; Status:       Experimental
;
; (C) Copyright 2000, Darryl Okahata, all rights reserved.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ALPHA VERSION 0.85
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is a cscope interface for XEmacs.
;; It currently runs under Unix only.
;;
;; Using cscope, you can easily search for where symbols are used and defined.
;; Cscope is designed to answer questions like:
;;
;;         Where is this variable used?
;;         What is the value of this preprocessor symbol?
;;         Where is this function in the source files?
;;         What functions call this function?
;;         What functions are called by this function?
;;         Where does the message "out of space" come from?
;;         Where is this source file in the directory structure?
;;         What files include this header file?
;;
;; Send comments to one of:     darrylo@soco.agilent.com
;;                              darryl_okahata@agilent.com
;;                              darrylo@sonic.net
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ***** INSTALLATION *****
;;
;; * NOTE: this interface currently runs under Unix only.
;;
;; This module needs a shell script called "cscope-indexer", which
;; should have been supplied along with this emacs-lisp file.  The
;; purpose of "cscope-indexer" is to create and optionally maintain
;; the cscope databases.  If all of your source files are in one
;; directory, you don't need this script; it's very nice to have,
;; though, as it handles recursive subdirectory indexing, and can be
;; used in a nightly or weekly cron job to index very large source
;; repositories.  See the beginning of the file, "cscope-indexer", for
;; usage information.
;;
;; Installation steps:
;;
;; 0. (It is, of course, assumed that cscope is already properly
;;    installed on the current system.)
;;
;; 1. Install the "cscope-indexer" script into some convenient
;;    directory in $PATH.  The only real constraint is that XEmacs
;;    must be able to find and execute it.  You may also have to edit
;;    the value of PATH in the script, although this is unlikely; the
;;    majority of people should be able to use the script, "as-is".
;;
;; 2. Make sure that the "cscope-indexer" script is executable.  In
;;    particular, if you had to ftp this file, it is probably no
;;    longer executable.
;;
;; 3. Put this emacs-lisp file somewhere where XEmacs can find it.  It
;;    basically has to be in some directory listed in "load-path".
;;
;; 4. Edit your ~/.emacs file to add the line:
;;
;;      (require 'xcscope)
;;
;; 5. Restart XEmacs.  That's it.
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ***** USING THIS MODULE *****
;;
;; * Basic usage:
;;
;; If all of your C/C++/lex/yacc source files are in the same
;; directory, you can just start using this module.  If your files are
;; spread out over multiple directories, see "Advanced usage", below.
;;
;; Just edit a source file, and use the pull-down or pop-up (button 3)
;; menus to select one of:
;;
;;         Find symbol
;;         Find global definition
;;         Find called functions
;;         Find functions calling a function
;;         Find text string
;;         Find egrep pattern
;;         Find a file
;;         Find files #including a file
;;
;; The cscope database will be automatically created in the same
;; directory as the source files (assuming that you've never used
;; cscope before), and a buffer will pop-up displaying the results.
;; You can then use button 2 (the middle button) on the mouse to edit
;; the selected file, or you can move the text cursor over a selection
;; and press [Enter].
;;
;; Hopefully, the interface should be fairly intuitive.
;;
;;
;; * Locating the cscope databases:
;;
;; This module will first use the variable, `cscope-database-regexps',
;; to search for a suitable database directory.  If a database
;; location cannot be found using this variable, then the current
;; directory is searched, then the parent, then the parent's parent,
;; etc. until a cscope database directory is found, or the root
;; directory is reached.  If the root directory is reached, the
;; current directory will be used.
;;
;; A cscope database directory is one in which EITHER a cscope
;; database file (e.g., "cscope.out") OR a cscope file list (e.g.,
;; "cscope.files") exists.  If only "cscope.files" exists, the
;; corresponding "cscope.out" will be automatically created by cscope
;; when a search is done.
;;
;; Note that the variable, `cscope-database-regexps', is generally not
;; needed, as the normal hierarchical database search is sufficient
;; for placing and/or locating the cscope databases.  However, there
;; may be cases where it makes sense to place the cscope databases
;; away from where the source files are kept; in this case, this
;; variable is used to determine the mapping.  One use for this
;; variable is when you want to share the database file with other
;; users; in this case, the database may be located in a directory
;; separate from the source files.
;;
;;
;; * Keybindings:
;;
;; All keybindings use the "C-c s" prefix, but are usable only while
;; editing a source file, or in the cscope results buffer:
;;
;;      C-c s s         Find symbol.
;;      C-c s d         Find global definition.
;;      C-c s g         Find global definition (alternate binding).
;;      C-c s c         Find functions calling a function.
;;      C-c s C         Find called functions (list functions called
;;                      from a function).
;;      C-c s t         Find text string.
;;      C-c s e         Find egrep pattern.
;;      C-c s f         Find a file.
;;      C-c s i         Find files #including a file.
;;
;; These pertain to cscope database maintanance:
;;
;;      C-c s L         Create list of files to index.
;;      C-c s I         Create list and index.
;;      C-c s E         Edit list of files to index.
;;      C-c s W         Locate this buffer's cscope directory
;;                      ("W" --> "where").
;;      C-c s S         Locate this buffer's cscope directory.
;;                      (alternate binding: "S" --> "show").
;;      C-c s T         Locate this buffer's cscope directory.
;;                      (alternate binding: "T" --> "tell").
;;      C-c s D         Dired this buffer's directory.
;;
;;
;; * Advanced usage:
;;
;; If the source files are spread out over multiple directories,
;; you've got a few choices:
;;
;; [ NOTE: you will need to have the script, "cscope-indexer",
;;   properly installed in order for the following to work.  ]
;;
;; 1. If all of the directories exist below a common directory
;;    (without any extraneous, unrelated subdirectories), you can tell
;;    this module to place the cscope database into the top-level,
;;    common directory.  This assumes that you do not have any cscope
;;    databases in any of the subdirectories.  If you do, you should
;;    delete them; otherwise, they will take precedence over the
;;    top-level database.
;;
;;    If you do have cscope databases in any subdirectory, the
;;    following instructions may not work right.
;;
;;    It's pretty easy to tell this module to use a top-level, common
;;    directory:
;;
;;    a. Make sure that the menu pick, "Cscope/Index recursively", is
;;       checked (the default value).
;;
;;    b. Select the menu pick, "Cscope/Create list and index", and
;;       specify the top-level directory.  This will run the script,
;;       "cscope-indexer", in the background, so you can do other
;;       things if indexing takes a long time.  A list of files to
;;       index will be created in "cscope.files", and the cscope
;;       database will be created in "cscope.out".
;;
;;    Once this has been done, you can then use the menu picks
;;    (described in "Basic usage", above) to search for symbols.
;;
;;    Note, however, that, if you add or delete source files, you'll
;;    have to either rebuild the database using the above procedure,
;;    or edit the file, "cscope.files" to add/delete the names of the
;;    source files.  To edit this file, you can use the menu pick,
;;    "Cscope/Edit list of files to index".
;;
;;
;; 2. If most of the files exist below a common directory, but a few
;;    are outside, you can use the menu pick, "Cscope/Create list of
;;    files to index", and specify the top-level directory.  Make sure
;;    that "Cscope/Index recursively", is checked before you do so,
;;    though.  You can then edit the list of files to index using the
;;    menu pick, "Cscope/Edit list of files to index".  Just edit the
;;    list to include any additional source files not already listed.
;;
;;    Once you've created, edited, and saved the list, you can then
;;    use the menu picks described under "Basic usage", above, to
;;    search for symbols.  The first time you search, you will have to
;;    wait a while for cscope to fully index the source files, though.
;;    If you have a lot of source files, you may want to manually run
;;    cscope to build the database:
;;
;;            cd top-level-directory    # or whereever
;;            rm -f cscope.out          # not always necessary
;;            cscope -b
;;
;;
;; 3. If the source files are scattered in many different, unrelated
;;    places, you'll have to manually create cscope.files and put a
;;    list of all pathnames into it.  Then build the database using:
;;
;;            cd some-directory         # whereever cscope.files exists
;;            rm -f cscope.out          # not always necessary
;;            cscope -b
;;
;;    Next, read the documentation for the variable,
;;    "cscope-database-regexps", and set it appropriately, such that
;;    the above-created cscope database will be referenced when you
;;    edit a related source file.
;;
;;    Once this has been done, you can then use the menu picks
;;    described under "Basic usage", above, to search for symbols.
;;
;;
;; * Interesting configuration variables:
;;
;; "cscope-truncate-lines"
;;      This is the value of `truncate-lines' to use in cscope
;;      buffers; the default is the current setting of
;;      `truncate-lines'.  This variable exists because it can be
;;      easier to read cscope buffers with truncated lines, while
;;      other buffers do not have truncated lines.
;;
;; "cscope-use-relative-paths"
;;      If non-nil, use relative paths when creating the list of files
;;      to index.  The path is relative to the directory in which the
;;      cscope database will be created.  If nil, absolute paths will
;;      be used.  Absolute paths are good if you plan on moving the
;;      database to some other directory (if you do so, you'll
;;      probably also have to modify `cscope-database-regexps').
;;      Absolute paths may also be good if you share the database file
;;      with other users (you'll probably want to specify some
;;      automounted network path for this).
;;
;; "cscope-index-recursively"
;;      If non-nil, index files in the current directory and all
;;      subdirectories.  If nil, only files in the current directory
;;      are indexed.  This variable is only used when creating the
;;      list of files to index, or when creating the list of files and
;;      the corresponding cscope database.
;;
;; "cscope-name-line-width"
;;      The width of the combined "function name:line number" field in
;;      the cscope results buffer.  If negative, the field is
;;      left-justified.
;;
;; "cscope-do-not-update-database"
;;      If non-nil, never check and/or update the cscope database when
;;      searching.  Beware of setting this to non-nil, as this will
;;      disable automatic database creation, updating, and
;;      maintenance.
;;
;; "cscope-database-regexps"
;;      List to force directory-to-cscope-database mappings.
;;      This is a list of `(REGEXP DIRECTORY OPTIONS)' triplets, where:
;;      
;;      REGEXP is a regular expression matched against the current
;;      buffer's current directory.  The current buffer is typically
;;      some source file, and you're probably searching for some
;;      symbol in or related to this file.  Basically, this regexp is
;;      used to relate the current directory to a cscope database.
;;      
;;      DIRECTORY is the name of the corresponding directory
;;      containing (or will contain, if creating) the cscope database
;;      files.
;;      
;;      OPTIONS is a string listing any additional options (e.g.,
;;      "-d") to pass to the cscope executable.  Normally, this
;;      string is empty.
;;      
;;      All of the above are strings.
;;      
;;      This variable is generally not used, as the normal
;;      hierarchical database search is sufficient for placing and/or
;;      locating the cscope databases.  However, there may be cases
;;      where it makes sense to place the cscope databases away from
;;      where the source files are kept; in this case, this variable
;;      is used to determine the mapping.
;;      
;;      This module searches for the cscope databases by first using
;;      this variable; if a database location cannot be found using
;;      this variable, then the current directory is searched, then
;;      the parent, then the parent's parent, until a cscope database
;;      directory is found, or the root directory is reached.  If the
;;      root directory is reached, the current directory will be used.
;;      
;;      A cscope database directory is one in which EITHER a cscope
;;      database file (e.g., "cscope.out") OR a cscope file list
;;      (e.g., "cscope.files") exists.
;;
;;
;; * Other notes:
;;
;; 1. The script, "cscope-indexer", uses a sed command to determine
;;    what is and is not a C/C++/lex/yacc source file.  It's idea of a
;;    source file may not correspond to yours.
;;
;; 2. This module is called, "xcscope", because someone else has
;;    already written a "cscope.el" (although it's quite old).
;;
;;
;; * KNOWN BUGS:
;;
;; 1. Cannot handle whitespace in directory or file names.
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'easymenu)


(defgroup cscope nil
  "Cscope interface for XEmacs.
Using cscope, you can easily search for where symbols are used and defined.
It is designed to answer questions like:

        Where is this variable used?
        What is the value of this preprocessor symbol?
        Where is this function in the source files?
        What functions call this function?
        What functions are called by this function?
        Where does the message \"out of space\" come from?
        Where is this source file in the directory structure?
        What files include this header file?
"
  :prefix "cscope-"
  :group 'tools)


(defcustom cscope-do-not-update-database nil
  "*If non-nil, never check and/or update the cscope database when searching.
Beware of setting this to non-nil, as this will disable automatic database
creation, updating, and maintenance."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-database-regexps nil
  "*List to force directory-to-cscope-database mappings.
This is a list of `(REGEXP DIRECTORY OPTIONS)' triplets, where:

REGEXP is a regular expression matched against the current buffer's
current directory.  The current buffer is typically some source file,
and you're probably searching for some symbol in or related to this
file.  Basically, this regexp is used to relate the current directory
to a cscope database.

DIRECTORY is the name of the corresponding directory containing (or will
contain, if creating) the cscope database files.

OPTIONS is a string listing any additional options (e.g., \"-d\") to pass
to the cscope executable.  Normally, this string is empty.

All of the above are strings.

This variable is generally not used, as the normal hierarchical
database search is sufficient for placing and/or locating the cscope
databases.  However, there may be cases where it makes sense to place
the cscope databases away from where the source files are kept; in
this case, this variable is used to determine the mapping.

This module searches for the cscope databases by first using this
variable; if a database location cannot be found using this variable,
then the current directory is searched, then the parent, then the
parent's parent, until a cscope database directory is found, or the
root directory is reached.  If the root directory is reached, the
current directory will be used.

A cscope database directory is one in which EITHER a cscope database
file (e.g., \"cscope.out\") OR a cscope file list (e.g., \"cscope.files\")
exists.
"
  :type '(repeat (list :format "%v"
		       (choice :value ""
			       (regexp :tag "Buffer regexp")
			       string)
		       (choice :value ""
			       (directory :tag "Cscope database directory")
			       string)
		       (string :value ""
			       :tag "Optional cscope command-line arguments")
		       ))
  :group 'cscope)


(defcustom cscope-name-line-width -30
  "*The width of the combined \"function name:line number\" field in the
cscope results buffer.  If negative, the field is left-justified."
  :type 'integer
  :group 'cscope)


(defcustom cscope-truncate-lines truncate-lines
  "*The value of `truncate-lines' to use in cscope buffers.
This variable exists because it can be easier to read cscope buffers
with truncated lines, while other buffers do not have truncated lines."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-display-times t
  "*If non-nil, display how long each search took.
The elasped times are in seconds.  Floating-point support is required
for this to work."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-program "cscope"
  "*The pathname of the cscope executable to use."
  :type 'string
  :group 'cscope)


(defcustom cscope-index-file "cscope.files"
  "*The name of the cscope file list file."
  :type 'string
  :group 'cscope)


(defcustom cscope-database-file "cscope.out"
  "*The name of the cscope database file."
  :type 'string
  :group 'cscope)


(defcustom cscope-edit-single-match t
  "*If non-nil and only one match is output, edit the matched location."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-stop-at-first-match-dir nil
  "*If non-nil, stop searching through multiple databases if a match is found.
This option is useful only if multiple cscope database directories are being
used.  When multiple databases are searched, setting this variable to non-nil
will cause searches to stop when a search outputs anything; no databases after
this one will be searched."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-use-relative-paths t
  "*If non-nil, use relative paths when creating the list of files to index.
The path is relative to the directory in which the cscope database
will be created.  If nil, absolute paths will be used.  Absolute paths
are good if you plan on moving the database to some other directory
(if you do so, you'll probably also have to modify
\`cscope-database-regexps\').  Absolute paths  may also be good if you
share the database file with other users (you\'ll probably want to
specify some automounted network path for this)."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-index-recursively t
  "*If non-nil, index files in the current directory and all subdirectories.
If nil, only files in the current directory are indexed.  This
variable is only used when creating the list of files to index, or
when creating the list of files and the corresponding cscope database."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-no-mouse-prompts nil
  "*If non-nil, use the file/symbol under the cursor.
Do not prompt for a value."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-indexing-script "cscope-indexer"
  "*The shell script used to create cscope indices."
  :type 'string
  :group 'cscope)


(defcustom cscope-symbol-chars "A-Za-z0-9_"
  "*A string containing legal characters in a symbol.
The current syntax table should really be used for this."
  :type 'string
  :group 'cscope)


(defvar cscope-minor-mode-hooks nil
  "List of hooks to call when entering cscope-minor-mode.")


(defconst cscope-separator-line
  "-------------------------------------------------------------------------------\n"
  "Line of text to use as a visual separator.
Must end with a newline.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Probably, nothing user-customizable past this point.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cscope-search-keymap
  (let ((m (make-keymap)))
    (set-keymap-name m 'cscope-search-keymap)
;    (suppress-keymap m t)
    (if (string-match "XEmacs" emacs-version)
	(progn
	  (define-key m 'button2 'cscope-show-message-event)
	  (define-key m [return] 'cscope-show-message-key)
	  (define-key m 'q 'bury-buffer)
	  ))
    m)
  "The keymap used for the highlighted messages in the results buffer.")


(defvar cscope-output-buffer-name "*cscope*"
  "The name of the cscope output buffer.")


(defvar cscope-info-buffer-name "*cscope-info*"
  "The name of the cscope information buffer.")


(defvar cscope-process nil
  "The current cscope process.")
(make-variable-buffer-local 'cscope-process)


(defvar cscope-process-output nil
  "A buffer for holding partial cscope process output.")
(make-variable-buffer-local 'cscope-process-output)


(defvar cscope-command-args nil
  "Internal variable for holding major command args to pass to cscope.")
(make-variable-buffer-local 'cscope-command-args)


(defvar cscope-search-list nil
  "A list of (DIR . FLAGS) entries.
This is a list of database directories to search.  Each entry in the list
is a (DIR . FLAGS) cell.  DIR is the directory to search, and FLAGS are the
flags to pass to cscope when using this database directory.  FLAGS can be
nil (meaning, \"no flags\").")
(make-variable-buffer-local 'cscope-search-list)


(defvar cscope-searched-dirs nil
  "The list of database directories already searched.")
(make-variable-buffer-local 'cscope-searched-dirs)


(defvar cscope-filter-func nil
  "Internal variable for holding the filter function to use (if any) when
searching.")
(make-variable-buffer-local 'cscope-filter-func)


(defvar cscope-last-file nil
  "The file referenced by the last line of cscope process output.")
(make-variable-buffer-local 'cscope-last-file)


(defvar cscope-start-time nil
  "The search start time, in seconds.")


(defvar cscope-first-match nil
  "The first match result output by cscope.")


(defvar cscope-first-match-point nil
  "Buffer location of the first match.")


(defvar cscope-matched-multiple nil
  "Non-nil if cscope output multiple matches.")


(defvar cscope-stop-at-first-match-dir-meta nil
  "")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cscope:map (make-sparse-keymap)
  "The cscope keymap.")

(define-key cscope:map "\C-css" 'cscope-find-this-symbol)
(define-key cscope:map "\C-csd" 'cscope-find-global-definition)
(define-key cscope:map "\C-csg" 'cscope-find-global-definition)
(define-key cscope:map "\C-csc" 'cscope-find-functions-calling-this-function)
(define-key cscope:map "\C-csC" 'cscope-find-called-functions)
(define-key cscope:map "\C-cst" 'cscope-find-this-text-string)
(define-key cscope:map "\C-cse" 'cscope-find-egrep-pattern)
(define-key cscope:map "\C-csf" 'cscope-find-this-file)
(define-key cscope:map "\C-csi" 'cscope-find-files-including-file)
;;
(define-key cscope:map "\C-csL" 'cscope-create-list-of-files-to-index)
(define-key cscope:map "\C-csI" 'cscope-index-files)
(define-key cscope:map "\C-csE" 'cscope-edit-list-of-files-to-index)
(define-key cscope:map "\C-csW" 'cscope-tell-user-about-directory)
(define-key cscope:map "\C-csS" 'cscope-tell-user-about-directory)
(define-key cscope:map "\C-csT" 'cscope-tell-user-about-directory)
(define-key cscope:map "\C-csD" 'cscope-dired-directory)

(easy-menu-define cscope:menu
		  cscope:map
		  "cscope menu"
		  '("Cscope"
		    [ "Find symbol" cscope-find-this-symbol t ]
		    [ "Find global definition" cscope-find-global-definition t ]
		    [ "Find called functions" cscope-find-called-functions t ]
		    [ "Find functions calling a function"
		      cscope-find-functions-calling-this-function t ]
		    [ "Find text string" cscope-find-this-text-string t ]
		    [ "Find egrep pattern" cscope-find-egrep-pattern t ]
		    [ "Find a file" cscope-find-this-file t ]
		    [ "Find files #including a file"
		      cscope-find-files-including-file t ]
		    "-----------"
		    [ "Create list of files to index"
		      cscope-create-list-of-files-to-index t ]
		    [ "Create list and index"
		      cscope-index-files t ]
		    [ "Edit list of files to index"
		      cscope-edit-list-of-files-to-index t ]
		    [ "Locate this buffer's cscope directory"
		      cscope-tell-user-about-directory t ]
		    [ "Dired this buffer's cscope directory"
		      cscope-dired-directory t ]
		    "-----------"
		    [ "Auto edit single match" (setq cscope-edit-single-match
						     (not cscope-edit-single-match))
		      :style toggle :selected cscope-edit-single-match ]
		    [ "Stop at first matching database"
		      (setq cscope-stop-at-first-match-dir
			    (not cscope-stop-at-first-match-dir))
		      :style toggle :selected cscope-stop-at-first-match-dir ]
		    [ "Index recursively" (setq cscope-index-recursively
						(not cscope-index-recursively))
		      :style toggle :selected cscope-index-recursively ]
		    [ "Use relative paths" (setq cscope-use-relative-paths
						 (not cscope-use-relative-paths))
		      :style toggle :selected cscope-use-relative-paths ]
		    [ "No mouse prompts" (setq cscope-no-mouse-prompts
						 (not cscope-no-mouse-prompts))
		      :style toggle :selected cscope-no-mouse-prompts ]
		    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cscope-show-message (file line-number &optional desired-window)
  "Display FILE in some window, and move to LINE-NUMBER."
  (let (buffer window)
    (setq buffer (find-file-noselect file))
    (setq window (if desired-window
		     (progn
		       (set-window-buffer desired-window buffer)
		       desired-window
		       )
		   (display-buffer buffer)))
    (set-buffer buffer)
    (if (> line-number 0)
	(progn
	  (goto-line line-number)
	  (set-window-point window (point))
	  ))
    (select-window window)
    ))


(defun cscope-show-message-key ()
  "Display the file/line number under the text cursor."
  (interactive)
  (let* ( (extent (extent-at (point) (current-buffer) 'cscope))
	  (file (extent-property extent 'cscope-file))
	  (line-number (extent-property extent 'cscope-line-number))
	 )
    (cscope-show-message file line-number)
    ))


(defun cscope-show-message-event (event)
  "Display the file/line number highlighted by the mouse."
  (interactive "e")
  (let* ( (ep (event-point event))
	  (buffer (window-buffer (event-window event)))
	  (extent (extent-at ep buffer 'cscope))
	  (file (extent-property extent 'cscope-file))
	  (line-number (extent-property extent 'cscope-line-number))
	  )
    (set-buffer buffer)		;; needed for the current directory
    (select-window (event-window event))
    (cscope-show-message file line-number)
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cscope-canonicalize-directory (dir)
  (progn
    (if (not dir)
	(setq dir default-directory))
    (setq dir (file-name-as-directory
	       (expand-file-name (substitute-in-file-name dir))))
    dir
    ))


(defun cscope-search-directory-hierarchy (directory)
  "Look for a cscope database in the directory hierarchy.
Starting from DIRECTORY, look upwards for a cscope database."
  (let (this-directory database-dir)
    (catch 'done
      (setq directory (cscope-canonicalize-directory directory)
	    this-directory directory)
      (while this-directory
	(if (or (file-exists-p (concat this-directory cscope-database-file))
		(file-exists-p (concat this-directory cscope-index-file)))
	    (progn
	      (setq database-dir this-directory)
	      (throw 'done database-dir)
	      ))
	(if (string-match "^\\(/\\|[A-Za-z]:[\\/]\\)$" this-directory)
	    (throw 'done directory))
	(setq this-directory (file-name-as-directory
			      (file-name-directory
			       (directory-file-name this-directory))))
	))
    ))


(defun cscope-find-info (top-directory)
  "Locate a suitable cscope database directory.
First, `cscope-database-regexps' is used to search for a suitable
database directory.  If a database location cannot be found using this
variable, then the current directory is searched, then the parent,
then the parent's parent, until a cscope database directory is found,
or the root directory is reached.  If the root directory is reached,
the current directory will be used."
  (let (info regexps dir-regexp this-directory)
    (setq top-directory (cscope-canonicalize-directory top-directory))

    (catch 'done

      ;; Try searching using `cscope-database-regexps' ...
      (setq regexps cscope-database-regexps)
      (while regexps
	(setq dir-regexp (car (car regexps)))
	(cond
	 ( (stringp dir-regexp)
	   (if (string-match dir-regexp top-directory)
	       (progn
		 (setq info (cdr (car regexps)))
		 (throw 'done t)
		 )) )
	 ( (and (symbolb dir-regexp) dir-regexp)
	   (progn
	     (setq info (cdr (car regexps)))
	     (throw 'done t)
	     ) ))
	(setq regexps (cdr regexps))
	)

      ;; Try looking in the directory hierarchy ...
      (if (setq this-directory
		(cscope-search-directory-hierarchy top-directory))
	  (progn
	    (setq info (list (list this-directory)))
	    (throw 'done t)
	    ))

      ;; Should we add any more places to look?

      )	;; end catch
    (if (not info)
	(setq info (list (list top-directory))))
    info
    ))


(defun cscope-insert-text-with-extent (text file line-number)
  (let (begin end extent)
    (setq begin (point))
    (insert text)
    (setq end (point))
    (setq extent (make-extent begin end))
;;;    (set-extent-face extent 'bold)
    (set-extent-property extent 'highlight t)
    (set-extent-property extent 'cscope t)
    (set-extent-property extent 'cscope-file file)
    (if (stringp line-number)
	(setq line-number (string-to-number line-number)))
    (set-extent-property extent 'cscope-line-number line-number)
    (set-extent-property extent 'keymap cscope-search-keymap)
    ))


(defun cscope-process-filter (process output)
  "Accept cscope process output and reformat it for human readability.
Magic extent properties are added to allow the user to select lines
using the mouse."
  (let ( (old-buffer (current-buffer)) )
    (unwind-protect
	(progn
	  (set-buffer (process-buffer process))
	  ;; Make buffer-read-only nil
	  (let (buffer-read-only line file function-name line-number moving
				 new-file-hook-point offset-hook-point)
	    (setq moving (= (point) (process-mark process)))
	    (save-excursion
	      (goto-char (process-mark process))
	      ;; Get the output thus far ...
	      (if cscope-process-output
		  (setq cscope-process-output (concat cscope-process-output output))
		(setq cscope-process-output output))
	      ;; Slice and dice it into lines.
	      ;; While there are whole lines left ...
	      (while (and cscope-process-output
			  (string-match "\\([^\n]+\n\\)\\(\\(.\\|\n\\)*\\)"
					cscope-process-output))
		(setq new-file-hook-point		nil
		      offset-hook-point			nil
		      file				nil
		      glimpse-stripped-directory	nil
		      )
		;; Get a line
		(setq line (substring cscope-process-output
				      (match-beginning 1) (match-end 1)))
		(setq cscope-process-output (substring cscope-process-output
						       (match-beginning 2)
						       (match-end 2)))
		(if (= (length cscope-process-output) 0)
		    (setq cscope-process-output nil))

		;; This should always match.
		(if (string-match
		     "^\\([^ \t]+\\)[ \t]+\\([^ \t]+\\)[ \t]+\\([0-9]+\\)[ \t]+\\(.*\n\\)"
		     line)
		    (progn
		      (setq file (substring line
					    (match-beginning 1) (match-end 1))
			    function-name (substring line
						     (match-beginning 2)
						     (match-end 2))
			    line-number (substring line
						   (match-beginning 3)
						   (match-end 3))
			    )
		      (setq line (substring line
					    (match-beginning 4) (match-end 4)))
		      ;; If the current file is the same as the previous
		      ;; one ...
		      (if (and cscope-last-file
			       (string= file cscope-last-file))
			  (progn
			    ;; ... setup for calling the new-line
			    ;; hook ...
			    (setq offset-hook-point (point))
			    )
			(progn
			  ;; The current file is different.

			  ;; Insert a separating blank line if
			  ;; necessary.
			  (if cscope-last-file
			      (insert "\n"))
			  ;; Insert the file name
			  (cscope-insert-text-with-extent
			   (concat "***** " file ":\n")
			   (expand-file-name file)
			   ;; Yes, -1 is intentional
			   -1)
			  ))
		      (if (not cscope-first-match)
			  (setq cscope-first-match-point (point)))
		      ;; ... and insert the line, with the
		      ;; appropriate indentation.
		      (cscope-insert-text-with-extent
		       (format "%*s %s" cscope-name-line-width
			       (format "%s:%s" function-name line-number)
			       line)
		       (expand-file-name file) line-number)
		      (setq cscope-last-file file)
		      (if cscope-first-match
			  (setq cscope-matched-multiple t)
			(setq cscope-first-match
			      (cons (expand-file-name file)
				    (string-to-number line-number))))
		      )
		  (progn
		    (insert line)
		    ))
		)
	      (set-marker (process-mark process) (point))
	      )
	    (if moving
		(goto-char (process-mark process)))
	    (set-buffer-modified-p nil)
	    ))
      (set-buffer old-buffer))
    ))


(defun cscope-process-sentinel (process event)
  "Sentinel for when the cscope process dies."
  (let ( buffer window update-window (done t) )
    (save-window-excursion
      (save-excursion
	(setq buffer (process-buffer process))
	(set-buffer buffer)
	(if (and (setq window (get-buffer-window buffer))
		 (= (window-point window) (point-max)))
	    (progn
	      (setq update-window t)
	      ))
	(delete-process process)
	(let (buffer-read-only continue)
	  (goto-char (point-max))
	  (insert cscope-separator-line)
	  (setq continue
		(and cscope-search-list
		     (not (and cscope-first-match
			       cscope-stop-at-first-match-dir
			       (not cscope-stop-at-first-match-dir-meta)))))
	  (if continue
	      (setq continue (cscope-search-one-database)))
	  (if continue
	      (progn
		(setq done nil)
		)
	    (progn
	      (insert "\nSearch complete.")
	      (if cscope-display-times
		  (let ( (times (current-time)) stop-time elapsed-time )
		    (setq cscope-stop (+ (* (car times) 65536.0)
					 (car (cdr times))
					 (* (car (cdr (cdr times))) 1.0E-6)))
		    (setq elapsed-time (- cscope-stop cscope-start-time))
		    (insert (format "  Search time = %.2f seconds."
				    elapsed-time))
		    ))
	      (setq cscope-process nil
		    modeline-process ": Search complete")
	      )
	    ))
	(set-buffer-modified-p nil)
	))
    (cond
     ( (not done)		;; we're not done -- do nothing for now
       (if update-window
	   (set-window-point window (point-max)))
       )
     ( (and cscope-edit-single-match cscope-first-match
	    (not cscope-matched-multiple))
       (progn
	 (cscope-show-message (car cscope-first-match)
			      (cdr cscope-first-match) window)
	 ))
     ( update-window
       (set-window-point window cscope-first-match-point))
     )
    ))


(defun cscope-search-one-database ()
  "Pop a database entry from cscope-search-list and do a search there."
  (let ( next-item directory options cscope-directory database-file outbuf done)
    (setq outbuf (get-buffer-create cscope-output-buffer-name))
    (save-excursion
      (catch 'finished
	(set-buffer outbuf)
	(setq options '("-L"))
	(while (and (not done) cscope-search-list)
	  (setq next-item (car cscope-search-list)
		cscope-search-list (cdr cscope-search-list)
		)
	  (if (listp next-item)
	      (progn
		(setq cscope-directory (car next-item))
		(if (not (stringp cscope-directory))
		    (setq cscope-directory
			  (cscope-search-directory-hierarchy default-directory)))
		(setq cscope-directory (file-name-as-directory cscope-directory))
		(if (not (member cscope-directory cscope-searched-dirs))
		    (progn
		      (setq cscope-searched-dirs (cons cscope-directory
						       cscope-searched-dirs)
			    done t)
		      ))
		)
	    (progn
	      (if (and cscope-first-match
		       cscope-stop-at-first-match-dir
		       cscope-stop-at-first-match-dir-meta)
		  (throw 'finished nil))
	      ))
	  )
	(if (not done)
	    (throw 'finished nil))
	(if (car (cdr next-item))
	    (let (newopts)
	      (setq newopts (car (cdr next-item)))
	      (if (not (listp newopts))
		  (error (format "Cscope options must be a list: %s" newopts)))
	      (setq options (append options newopts))
	      ))
	(if cscope-command-args
	    (setq options (append options cscope-command-args)))
	(setq database-file (concat cscope-directory cscope-database-file)
	      cscope-searched-dirs (cons cscope-directory cscope-searched-dirs)
	      )

	;; The database file and the directory containing the database file must
	;; both be writable.
	(if (or (not (file-writable-p database-file))
		(not (file-writable-p (file-name-directory database-file)))
		cscope-do-not-update-database)
	    (setq options (cons "-d" options)))

	(goto-char (point-max))
	(insert "\nDatabase directory: " cscope-directory "\n"
		cscope-separator-line)
	(setq default-directory cscope-directory)
	(if cscope-filter-func
	    (progn
	      (setq cscope-process-output nil
		    cscope-last-file nil
		    )
	      (setq cscope-process
		    (apply 'start-process "cscope" outbuf cscope-program options))
	      (set-process-filter cscope-process 'cscope-process-filter)
	      (set-process-sentinel cscope-process 'cscope-process-sentinel)
	      (set-marker (process-mark cscope-process) (point))
	      (process-kill-without-query cscope-process)
	      (setq modeline-process ": Searching ..."
		    buffer-read-only t
		    )
	      )
	  (progn
	    (apply 'call-process cscope-program nil outbuf t options)
	    ))
	t
	))
    ))


(defun cscope-call (msg args &optional directory filter-func)
  "Generic function to call to process cscope requests.
ARGS is a list of command-line arguments to pass to the cscope process.
DIRECTORY is the current working directory to use (generally, the
directory in which the cscope database is located, but not necessarily),
if different that the current one.  FILTER-FUNC is an optional process
filter."
  (let ( (outbuf (get-buffer-create cscope-output-buffer-name))
	 info options cscope-directory database-file
	 )
    (if cscope-process
	(error "A cscope search is still in progress -- only one at a time is allowed"))
    (if cscope-display-times
	(let ( (times (current-time)) )
	  (setq cscope-start-time (+ (* (car times) 65536.0) (car (cdr times))
				     (* (car (cdr (cdr times))) 1.0E-6)))))
    (setq directory (cscope-canonicalize-directory directory))
    (save-excursion
      (set-buffer outbuf)
      (setq default-directory directory
	    cscope-search-list (cscope-find-info directory)
	    cscope-searched-dirs nil
	    cscope-command-args args
	    cscope-filter-func filter-func
	    cscope-first-match nil
	    cscope-stop-at-first-match-dir-meta (memq t cscope-search-list)
	    cscope-matched-multiple nil
	    buffer-read-only nil)
      (buffer-disable-undo)
      (erase-buffer)
      (setq truncate-lines cscope-truncate-lines)
      (if msg
	  (insert msg "\n"))
      (cscope-search-one-database)
      )
    (pop-to-buffer outbuf)
    (goto-char (point-max))
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cscope-unix-index-process-buffer-name "*cscope-indexing-buffer*"
  "The name of the buffer to use for displaying indexing status/progress.")


(defvar cscope-unix-index-process-buffer nil
  "The buffer to use for displaying indexing status/progress.")


(defvar cscope-unix-index-process nil
  "The current indexing process.")


(defun cscope-unix-index-files-sentinel (process event)
  "Simple sentinel to print a message saying that indexing is finished."
  (let (buffer)
    (save-window-excursion
      (save-excursion
	(setq buffer (process-buffer process))
	(set-buffer buffer)
	(goto-char (point-max))
	(insert cscope-separator-line "\nIndexing finished\n")
	(delete-process process)
	(setq cscope-unix-index-process nil)
	(set-buffer-modified-p nil)
	))
    ))


(defun cscope-unix-index-files-internal (top-directory header-text args)
  "Core function to call the indexing script."
  (let ()
    (save-excursion
      (setq top-directory (cscope-canonicalize-directory top-directory))
      (setq cscope-unix-index-process-buffer
	    (get-buffer-create cscope-unix-index-process-buffer-name))
      (display-buffer cscope-unix-index-process-buffer)
      (set-buffer cscope-unix-index-process-buffer)
      (setq buffer-read-only nil)
      (setq default-directory top-directory)
      (buffer-disable-undo)
      (erase-buffer)
      (if header-text
	  (insert header-text))
      (setq args (append args
			 (list "-v"
			       "-i" cscope-index-file
			       "-f" cscope-database-file
			       (if cscope-use-relative-paths
				   "." top-directory))))
      (if cscope-index-recursively
	  (setq args (cons "-r" args)))
      (setq cscope-unix-index-process
	    (apply 'start-process "cscope-indexer"
		   cscope-unix-index-process-buffer
		   cscope-indexing-script args))
      (set-process-sentinel cscope-unix-index-process
			    'cscope-unix-index-files-sentinel)
      (process-kill-without-query cscope-unix-index-process)
      )
    ))


(defun cscope-index-files (top-directory)
  "Index files in a directory.
This function creates a list of files to index, and then indexes
the listed files.
The variable, \"cscope-index-recursively\", controls whether or not
subdirectories are indexed."
  (interactive "DIndex files in directory: ")
  (let ()
    (cscope-unix-index-files-internal
     top-directory 
     (format "Creating cscope index `%s' in:\n\t%s\n\n%s"
	     cscope-database-file top-directory cscope-separator-line)
     nil)
    ))


(defun cscope-create-list-of-files-to-index (top-directory)
  "Create a list of files to index.
The variable, \"cscope-index-recursively\", controls whether or not
subdirectories are indexed."
  (interactive "DCreate file list in directory: ")
  (let ()
    (cscope-unix-index-files-internal
     top-directory
     (format "Creating cscope file list `%s' in:\n\t%s\n\n"
	     cscope-index-file top-directory)
     '("-l"))
    ))


(defun cscope-edit-list-of-files-to-index ()
  "Search for and edit the list of files to index.
If this functions causes a new file to be edited, that means that a
cscope.out file was found without a corresponding cscope.files file."
  (interactive)
  (let (info directory file)
    (setq info (cscope-find-info nil))
    (if (/= (length info) 1)
	(error "There is no unique cscope database directory!"))
    (setq directory (car (car info)))
    (if (not (stringp directory))
	(setq directory
	      (cscope-search-directory-hierarchy default-directory)))
    (setq file (concat (file-name-as-directory directory) cscope-index-file))
    (find-file file)
    (message (concat "File: " file))
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cscope-tell-user-about-directory ()
  "Display the name of the directory containing the cscope database."
  (interactive)
  (let (info directory)
    (setq info (cscope-find-info nil))
    (if (= (length info) 1)
	(progn
	  (setq directory (car info))
	  (message (concat "Cscope directory: " directory))
	  )
      (let ( (outbuf (get-buffer-create cscope-info-buffer-name)) )
	(display-buffer outbuf)
	(save-excursion
	  (set-buffer outbuf)
	  (buffer-disable-undo)
	  (erase-buffer)
	  (insert "Cscope search directories:\n")
	  (while info
	    (if (listp (car info))
		(progn
		  (setq directory (car (car info)))
		  (if (not (stringp directory))
		      (setq directory
			    (cscope-search-directory-hierarchy
			     default-directory)))
		  (insert "\t" directory "\n")
		  ))
	    (setq info (cdr info))
	    )
	  )
	))
    ))


(defun cscope-dired-directory ()
  "Run dired upon the cscope database directory.
If possible, the cursor is moved to the name of the cscope database
file."
  (interactive)
  (let (info directory buffer p1 p2 pos)
    (setq info (cscope-find-info nil))
    (if (/= (length info) 1)
	(error "There is no unique cscope database directory!"))
    (setq directory (car (car info)))
    (if (not (stringp directory))
	(setq directory
	      (cscope-search-directory-hierarchy default-directory)))
    (setq buffer (dired-noselect directory nil))
    (switch-to-buffer buffer)
    (set-buffer buffer)
    (save-excursion
      (goto-char (point-min))
      (setq p1 (search-forward cscope-index-file nil t))
      (if p1
	  (setq p1 (- p1 (length cscope-index-file))))
      )
    (save-excursion
      (goto-char (point-min))
      (setq p2 (search-forward cscope-database-file nil t))
      (if p2
	  (setq p2 (- p2 (length cscope-database-file))))
      )
    (cond
     ( (and p1 p2)
       (if (< p1 p2)
	   (setq pos p1)
	 (setq pos p2))
       )
     ( p1
       (setq pos p1)
       )
     ( p2
       (setq pos p2)
       )
     )
    (if pos
	(set-window-point (get-buffer-window buffer) pos))
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cscope-extract-symbol-at-cursor ()
  (let ( (symbol-char-regexp (concat "[" cscope-symbol-chars "]")) )
    (save-excursion
      (buffer-substring
       (progn
	 (if (not (looking-at symbol-char-regexp))
	     (re-search-backward "\\w" nil t))
	 (skip-chars-backward cscope-symbol-chars)
	 (point))
       (progn
	 (skip-chars-forward cscope-symbol-chars)
	 (point)
	 )))
      ))


(defun cscope-prompt-for-symbol (prompt)
  "Prompt the user for a cscope symbol."
  (let (sym)
    (setq sym (cscope-extract-symbol-at-cursor))
    (if (not (and cscope-no-mouse-prompts current-mouse-event
		  (or (mouse-event-p current-mouse-event)
		      (misc-user-event-p current-mouse-event))))
	(setq sym (read-from-minibuffer prompt sym))
      sym)
    ))


(defun cscope-find-this-symbol (symbol)
  "Locate a symbol in source code."
  (interactive (list
		(cscope-prompt-for-symbol "Find this symbol: ")
		))
  (let ()
    (cscope-call (format "Finding symbol: %s" symbol)
		 (list "-0" symbol) nil 'cscope-process-filter)
    ))


(defun cscope-find-global-definition (symbol)
  "Find a symbol's global definition."
  (interactive (list
		(cscope-prompt-for-symbol "Find this global definition: ")
		))
  (let ()
    (cscope-call (format "Finding global definition: %s" symbol)
		 (list "-1" symbol) nil 'cscope-process-filter)
    ))


(defun cscope-find-called-functions (symbol)
  "Display functions called by a function."
  (interactive (list
		(cscope-prompt-for-symbol "Find functions called by this function: ")
		))
  (let ()
    (cscope-call (format "Finding functions called by: %s" symbol)
		 (list "-2" symbol) nil 'cscope-process-filter)
    ))


(defun cscope-find-functions-calling-this-function (symbol)
  "Display functions calling a function."
  (interactive (list
		(cscope-prompt-for-symbol "Find functions calling this function: ")
		))
  (let ()
    (cscope-call (format "Finding functions calling: %s" symbol)
		 (list "-3" symbol) nil 'cscope-process-filter)
    ))


(defun cscope-find-this-text-string (symbol)
  "Locate where a text string occurs."
  (interactive (list
		(cscope-prompt-for-symbol "Find this text string: ")
		))
  (let ()
    (cscope-call (format "Finding text string: %s" symbol)
		 (list "-4" symbol) nil 'cscope-process-filter)
    ))


(defun cscope-find-egrep-pattern (symbol)
  "Run egrep over the cscope database."
  (interactive (list
		(cscope-prompt-for-symbol "Find this egrep pattern: ")
		))
  (let ()
    (cscope-call (format "Finding egrep pattern: %s" symbol)
		 (list "-6" symbol) nil 'cscope-process-filter)
    ))


(defun cscope-find-this-file (symbol)
  "Locate a file."
  (interactive (list
		(cscope-prompt-for-symbol "Find this file: ")
		))
  (let ()
    (cscope-call (format "Finding file: %s" symbol)
		 (list "-7" symbol) nil 'cscope-process-filter)
    ))


(defun cscope-find-files-including-file (symbol)
  "Locate all files #including a file."
  (interactive (list
		(cscope-prompt-for-symbol "Find files #including this file: ")
		))
  (let ()
    (cscope-call (format "Finding files #including file: %s" symbol)
		 (list "-8" symbol) nil 'cscope-process-filter)
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cscope-minor-mode nil
  "")
(make-variable-buffer-local 'cscope-minor-mode)
(put 'cscope-minor-mode 'permanent-local t)


(defun cscope-minor-mode (&optional arg)
  ""
  (progn
    (setq cscope-minor-mode (if (null arg) t (car arg)))
    (if cscope-minor-mode
	(progn
	  (easy-menu-add cscope:menu cscope:map)
	  (run-hooks 'cscope-minor-mode-hooks)
	  ))
    cscope-minor-mode
    ))


(defun cscope:hook ()
  ""
  (progn
    (cscope-minor-mode)
    ))


(or (assq 'cscope-minor-mode minor-mode-map-alist)
    (setq minor-mode-map-alist (cons (cons 'cscope-minor-mode cscope:map)
				     minor-mode-map-alist)))

(add-hook 'c-mode-hook (function cscope:hook))
(add-hook 'c++-mode-hook (function cscope:hook))
(add-hook 'dired-mode-hook (function cscope:hook))

(provide 'xcscope)
