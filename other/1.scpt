# 标签, 例如 {学习},{研究} 用逗号隔开
set labels to "{GAN}"

# 要增加标签的论文所在的group,逗号分隔
set groups to "Imported References,Duplicate References"
set groups to "aaa     GAN"

# library 名称
set doc to "papers.enl"

# 是否用于删除已存在的标签 true or false
set is_del to "false"


tell application "EndNote 20"
	set myResults to get groups in window doc
end tell
log "所有group数量: " & (count of myResults)
log myResults
tell application "EndNote 20"
	set rs to (retrieve of "all" records in document "papers.enl")
	log "数据库论文总数: " & (count of rs)
end tell
log
log "标签: " & labels
log "论文所在的groups: " & groups
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

set labels_ to theSplit(labels, ",")
set find_n to 0
set modify_n to 0
tell application "EndNote 20"
	set myResults to {}
	set groups to my theSplit(groups, ",")
	log "group数量: " & (count of groups)
	repeat with group in groups
		set myResults to myResults & (get records in group in window doc)
	end repeat
	log "发现论文数量(含重复): " & (count of myResults)
	set myResults to my union({myResults})
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
log {"发现论文数量: " & find_n, "修改论文数量: " & modify_n}

if is_del = "false" then
	set link to "[en:" & labels & "](hook://endnote/?" & doc & "=" & labels & "&logic=and)"
	log "拷贝链接: " & link
	set the clipboard to link
end if

