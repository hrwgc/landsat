#!/bin/bash
set -a;
csv=$1;
# expected arg is downloaded csv from usgs
# http://landsat.usgs.gov/metadata_service/bulk_metadata_files/LANDSAT_8.csv.gz
url_base="http://earthexplorer.usgs.gov/metadata"
# declare -a url_stem;
# url_stem[LC8]=4923;
# export url_stem;
## temp workaround, since we're only looking at l8 images
# todo: l7, etc have different numbers here.
url_stem=4923
workDir=$(dirname "$0");
mkdir -p $workDir/tmp;
dateId=$(date +%s);

sceneHtml="<tr><td>{{data}}</td></tr>"

function makeScenePage() {
    sceneId=$1;
    sceneEntry="$2";
    [ -f "scenes/${sceneId}.html" ] || {
        html=$(cat $workDir/fixtures/scene-template.html);
        html=$(echo "$html" | sed "s/{{sceneId}}/$sceneId/g");
        html=$(echo "$html" | sed "s~{{data}}~$sceneEntry~1");
        echo $html | tidy -qim > $workDir/scenes/${sceneId}.html;
    }
}


function onEachItem() {
    sceneId=$(cut -d, -f1 <<< $1);
    sensor=$(cut -c1-3 <<< $sceneId)
    metadata_url="$url_base/${url_stem}/$sceneId"
    sceneHtml="<tr><td><a href=\"/landsat/scenes/$sceneId.html\">$sceneId</a></td><td>View on <a href=\"$metadata_url\">USGS</a>.</td></tr>"
    echo "$sceneHtml" >> $workDir/tmp/$dateId;
    makeScenePage $sceneId "$sceneHtml" || return
};

function makeIndexPage() {
    data=$(cat $workDir/tmp/$dateId | tr -d '\n');
    cat $workDir/fixtures/index-template.html | \
      sed "s~{{data}}~${data}~g" | tidy -qim  > $workDir/index.html;
}

export -f onEachItem;
export -f makeScenePage;
parallel onEachItem "{}" ::: `tail -n+2 "$csv" | head -n10`
makeIndexPage;
rm -rf $workDir/tmp;
set +a;
