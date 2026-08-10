--generate translations for each palette index

for i = 0, 255 do
	print(("Menu_Translation_%d = \"0:0=%d:%d\""):format(i, i, i))
end