function run(msg, matches)
if not is_sudo(msg) then
return 
end
text = io.popen("sudo apt-get install "..matches[1]):read('*all')
  return "🔐packages succesfuly instaled"..text
end
return {
  patterns = {
    '^[#/!]install (.*)$'
  },
  run = run,
  moderated = true
}


-- read @TELEBOOMBANG_TG

-- @SudO_1_ARMiN

-- @beni68