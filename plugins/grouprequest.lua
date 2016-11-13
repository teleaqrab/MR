do

 function run(msg, matches)
 local ch = '214287059'..msg.to.id
 local fuse = 'درخواست سوپرگروه جدید!\n\nایدی : ' .. msg.from.id .. '\n\nنام: ' .. msg.from.print_name ..'\n\nیوزرنیم: @' .. msg.from.username ..'\n\nپیام از: '..msg.to.id.. '\n\nتایم ارسال :\n' .. matches[1]
 local fuses = '!printf user#id' .. msg.from.id


   local text = matches[1]
   local chat = "channel#id"..214287059


  local sends = send_msg(chat, fuse, ok_cb, false)
  return 'درخواست شما ارسال شد!\n سوپرگروه شما درانتظارساخت است!'

 end
 end
 return {

  description = "SuperGroup request",

  usage = "",
  patterns = {
  "^[#!/]reqgp$"

  },
  run = run
 }
--by @MehdiHS