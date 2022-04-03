# : represents space, 冒号代表空格. 数据库不能重名, 名字变了链接中的名字也要变
set only_use_front_document to "false" # true or false, 是否只获取最前面打开的endnote数据库

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

tell application "EndNote 20"
	set doc_records to {}
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

set dr_url to ""
repeat with dr in doc_records
	if dr_url ≠ "" then set dr_url to dr_url & "&"
	set dr_url to dr_url & item 1 of dr & "="
	repeat with r in item 2 of dr
		if character -1 of dr_url ≠ "=" then set dr_url to dr_url & ","
		set dr_url to dr_url & item 4 of theSplit(r, "\"")
	end repeat
end repeat
set dr_url to replace_chars(dr_url, " ", ":")

return "[en](hook://endnote/?" & dr_url & ")"
