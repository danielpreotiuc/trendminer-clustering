# Example: ./run.sh sep5 de 1 0.1 30 30

# Parameters to script:
# $1 - input file 
# $2 - language (de - german, en - english)
# $3 - vocabulary threshold (depends on the size of input)
# $4 - pmi threshold (rec.value 0.3)
# $5 - k in knn for spectral clustering (rec.value 30)
# $6 - no clusters

echo 'Step 1: Processing data - tokenization, language detection and filtering'
java -jar ~/TrendminerTool-uber.jar -i $1 -o $1-tok-lid-$2 -m TOKENISE -m LANG_ID -pof LANG --accept-language $2 -ot TWITTER 
echo 'Step 2: Deduplication of tweets'
cat $1-tok-lid-$2 | python bloom-dedup-tok.py > $1-tok-lid-$2-dedup
echo 'Step 3: Computing word counts'
cat $1-tok-lid-$2-dedup | python wc-map.sh | sort | python wc-red.sh > wc.$1-tok-lid-$2-dedup
echo 'Step 4: Creating dictionary'
cat wc.$1-tok-lid-$2-dedup | python wc-filter.py $3 | python makevoc.py > dict.$1
echo 'Step 5: Computing dictionary unigram counts'
cat $1-tok-lid-$2-dedup | python wc-map-dict.sh dict.$1 | sort | python wc-red.sh > wc.$1-tok-lid-$2-dedup
echo 'Step 6: Computing dictionary co-occurence counts'
cat $1-tok-lid-$2-dedup | python pmi-map-ml.sh dict.$1 | sort | python wc-red.sh > wco.$1-tok-lid-$2-dedup
echo 'Step 7: Computing NPMI scores'
python compute-npmi.py wc.$1-tok-lid-$2-dedup wco.$1-tok-lid-$2-dedup > npmi.$1-tok-lid-$2-dedup
echo 'Step 8: Truncating and making NPMI symmetric'
cat npmi.$1-tok-lid-$2-dedup | python truncate.py $4 | python sym.py > npmi.$1-tok-lid-$2-dedup-sym-$4
echo 'Step 9: Performing the actual clustering'
matlab -nojvm -nodesktop -nosplash -nodisplay -r "spectral('$1','npmi.$1-tok-lid-$2-dedup-sym-$4','dict.$1',$5,$6); quit;"
echo "Finished, clustering results are in cl.$1-$6"
