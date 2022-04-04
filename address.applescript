set db to "" # 默认 database 编号, 为空则使用获取到的 database. 使用多个数据库必须留空, 并且要保证数据库打开的顺序是固定的

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

on theSplit(theString, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to oldDelimiters
	return theArray
end theSplit

tell application "EndNote 20"
	# 这里需要增加论文一定会包括的字符
	set myResults to {(find "0" constrain to "selected"), (find "9" constrain to "selected"), (find " " constrain to "selected")}
end tell

set ret to ""
repeat with r in union(myResults)
	if db = "" then
		set database to item 2 of theSplit(r, "\"")
	else
		set database to db
	end if
	set recNum to item 4 of theSplit(r, "\"")
	if ret = "" then
		set ret to database & "-" & recNum
	else
		set ret to ret & "," & database & "-" & recNum
	end if
end repeat

return "[en](hook://endnote/?dn=" & ret & ")"
