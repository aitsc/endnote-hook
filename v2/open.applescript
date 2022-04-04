# : represents space, 冒号代表空格. 数据库不能重名, 名字变了链接中的名字也要变
# 链接例子 hook://endnote://?papers.enl=中4,Q3&My:EndNote:Library.enl=1&logic=and
# 链接例子 hook://endnote://?papers.enl=text:&logic=or&field=Title
# 链接例子 hook://endnote://?papers.enl=ag:::NLP书籍&logic=or&field=group
# 链接例子 hook://endnote://?papers.enl=1991,1878&My:EndNote:Library.enl=1
# logic 如果为空则使用编号匹配, 否则使用field匹配(默认Label). logic 如果是 or 则表示不同词是或的关系进行检索, and 就是且的关系
# field 是 endnote 中的 Display Fields 的名字, 也可以是 group 来表示选择组
# url不要自己encode编码, 词或编号用逗号(,)分隔
# 如果剪切板中文本为 shown 则只会匹配链接中记录已经显示在当前document中的记录

on path2url(thepath)
	return do shell script "python3 -c \"from urllib.parse import unquote; print(unquote('" & thepath & "'))\" || python -c \"import urllib; print urllib.unquote('" & thepath & "')\""
end path2url

on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars

set fullURL to path2url("$0")
# set fullURL to "hook://endnote://?papers.enl=1991,1878&My:EndNote:Library.enl=1"
# set fullURL to "hook://endnote://?papers.enl=ag:::NLP书籍&logic=or&field=group"
# set fullURL to "hook://endnote://?papers.enl=中4,Q3&My:EndNote:Library.enl=1&logic=and&field=Label"
# set fullURL to "hook://endnote/?papers.enl={层次}&logic=and"
set fullURL to replace_chars(fullURL, ":", " ")

on theSplit(theString, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to oldDelimiters
	return theArray
end theSplit

on intersection(list_list) # 多个list求交集
	local newList, listB, a
	set newList to item 1 of list_list
	repeat with listA in list_list
		set listB to {}
		repeat with a in listA
			set a to contents of a -- dereference implicit loop reference
			if {a} is in newList then set end of listB to a
		end repeat
		set newList to listB
	end repeat
	return newList
end intersection

on union(list_list) # 多个list求并集, 一个list内部重复的元素会去除
	local listA, listB
	set listA to {}
	repeat with listB in list_list
		set listA to listA & listB
	end repeat
	set listB to {}
	repeat with a in listA
		set a to contents of a -- dereference implicit loop reference
		if {a} is not in listB then set end of listB to a
	end repeat
	return listB
end union

# 解析链接
set field_ to "Label"
set logic_ to ""
set doc_records to {} # {{"name",{"123"/"word"/"group name",..}},..}
set no_open_doc to ""
tell application "EndNote 20"
	set all_doc to name of every document
end tell
if (count of text items of fullURL) is greater than 1 then
	set fragment to item 2 of theSplit(fullURL, "?")
	set AppleScript's text item delimiters to "&"
	set kvs to text items of fragment
	repeat with kv in kvs
		set AppleScript's text item delimiters to "="
		set k to text item 1 of kv
		set v to text item 2 of kv
		if k = "field" then
			set field_ to v
		else if k = "logic" then
			set logic_ to v
		else
			if all_doc contains k then
				set end of doc_records to {k, theSplit(v, ",")}
			else
				set no_open_doc to no_open_doc & k & ", "
			end if
		end if
	end repeat
end if
log doc_records

# 获取所有记录
set doc_results to {}
set cb to the clipboard as text
if logic_ = "" then
	repeat with dr in doc_records
		tell application "EndNote 20"
			set r to item 1 of (retrieve of "all" records in document (item 1 of dr))
		end tell
		set database to item 2 of theSplit(r, "\"")
		set records_ to {}
		repeat with r in item 2 of dr
			set end of records_ to "<RecordID database=\"" & database & "\" recNum=\"" & r & "\" />"
		end repeat
		set end of doc_results to {item 1 of dr, records_}
	end repeat
else
	repeat with dr in doc_records
		tell application "EndNote 20"
			set myResults to {}
			repeat with k in (item 2 of dr)
				if field_ = "group" then
					set end of myResults to get records in k in window (item 1 of dr)
				else # 所有文档中所有满足的记录
					set end of myResults to find k in field field_
				end if
			end repeat
			set r to item 1 of (retrieve of "all" records in document (item 1 of dr)) # 用于获取文档所在数据库编号
			if cb = "shown" then set shown_rs to retrieve of cb records in document (item 1 of dr)
		end tell
		if logic_ = "or" then
			set myResults to union(myResults)
		else
			set myResults to intersection(myResults)
		end if
		set database to item 2 of theSplit(r, "\"")
		set records_ to {}
		repeat with r in myResults
			if r contains " database=\"" & database & "\"" then set end of records_ to contents of r
		end repeat
		if cb = "shown" then set records_ to intersection({shown_rs, records_})
		set end of doc_results to {item 1 of dr, records_}
	end repeat
end if
log doc_results

# 展示所有记录
tell application "EndNote 20"
	activate
	repeat with dr in doc_results
		show records in (item 2 of dr) in window (item 1 of dr)
		if (count of item 2 of dr) = 1 then highlight records in (item 2 of dr) in window (item 1 of dr)
	end repeat
	set index of window (item 1 of (item 1 of doc_results)) to 1
end tell
if no_open_doc ≠ "" then display alert "Please open: " & no_open_doc
if cb = "shown" then display alert "检测到剪切板中有shown, 因此只从窗口中已显示的记录中匹配记录"
