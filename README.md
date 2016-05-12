# Jekyll-Util.vim

[![MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Jekyll utilities for vimmer. Works on Windows, MSYS2, Linux, and Mac!

I'm happy if can help you from boring works. Entering to `_posts` directory,
typing ISO date-formatted file name and front matter, and so on.

- [Install](#install_pathogen)
- [Commands](#commands)
   - [JekyllConf](#jekyllconf)
   - [JekyllEdit](#jekylledit)
   - [JekyllExec](#jekyllexec)
- [Configuration](#configuration)
- [License](#lisence)

## Install (Pathogen)

```bash
git clone https://github.com/retorillo/jekyll-util.vim.git ~/.vim/bundle/jekyll-util.vim
```

## Commands

### JekyllConf

Open configuration file of this plugin `~/.jekyllutil`

```vimL
:JekyllConf
```

First, set your blog name and local path as follow and save this.

```ini
[blog1]
root=~/your/blog1/
```

In this case, blog name is `blog1` and path is `~/your/blog1`.
Now you can use [JekyllEdit](#jekylledit) command!

Of course, for advanced user, there are more options can be configured.

| Key       | Description                             | DefaultValue | Required |
|-----------|-----------------------------------------|--------------|----------|
| root      | Specify root directory of jekyll blog   |              | yes      |
| posts     | Set to change _posts directory path     | _posts       |          |
| extension | Set to change default extension of post | .md          |          |
| layout    | Set to change default layout of post    | post         |          |

```ini
[blog1]
root=~/your/blog1/
posts=_posts
extension=.markdown
layout=blogpost

[blog2]
root=~/your/blog2/
; Comment starts with semicolon
; ...
```

### JekyllEdit

Create or amend post more quickly. (including past and feature posts)

```vim
:JekyllEdit blog [ [ dayoffset | date ] title ]
```

**TIPS:** `jeke` is an abbrev for `JekyllEdit`. Type `:jeke` and whitespace,
then it will be automatically replaced by `:JekyllEdit `.

- Specify `blog` for blog name defined in `~/.jekyllutil`. See
  [JekyllConf](#jekyllconf)
   - Tab autocompletion is available if `~/.jekyllutil` is correctly configured.
- Specify `dayoffset` for past or future post. For example, when specified `-1`,
  creates or amend blog post as yesterday's. This is optinal argument. Skip this
  to create or amend post as today's.
   - Instead of `dayoffset`, `date` can be directly specified. For example,
     specify `5-11` or `5/11` to create or armend post of 11 May of current
     year. If you want to explicitly specify year, do as following: `2017-5-11`,
     `17-5-11` or `7-5-11`.
- Specify `title` for title of this post. This is not `title` of front
  matter(YML), but is used for filename.(ex. `2016-04-24-title-is-here.md`)
   - Tab autocompletion is available if there are post files of that day, or comes
     from `jekyllUtil#defaultTitles`
- When both `title` and `dayoffset` arguments are omitted, just browses `_posts`
  directory(`netrw`). This is useful feature to rename and remove post files.

**Example:**

- If today is 18 March 2016, `:JekyllEdit blog 2 new-post-title` will try to
  create or open `2016-03-20-new-post-title.md`.
- If current year is 2016, `:JekyllEdit blog 5/12 new-post-title` will try to
  create or open `2016-05-12-new-post-title.md`.


## JekyllExec

Execute system command on the specified Jekyll `root` directory without changing
Vim current working directory. May be able to liberate you from `:cd` hell!

This command has a bit comfortable auto-completion. (system commands, git
commands, and file names on Jekyll `root` directory) Enter some characters, then
type TAB key to try!

```vim
:JekyllExec blog command
```

**TIPS:** `jek!` is an abbrev for `JekyllExec`. Type `:jek!` and whitespace,
then it will be automatically replaced by `:JekyllExec `.

To find recent 5 files that contains line starts with `Vim is awesome` from your
blog which name is `myblog`:

```vim
:JekyllExec myblog grep ^Vim\ is \ awesome * -lr | sort | tail -5
```

To open its `root` directory:

```vim
:JekyllExec myblog start .
```

To open new shell window on its `root` directory:

```vim
:JekyllExec myblog start
```

To git commit and git push:

```vim
:JekyllExec myblog start git add *; git commit -m 'Update blog' && git push origin master
```

When execute the above command, you may feel that Vim hung up. I recommend to
`:JekyllExec blog start` to create new shell window for long-running script.

**TIPS:**

- `;`, `&&`, `|`, and all redirections(`>`) work fine. Never try to escape them.
- Set `g:jekyllUtil#faroviteCommands` to customize auto-completion list for
  commands.`

## Configuration

By changing the following variables on your `~/.vimrc`, you can overwrite
default values of this plugin.

```vim
" Change to ~/.jekyllutil path
let g:jekyllUtil#configFile = "~/.jekyllutil"
" To change extension of posts. Must starts with dot.
" This value will be overwritten by ~/.jekyllutil
let g:jekyllUtil#defaultExtension = ".md"
" To change name of layout on automatically generated YML front matter
" This value will be overwritten by ~/.jekyllutil
let g:jekyllUtil#defaultLayout = "post"
" To change _posts directory.
" This value will be overwritten by ~/.jekyllutil
let g:jekyllUtil#postsDirectory = "_posts"
" Titles that be used for completion when there are no post of that day
let g:jekyllUtil#defaultTitles = ['untitled', 'todo-list']
" Additional auto completion list for JekyllExec command
let g:jekyllUtil#favoriteCommands = ['start mintty',
   \ 'git add *; git commit -m Update && git push origin master']
```

Blog specific configurations are defined in `~/.jekyllutil`. See
[JekyllConf](#jekyllconf).

## License

Distributed under the MIT license

Copyright (C) 2016 Retorillo
