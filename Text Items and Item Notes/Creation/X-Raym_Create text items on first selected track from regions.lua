--[[
 * ReaScript Name: Create text items on first selected track from regions
 * Description: Create text items on first selected track from regions
 * Instructions: Select a destination track. Execute the script. Text items will be colored depending on original region color. The text note will came from the original region name.
 * Author: X-Raym
 * Author URl: http://extremraym.com
 * Repository: GitHub > X-Raym > EEL Scripts for Cockos REAPER
 * Repository URl: https://github.com/X-Raym/REAPER-EEL-Scripts
 * File URl: https://github.com/X-Raym/REAPER-EEL-Scripts/scriptName.eel
 * Licence: GPL v3
 * Forum Thread: Script: Scripts (LUA): Create Text Items Actions (various)
 * Forum Thread URl: http://forum.cockos.com/showthread.php?t=156763
 * Version: 1.1.1
 * Version Date: 2015-03-11
 * REAPER: 5.0 pre 15
 * Extensions: SWS/S&M 2.6.2
 --]]
 
--[[
 * Changelog:
 * v1.1.1 (2015-03-11)
	# Better item selection restoration
	# First selected track as last touched
 * v1.1 (2015-03-06)
	+ Multiple lines support
	+ Dialog box if no track selected
 * v1.0 (2015-02-28)
	+ Initial Release
 --]]

--[[ ----- DEBUGGING ====>
function get_script_path()
  if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
    return debug.getinfo(1,'S').source:match("(.*".."\\"..")"):sub(2) -- remove "@"
  end
    return debug.getinfo(1,'S').source:match("(.*".."/"..")"):sub(2)
end

package.path = package.path .. ";" .. get_script_path() .. "?.lua"
require("X-Raym_Functions - console debug messages")

debug = 0 -- 0 => No console. 1 => Display console messages for debugging.
clean = 0 -- 0 => No console cleaning before every script execution. 1 => Console cleaning before every script execution.

--msg_clean()
]]-- <==== DEBUGGING -----

-- From Heda's HeDa_SRT to text items.lua ====>
--[[dbug_flag = 0 -- set to 0 for no debugging messages, 1 to get them
function dbug (text) 
	if dbug_flag==1 then  
		if text then
			reaper.ShowConsoleMsg(text .. '\n')
		else
			reaper.ShowConsoleMsg("nil")
		end
	end
end]]

function CreateTextItem(starttime, endtime, notetext, color) 
	--ref: Lua: number startOut retval, number endOut reaper.GetSet_LoopTimeRange(boolean isSet, boolean isLoop, number startOut, number endOut, boolean allowautoseek)
	reaper.GetSet_LoopTimeRange(1,0,starttime,endtime,0) -- define the time range for the empty item
	--ref: Lua: reaper.Main_OnCommand(integer command, integer flag)
	reaper.Main_OnCommand(40142,0) -- insert empty item
	--ref: Lua: MediaItem reaper.GetSelectedMediaItem(ReaProject proj, integer selitem)
	item = reaper.GetSelectedMediaItem(0,0) -- get the selected item
	reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)

	HeDaSetNote(item, "|" .. notetext) -- set the note add | character to the beginning of each line. only 1 line for now.
	reaper.SetEditCurPos(endtime, 1, 0) -- moves cursor for next item
end

function HeDaSetNote(item,newnote)  -- HeDa - SetNote v1.0
	--ref: Lua: boolean retval, string str reaper.GetSetItemState(MediaItem item, string str)
	retval, s = reaper.GetSetItemState(item, "")	-- get the current item's chunk
	--dbug("\nChunk=" .. s .. "\n")
	has_notes = s:find("<NOTES")  -- has notes?
	if has_notes then
		-- there are notes already
		chunk, note, chunk2 = s:match("(.*<NOTES\n)(.*)(\n>\nIMGRESOURCEFLAGS.*)")
		newchunk = chunk .. newnote .. chunk2
		--dbug(newchunk .. "\n")
		
	else
		--there are still no notes
		chunk,chunk2 = s:match("(.*IID%s%d+)(.*)")
		newchunk = chunk .. "\n<NOTES\n" .. newnote .. "\n>\nIMGRESOURCEFLAGS 0" .. chunk2
		--dbug(newchunk .. "\n")
	end
	reaper.GetSetItemState(item, newchunk)	-- set the new chunk with the note
end
-- <==== From Heda's HeDa_SRT to text items.lua


function main() -- local (i, j, item, take, track)

	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	track = reaper.GetSelectedTrack(0, 0) -- Get selected track i

	-- IF THERE IS A TRACK SELECTED
	if track ~= nil then
	
		-- LOOP THROUGH REGIONS
		i=0
		repeat
			iRetval, bIsrgnOut, iPosOut, iRgnendOut, sNameOut, iMarkrgnindexnumberOut, iColorOut = reaper.EnumProjectMarkers3(0, i)
			if iRetval >= 1 then
				if bIsrgnOut == true then
					CreateTextItem(iPosOut, iRgnendOut, sNameOut, iColorOut)
				end
				i = i+1
			end
		until iRetval == 0
		reaper.Undo_EndBlock("My action", 0) -- End of the undo block. Leave it at the bottom of your main function.
	else -- no selected track
		reaper.ShowMessageBox("Select a destination track before running the script","Please",0)
	end

end

--[[ ----- INITIAL SAVE AND RESTORE ====> ]]

-- LOOP AND TIME SELECTION
-- SAVE INITIAL LOOP AND TIME SELECTION
function SaveLoopTimesel()
	init_start_timesel, init_end_timesel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
	init_start_loop, init_end_loop = reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
end

-- RESTORE INITIAL LOOP AND TIME SELECTION
function RestoreLoopTimesel()
	reaper.GetSet_LoopTimeRange(1, 0, init_start_timesel, init_end_timesel, 0)
	reaper.GetSet_LoopTimeRange(1, 1, init_start_loop, init_end_loop, 0)
end

-- CURSOR
-- SAVE INITIAL CURSOR POS
function SaveCursorPos()
	init_cursor_pos = reaper.GetCursorPosition()
end

-- RESTORE INITIAL CURSOR POS
function RestoreCursorPos()
	reaper.Main_OnCommand(40042, 0) -- Go to start of the project
	reaper.MoveEditCursor(init_cursor_pos, false)
end

--[[ <==== INITIAL SAVE AND RESTORE ----- ]]

--msg_start() -- Display characters in the console to show you the begining of the script execution.

reaper.PreventUIRefresh(1)
SaveCursorPos()
SaveLoopTimesel()

reaper.Main_OnCommand(40914, 0) -- Select first track as last touched
main() -- Execute your main function

RestoreLoopTimesel()
RestoreCursorPos()
reaper.PreventUIRefresh(-1)

reaper.UpdateArrange() -- Update the arrangement (often needed)

--msg_end() -- Display characters in the console to show you the end of the script execution.
