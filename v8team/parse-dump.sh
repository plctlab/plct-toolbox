#!/bin/bash

# Release Notes:
# v0.1 20200620 initial release
#
# maintainer: @lazyparser
# bug report url:
#     https://github.com/isrc-cas/PLCT-Toolbox/issues
# feedbacks are welcome!

tmp_id=b9c474f8981087
inputdata="hex.${tmp_id}.txt"
tmpfile1="dump1.${tmp_id}.bin"
tmpfile2="dump2.${tmp_id}.bin"
outfile="dis.${tmp_id}.txt"

die () {
	echo "$*"
	exit 9
}

process_one_bunk () {
	while read; do
                echo "$REPLY"
        done | xxd -r -p -g 4 > ${tmpfile1}
	# debug
	od -x ${tmpfile1}  > ${tmpfile1}.txt
	cat ${tmpfile1} | xxd -g 4 -e | xxd -r > ${tmpfile2}
	# debug
	od -x ${tmpfile2} > ${tmpfile2}.txt
	# FIXME: remove headers of outputs
	riscv64-unknown-elf-objdump -D -m riscv:rv64 -b binary ${tmpfile2} | tail -n +8 > ${outfile}
	#cat ${outfile}
}


process_code_dump () {
	pure_hex_data=""
	raw_hex_lines=""
	while read l; do
		if echo "$l" | grep -i -q '^0x'; then
			one_hex=`echo "$l" | awk '{print $3}'`
			pure_hex_data="$one_hex"
			raw_hex_lines="$l"
			while true; do
				read xl
				# a empty line triggers disassembler
				if [ x"$xl" = x"" ]; then
					echo "$pure_hex_data" | process_one_bunk
					echo -e "$raw_hex_lines"  > "${inputdata}"
					paste "$inputdata" "${outfile}"
					pure_hex_data=""
					raw_hex_lines=""
					break
				else
					echo "$xl" | grep -i -q '^0x' || die "ERROR: expect hex but got [$xl]"
					xl=`echo "$xl" | sed 's, *nop,,'`
					one_hex=`echo "$xl" | awk '{print $3}'`
					pure_hex_data="${pure_hex_data}\n${one_hex}"
					raw_hex_lines="${raw_hex_lines}\n${xl}"

				fi
			done

		else
			echo $l
		fi
	done
}

process_code_dump
