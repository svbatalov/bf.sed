echo -n 's/$/'
for i in `seq 0 127`;
do
	printf '\d%.3s' $i
done

echo -n '/'
