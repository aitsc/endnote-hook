# 标签, 例如 {学习},{研究} 用逗号隔开
set labels to "{GAN}"

# 要增加标签的论文所在的group
set group to "Imported References"
set group to "aaa     GAN"

# library 名称
set doc to "papers.enl"

# 是否用于删除已存在的标签 true or false
set is_del to "false"


tell application "EndNote 20"
	set myResults to get groups in window doc
end tell
log "所有group数量: " & (count of myResults)
log myResults
log
log "标签: " & labels
log "论文所在的group: " & group
log "library 名称: " & doc
log "是否删除标签: " & is_del
log

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
	return item_num
end each_count

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

set labels_ to theSplit(labels, ",")
set find_n to 0
set modify_n to 0
tell application "EndNote 20"
	set myResults to get records in group in window doc
	repeat with r in myResults
		set Label to field "Label" of record r
		set Label_ to Label
		repeat with l in labels_
			if is_del = "false" then
				if Label does not contain l then
					if character -1 of Label ≠ "}" then set Label to Label & "

"
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
		set find_n to find_n + 1
	end repeat
end tell
log {"发现数量: " & find_n, "修改数量: " & modify_n}

if is_del = "false" then
	set link to "[en:" & labels & "](hook://endnote/?" & doc & "=" & labels & "&logic=and)"
	log "拷贝链接: " & link
	set the clipboard to link
end if

tell application "EndNote 20"
	set rs to (retrieve of "all" records in document "papers.enl")
	log "数据库论文总数: " & (count of rs)
	log "统计每个标签出现的次数: ..."
	set t to {}
	repeat with r in rs
		set end of t to field "Label" of record r
	end repeat
end tell
set all_labels to match(list2string(t, ""), "/\\{.+?\\}/g")
log "所有标签数量: " & (count of all_labels)
each_count(all_labels)
