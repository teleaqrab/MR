do
 function run(msg, matches)
 local reply_id = msg['id']
 local text = 'nerkh'
 local text1 ="✅ربات E•N•S✅\n==========================\n👥نرخ سوپر گروه👥\n\n👥گروه یک ماهه👥\n💶 2000 تومان 💶\n👥گروه سه ماهه👥\n💶 3000 تومان 💶\n👥گروه مادامالعمر👥\n💶 5000 تومان 💶\n==========================\n👥نرخ گروه معمولی👥\n\n👥گروه یک ماهه👥\n💶 1000 تومان 💶\n👥گروه سه ماهه👥\n💶 2000 تومان 💶\n👥گروه مادامالعمر👥\n💶 3000 تومان 💶\n==========================\n👌قيمت ها بسيار پايين و مناسب هستند 👌"
   reply_msg(reply_id, text1, ok_cb, false)
 end
 return {
  description = "!nerkh",
  usage = " !nerkh",
  patterns = {
    "^[#/!][Pp]rice$",
	"^[Pp]rice$"
  },
  run = run
}
end


-- read @TELEBOOMBANG_TG

-- @SudO_1_ARMiN

-- @beni68