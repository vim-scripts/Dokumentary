" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
bundle/vim-dokumentary/plugin/dokumentary.vim	[[[1
203
" dokumentary.vim - Improve what K does
" Author: Gastón Simone

if exists("g:loaded_dokumentary") || &cp
	finish
endif
let g:loaded_dokumentary = 1

" Configuration {{{1
let g:dokumentary_open = 'rightbelow 84vnew'
" }}}1

" Auxiliary functions {{{1
function! s:get_selected_text()
	let l:aux = @z
	normal! gv"zy
	let l:text = @z
	let @z = l:aux
	let l:text = substitute(l:text, '\\(.\\{-}\\)\\n.*', '\\1', '')
	return l:text
endfunction

function! s:get_keyword(visual)
	if a:visual
		return s:get_selected_text()
	else
		return expand('<cword>')
	endif
endfunction " }}}1

" Define a system dictionary as the default search {{{1
function! s:dict(visual)
	let l:keyword = shellescape(s:get_keyword(a:visual))
	if has('mac')
		" Use Mac OS X Dictionary app for keyword search by default
		silent let l:dokumentary_null = system('open dict://' . l:keyword)
	elseif has('unix')
		" Use command-line dictionary tools if available
		if len(system('which dict')) > 0
			call s:output_to_window(l:keyword, a:visual, 1, "dict")
		elseif len(system('which sdvc')) > 0
			call s:output_to_window(l:keyword, a:visual, 1, "sdvc")
		else
			echo "No dictionary program found."
		endif
	else
		echo "Dokumentary: Dictionary only supported on mac and unix."
	endif
endfunction

nnoremap <silent> K :call <SID>dict(0)<CR>
vnoremap <silent> K :call <SID>dict(1)<CR>

" }}}1

" External documentation programs {{{1

" Key: filetype, Value: command
let g:dokumentary_docprgs = {}
let g:dokumentary_docprgs["man"]      = "man {0} | col -b"
let g:dokumentary_docprgs["c"]        = "man {0} | col -b"
let g:dokumentary_docprgs["cpp"]      = "man {0} | col -b"
let g:dokumentary_docprgs["make"]     = "man {0} | col -b"
let g:dokumentary_docprgs["yacc"]     = "man {0} | col -b"
let g:dokumentary_docprgs["sh"]       = "man {0} | col -b"
let g:dokumentary_docprgs["python"]   = "pydoc {0}"
let g:dokumentary_docprgs["go"]       = "godoc {0}"
let g:dokumentary_docprgs["perl"]     = "perldoc -f {0}"
let g:dokumentary_docprgs["plaintex"] = "texdoc -I -M -q {0}"
let g:dokumentary_docprgs["tex"]      = "texdoc -I -M -q {0}"
let g:dokumentary_docprgs["dict"]     = "dict {0}"
let g:dokumentary_docprgs["sdvc"]     = "sdvc {0}"

" }}}1

function! s:output_to_window(given_keyword, visual, newwindow, type) " {{{1
	if !empty(a:given_keyword)
		let l:keyword = a:given_keyword
	else
		let l:keyword = shellescape(s:get_keyword(a:visual))
	endif

	let l:prg = g:dokumentary_docprgs[a:type]

	if !empty(l:keyword) && executable(split(l:prg)[0])
		if a:newwindow
			if exists('g:dokumentary_open') && !empty(g:dokumentary_open)
				execute g:dokumentary_open
			else
				rightbelow 84vnew
			endif
			setlocal buftype=nofile
			set bufhidden=delete
		else
			0,$d
		endif

		let b:dokumentary_filetype = a:type

		let l:prgaux = substitute(l:prg, "{0}", l:keyword, "g")
		silent execute "read !" . l:prgaux
		0

		nnoremap <buffer> K :call <SID>output_to_window('', 0, 0, b:dokumentary_filetype)<CR>
		vnoremap <buffer> K :call <SID>output_to_window('', 1, 0, b:dokumentary_filetype)<CR>

		nnoremap <silent> <buffer> <RightMouse> <LeftMouse>:call <SID>output_to_window('', 0, 0, b:dokumentary_ftype)<CR>
		vnoremap <silent> <buffer> <RightMouse> :call <SID>output_to_window('', 1, 0, b:dokumentary_ftype)<CR>
	else
		echo "Dokumentary: Nothing to search."
	endif
endfunction " }}}1

function! s:open_man_page(visual, newwindow) " {{{1
	let l:expr = s:get_keyword(a:visual)

	" Matches man-page reference. Example: printf(3)
	let l:mansectionpattern = '\([a-zA-Z0-9_\-./]\+\)\((\([1-8]\))\)\?\([.,:;]\)\?'

	if match(l:expr, l:mansectionpattern) >= 0
		let l:name = substitute(l:expr, l:mansectionpattern, "\\1", "")
		let l:section = substitute(l:expr, l:mansectionpattern, "\\3", "")
	else
		let l:name = expand("<cword>")
		let l:section = ''
	endif

	let l:keyword = substitute(l:section . " " . l:name, "\s*\(.*\)", "\\1", "")

	if exists("g:dokumentary_man2html") && g:dokumentary_man2html && len(system('which man2html')) > 0
		let l:tmpfile = tempname() . '_' . l:keyword . '.html'
		silent execute '!man ' . l:keyword . ' | man2html > ' . l:tmpfile
		silent execute '!open ' . l:tmpfile
	else
		call s:output_to_window(l:keyword, a:visual, a:newwindow, "man")
	endif
endfunction " }}}1

" Mappings for each file type {{{1

augroup dokumentary_c
	au!
	autocmd FileType c nnoremap <silent> <buffer> K :call <SID>open_man_page(0, 1)<CR>
	autocmd FileType c vnoremap <silent> <buffer> K :call <SID>open_man_page(1, 1)<CR>
augroup END

augroup dokumentary_cpp
	au!
	autocmd FileType cpp nnoremap <silent> <buffer> K :call <SID>open_man_page(0, 1)<CR>
	autocmd FileType cpp vnoremap <silent> <buffer> K :call <SID>open_man_page(1, 1)<CR>
augroup END

augroup dokumentary_make
	au!
	autocmd FileType make nnoremap <silent> <buffer> K :call <SID>open_man_page(0, 1)<CR>
	autocmd FileType make vnoremap <silent> <buffer> K :call <SID>open_man_page(1, 1)<CR>
augroup END

augroup dokumentary_sh
	au!
	autocmd FileType sh nnoremap <silent> <buffer> K :call <SID>open_man_page(0, 1)<CR>
	autocmd FileType sh vnoremap <silent> <buffer> K :call <SID>open_man_page(1, 1)<CR>
augroup END

augroup dokumentary_python
	au!
	autocmd FileType python nnoremap <silent> <buffer> K :call <SID>output_to_window('', 0, 1, "python")<CR>
	autocmd FileType python vnoremap <silent> <buffer> K :call <SID>output_to_window('', 1, 1, "python")<CR>
augroup END

augroup dokumentary_go
	au!
	autocmd FileType go nnoremap <silent> <buffer> K :call <SID>output_to_window('', 0, 1, "go")<CR>
	autocmd FileType go vnoremap <silent> <buffer> K :call <SID>output_to_window('', 1, 1, "go")<CR>
augroup END

augroup dokumentary_perl
	au!
	autocmd FileType perl nnoremap <silent> <buffer> K :call <SID>output_to_window('', 0, 1, "perl")<CR>
	autocmd FileType perl vnoremap <silent> <buffer> K :call <SID>output_to_window('', 1, 1, "perl")<CR>
augroup END

augroup dokumentary_plaintex
	au!
	autocmd FileType plaintex nnoremap <silent> <buffer> K :call <SID>output_to_window('', 0, 1, "plaintex")<CR>
	autocmd FileType plaintex vnoremap <silent> <buffer> K :call <SID>output_to_window('', 1, 1, "plaintex")<CR>
augroup END

augroup dokumentary_tex
	au!
	autocmd FileType tex nnoremap <silent> <buffer> K :call <SID>output_to_window('', 0, 1, "tex")<CR>
	autocmd FileType tex vnoremap <silent> <buffer> K :call <SID>output_to_window('', 1, 1, "tex")<CR>
augroup END

augroup dokumentary_vim
	au!
	autocmd FileType vim  nnoremap <silent> <buffer> K :execute ":help " . expand("<cword>")<CR>
	autocmd FileType help nnoremap <silent> <buffer> K :execute ":help " . expand("<cword>")<CR>
augroup END

" }}}1

" vim:ft=vim foldmethod=marker
bundle/vim-dokumentary/doc/dokumentary.txt	[[[1
179
*dokumentary.txt* Improve what K does.

                             DOKUMENTARY

Author:  Gastón Simone
License: Same terms as Vim itself (see |license|)

=============================================================================
CONTENTS                                                     *dokumentary*

    1. Introduction ................... |dokumentary-intro|
    2. Supported file types ........... |dokumentary-filetypes|
    3. Mappings ....................... |dokumentary-mappings|
    4. Behavior ....................... |dokumentary-behavior|
    5. Configuration .................. |dokumentary-config|
    6. TO DO .......................... |dokumentary-todo|


=============================================================================
1. INTRODUCTION             *dokumentary-intro* *K-better* *K-dokumentary*

Vim's standard |K| command for normal mode let's us easily run a program to
lookup the keyword under the cursor. The program to run can be customized with
the 'keywordprg' (kp) option, whose default option is "man".

This presents two problems:

    1. The "man" command is the right choice only if you are writing a shell
       script or C code.

    2. Vim only runs that command and waits for it to finish to continue using
       Vim, which sometimes is not the ideal, because you would like to see
       that documentation at the same time you are editing your file.

Dokumentary solves these two issues by doing the following:

    1. It creates buffer-specific mappings for |K| and {Visual}K, depending on
       the type of file you are editing. See |dokumentary-filetypes|.
    2. It loads the retireved documentation in a vim |window|, so you can see
       the documentation together with your file and use all the Vim power to
       search and copy from it.
    3. The default command is not "man", but a system-specific dictionary. So
       if you are just reading plain text, K will show the definition of the
       word under the cursor.

=============================================================================
2. SUPPORTED FILE TYPES                           *dokumentary-filetypes*

Currently Dokumentary supports these file types:

    File type		Documentation program
    ---------		--------------------------------------
    C			man
    C++			man
    go			godoc
    Makefiles		man
    perl		perldoc
    Plain text		dict, sdvc or Mac OS X Dictionary app.
    python		pydoc
    sh			man
    TeX/LaTeX		texdoc
    Vimscript		:help
    Vim help		:help
    Yacc		man

=============================================================================
3. MAPPINGS                                        *dokumentary-mappings*

Dokumentary only maps K in |Normal| and |Visual| modes.

=============================================================================
4. BEHAVIOR                                          *dokumentary-behavior*

                                                      *dokumentary-windows*

As described in the introduction, Dokumentary shows the documentation in a Vim
|window|. This window has 'buftype'=nofile and 'bufhidden'=delete.

This special buffer also gets mappings for K, so it is very simple to
"navigate" through the documentation by pressing "K" in it. Every word becomes
a potential link!

As a side effect of how Dokumentary is implemented, pressing "u" in normal
mode (|undo|) in one of these buffers behaves like "going back" to the
previous documentation page.

                                                          *dokumentary-man*

When using "man" as the documentation program, Dokumentary understands section
references. For example, if the cursor is over

    printf(3)

and you press "K" in |Normal| mode, Dokumentary will load the documentation
for printf under section 3.

                                                       *dokumentary-visual*

You can select more than one word in |Visual| mode and press "K". Dokumentary
will use all the selected text as the keyword for the corresponding
documentation program.

Careful! Some documentation programs will not work with more than one word.
The result may be unexpected in some cases.

=============================================================================
5. CONFIGURATION                                     *dokumentary-config*

Dictionary                                         *dokumentary-cfg-dict*

As said before, the documentation program on normal files is a dictionary.
For Mac OS X users this is quite transparent, because Dokumentary uses the
Dictionary application provided with the OS.

But for GNU/Linux users, this needs some additional work. For example, in a
Debian-based system you can install the following three packages:

    apt-get install dictd dict-gcide dict

This will install the Comprehensive English Dictionary, which can be queried
with the "dict" command. You can also install other dictionaries if you like.

If present in the system, Dokumentary will use "dict" and will search on all
the available dictionaries at once. See the next section to know how to
change this.

                                                     *g:dokumentary_open*
Documentation window location                 *dokumentary-cfg-docwindow*

The location of the documentation window can be customized by changing the
'g:dokumentary_open' variable. This variable contains the |ex|-mode command
that will be executed to create a new window for documentation. The default
value is

    rightbelow 84vnew

See the documentation for |rightbelow| and |vnew| to understand what this
command does and how to change it to your own preferences.

Documentation commands                         *dokumentary-cfg-commands*

Dokumentary keeps a table of the documentation programs to use in the global
variable 'g:dokumentary_docprgs', which is a vimscript dictionary. The key is
the filetype under which that documentation program is run, except for the
special cases of "man", "dict" and "sdvc". The value is the command to execute,
where the substring '{0}' will be substituted by the keyword to search.
For example, try:

    echo g:dokumentary_docprgs["c"]

in |ex| mode to see which command will be used to get documentation on a file
of "c" type.

man2html                                         *g:dokumentary_man2html*

Dokumentary understands the global, boolean variable 'g:dokumentary_man2html'.
When it is set to true and the command "man2html" is available in the system,
it will redirect the man output to a temporary file in HTML format and open it
in the system's default browser. By default this variable is undefined.

NOTE: The underlying system must support the "open" command in the same way
Mac OS X does. This is the method used to open the temporary HTML file in the
default browser.

=============================================================================
6. TO DO                                               *dokumentary-todo*

    1. Simplify the process of adding more supported file types.
       It would be easier if |autocmd| allowed to define the pattern from
       a variable.
    2. Add public commands so the user can add support for more file types.
       Something like:
           :Dok[ument] c "mycdoc -s {0}"
    3. Vim's standard |K| command supports a count before "K" to specify the
       specific manual page to show when the documentation program being used
       is "man". For completeness this should be included. I could not find an
       easy way to do this.

 vim:tw=78:ts=8:ft=help:norl:
