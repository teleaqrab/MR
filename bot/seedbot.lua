package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
VERSION = assert(f:read('*a'))
f:close()

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  msg = backward_msg_format(msg)

  local receiver = get_receiver(msg)
  print(receiver)
  --vardump(msg)
  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)

end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)
  -- See plugins/isup.lua as an example for cron

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < os.time() - 5 then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
    --send_large_msg(*group id*, msg.text) *login code will be sent to GroupID*
    return false
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end
  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Sudo user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
	"admin",
    "activeuser",
    "onservice",
    "inrealm",
    "ingroup",
    "inpm",
    "banhammer",
    "block",
    "stats",
    "Google",
    "txt2img",
    "filterworld",
    "anti_spam",
    "plugins",
    "aparat",
    "owners",
    "arabic_lock",
    "instagram",
    "set",
    "joke",
    "get",
    "broadcast",
    "invite",
    "all",
    "location",
    "short.link",
    "info",
    "shekayat",
    "azan",
    "tophoto",
    "tosticker",
    "wai",
    "qrcode",
    "weather",
    "mypic",
    "invsudo",
    "leave_ban",
    "supergroup",
    "whitelist",
    "msg_checks",
    "getplug",
    "danbooru",
    "voice-space",
    "music",
    "rmsg",
	"toVoice",
	"voice-space"
    },
 sudo_users = {152150380,113000795, 212586772,0,tonumber(our_id)},--Sudo users
    moderation = {data = 'data/moderation.json'},
    about_text = [[
⚜Tg.Dev™⚜
☄
☄LinuxManager TgBot☄ 
☄Developer And Founder☄
☄{ @HazratBiAsabam }☄
☄Developer☄ 
☄{ @mamad_ninja }☄
☄{ @XxAli_sinner_safir_blackbangamxX }☄
☄
if Reoport Send pm on 
☄{ @HazratBiAsabambot} ☄
☄
⚜Tg.Dev™⚜
]],
    help_text_realm = [[
راهنمای گروه مدیران:

!creategroup [Name]
☄ساخت گروه☄

!createrealm [Name]
☄ساخت گروه مدیریت☄

!setname [Name]
☄قرار دادن نام گروه☄

!setabout [group|sgroup] [GroupID] [Text]
☄قرار دادن درباره گروه☄

!setrules [GroupID] [Text]
☄قرار دادن قوانین گروه☄

!lock [GroupID] [setting]
☄بستن ستینگ☄

!unlock [GroupID] [setting]
☄باز کردن ستینگ☄

!settings [group|sgroup] [GroupID]
☄نمایش ستینگ گروه☄
!wholist
☄گرفتن ایدی اعضا گروه ها☄

!who
☄گرفتن ایدی اعضا گروه ها در یک فایل☄

!type
☄نمایش نوع گروه☄

!kill chat [GroupID]
☄پاک کردن تمام اعضای گروه و پاک کردن گروه☄

!kill realm [RealmID]
☄پاک کردن تمام اعضا گروه مدیریت و ریمو گردن گروه☄

!addadmin [id|username]
☄ادمین کردن یک شخص فقط سودو ها میتوانند☄

!removeadmin [id|username]
☄ریمو کردن ادمین گروه فقط سودو ها میتوانند☄

!list groups
☄گرفتن لیست تمام گروه ها☄

!list realmss
☄گرفتن لیست گروه های ریلم☄

!support
☄قراردادن یک شخص به عنوان ساپورت بات☄

!-support
☄ریمو کردن شخص از ساپورت بات☄

!log
☄گرفتن فایل لوگ گروه☄

!broadcast [text]
!broadcast Hello !
☄ارسال پیام همگانی☄
☄فقط سودو میتواند ارسال انبوه کند☄

!bc [group_id] [text]
!bc 123456789 Hello !
☄ارسال یک متن به گروه خاص☄


☄همچنین شما میتوانید از / و # و ! استفاده کنید☄
]],
    help_text = [[
⚡️دستورات راهنمای Linux Manager :⚡️
⚡️برای حذف شخص از گروه ⚡️
!kick {یوزرنیم یا ایدی}
.............................................
💥محروم کردن شخص به طور کلی از گروه💥
!ban {یوزرنیم یا ایدی}
.............................................
💥خارج کردن از محروم کردن گروه💥
!unban {ایدی}
.............................................
ب💥رای مشاهده ایدی اعضای گروه 💥
!who or !wholist
.............................................
💥برای نمایش کمک مدیران گروه💥
!modlist
.............................................
💥برای کمک مدیر کردن یک فرد 💥
!promote {یوزرنیم}
.............................................
💥برای خارج کردن از کمک مدیر💥
!demote {یوزرنیم}
.............................................
💢برای خروج از گروه💢 
!kickme
.............................................
💢برای نمایش درباره گروه💢
!about
.............................................
💢برای قراردادن عکس برروی پروفایل گروه💢
!setphoto
.............................................
💢برای قرار دادن اسم گروه💢
!setname{نام مورد نظر}
.............................................
💢برای نمایش قوانین گروه💢
!rules
.............................................
💢برای نمایش ایدی گروه یا شخص مورد نظر💢
!id
.............................................
برای نمایش راهنمای ربات💢
!help
.............................................
🔆برای قفل کردن {ارسال لینک تبلیغ/تکرار/اسپم/چت کردن فارسی/ادکردن و ورود عضو جدید/چپ به راست/ارسال استیکر/ارسال شماره تلفن/تگ}
!lock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]
به ترتیب استفاده میشود🔆
.............................................
🔆برای دراوردن قفل {ارسال لینک تبلیغ/تکرار/اسپم/چت کردن فارسی/ادکردن و ورود عضو جدید/چپ به راست/ارسال استیکر/ارسال شماره تلفن/تگ}
!unlock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]
به ترتیب استفاده میشود🔆
.............................................
🔆موت کردن{به محظ ارسال ریمو میشود }: بستن ارسال همه چیزها /صداو ویس/تصاویرمتحرک/عکس/فیلم
!mute [all|audio|gifs|photo|video]
برای بستن ارسال استفاده میشود🔆
.............................................
🔆برای ان موت کردن و بازکردن ارسال :بازکردن ارسال همه چیزها /صداو ویس/تصاویرمتحرک/عکس/فیلم
!unmute [all|audio|gifs|photo|video]
برای بازکردن ارسال استفاده میشود🔆
.............................................
🔆قراردادن قوانین🔆
!set rules متن قوانین
.............................................
☄قراردادن توضیحات☄
!set about متن مورد نظر
.............................................
☄نمایش تنظیمات گروه☄
!settings
.............................................
☄نمایش کاربرهای لال شده[کاربرلال شده نمیتواند درگروه هیچ متن یا چیزی ارسال کند]☄
!mutelist
.............................................
☄لال کردن کاربر [کاربرلال شده نمیتواند درگروه هیچ متن یا چیزی ارسال کنداگر چیزی بنویسد یا ارسال کند ریمو خواهد شد ]☄
!muteuser {یوزرنیم}
.............................................
☄برای در اوردن کاربر لال☄ 
!muteuser {یوزرنیم}
☄همانگونه درخواهد امد☄
.............................................
🔶نمایش ارسال های لال شده{عکس یا فیلم را مثلا بسته باشید}🔶
!muteslist
.............................................
🔶ساخت لینک جدید🔶
!newlink
.............................................
🔶نمایش لینک گروه🔶
!link
.............................................
🔶نمایش مدیر اصلی گروه🔶
!owner
.............................................
🔶برای قرار دادن تعداد اسپم درگروه🔶
!setflood مقدار از 5 تا 20
.............................................
🔰پاک کردن کمک مدیر/قوانین/توضیحات 🔰
!clean [modlist|rules|about]
.............................................
🔰نمایش ایدی شخص مورد نظر🔰
!res {یوزرنیم}
.............................................
🔰نمایش اتفاقات گروه🔰
!log
.............................................
🔰نمایش افراد محروم شده از گروه🔰
!banlist
.............................................
🔰تبدیل عکس به استیکر🔰
!tosticker
.............................................
🔰تبدیل استیکر به عکس🔰
!tophoto
.............................................
⚜نمایش اطلاعات شما⚜
!info
.............................................
⚜عکس گرفتن از نمای یک سایت⚜
!shot ادرس سایت
.............................................
⚜نمایش مقام شما در گروه⚜
!wai
.............................................
✨نمایش اینستا شخص مودر نظر✨
!insta ایدی اینستا 
.............................................
✨سرچ کردن از گوگل✨
#src کلمه مورد نظر
.............................................
✨سرچ از آپارات✨
!aparat کلمه مورد نظر
.............................................
✨تبدیل لینک به کیوآر کد✨
!qr لینک
.............................................
✨فیلتر کردن یک کلمه✨
!filter + کلمه مورد نظر
.............................................
✨ارسال عکس های جالب✨
!danbooru
.............................................
✨تبدیل نوشته به عکس✨
t2i متن
.............................................
✨تبدیل متن به صدا✨
!voice متن
.............................................
✨اد کردن مدیر ربات✨
!invsudo
.............................................
✨شکایت کردن از یک شخص ریپلای رو پیامش ونوشتن دستور✨
shak
.............................................
✨کوتاه کردن لینک دانلود✨
!shortlink لینک دانلود
.............................................
✨ارسال ایدی و عکس پروفایل شما✨
/mypic
.............................................
✨برای نمایش اب و هوا یک شهر✨
!weather شهر 
.............................................
✨برای دیدن اوقات شرعی یک شهر✨
!praytime نام شهر
.............................................
✨برای نمایش 3 اعضای فعال گروه✨
!pmuser
.............................................
✨سرچ کردن موزیک✨
!music نام موزیک یا خاننده به صورت فینگلیش
✨برای دانلود از لیست✨
!dl عدد انتخابی از لیست
.............................................
⚜شما میتوانید از # و / و ! برای تمام دستورات استفاده نماید⚜
]],
	help_text_super =[[
⚡️راهنمای سوپرگروه ربات Linux :⚡️
⚡️نمایش اطلاعات سوپر گروه⚡️
!info
.............................................
💥نمایش ادمین های سوپرگروه💥
!admins
.............................................
💥نمایش مدیر اصلی سوپرگروه💥
!owner
.............................................
💥نمایش کمک مدیران💥
!modlist
.............................................
💥نمایش ربات های فعال سوپرگروه💥
!bots
.............................................
💢نمایش اعضا سوپرگروه💢
!who
.............................................
💢محروم و بلاک کردن شخص از سوپرگروه 💢
!block
.............................................
💢محروم کردن شخص💢
!ban
.............................................
🔆دراوردن از محرومیت🔆
!unban
.............................................
🔆نمایش ایدی گروه و شخص مورد نظر🔆
!id
.............................................
🔆خروج از سوپرگروه🔆
!kickme
.............................................
🔆برای کمک مدیر کردن یک فرد 🔆
!promote {یوزرنیم}
.............................................
🔆برای خارج کردن از کمک مدیر🔆
!demote {یوزرنیم}
.............................................
☄برای قراردادن عکس برروی پروفایل گروه☄
!setphoto
.............................................
☄برای قرار دادن اسم گروه☄
!setname{نام مورد نظر}
.............................................
☄ساخت لینک جدید☄
!newlink
.............................................
☄نمایش لینک گروه☄
!link
.............................................
☄برای نمایش قوانین گروه☄
!rules
.............................................
🔰برای قفل کردن {ارسال لینک تبلیغ/تکرار/اسپم/چت کردن فارسی/ادکردن و ورود عضو جدید/چپ به راست/ارسال استیکر/ارسال شماره تلفن/تگ}
!lock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]
به ترتیب استفاده میشود🔰
.............................................
🔰برای دراوردن قفل {ارسال لینک تبلیغ/تکرار/اسپم/چت کردن فارسی/ادکردن و ورود عضو جدید/چپ به راست/ارسال استیکر/ارسال شماره تلفن/تگ}
!unlock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]
به ترتیب استفاده میشود🔰
.............................................
🔰موت کردن{مخصوص سوپرگروه}: بستن ارسال همه چیزها /صداو ویس/تصاویرمتحرک/عکس/فیلم
!mute [all|audio|gifs|photo|video]
برای بستن ارسال استفاده میشود🔰
.............................................
🔰برای ان موت کردن و بازکردن ارسال {مخصوص سوپرگروه}:بازکردن ارسال همه چیزها /صداو ویس/تصاویرمتحرک/عکس/فیلم
!unmute [all|audio|gifs|photo|video]
برای بازکردن ارسال استفاده میشود🔰
.............................................
🔰قراردادن قوانین🔰
!set rules متن قوانین
.............................................
🔶قراردادن توضیحات🔶
!set about متن مورد نظر
.............................................
🔶نمایش تنظیمات گروه🔶
!settings
.............................................
🔶پاک کردن پیام مورد نظر🔶
!del
.............................................
🔶تبدیل عکس به استیکر🔶
!tosticker
.............................................
🔶تبدیل استیکر به  عکس🔶
!tophoto
.............................................
⚜نمایش اطلاعات شما⚜
!info
.............................................
⚜عکس گرفتن از نمای یک سایت⚜
!shot ادرس سایت
.............................................
⚜ادمین کردن یک شخص باید روی پیام ان ریپلای کنید و دستور⚜
!setadmin
.............................................
⚜نمایش مقام شما در گروه⚜
!wai
.............................................
✨نمایش اینستا شخص مودر نظر✨
!insta ایدی اینستا 
.............................................
✨سرچ کردن از گوگل✨
#src کلمه مورد نظر
.............................................
✨سرچ از آپارات✨
!aparat کلمه مورد نظر
.............................................
✨تبدیل لینک به کیوآر کد✨
!qr لینک
.............................................
✨فیلتر کردن یک کلمه✨
!filter + کلمه مورد نظر
.............................................
✨ارسال عکس های جالب✨
!danbooru
.............................................
✨تبدیل نوشته به عکس✨
t2i متن
.............................................
✨تبدیل متن به صدا✨
!voice متن
.............................................
✨اد کردن مدیر ربات✨
!insudo
.............................................
✨کوتاه کردن لینک دانلود✨
!shortlink لینک دانلود
.............................................
✨ارسال ایدی و عکس پروفایل شما✨
/mypic
.............................................
✨برای نمایش اب و هوا یک شهر✨
!weather شهر 
.............................................
✨برای دیدن اوقات شرعی یک شهر✨
!praytime نام شهر
.............................................
✨برای نمایش 3 اعضای فعال گروه✨
!pmuser
.............................................
✨پاک کردن راحت و سریع پیام سوپرگروه✨
!rmsg  تعداد مثلا 10یا 100
.............................................
✨سرچ کردن موزیک✨
!music نام موزیک یا خاننده به صورت فینگلیش
✨برای دانلود از لیست✨
!dl عدد انتخابی از لیست
.............................................
⚜شما میتوانید از # و / و ! برای تمام دستورات استفاده نماید⚜
]],
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)
  --vardump (chat)
end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
	  print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end

  end
end

-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end


-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
