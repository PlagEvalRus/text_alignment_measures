#!/usr/bin/env bash

run_eval_for_task(){
    local task_dir="$1"
    local title="$2"

    if [ ! -e "$task_dir" ]; then
        echo "No such directory $task_dir!!"
        return
    fi

    local local_results_dir="$results_dir"/"$task_dir"
    mkdir -p "$local_results_dir"

    # 00001.txt 2494271.txt -> 004-1320906.xml
    cat "$task_dir"/pairs | \
        sed 's/.txt//g' | \
        sed 's/ /-/' | \
        sed 's/\r//' | \
        sed 's/$/.xml/' | \
        xargs -I{} cp "$results_dir"/{} "$local_results_dir"/

    echo "============$title MACRO============"
    local macro_out="$(python ./text_alignment_measures.py -p "$task_dir" -d "$local_results_dir")"
    echo "$macro_out"

    echo "============$title MICRO============"
    local micro_out="$(python ./text_alignment_measures.py -p "$task_dir" -d "$local_results_dir" --micro)"
    echo "$micro_out"

    make_csv_row "$run_name" "$title" "$macro_out" "$micro_out"

    rm -r "$local_results_dir"
}

# Plagdet Score 0.375781297067
# Recall 0.2570745778
# Precision 0.745795503916
# Granularity 1.0243902439
parse_granularity(){
   local output="$1"
   gran="$(echo "$output" | grep -Po '(?<=Granularity ).*')"
   echo "$gran"
}

parse_plagdet(){
    local output="$1"
    plagdet="$(echo "$output" | grep -Po '(?<=Plagdet Score ).*')"
    echo "$plagdet"
}

parse_recall(){
    local output="$1"
    recall="$(echo "$output" | grep -Po '(?<=Recall ).*')"
    echo "$recall"
}

parse_precision(){
    local output="$1"
    precision="$(echo "$output" | grep -Po '(?<=Precision ).*')"
    echo "$precision"
}

round_val(){
    local val="$1"
    echo $(LC_ALL=C /usr/bin/printf '%.*f\n' $round_precision $val)
}

make_csv_header(){
    if [ ! -e "$output_file" ]; then
        echo "run,type,granularity,macro_precision,macro_recall,macro_plagdet,micro_precision,micro_recall,micro_plagdet" >> "$output_file"
    fi
}

make_csv_row(){
    local run="$1"
    local type="$2"
    local macro_output="$3"
    local micro_output="$4"

    gran=$(parse_granularity "$macro_output")
    gran=$(round_val $gran)

    row="\"$run\",\"$type\",$gran,$(make_row_from_std_metrics "$macro_output")"
    row="$row,$(make_row_from_std_metrics "$micro_output")"

    echo "$row" >> "$output_file"
}

make_row_from_std_metrics(){
    local output="$1"
    local prec=$(round_val $(parse_precision "$output"))
    local rec=$(round_val $(parse_recall "$output"))
    local plagdet=$(round_val $(parse_plagdet "$output"))
    echo "$prec,$rec,$plagdet"
}

parse_run_name(){

    local run_name="$(basename $results_dir)"
    if [ "$run_name" == "output" ];then
        run_name="$(basename $(dirname $results_dir))"
    else
        run_name="$results_dir"
    fi
    echo "$run_name"


}
# set -e
# set -xv

results_dir="results"
tasks_dir="."
round_precision=3
output_file="result.csv"
while [ $# -gt 0 ] ; do
    case "$1" in
        -r) results_dir="$2"                 ; shift 2 ;;
        -t) tasks_dir="$2"                   ; shift 2 ;;
        -p) round_precision="$2"             ; shift 2 ;;
        -o) output_file="$2"                 ; shift 2 ;;
        *)            shift 1 ;;
    esac
done

run_name="$(parse_run_name)"

make_csv_header

echo "============TOTAL MACRO============"
macro_out="$(python ./text_alignment_measures.py -p "$tasks_dir" -d "$results_dir")"
echo "$macro_out"

echo "============TOTAL MICRO============"
micro_out="$(python ./text_alignment_measures.py -p "$tasks_dir" -d "$results_dir" --micro)"
echo "$micro_out"

make_csv_row "$run_name" "total" "$macro_out" "$micro_out"


run_eval_for_task "$tasks_dir/01-generated-copypaste" "Generated copypast"
run_eval_for_task "$tasks_dir/02-generated-paraphrased" "Generated paraphrase"

run_eval_for_task "$tasks_dir/03-manually-paraphrased" "Manually paraphrased"
run_eval_for_task "$tasks_dir/04-manually-paraphrased-light" "Manually paraphrased light"
