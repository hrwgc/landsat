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
    wrsPath=$2;
    wrsRow=$3;
    sceneEntry="$4";
    mkdir -p $workDir/scenes/${wrsPath}/${wrsRow};

    [ -f "$workDir/scenes/${wrsPath}/${wrsRow}/${sceneId}.html" ] || {
        html=$(cat $workDir/fixtures/scene-template.html);
        html=$(echo "$html" | sed "s/{{sceneId}}/$sceneId/g");
        html=$(echo "$html" | sed "s~{{data}}~$sceneEntry~1");
        echo $html | \
          tidy -qim > $workDir/scenes/${wrsPath}/${wrsRow}/${sceneId}.html;
    }
}


function onEachItem() {
    sceneId=$(cut -d, -f1 <<< $1);
    sensor=$(cut -c1-3 <<< $sceneId);
    wrsPath=$(cut -c4-6 <<< $sceneId);
    wrsRow=$(cut -c7-9 <<< $sceneId);
    metadata_url="$url_base/${url_stem}/$sceneId"
    sceneHtml="<tr><td><a href=\"/landsat/scenes/$wrsPath/$wrsRow/$sceneId.html\">$sceneId</a></td><td>View on <a href=\"$metadata_url\">USGS</a>.</td></tr>"
    echo "$sceneHtml" >> $workDir/tmp/$dateId;
    makeScenePage $sceneId $wrsPath $wrsRow "$sceneHtml" || return
};

function makeIndexPage() {
    cat $workDir/fixtures/index-template.html > $workDir/tmp/index.html;
    cat $workDir/tmp/$dateId >> $workDir/tmp/index.html;
    echo "</tbody></table></body></html>" >> $workDir/tmp/index.html;
    cat $workDir/tmp/index.html | tidy -qim  > $workDir/index.html;
}

export -f onEachItem;
export -f makeScenePage;
tail -n+2 "$csv" | head -n1000 | xargs -L1 -n100 | parallel  -d ' ' onEachItem "{}"
makeIndexPage;
rm -rf $workDir/tmp/*;
set +a;
