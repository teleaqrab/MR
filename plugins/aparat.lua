local function run(msg, matches)
 if matches[1]:lower() == 'aparat' then
  local url = http.request('http://www.aparat.com/etc/api/videoBySearch/text/'..URL.escape(matches[2]))
  local jdat = json:decode(url)

  local items = jdat.videobysearch
  text = '🎥Search results in Aparat: \n'
  for i = 1, #items do
  text = text..'\n'..i..'- '..items[i].title..'  -  🎫Seen: '..items[i].visit_cnt..'\n    🎬Link: aparat.com/v/'..items[i].uid
  end
  text = text..'\n\n🎮Powered by @ENS_Tg'
  return text
 end
end

return {
   patterns = {
"^[#/!](aparat) (.*)$",
   },
   run = run
}


فرشاد درجریانی ک @SudO_1_ARMiN ننتو گاییده😂😂😂😂