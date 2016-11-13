do

local function run(msg, matches)
  if matches[1] == 'wai' then
    if is_sudo(msg) then
     send_document(get_receiver(msg), "/home/ugig/TeleSeed/axs/sudo.webp", ok_cb, false)
      return "بابایی من"
    elseif is_admin(msg) then
    send_document(get_receiver(msg), "/home/ugig/TeleSeed/axs/admin.webp", ok_cb, false)
      return "ادمین کمکی باباییم"
    elseif is_owner(msg) then
    send_document(get_receiver(msg), "/home/ugig/TeleSeed/axs/owner.webp", ok_cb, false)
      return "مدیر اصلی گروه"
    elseif is_momod(msg) then
    send_document(get_receiver(msg), "/home/ugig/TeleSeed/axs/mod.webp", ok_cb, false)
      return "کمک مدیر گروه"
    else
  --  send_document(get_receiver(msg), "/root/quick/axs/mmbr.webp", ok_cb, false)
      return "عضو گروه"
    end
  end
end

return {
  patterns = {
    "^[#!/]([Ww]ai)$",
     "^([Ww]ai)$"
    },
  run = run
}
end 
