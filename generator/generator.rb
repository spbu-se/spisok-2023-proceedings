#!/usr/bin/env ruby

require_relative './misc.rb'

class Section
  def maketex(start_page)
    @start_page = start_page
    emptypage = "\\mbox{}\\newpage"

    chairman_texs = @heads.map do |h|
      <<~HEAD_TEMPLATE
      \\vspace{5mm}
      \\includegraphics[height=5cm]{../../portraits/#{h.photo}}\\\\
      \\vspace{2mm}
      {\\large \\textbf{\\textsf{#{h.name}}}}\\\\
      \\textsf{#{h.title}}

      HEAD_TEMPLATE
    end

    warning = if @status == true then '' else "{\\Huge \\color{red}~#{@status}}\n" end

    cur_page = start_page + 2

    section_articles_templ = ERB::new(File::read(File::join(File::dirname(__FILE__), 'section_articles.erb')))
    articles_tex = section_articles_templ.result binding

    add_empty = cur_page.even?

    finalemptypage = if add_empty then # last is odd
      cur_page += 1
      emptypage
    else
      ''
    end

    section_templ = ERB::new(File::read(File::join(File::dirname(__FILE__), 'section_tex.erb')))
    section_tex = section_templ.result binding

    File::open(File::join(@fullfolder, "_section-overlay.tex"), "w:UTF-8") do |f|
      f.write section_tex 
    end

    win = is_os_windows?
    suffix, hashbang = win ? [ 'bat', '' ] : [ 'sh', '#!/bin/bash' ]

    File::open(File::join(@fullfolder, "_section-compile.#{suffix}"), "w:UTF-8") do |f|
      pdfs = ['../../generator/a5-empty.pdf'] * 2 +
        @articles.map { |a| File::basename(a.fullfile) } +
        if add_empty then ['../../generator/a5-empty.pdf'] else [] end

      f.write <<~COMPILE
        #{hashbang}
        #{OPTIONS[:texlauncher]} _section-overlay.tex
        #{OPTIONS[:texlauncher] == 'tectonic' ? '# ' : ''}#{OPTIONS[:texlauncher]} _section-overlay.tex

        pdftk #{pdfs.join ' '} cat output _section-articles.pdf
        pdftk _section-overlay.pdf multibackground _section-articles.pdf output #{@pdfname}

        #{win ? 'move' : 'mv'} #{@pdfname} ..
        COMPILE
    end

    if not win
      File::u_plus_x File::join(@fullfolder, "_section-compile.sh")
    end
    cur_page
  end
end
