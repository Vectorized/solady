import subprocess

for i in range(254,258):
	s = '00' * i
	command = 'cast to-rlp "[\\"0x' + s + '\\"]"'
	print(i)
	print(command)
	result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
	print(result.stdout)