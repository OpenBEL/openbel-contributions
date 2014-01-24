#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${DIR}" || exit 1
IFS="
"

echo "Generating the following GraphML files:"
kams=($(./run.sh | grep ".*\[java\] *	" | sed 's/.*\[java\] *	//g'))
for kam in ${kams[@]}; do
    xml=$(echo $kam | tr ' ' '_' | tr '-' '_' | tr '[[:upper:]]' '[[:lower:]]')
    xml+=".xml"
    echo -e "\t$kam -> $xml"
done
echo "[ENTER] when ready, [CTRL-C] to cancel"
read

for kam in ${kams[@]}; do
    xml=$(echo $kam | tr ' ' '_' | tr '-' '_' | tr '[[:upper:]]' '[[:lower:]]')
    xml+=".xml"
    echo "$kam -> $xml"
    ./run.sh "${kam}" "${xml}"
done

