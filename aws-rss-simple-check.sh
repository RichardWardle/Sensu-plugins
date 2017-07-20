date=$(date +%a," "%d" "%b" "%Y)

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $# != 2 ]]; then
        echo "ERROR: Usage: $1 = service e.g elasticsearch $2 = zone e.g. us-east-1"
        echo "This would call http://status.aws.amazon.com/rss/elasticsearch-us-east-1.rss"
        echo "The RSS links can be found: http://status.aws.amazon.com/"
        exit 3
fi

service="$1"
zone="$2"
link="http://status.aws.amazon.com/rss/${service}-${zone}.rss"

curl -H "Content-Type: text/xml" -N -s -g $link | xmlstarlet sel -t -m "/rss/channel/item" -v "title" -o "|" -v "pubDate" -o "|" -v "description" -n 1> output.txt

if [[ $? != 0 ]]; then
        echo "I had a problem accessing: $link, please check internet connectivity, your paramters, your proxy and that packages curl and xmlstarlet are installed"
        exit 3
fi

grep "$date" output.txt > results.txt

if [[ $(wc -l results.txt | cut -f 1 -d ' ') == 0 ]]; then
        echo "OK: There are no reported problems for $service-$zone-sz on $date, The last reported issue or update was:"
        echo ""
        tail -n 1 output.txt | awk -F "|" '{printf "    Date Post: " $2 "\n    Issue Title: " $1 "\n    Description: " $3 "\n"}'
        rm results.txt output.txt
        exit 0
fi

echo "WARNING: There are the reported issues for $service-$zone-sz on $date on RSS feed: $link"
echo ""
tac results.txt | while read LINE; do
        awk -F "|" '{printf "Date Post: " $2 "\nIssue Title: " $1 "\nDescription: " $3 "\n\n"}'
done

rm results.txt output.txt
exit 1
