" jekyll-util
" https://github.com/retorillo/jekyll-util.vim
" Distributed under the MIT license
" Copyright (C) 2016 Retorillo

" ----------------------------------------------------------------------------------------
" Global Variables
" ----------------------------------------------------------------------------------------

function! s:let_safe(name, default)
   if !exists(a:name)
      exec 'let '.a:name.' = '.a:default
   endif
endfunction

call s:let_safe('g:jekyllUtil#defaultExtension', '".md"')
call s:let_safe('g:jekyllUtil#defaultLayout', '"post"')
call s:let_safe('g:jekyllUtil#configFile', '"~/.jekyllutil"')
call s:let_safe('g:jekyllUtil#defaultTitles', '["untitled"]')

call s:let_safe('g:jekyllUtil#maxExecutableListing', '32')
call s:let_safe('g:jekyllUtil#maxExecutableLength', '8')
call s:let_safe('g:jekyllUtil#favoriteCommands', '["start", "start .", "git"]')

call s:let_safe('g:jekyllUtil#dateSeparator', '"[-/]"')

" ----------------------------------------------------------------------------------------
" Misc Functions
" ----------------------------------------------------------------------------------------

let s:hasWindows = has('win64') + has('win32') + has('win16') + has('win95')
let s:pathSeparator = s:hasWindows ? '\\' : '/'
let s:gitCommands = [
\  'add',                       'merge-octopus',
\  'add--interactive',          'merge-one-file',
\  'am',                        'merge-ours',
\  'annotate',                  'merge-recursive',
\  'apply',                     'merge-resolve',
\  'archimport',                'merge-subtree',
\  'archive',                   'merge-tree',
\  'bisect',                    'mergetool',
\  'bisect--helper',            'mktag',
\  'blame',                     'mktree',
\  'branch',                    'mv',
\  'bundle',                    'name-rev',
\  'cat-file',                  'notes',
\  'check-attr',                'p4',
\  'check-ignore',              'pack-objects',
\  'check-mailmap',             'pack-redundant',
\  'check-ref-format',          'pack-refs',
\  'checkout',                  'patch-id',
\  'checkout-index',            'prune',
\  'cherry',                    'prune-packed',
\  'cherry-pick',               'pull',
\  'citool',                    'push',
\  'clean',                     'quiltimport',
\  'clone',                     'read-tree',
\  'column',                    'rebase',
\  'commit',                    'receive-pack',
\  'commit-tree',               'reflog',
\  'config',                    'relink',
\  'count-objects',             'remote',
\  'credential',                'remote-ext',
\  'credential-cache',          'remote-fd',
\  'credential-cache--daemon',  'remote-ftp',
\  'credential-store',          'remote-ftps',
\  'cvsexportcommit',           'remote-http',
\  'cvsimport',                 'remote-https',
\  'cvsserver',                 'remote-testsvn',
\  'daemon',                    'repack',
\  'describe',                  'replace',
\  'diff',                      'request-pull',
\  'diff-files',                'rerere',
\  'diff-index',                'reset',
\  'diff-tree',                 'rev-list',
\  'difftool',                  'rev-parse',
\  'difftool--helper',          'revert',
\  'fast-export',               'rm',
\  'fast-import',               'send-email',
\  'fetch',                     'send-pack',
\  'fetch-pack',                'sh-i18n--envsubst',
\  'filter-branch',             'shell',
\  'fmt-merge-msg',             'shortlog',
\  'for-each-ref',              'show',
\  'format-patch',              'show-branch',
\  'fsck',                      'show-index',
\  'fsck-objects',              'show-ref',
\  'gc',                        'stage',
\  'get-tar-commit-id',         'stash',
\  'grep',                      'status',
\  'gui',                       'stripspace',
\  'gui--askpass',              'submodule',
\  'hash-object',               'submodule--helper',
\  'help',                      'subtree',
\  'http-backend',              'svn',
\  'http-fetch',                'symbolic-ref',
\  'http-push',                 'tag',
\  'imap-send',                 'unpack-file',
\  'index-pack',                'unpack-objects',
\  'init',                      'update-index',
\  'init-db',                   'update-ref',
\  'instaweb',                  'update-server-info',
\  'interpret-trailers',        'upload-archive',
\  'log',                       'upload-pack',
\  'ls-files',                  'var',
\  'ls-remote',                 'verify-commit',
\  'ls-tree',                   'verify-pack',
\  'mailinfo',                  'verify-tag',
\  'mailsplit',                 'web--browse',
\  'merge',                     'whatchanged',
\  'merge-base',                'worktree',
\  'merge-file',                'write-tree',
\  'merge-index' ]

