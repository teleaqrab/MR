do
local function pre_process(msg)
  if not msg.text and msg.media then
    msg.text = '['..msg.media.type..']'
  end
  return msg
end
local function del_by_reply(extra, success, result)
  vardump(result)
    if result.to.peer_type == "channel" then
        delete_msg(result.id, ok_cb, false)
    end
end
function status_msg(msg, trigger)
  local data = load_data(_config.moderation.data)
  local strict_settings = data[tostring(msg.to.id)]['settings']['strict']
  local status = trigger.." is not allowed here\n"..('@'..msg.from.username or msg.from.first_name).."\nStatus:"
  if strict_settings == "yes" and msg.to.type == 'channel' then
    kick_user(msg.from.id, msg.to.id)
	delete_msg(msg.id, ok_cb, false)
	status = status.."User kicked/msg deleted"
  else
    delete_msg(msg.id, ok_cb, false)
	status = status.."Mssage deleted"
  end
  send_large_msg(get_receiver(msg), status)
end
local function run(msg, matches)
  local data = load_data(_config.moderation.data)
  if data[tostring(msg.to.id)] then
    local strict = data[tostring(msg.to.id)]['settings']['strict']
    if data[tostring(msg.to.id)]['settings']['lock_link'] == "yes" then
      if msg.text:match("telegram.me") and not is_momod(msg) then
	    if msg.to.type == "chat" then
		  kick_user(msg.from.id, msg.to.id)
	      return send_large_msg(get_receiver(msg), "Link postig is not allowed here")
		else
		  delete_msg(msg.id, ok_cb, true)
		  if strict == "yes" then
		    delete_msg(msg.id, ok_cb, true)
			kick_user(msg.from.id, msg.to.id)
		  end
		end
      end
      if msg.media then
        if msg.media.caption:match("telegram.me") and not is_momod(msg) then
		  if msg.to.type == "chat" then
		    kick_user(msg.from.id, msg.to.id)
			return send_large_msg(get_receiver(msg), "Link posting is not allowed here")
		  else
            delete_msg(msg.id, ok_cb, true)
		    if strict == "yes" then
			  kick_user(msg.from.id, msg.to.id)
		    end
		  end
        end
      end
	end
  end
  if data[tostring(msg.to.id)] then
    if data[tostring(msg.to.id)]['settings']['lock_sticker'] == "yes" then
	  if msg.media then
	    if msg.media.caption == "sticker.webp" or msg.media.caption and msg.media.caption:match("webp") and not is_momod(msg) then
	      delete_msg(msg.id,ok_cb, true)
		  if strict == "yes" then
		    delete_msg(msg.id, ok_cb, false)
			kick_user(msg.from.id, msg.to.id)
		  end
		  if msg.to.type == "chat" then
		    kick_user(msg.from.id, msg.to.id)
			return send_large_msg(get_receiver(msg), "Sticker posting is not allowed here")
		  end
	    end
	  end
	end
	if data[tostring(msg.to.id)]['settings']['lock_arabic'] == "yes" then
	  if msg.text:match('[\216-\219][\128-\191]') and not is_momod(msg) then
	    local trigger = "Persian"
	    status_msg(msg, trigger)
	  end
	end
  end
  if data[tostring(msg.to.id)] then
    if data[tostring(msg.to.id)]['settings']['lock_rtl'] == "yes" then
	  if msg.text:match('‮') or msg.text:match('‏') and not is_momod(msg) then
	    local trigger = "RTL characters"
	    status_msg(msg, trigger)
		if msg.to.type == "chat" then
		  kick_user(msg.from.id, msg.to.id)
		  return send_large_msg(get_receiver(msg), "RTL characters are not allowed here")
		end
	  end
	end
  end
  if matches[1] == "del" and is_momod(msg) then
    if type(msg.reply_id)~= "nil" then
	  delete_msg(msg.id, ok_cb, false)
      msgreply = get_message(msg.reply_id, del_by_reply, false)
	end
  end
  if msg.to.type == "user" then
    if msg.fwd_from and is_admin(msg) then
	  local text = "User Info\n\nFist: "..msg.fwd_from.fist_name.."\nLast:"..(msg.fwd_from.last_name or '').."\nUsername:"..(msg.fwd_from.username or '').."\nID:"..msg.fwd_from.id
	  return text
	end
  end
  return 
end
return {
  patterns = {
    "(telegram.me)",
	'‮',
	'‏', 
	"%[(photo)%]",
	"([\216-\219][\128-\191])",
	"^[/!#](del)$",
	'%[(document)%]',
	"^!!tgservice (.+)$"
  },
  run = run,
  pre_process = pre_process
}
end