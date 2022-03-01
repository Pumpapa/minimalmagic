function dump(o,d)
	d = d or 3
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
				if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s .. '['..k..'] = ' .. (d==0 and '' or dump(v,d-1)) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

io.output():setvbuf("no")

local write = function(...)
	local arg = ...
	for i=1, select('#',...) do
		io.stderr:write(select(i,...))
	end
end

local flush = function()
	write('\n')
	io.flush()
end

function trace(n,el) 
	write(n..'#'..st..'#'..fun..'#'..aterm..'#'..bterm..'#')
	if el and el.__type then 
		write(el.__type.name..'#'..dump(el)) 
	else 
		write('[['..dump(el)..']]') 
	end
	flush()
end


function mkstr(o)
	if type(o)=='string' then
		return o
	elseif type(o)=='table' then
		return o.text
	elseif type(o)=='userdata' then
		return '<<'..dump(o)..'>>'
	else
		write("Error! Yet Another Type\n",type(o),"%%%[",dump(o),']\n')
	end
end



macros = {
	figure = {
		prepost = function (args) -- args: label file place %
					local lbl = args[1].text
					local path = args[2].text
					local pos = args[3]
					local sz = (tonumber(args[4])/100)
					local ltx
					--write('XYX ',dump(args),'\n')
					--write('XXX ',dump(lbl),', ',dump(path),', ',dump(pos),', ',dump(ltx),', ',dump(args),'\n')
					if path:find('/images',1)==1 then
						path = path:sub(8)
					end
					if sz=='1' then 
						ltx = '\\begin{figure}'..
							'\\centerline{\\includegraphics{'..path..'}}'..
							'\\caption{'..lbl..'}'..
							'\\label{fig:fig}'..
							'\\end{figure}'
					else
						ltx = '\\img{'..(mkstr(pos)=='right' and 'r' or 'l')..
							'}{'..sz..'}{'..sz..'}{-25}{'..path..
							'}{fig}{'..lbl..'}'
					end
					fun = ''; args = {}; body = {}; 
					return { 
						pandoc.RawInline('latex', ltx)
					}
				end,
		},
	collapsible = {
		pre = function(args) 
					return pandoc.RawInline('latex', '\\begin{remark}\n') 
				end,
		post = function(args)
					return pandoc.RawInline('latex', '\\end{remark}\n')
				end,
		},
	exercise = {
		pre = function(args) 
					return pandoc.RawInline('latex', '\\tbox{1}{0.5}{\n') 
				end,
		post = function(args) 
					return pandoc.RawInline('latex', '\n}\n')
				end,
		},
	}

function reset()
	fun = ''; st = 0; args = {}; aterm=''; bterm='';
end

reset()

function rev(c)
	return c=='<' and '>' or '%'
end

