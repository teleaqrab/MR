local function run(msg, matches)
local text = io.popen("sh ./data/cmd.sh"):read('*all')
if is_sudo(msg) then
  return text
end
  end
return {
  patterns = {
    '^[!/]serverinfo$'
  },
  run = run,
  moderated = true
}

-- read @TELEBOOMBANG_TG

-- @SudO_1_ARMiN

-- @beni68