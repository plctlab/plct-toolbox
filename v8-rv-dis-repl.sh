#!/bin/bash

# Release Notes:
# v0.1 20200620 initial release
#
# maintainer: @lazyparser
# bug report url:
#     https://github.com/isrc-cas/PLCT-Toolbox/issues
# feedbacks are welcome!

tmp_id=b9c474f8981087776b8631ea6b99e01e
inputdata="hex.${tmp_id}.txt"
tmpfile1="dump1.${tmp_id}.bin"
tmpfile2="dump2.${tmp_id}.bin"
outfile="dis.${tmp_id}.txt"

process_one_bunk () {
	while read; do
		echo "$REPLY"
	done | xxd -r -p -g 4 > ${tmpfile1}
	# debug
	od -x ${tmpfile1}  > ${tmpfile1}.txt
	cat ${tmpfile1} | xxd -g 4 -e | xxd -r > ${tmpfile2}
	# debug
	od -x ${tmpfile2} > ${tmpfile2}.txt
	riscv64-unknown-elf-objdump -D -m riscv:rv64 -b binary ${tmpfile2} > ${outfile}
	cat ${outfile}
}


repl_loop () {
	pure_hex_data=""
	echo "Just paste v8 log or pure hex here:"
	echo ""
	echo "like"
	echo "0x2d1f27c0     0  fe01011b"
	echo "0x2d1f280c    4c  00000013           nop"
	echo ""
	echo "or just"
	echo "fe01011b"
	echo "00000013"
	echo -n "> "
	while true; do
		read l
		# a empty line triggers disassembler
		if [ x"$l" = x"" ]; then
			echo "$pure_hex_data" | process_one_bunk
			pure_hex_data=""
			echo -n "> "
		# simple way to check which type
		elif echo "$l" | grep -i -q '0x'; then
			one_hex=`echo "$l" | awk '{print $3}'`
		else
			one_hex="$l"
		fi
		pure_hex_data="${pure_hex_data}\n${one_hex}"
		# debug
		#echo -e DEBUG "$pure_hex_data" DEBUG
	done
}

repl_loop