function! s:join_path(a, b)
   return substitute(a:a, s:pathSeparator.'$', '', '').s:pathSeparator.a:b
endfunction

function! s:is_current_buffer_empty()
   return line('.') == 1 && line('$') == 1 && col('.') == 1
endfunction

function! s:insert_to_current_buffer(lines)
   let c = 0
   for l in a:lines
      if c == 0
         call setline('.', l)
      else
         call append(c, l)
      endif
      let c += 1
   endfor
endfunction

function! s:get_repo_config(name)
   let path = expand(g:jekyllUtil#configFile)
   let dict = s:parse_ini_section(path, a:name)
   if empty(dict)
      throw 'Error on '.path.'\n repository "'.a.name.'" is not found '
   endif
   if !has_key(dict, 'root')
      throw 'Error on '.path.'\n root is required for '.a:name
   endif
   if !has_key(dict, 'posts')
      let dict['posts'] = s:join_path(dict['root'], '_posts')
   endif
   if !has_key(dict, 'extension')
      let dict['extension'] = g:jekyllUtil#defaultExtension
   endif
   if !has_key(dict, 'layout')
      let dict['layout'] = g:jekyllUtil#defaultLayout
   endif
   return dict
endfunction

function! s:is_nr(str)
   return a:str =~ '\v^[-+]?[0-9]+$'
endfunction

" Returns as dictionary with syntactical check
function! s:parse_ini_section(path, name)
   let ignorable = '\v(^\s*;|^\s*$)'
   let dict = {}
   let sect = s:match_ini_section(a:path, a:name)
   if empty(sect)
      return dict
   endif
   if len(sect) > 1
      let lnum = sect[1]['lnum']
      throw 'Syntax error on '.a:path.' (Line Number:'.lnum.')\nDuplicated section: '.a:name
   endif
   let lnum = sect[0]['lnum']
   for l in sect[0]['lines']
      let lnum += 1
      let m = matchlist(l, '\v^\s*([-a-zA-Z0-9_]+)\s*[=]\s*("([^"]+)"|' . "'([^']+)'" . '|([^;]*))(.*)$')
      if !len(m)
         if len(l) && match(l, ignorable) == -1
            throw 'Syntax error on '.a:path.' (Line Number:'.lnum.')\nUnexpected line: '.l
         endif
         continue
      endif
      if len(m[6]) && match(m[6], ignorable) == -1
         throw 'Syntax error on '.a:path.' (Line Number:'.lnum.')\nTrailing characters: '.m[6]
      endif
      let key = m[1]
      let value = len(m[3]) ? m[3] : (len(m[4]) ? m[4] : substitute(m[5], '\s*$', '', ''))
      if has_key(dict, key)
         throw 'Syntax error on '.a:path.' (Line Number:'.lnum.')\nDuplicated key: '.key
      endif
      let dict[key] = value
   endfor
   return dict
endfunction

" Returns matched sections as array of dictonary without any syntaxial check
" Each dictionary has two keys
"  lnum  : first line number of matched section
"  lines : entire lines of section (including empty and syntactically invalid line)
function! s:match_ini_section(path, name)
   let sections = []
   let lines = []
   let lnum = 0
   let matched = 0
   if filereadable(a:path) == 1
      for l in readfile(a:path)
         let lnum += 1
         if matched
            if match(l, '\v^\s*\[([^\]]+)\]\s*$') != -1
               call add(sections, { 'lnum': matched , 'lines': lines })
               let lines = []
               let matched = 0
            else
               call add(lines, l)
            endif
         endif
         if a:name == substitute(l, '\v^\s*\[([^\]]+)\]', '\1', '')
            let matched = lnum
         endif
      endfor
   else
     throw 'Cannot open '.a:path
   endif
   if matched
      call add(sections, { 'lnum': matched , 'lines': lines })
   endif
   return sections
endfunction

function! s:list_ini_section_names(path)
   let sections = []
   if filereadable(a:path) == 1
      for l in readfile(a:path)
         if match(l, '\v^\s*\[([^\]]+)\]\s*$') != -1
            call add(sections, substitute(l, '\v^\s*\[([^\]]+)\]', '\1', ''))
         endif
      endfor
   endif
   return sections
endfunction

function! s:make_jekyll_path(config, title, offset)
   let today = s:today_unix() + a:offset * 24 * 60 * 60
   return s:join_path(expand(a:config['posts']), strftime("%Y-%m-%d-", today).a:title.g:jekyllUtil#defaultExtension)
endfunction

function! s:write_error(err)
   echohl Error
   for l in split(a:err, '\\n')
      echo l
   endfor
   echohl None
endfunction

" Compare to sort descendantly
function! s:mtime_comparer(a, b)
   return getftime(a:b) - getftime(a:a)
endfunction

function! s:is_leap_year(year)
   return !(a:year % 4) && a:year % 100 || !(a:year % 400)
endfunction

" Convert YMD to Unix time (ignoring leap second)
function! s:ymd_to_unix(year, month, day)
   if (a:year < 1970 || a:year > 9999)
      throw 'Invalid year: '.a:year
   endif
   if (a:month < 1 || a:month > 12)
      throw 'Invalid month: '.a:month
   endif

   let leap = s:is_leap_year(a:year)
   let mdays = [31, leap ? 29 : 28 ,31,30,31,30,31,31,30,31,30,31]

   if a:day < 1 || a:day > mdays[a:month - 1]
      throw 'Invalid date: '.a:year.'-'.a:month.'-'.a:day
   endif

   let tzh = str2nr(strftime('%z') / 100)
   let unix = 0
   let d2sec = 24 * 60 * 60

   let y = 1970
   while y < a:year
      let unix += (365 + s:is_leap_year(y)) * d2sec
      let y += 1
   endwhile

   let m = 1
   while m < a:month
      let unix += mdays[m-1] * d2sec
      let m += 1
   endwhile
   return unix + (a:day - 1) * d2sec + tzh * 60 * 60
endfunction

" Get Unix time 12:00 AM today (ignoring leap second and timezone)
function! s:today_unix()
   let str = strftime("%Y%m%d")
   return s:ymd_to_unix(str2nr(str[0:3]), str2nr(str[4:5]), str2nr(str[6:7]))
   " Using localtime() is more programmatically optimal, but should not be
   " used in this case because its value can be unmatched with s:ymd_to_unix.
   " For example, localtime() now seems to have no leap-second-awareness.
   " But this behavior may be changed in the future VIM release.
endfunction

" Returns unix time from text (When invalid format, returns -1)
function! s:str2unix(text)
   let ymd = matchlist(a:text, '\v^([0-9]{1,4})('
      \ .g:jekyllUtil#dateSeparator.')([0-9]{1,2})\2([0-9]{1,2})$')
   if empty(ymd)
      let ymd = matchlist(a:text, '\v^([0-9]{1,2})'
         \ .g:jekyllUtil#dateSeparator.'([0-9]{1,2})$')
      if empty(ymd)
         return -1
      endif
      let y = ''
      let m = ymd[1]
      let d = ymd[2]
   else
      let y = ymd[1]
      " ymd[2] is seperator
      let m = ymd[3]
      let d = ymd[4]
   endif
   return s:ymd_to_unix(str2nr(strlen(y) < 4 ?
      \ strftime('%Y')[0 : 3 - strlen(y)].y : y),
      \ str2nr(m), str2nr(d))
endfunction

" Returns dayoffset from number or dateformat that is convertible by str2unix
function! s:str2dayoffset(text, errorThrown)
   let unix = s:str2unix(a:text)
   if !s:is_nr(a:text) && unix < 0
      throw a:errorThrown
   endif
   let day2sec = 24 * 60 * 60
   return unix < 0 ? str2nr(a:text) :
      \ float2nr(round((unix * 1.0 - s:today_unix())/day2sec))
endfunction

" Test str2dayoffset
function! s:test_str2dayoffset(text)
try
   call s:str2dayoffset(a:text, '')
   return 1
catch
   return 0
endtry
endfunction

" Returns title of Jekyll post from path (without date-time and extension)
function! s:get_info_from_path(config, path)
   let mtitle = matchlist(a:path, '\v([^\\/]{-})('.substitute(a:config['extension'], '[.]', '\\\0', 'g').')?$')
   let title = empty(mtitle) ? a:path : mtitle[1]
   let mdate = matchlist(title, '\v^(\d{4})-(\d{2})-(\d{2})-(.*)')
   if !empty(mdate)
      try
         let date = s:ymd_to_unix(str2nr(mdate[1]), str2nr(mdate[2]), str2nr(mdate[3]))
         let title = mdate[4]
      catch
         let date = 0
      endtry
   else
      let date = 0
   endif
   return { 'title': title, 'date': date }
endfunction

" Parses front matter of Jekyll post (ignoring any error)
function! s:parse_frontmatter_lazy(config, path)
   let inside = 0
   let yml = {}
   " fallback of title when YML does not contain title property
   let yml['title'] = s:get_info_from_path(a:config, a:path)['title']
   let yml['category'] = ''
   let yml['categories'] = ''
   let yml['tags'] = ''
   for l in readfile(a:path)
      if match(l, '\v^[-]{3}') != -1
         if inside
            return yml
         endif
         let inside = 1
      endif
      if inside
         let m = matchlist(l, '\v^\s*([-_a-zA-Z0-9]+)\s*:\s*(.{-})\s*$')
         if empty(m) || !has_key(yml, m[1])
            continue
         endif
         let unq = matchlist(m[2], '\v("([^"]+)"|'."'([^']+)')")
         let m[2] = empty(unq) ? m[2] : (len(unq[2]) ? unq[2] : unq[3])
         if !len(m[2])
            continue
         endif
         let yml[m[1]] = m[2]
      endif
   endfor
   return yml
endfunction

function! s:pad_left(num, len)
   return printf('%'.a:len.'s', a:num)
endfunction

function! s:starts_with(a, b)
   let lenb = len(a:b)
   if len(a:a) < lenb
      return 0
   endif
   return a:a[0 : lenb - 1] == a:b
endfunction

functio! s:ends_with(a, b)
   let lena = len(a:a)
   let lenb = len(a:b)
   if lena < lenb
      return 0
   endif
   return a:a[lena - lenb : ] == a:b
endfunction

" ----------------------------------------------------------------------------------------
" For completion
" ----------------------------------------------------------------------------------------

" Splits string tVo VimL syntactical words (including unclosed quoted string)
" Each item of returned array has two properties: index, and word
function! s:splitword(line)
   let words = []
   let cur = 0
   let end = 0
   let len = len(a:line)
   let pat = '\v'."'([^']*)'?".'|"([\\]"|[^"])*"?|(([\\]\s|\S)+)'
   while cur != -1 && cur < len
      let start = match(a:line, pat, cur)
      if start == -1
         break
      endif
      let end = matchend(a:line, pat , cur)
      call add(words, { 'index': start, 'word': a:line[start : end - 1] })
      let cur = end "?
   endwhile
   if end < len
      let tail = a:line[end : 1]
      if match(tail, '^\s+$') != -1
         call add(words, { 'index': a:line, 'word': tail })
      endif
   endif
   return words
endfunction

" Returns helpful statistics of completion
" Note: Returned words is not simple string list. See s:splitwords
function! s:stat_completion(lead, line, pos)
   let words = s:splitword(a:line)
   let c = 0
   for w in words
      if w['index'] <= a:pos && a:lead == w['word']
         break
      endif
      let c += 1
   endfor
   return { 'pos': c, 'words': words }
endfunction

" Get word of specified index from return value of stat_completion
" Negative value is treated as index counting from the end
function! s:get_statword(stat, i)
   if a:i < 0
      let pos = a:stat['pos']
      return -a:i > pos ? '' : a:stat['words'][pos + a:i]['word']
   endif
   return a:stat['words'][a:i]['word']
endfunction

" Removes leading and trailing quotes and backslash of whitespace
function! s:unescape_to_complete(lead)
   " TODO: unescape \" inside quoted string
   return substitute(substitute(a:lead, '\v[\\](\s)', '\1' ,'g'),
      \ '\v(^"|"$|'."^'|'$".')', '', 'g')
endfunction

function! s:escape_to_complete(lead)
   " TODO: restore leading and trailing quotes when required
   " TODO: escape \" inside quoted string
   return substitute(a:lead, '\s', '\\\0', 'g')
endfunction

" lead never be apply with unescape_to_complete
" to check your code: /s:filter_to_complete([^)]\{-}unescape_to_complete
" all candidates are passed through s:escape_to_complete,
" to suppress this, specify 1 for 3rd argument.
function! s:filter_to_complete(list, lead, ...)
   let cand = []
   let lead = s:unescape_to_complete(a:lead)
   let suppress_escape = len(a:000) > 2 ? a:000[2] : 0
   if len(lead) == 0
      for n in a:list
         call add(cand, suppress_escape ? n : s:escape_to_complete(n))
      endfor
   else
      for n in a:list
         if s:starts_with(n, a:lead)
            call add(cand, suppress_escape ? n : s:escape_to_complete(n))
         endif
      endfor
   endif
   return cand
endfunction

" Completion for repository name
" lead never be apply with unescape_to_complete, its work is for s:filter_to_complete
function! s:complete_repo(lead)
   return s:filter_to_complete(
      \ s:list_ini_section_names(expand(g:jekyllUtil#configFile)),
      \ a:lead)
endfunction

" Completion for title
" lead never be apply with unescape_to_complete, its work is for s:filter_to_complete
function! s:complete_title(config, lead, day)
   let cand = copy(g:jekyllUtil#defaultTitles)
   let today = s:today_unix() + a:day * 24 * 60 * 60
   for i in globpath(a:config['posts'], '*'.a:config['extension'], 0, 1)
      let info = s:get_info_from_path(a:config, i)
      if (info['date'] == today)
         call add(cand, info['title'])
      endif
   endfor
   return s:filter_to_complete(cand, a:lead)
endfunction

" Completion for path
function! s:complete_path(root, lead)
   let cand = []
   let r = expand(a:root)
   for p in globpath(r, s:unescape_to_complete(a:lead).'*', 0, 1)
      call add(cand, substitute(strpart(p, strlen(r) + 1), '\s', '\\\0', 'g'))
   endfor
   return cand
endfunction

" Completion for command
function! s:complete_command(lead)
   if strlen(a:lead) == 0
      return g:jekyllUtil#favoriteCommands
   endif
   let cand = s:filter_to_complete(g:jekyllUtil#favoriteCommands, a:lead, 1)
   let favlen = len(cand)
   for path in split($PATH, s:hasWindows ? ';' : ':')
      for bin in globpath(path, a:lead."*", 0, 1)
         let name = substitute(strpart(bin, strlen(path) + 1), '\..*$', '', '')
         if strlen(name) < g:jekyllUtil#maxExecutableLength  && executable(name)
            call add(cand, name)
         endif
      endfor
      call uniq(sort(cand))
      if len(cand) - favlen > g:jekyllUtil#maxExecutableListing
         break
      endif
   endfor
   return cand
endfunction

" Check whether end with command separator, does not use unescape_to_complete
function! s:ends_with_command_starter(text)
   for d in [ ';', '&&', '|' ]
      if s:ends_with(a:text, d)
         return 1
      endif
   endfor
   return 0
endfunction

" ----------------------------------------------------------------------------------------
" JekyllConf
" ----------------------------------------------------------------------------------------

command! -nargs=* -complete=customlist,s:JekyllConf_Complete JekyllConf :call JekyllConf(<f-args>)
cabbrev jekyllconf <c-r>=getcmdtype() == ':' && getcmdpos() == 1 ? 'JekyllConf' : 'jekyllconf'<CR>
cabbrev jekc <c-r>=getcmdtype() == ':' && getcmdpos() == 1 ? 'JekyllConf' : 'jekc'<CR>

function! JekyllConf(...)
try
   if len(a:000) > 0
      return s:get_repo_config(a:1)
   else
      exec 'e '. expand(g:jekyllUtil#configFile) .' | set syntax=dosini'
      if s:is_current_buffer_empty()
         call s:insert_to_current_buffer([
            \ '; Configuration of jekyll-util.vim',
            \ '; See http://github.com/retorillo/jekyll-util.vim/blog/master/README.md',
            \ ';',
            \ '; Example: ',
            \ ';',
            \ '; [blog1]',
            \ '; root=~/documents/jekyllblog1',
            \ '; layout=blogpost',
            \ '; extension=.markdown',
            \ '; [blog2]',
            \ '; root=~/documents/jekyllblog2',
            \ ';',
            \ '', '',
         \ ])
         exec '$'
      endif
   endif
catch
   echo s:write_error(v:exception)
endtry
endfunction

function! s:JekyllConf_Complete(lead, line, pos)
   let stat = s:stat_completion(a:lead, a:line, a:pos)
   if stat['pos'] == 1
      return s:complete_repo(a:lead)
   endif
   return []
endfunction

" ----------------------------------------------------------------------------------------
" JekyllEdit
" ----------------------------------------------------------------------------------------

command! -nargs=+ -complete=customlist,s:JekyllEdit_Complete JekyllEdit :call JekyllEdit(<f-args>)
cabbrev jekylledit <c-r>=getcmdtype() == ':' && getcmdpos() == 1 ? 'JekyllEdit' : 'jekylledit'<CR>
cabbrev jeke <c-r>=getcmdtype() == ':' && getcmdpos() == 1 ? 'JekyllEdit' : 'jeke'<CR>
let s:jekylledit_usage = "USAGE: JekyllEdit name [day_offset | date] title"



function! JekyllEdit(...)
try
   let repo = ''
   let day = 0
   let title = ''
   if len(a:000) == 3
      let repo = a:1
      let day = s:str2dayoffset(a:2,
         \ 'Invalid day_offset or date format\n'.s:jekylledit_usage)
      let title = a:3
   elseif len(a:000) == 2
      if s:is_nr(a:2) || s:str2unix(a:2) >= 0
         throw 'Title is required\n'.s:jekylledit_usage
      endif
      let repo = a:1
      let title = a:2
   elseif len(a:000) == 1
      let repo = a:1
      let config = s:get_repo_config(repo)
      exec "e ". config['posts']
      return
   else
      throw s:jekylledit_usage
   endif
   let config = s:get_repo_config(repo)
   exec "e ". s:make_jekyll_path(config, title, day)
   if s:is_current_buffer_empty()
      call s:insert_to_current_buffer([
         \ "---",
         \ "layout: ". g:jekyllUtil#defaultLayout,
         \ "title: ",
         \ "---",
         \ "",
      \ ])
      exec '3'
      call cursor(".", col("$") + 1)
   else
      exec '$'
   endif
catch
   call s:write_error(v:exception)
endtry
endfunction

function! s:JekyllEdit_Complete(lead, line, pos)
   let stat = s:stat_completion(a:lead, a:line, a:pos)
   if stat['pos'] == 1
      return s:complete_repo(a:lead)
   elseif (stat['pos'] == 3 &&
      \ s:test_str2dayoffset(s:unescape_to_complete(s:get_statword(stat, 2))))
      \ || (stat['pos'] == 2 &&
      \ !s:test_str2dayoffset(s:unescape_to_complete(a:lead)))
         if stat['pos'] == 3
            let day = s:str2dayoffset(s:unescape_to_complete(s:get_statword(stat, 2)), '')
         else
            let day = 0
         endif
         let config = s:get_repo_config(s:unescape_to_complete(s:get_statword(stat, 1)))
         return s:complete_title(config, a:lead, day)
      try
      catch
         return s:filter_to_complete(g:jekyllUtil#defaultTitles, a:lead)
      endtry
   endif
   return []
endfunction

" ----------------------------------------------------------------------------------------
" JekyllExec
" ----------------------------------------------------------------------------------------

command! -nargs=+ -complete=customlist,s:JekyllExec_Complete JekyllExec :call JekyllExec(<f-args>)
cabbrev jekyllexec <c-r>=getcmdtype() == ':' && getcmdpos() == 1 ? 'JekyllExec' : 'jekyllexec'<CR>
cabbrev jek! <c-r>=getcmdtype() == ':' && getcmdpos() == 1 ? 'JekyllExec' : 'jek!'<CR>
let s:jekyllexec_usage = "USAGE: JekyllExec name command"

function! JekyllExec(...)
   let cwd = 0
try
   if len(a:000) < 1
      throw s:jekyllexec_usage
   endif
   let repo = ''
   let cmd = ''
   let c = 0
   for a in a:000
      if c == 0
         let repo = a
      else
         if (c > 1)
            let cmd .= ' '
         endif
         let cmd .= substitute(a, '\s', '\\\0', 'g')
      endif
      let c += 1
   endfor
   let config = s:get_repo_config(repo)
   let cwd = getcwd()
   exec 'cd '.substitute(config['root'], '\s', '\\\0', 'g')
   echo system(cmd)
catch
   call s:write_error(v:exception)
finally
   if cwd
      exec 'cd '. cwd
   endif
endtry
endfunction

function! s:JekyllExec_Complete(lead, line, pos)
   let stat = s:stat_completion(a:lead, a:line, a:pos)
   if stat['pos'] == 1
      return s:complete_repo(a:lead)
   else
      try
         if stat['pos'] == 2 || s:ends_with_command_starter(s:get_statword(stat, -1))
            return s:complete_command(a:lead)
         elseif s:get_statword(stat, -1) == 'git' &&
            \ (stat['pos'] == 3 || s:ends_with_command_starter(s:get_statword(stat, -2)))
            return s:filter_to_complete(s:gitCommands, a:lead)
         else
            let config = s:get_repo_config(s:unescape_to_complete(s:get_statword(stat, 1)))
            return s:complete_path(config['root'], a:lead)
         endif
      catch
         return []
      endtry
   endif
   return []
endfunction
