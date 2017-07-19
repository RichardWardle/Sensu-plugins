
#!/bin/sh

date=$(date +%d" "%b" "%Y)
#date="5 Sep 2016"
echo $date

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $# != 2 ]]; then
        echo "ERROR: Usage: $1 = service e.g elasticsearch $2 = zone e.g. us-east-1"
        echo "This would call http://status.aws.amazon.com/rss/elasticsearch-us-east-1.rss"
        echo "The RSS links can be found: http://status.aws.amazon.com/"
        exit 3
fi

service="$1"
zone="$2"


curl -H "Content-Type: text/xml" -N -s -g http://status.aws.amazon.com/rss/${service}-${zone}.rss | xmlstarlet sel -t -m "/rss/channel/item" -v "title" -o "|" -v "pubDate" -o "|" -v "description" -n > output.txt

if [[ $? != 0 ]]; then
        echo "Error code: $?"
        echo "I had a problem curling, please check internet connectivity, your paramters and any other connectivity issues"
        exit 3
fi

grep "$date" output.txt > results.txt

 echo $(wc -l results.txt)

if [[ $(wc -l results.txt) > 1 ]]; then
        echo "OK: There are no reported problems for $service-$zone-sz on $date"
        rm results.txt output.txt
        exit 0
fi

echo "WARNING: There are the reported updates for $service-$zone-sz on $date"
echo ""
tac results.txt | while read LINE; do
        awk -F "|" '{printf "Issue: " $1 "\nDate Posted: " $2 "\nDescription: " $3 "\n\n"}'
done

#rm results.txt output.txt
exit 1
