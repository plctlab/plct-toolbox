import os,sys
import re
import pexpect



def SudoCmd(cmd):
	p=pexpect.spawn(cmd)
	p.expect("password for .*:")
	#put your password here
	p.sendline("XXXX")
	return p
	
def ddImage(tfId,image):
	print("Now dd image into "+tf+"...")
	cmd="bzcat "+image+" | sudo dd of=/dev/"+tf+" bs=1M iflag=fullblock oflag=direct conv=fsync status=progress"
	result=os.popen(cmd).read()
	print(result)
	
	
	print("--resize "+tf+"...")
	cmd="sudo fdisk /dev/"+tf
	result=SudoCmd(cmd)
	print("----del the 4 partition")
	result.expect("Command.*:")
	result.sendline("d")
	result.expect("Partition number.*:")
	result.sendline("4")
	
	print("----new the 4 partition")
	result.expect("Command.*:")
	result.sendline("n")
	result.expect("Partition number.*:")
	result.sendline("4")
	
	print("----set size")
	result.expect("First sector.*:")
	result.sendline("100832")
	result.expect("Last sector.*: ")
	result.sendline("")
	result.expect("Do you want to remove the signature.*:")
	result.sendline("n")
	print("----write")
	result.expect("Command.*:")
	result.sendline("w")
	
	print("--sudo resize")
	cmd="sudo resize2fs /dev/"+tf+"4"
	p=SudoCmd(cmd)
	p.expect(pexpect.EOF)
	result=p.before.decode()

	if "No such file or directory" in result:
		print("--!!!need plugout/plugin tf manually, then run 'sudo resize2fs /dev/"+tf+"4'")
	
if __name__=="__main__":
	image=sys.argv[1]

	cmd="sudo fdisk -l"
	p=SudoCmd(cmd)
	p.expect(pexpect.EOF)
	fdisk=p.before.decode()
	print (fdisk)

	tfList=re.findall("Disk /dev/(sd[^a])",fdisk)
	print("find tfs in system")
	print (tfList)

	if len(tfList)==0:
		raise Exception("there is no TF connected to system")

	for tf in tfList:
		ddImage(tf,image)

