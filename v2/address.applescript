# : represents space, 冒号代表空格. 数据库不能重名, 名字变了链接中的名字也要变
# 没有选择任何论文则会统计当前窗口显示论文的每个{..}标签出现论文的次数, 1千论文预计5秒左右
# 没有选择任何论文时, 如果剪切板包含匹配正则 "/^(add|del):(\\{.+?\\},)*(\\{.+?\\})?$/g" 的字符串, 那么就会增加删除当前显示的论文标签
# 例如 add:{123},{abc} 就是为当前显示的论文增加{123}和{abc}两个标签
set only_use_front_document to "true" # true or false, 是否只获取最前面打开的endnote数据库

on theSplit(theString, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to oldDelimiters
	return theArray
end theSplit

on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars

on match(_subject, _regex)
	set _js to "(new String(`" & _subject & "`)).match(" & _regex & ")"
	set _result to run script _js in "JavaScript"
	if _result is null or _result is missing value then
		return {}
	end if
	return _result
end match

on each_count(inList) # {a,b,a} to {{a,2},{b,1}}
	set outList to union({inList})
	set item_num to {}
	repeat with i in outList
		set i to contents of i
		set i_n to 0
		repeat with j in inList
			set j to contents of j
			if i = j then set i_n to i_n + 1
		end repeat
		set end of item_num to {i, i_n}
	end repeat
	return sorted(item_num, 2, "true")
end each_count

on sorted(myList, ii, reversed) # 冒泡排序, 输入: ({{..},..}, 针对{..}中的第几个排序, 是否倒序)
	repeat with i from 1 to (count of myList) - 1
		repeat with j from i + 1 to count of myList
			if reversed = "false" then
				if item ii of item j of myList < item ii of item i of myList then
					set temp to item i of myList
					set item i of myList to item j of myList
					set item j of myList to temp
				end if
			else
				if item ii of item j of myList > item ii of item i of myList then
					set temp to item i of myList
					set item i of myList to item j of myList
					set item j of myList to temp
				end if
			end if
		end repeat
	end repeat
	return myList
end sorted

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

on list2string(theList, theDelimiter) # list to str
	set theBackup to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theString to theList as string
	set AppleScript's text item delimiters to theBackup
	return theString
end list2string

# 收集每个doc选择的记录
tell application "EndNote 20"
	set doc_records to {}  # {{doc,{r,..}},..}
	if only_use_front_document = "true" then
		set docs to {front document}
	else
		set docs to every document
	end if
	repeat with d in docs
		set myResults to retrieve of "selected" records in d
		if myResults ≠ {} then set end of doc_records to {name of d, myResults}
	end repeat
end tell

# 把记录转换为链接
set s_num to 0
set dr_url to ""
repeat with dr in doc_records
	if dr_url ≠ "" then set dr_url to dr_url & "&"
	set dr_url to dr_url & item 1 of dr & "="
	repeat with r in item 2 of dr
		if character -1 of dr_url ≠ "=" then set dr_url to dr_url & ","
		set dr_url to dr_url & item 4 of theSplit(r, "\"")
	end repeat
	set s_num to s_num + count of item 2 of dr
end repeat
set dr_url to replace_chars(dr_url, " ", ":")

# 没有获取到记录就统计标签出现论文数量, 或者执行其他操作
if dr_url = "" then
	set nn to "
"
	# 尝试从剪切板中获取增加或删除标签
	set opp to match(the clipboard as text, "/^(add|del):(\\{.+?\\},)*(\\{.+?\\})?$/g")
	if count of opp = 1 then
		set opp to item 1 of opp
		tell application "EndNote 20"
			set rs to retrieve of "shown" records in front document
		end tell
		set btns to {"No", "Yes"}
		display dialog opp & " in Label ?" with title ("Shown papers num: " & count of rs) buttons btns default button 1
		if the button returned of the result = "Yes" then
			set all_labels to match(opp, "/\\{.+?\\}/g")
			set op to item 1 of theSplit(opp, ":")
			set modify_n to 0
			tell application "EndNote 20"
				repeat with r in rs
					set Label to field "Label" of record r
					set Label_ to Label
					repeat with l in all_labels
						if op = "add" then
							if Label does not contain l then
								if Label ≠ "" and character -1 of Label ≠ "}" then set Label to Label & nn & nn
								set Label to Label & l
							end if
						else
							set Label to my replace_chars(Label, l, "")
						end if
					end repeat
					if Label_ ≠ Label then
						set field "Label" of record r to Label
						set modify_n to modify_n + 1
					end if
				end repeat
			end tell
			display dialog opp & nn & nn & "shown papers: " & count of rs & ", modified papers: " & modify_n
		end if
	else  # 统计标签出现论文数量
		tell application "EndNote 20"
			set rs to retrieve of "shown" records in front document
			log "发现论文数量(含重复): " & (count of rs)
			set rs to my union({rs})
			set out to "论文数量: " & (count of rs)
			log "统计每个标签出现的次数: ..."
			set t to {}
			repeat with r in rs
				set end of t to field "Label" of record r
			end repeat
		end tell
		set all_labels to match(list2string(t, ""), "/\\{.+?\\}/g")
		set out to out & "; 标签种数: " & (count of union({all_labels}))
		set out to out & "; 标签个数: " & (count of all_labels) & "; 每个标签出现次数:" & nn & nn
		repeat with l_n in each_count(all_labels)
			set out to out & item 1 of l_n & ":" & item 2 of l_n & ", "
		end repeat
		display dialog out
	end if
end if

# 返回
if s_num < 2 then
	set s_num to ""
else
	set s_num to ":" & s_num
end if
return "[en" & s_num & "](hook://endnote/?" & dr_url & ")"
