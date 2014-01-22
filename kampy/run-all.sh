#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${DIR}" || exit 1
IFS="
"

echo "Generating the following Python modules:"
kams=($(./run.sh | grep ".*\[java\] *	" | sed 's/.*\[java\] *	//g'))
for kam in ${kams[@]}; do
    mod=$(echo $kam | tr ' ' '_' | tr '-' '_' | tr '[[:upper:]]' '[[:lower:]]')
    mod+=".py"
    echo -e "\t$kam -> $mod"
done
echo "[ENTER] when ready, [CTRL-C] to cancel"
read

for kam in ${kams[@]}; do
    mod=$(echo $kam | tr ' ' '_' | tr '-' '_' | tr '[[:upper:]]' '[[:lower:]]')
    mod+=".py"
    echo "$kam -> $mod"
    ./run.sh "${kam}" "${mod}"
done

