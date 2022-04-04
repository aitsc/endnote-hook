# 要统计标签的论文所在的group, 用js语法的正则表达式匹配
set group_re to "/^(a|f)/g"

# library 名称
set doc to "papers.enl"


set groups to {}
tell application "EndNote 20"
	set myResults to get groups in window doc
	repeat with r in myResults
		if (count of my match(r, group_re)) > 0 then
			set end of groups to r
		end if
	end repeat
end tell
# log myResults  # 所有group
log "library 名称: " & doc
log "匹配group的正则表达式: " & group_re
log "所有group数量: " & (count of myResults)
log "匹配到的group数量: " & (count of groups) & "; 匹配到的group:"
log groups
log

on theSplit(theString, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to oldDelimiters
	return theArray
end theSplit

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


tell application "EndNote 20"
	set rs to {}
	repeat with group in groups
		set rs to rs & (get records in group in window doc)
	end repeat
	log "发现论文数量(含重复): " & (count of rs)
	set rs to my union({rs})
	log "发现论文数量: " & (count of rs)
	log "统计每个标签出现的次数: ..."
	set t to {}
	repeat with r in rs
		set end of t to field "Label" of record r
	end repeat
end tell
set all_labels to match(list2string(t, ""), "/\\{.+?\\}/g")
log "所有标签数量: " & (count of all_labels)
each_count(all_labels)
