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

" ----------------------------------------------------------------------------------------
" Misc Functions
" ----------------------------------------------------------------------------------------

let s:hasWindows = has('win64') + has('win32') + has('win16') + has('win95')
let s:pathSeparator = s:hasWindows ? '\\' : '/'

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
   return s:join_path(expand(a:config['posts']), strftime("%Y-%m-%d-", today).a:title.g:editJekyllPost#defaultExtension)
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
   let tzh = str2nr(strftime('%z') / 100)
   let unix = 0
   let d2sec = 24 * 60 * 60
   let y = 1970
   while y < a:year
      let unix += (365 + s:is_leap_year(y)) * d2sec 
      let y += 1
   endwhile
   let leap = s:is_leap_year(a:year)
   let mdays = [31, leap ? 29 : 28 ,31,30,31,30,31,31,30,31,30,31]
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
   if len(a:a) < len(a:b)
      return 0
   endif
   return a:a[0 : lenb - 1] == a:b
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
" To check your code: /s:filter_to_complete([^)]\{-}unescape_to_complete
function! s:filter_to_complete(list, lead)
   let cand = []
   let lead = s:unescape_to_complete(a:lead)
   if len(lead) == 0
      for n in a:list
         call add(cand, s:escape_to_complete(n))
      endfor
   else
      for n in a:list
         if s:starts_with(n, lead)
            call add(cand, s:escape_to_complete(n))
         endif
      endfor
   endif
   return cand
endfunction

" Completion for repository name
" lead never be apply with unescape_to_complete, its work is for s:_filter_tocomplete
function! s:complete_repo(lead)
   return s:filter_to_complete(
      \ s:list_ini_section_names(expand(g:jekyllUtil#configFile)),
      \ a:lead)
endfunction

" Completion for title
" lead never be apply with unescape_to_complete, its work is for s:_filter_tocomplete
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
let s:jekylledit_usage = "USAGE: JekyllEdit repo_name [days_offset] title"

function! JekyllEdit(...)
   let repo = ''
   let day = 0
   let title = ''
   if len(a:000) == 3
      if !s:is_nr(a:2)
         " must be a number
         throw s:jekylledit_usage
      endif
      let repo = a:1
      let day = str2nr(a:2)
      let title = a:3
   elseif len(a:000) == 2
      if s:is_nr(a:2)
         " never be a number
         throw s:jekylledit_usage
      endif
      let repo = a:1
      let title = a:2
   elseif len(a:000) == 1
      let repo = a:1
      let config = s:get_repo_config(repo)
      exec "e ". config['posts']
      sort
      return
   else
      throw s:jekylledit_usage
   endif
try
   let config = s:get_repo_config(repo)
   exec "e ". s:make_jekyll_path(config, title, day)
   if s:is_current_buffer_empty()
      call s:insert_to_current_buffer([
         \ "---",
         \ "layout: ". g:editJekyllPost#defaultLayout,
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
   let ulead = s:unescape_to_complete(a:lead)
   if stat['pos'] == 1
      return s:complete_repo(a:lead)
   elseif (stat['pos'] == 3 && s:is_nr(s:unescape_to_complete(stat['words'][2]['word']))) 
      \ || (stat['pos'] == 2 && !s:is_nr(ulead)) 
      try
         if stat['pos'] == 3
            let day = str2nr(s:unescape_to_complete(stat['words'][2]['word']))
         else
            let day = 0
         endif
         let config = s:get_repo_config(s:unescape_to_complete(stat['words'][1]['word']))
         return s:complete_title(config, a:lead, day)
      catch
         return s:filter_to_complete(g:jekyllUtil#defaultTitles, a:lead)
      endtry
   endif
   return []
endfunction
