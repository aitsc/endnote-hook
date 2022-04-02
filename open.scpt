# 链接例子为 hook://endnote/?dn=1-1954,1-2093&l=SCI|3区&or=false
# 其中dn表示 打开的数据库编号(从1开始)-论文的编号#,..
# l表示检索的Label, 不同词使用竖线|分割, or如果是true则表示不同词是或的关系进行检索, 默认为false是且的关系
# url不要自己encode编码, dn如果有值则会忽略l参数

on path2url(thepath)
	return do shell script "python3 -c \"from urllib.parse import unquote; print(unquote('" & thepath & "'))\" || python -c \"import urllib; print urllib.unquote('" & thepath & "')\""
end path2url

set fullURL to path2url("$0")

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

set l_or to "false"
if (count of text items of fullURL) is greater than 1 then
	set fragment to item 2 of theSplit(fullURL, "?")
	set AppleScript's text item delimiters to "&"
	set kvs to text items of fragment
	repeat with kv in kvs
		set AppleScript's text item delimiters to "="
		set k to text item 1 of kv
		set v to text item 2 of kv
		if k = "dn" then
			set database_recNum to v
		end if
		if k = "l" then
			set Label to theSplit(v, "|")
		end if
		if k = "or" then
			set l_or to v
		end if
	end repeat
end if

if database_recNum ≠ "" then
	set myResults to {}
	repeat with dr in theSplit(database_recNum, ",")
		set database to item 1 of theSplit(dr, "-")
		set recNum to item 2 of theSplit(dr, "-")
		set end of myResults to "<RecordID database=\"" & database & "\" recNum=\"" & recNum & "\" />"
	end repeat
else
	tell application "EndNote 20"
		set myResults to {}
		repeat with l in Label
			set end of myResults to find l in field "Label"
		end repeat
	end tell
	if l_or = "true" then
		set myResults to union(myResults)
	else
		set myResults to intersection(myResults)
	end if
end if

tell application "EndNote 20"
	activate
	show records in myResults in first window
end tell