function Inline(el)
	if st==0 then -- not in macro
															--trace(1,el)
		if el.text and el.text:find('{{[<%%]',1)==1 then -- start of macro
			local hm = el.text:sub(3,3)
			if el.text:find('[>%%]}}',#el.text-3) then -- no args
				fun = el.text:sub(4,#el.text-3)
				st=2; codeblock = '';
				bterm = '{{'..hm..'/'..fun..rev(hm)..'}}'
															--trace('2a',el)
				return macros[fun].pre({})
			else -- read args
				fun = el.text:sub(4)
				st = 1; 
				args = {}
				aterm = rev(hm)..'}}'
				bterm = macros[fun].post and '{{'..hm..'/'..fun..rev(hm)..'}}' or ''
															--trace('2b',el)
				return {}
			end
		end		
			if el.text and el.text:find('[Ци]',1) then
				el.text=el.text:gsub('Цвета','\\rn{Tsveta}',1,true)
				el.text=el.text:gsub('Тишины','\\rn{Tishiny}',1,true)
				return pandoc.RawInline('latex', el.text)
			elseif el.text and el.text:find('[∈]',1) then
				--el.text=el.text:gsub('∈','\\rn{Tsveta}',1,true)
				--return pandoc.RawInline('latex', el.text)
			end
															--trace(0,el)
		return el
	elseif st==1 then -- in args
															--trace(3,el)
			if el.text == aterm then -- end of args
															--trace(4,el)
				if bterm == '' then
															--trace(5,el)
					res = macros[fun].prepost(args)
					reset()
					return res
				else -- start accepting body
					st=2; 
															--trace(6,el)
					return macros[fun].pre(args)
				end
			else
															--trace(7,el)
				table.insert(args, el.text)
				return {}
			end
	elseif st==2 then -- in body
															--trace(8,el)
		if el.text == bterm then -- end of body
															--trace(9,el)
			res = macros[fun].post(args); -- skip body_
			reset()
			return res
		else
															--trace('A',el)
			return el
		end
	end
end

function cbreplace(s)
	s=s:gsub('@[$]','@\\mydollar')
	s=s:gsub("'[$]'","'\\mydollar'")
	s=s:gsub('[$]','\\mydollar')
	--s=s:gsub('\\','(*$\\backslash$*)')
	--s=s:gsub('@','(*$\\myat$*)')
	--s=s:gsub('&','(*$\\myamp$*)')
	s=s:gsub('→','(*$\\to$*)')
	--s=s:gsub('≠','(*$\\not=$*)')
	--s=s:gsub('…','(*$\\ldots$*)')
	--s=s:gsub('↠','(*$\\twoheadrightarrow$*)')
	--s=s:gsub('≤','(*$\\leq$*)')
	--s=s:gsub('∈','(*$\\in$*)')
	--s=s:gsub('π','(*$\\pi$*)')
	return s
end

function CodeBlock(el)
															--write('CODEBLOCK '); trace('CB',el);
	--el.text = cbreplace(el.text)
	if el.classes[2] and el.classes[2]=='nolinos' then
		return pandoc.RawBlock('latex',
			'\\begin{lstlisting}[language='..el.classes[1]..',numbers=none]\n'..
			el.text..
			'\n\\end{lstlisting}')
	elseif el.classes[1] then
		return pandoc.RawBlock('latex',
			'\\begin{lstlisting}[language='..el.classes[1]..']\n'..
			el.text..
			'\n\\end{lstlisting}')
	else
		return pandoc.RawBlock('latex',
			'\\begin{lstlisting}\n'..
			el.text..
			'\n\\end{lstlisting}')
	end
end		


function codereplace(s)
	--s=s:gsub('[$]','\\$')
	--s=s:gsub('@','(*$\\myat$*)')
	--s=s:gsub('&','(*$\\myamp$*)')
	--s=s:gsub('→','(*$\\to$*)')
	--s=s:gsub('≠','(*$\\not=$*)')
	--s=s:gsub('…','(*$\\ldots$*)')
	--s=s:gsub('↠','(*$\\twoheadrightarrow$*)')
	--s=s:gsub('≤','(*$\\leq$*)')
	--s=s:gsub('∈','\"O$\\in$\"O')
	--s=s:gsub('π','(*$\\pi$*)')
	s=s:gsub('.*ð','(*$\\degree-\\eth$*)')
	return s
end

function Code(el)
															--write('CODE '); trace('C',el)
	el.text = codereplace(el.text)
	if st == 1 then -- in args
		table.insert(args,el)
		return {}
	end
															--write('CODE '); trace('D',el)
	return el
end

function Block(el)
															--write('block '..dump(el)..'\n');
	return el
end

function SoftBreak(el)
															--write('SOFTBREAK '..dump(el)..'\n');
	return el
end

function BulletList(el)
	if st == 1 then
															--trace('B',el)
		table.insert(args, el.text)
		return {}
	else
		return el
	end
end

return {
	{Code = Code,
	 Block = Block,
	 BulletList = BulletList,
	 SoftBreak = SoftBreak,
	 CodeBlock = CodeBlock,
	 Inline = Inline,
	}
}
