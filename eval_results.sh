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
        sed 's/$/.xml/' | \
        xargs -I{} cp "$results_dir"/{} "$local_results_dir"/

    echo "============$title MICRO============"
    python ./text_alignment_measures.py -p "$task_dir" -d "$local_results_dir" --micro

    echo "============$title MACRO============"
    python ./text_alignment_measures.py -p "$task_dir" -d "$local_results_dir"

    rm -r "$local_results_dir"
}

# set -e
# set -xv

results_dir="$1"
if [ -z "$results_dir" ]; then
    results_dir="results"
fi


echo "============TOTAL MICRO============"
python ./text_alignment_measures.py -p tasks -d "$results_dir" --micro

echo "============TOTAL MACRO============"
python ./text_alignment_measures.py -p tasks -d "$results_dir"

run_eval_for_task "tasks/generated_copypast_meta" "Generated copypast"
run_eval_for_task "tasks/generated_paraphrased_meta" "Generated paraphrase"

run_eval_for_task "tasks/manually-paraphrased" "Manually paraphrased"
run_eval_for_task "tasks/manually_paraphrased2" "Manually paraphrased 2"
