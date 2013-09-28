# Trendminer clustering repo

## Description

Spectral clustering work done for D3.2.1 of the [Trendminer project] (http://www.trendminer-project.eu/). This builds hard clusters from co-occurrence counts of tweets. More information about the algorithm is available in the [deliverable] (http://www.trendminer-project.eu/)

## Installation

The code is available as a collection of python and Matlab scripts. You need to have both installed. The script that performs the entire sequence of operations is written in shell and tested under Ubuntu.

## Quick start

	./run file voc.threshold npmi.threshold k no.clusters

file - input file of tweets. One tweet in Json format per line.  This must be preprocessed using the [Trendminer Preprocessing pipeline] (https://github.com/sinjax/trendminer-java), needing tokenisation.
voc.threshold - vocabulary cut-off
npmi.threshold - NPMI cut-off
k - k of the mutual K nearest-neighbour graph for spectral clustering
no.clusters - number of clusters 

Example:
	
	./run.sh sep5 1 0.1 30 30

sep5 - sample tweets file processed for language and tokenized using the Trendminer pipeline. Fields are restricted to only text due for privacy. It largely consists of tweets written on 5 September 2013 in Austria and relating to politics.

## Scripts

#### dedup.py

Performs tweet deduplication. Uses a very aggressive method that removes all tweets that are detected as being retweets or that have the same first 5-6 word tokens.

	cat file | python dedup.py > file-dedup

#### wc-map.sh, wc-red.sh

Performs word count on all tokens in a tokenised tweet file. Written in Map-Reduce 2-step style.

	cat file | python wc-map.sh | sort | python wc-red.sh > wc.file

#### wc-filter.py

Filters the word count file by imposing a minimum count value.

	cat wc.file | python wc-filter.py threshold > wc.file.threshold

#### makevoc.py

	cat wc.file | python makevoc.py > dict.file

Gets as input a (word frequency) file and outputs a (id word) index.

#### wc-map-dict.sh

	cat file | python wc-map-dict.sh dict.file | sort | python wc-red.sh > wc.file

Performs word count on the tokens that exist in the vocabulary file. Written in MapReduce style.

#### pmi-map-ml.sh

        cat file | python pmi-mal-ml.sh dict.file | sort | python wc-red.sh > w
co.file

Performs word co-occurrence count on the tokens that exist in the vocabulary file. Written in MapReduce style. Output pairs are ordered alphabetically.

#### compute-npmi.py

	python compute-npmi.py wc.file wco.file > npmi.file

Computes the NPMI values of word pairs using the word occurrence and co-occurrence counts.

#### truncate.py

	cat npmi.file | python truncate.py threshold > npmi.file.threshold

Truncates a NPMI values file to a threshold.

#### sym.py

	cat npmi.file | python sym.py > npmi.file.symmetric

Makes an NPMI file symmetric.

#### spectral.m

	spectral(file,npmi.file,dict.file,k,no.clusters)

Performs spectral clustering using the tweet file, npmi file, dictionary.  K and no.clusters are parameters of the spectral clustering algorithm.

Outputs the Matlab variables in the file vars.file-no.clusters and another file cl.file-no.clusters. This file has the format (word clusterid centrality) for each word, one word/line.

For spectral clustering is currently using the code from the [AFFECT Matlab Toolbox] (http://tbayes.eecs.umich.edu/xukevin/affect). Their code is included in this project in the affect folder.


