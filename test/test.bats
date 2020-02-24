#!/usr/bin/env bats

source power-assert.bash

##################################################
# Setup & Teardown
##################################################

setup() {
  rm -rf tmp
  mkdir tmp
}


##################################################
# Shared
##################################################

base_apply() {
  cp conf.tf tmp
  cd tmp

  terraform init
  terraform apply -auto-approve
}

get_automv_line_count() {
  similarity_threshold=${1:-1.0}
  terraform plan -out=./plan-result > /dev/null 2>&1
  terraform show -json plan-result > plan-result.json 2> /dev/null
  ../../automv plan-result.json $similarity_threshold | wc -l
}


##################################################
# Test
##################################################

@test "terraform works correctly" {
  base_apply
}

@test "no output when no changes" {
  base_apply

  result_line_count=$(get_automv_line_count)
  [[[ $result_line_count -eq 0 ]]]
}

@test "1 line output when resource name changes" {
  base_apply

  cp ../name_change.tf conf.tf

  result_line_count=$(get_automv_line_count)
  [[[ $result_line_count -eq 1 ]]]
}

@test "no output when content and name change" {
  base_apply

  cp ../name_content_change.tf conf.tf

  result_line_count=$(get_automv_line_count)
  [[[ $result_line_count -eq 0 ]]]
}

@test "no output when content and name change and similarity threshold is 0.9" {
  base_apply

  cp ../name_content_change.tf conf.tf

  result_line_count=$(get_automv_line_count 0.9)
  [[[ $result_line_count -eq 0 ]]]
}

@test "1 line output when content and name change and similarity threshold is 0.7" {
  base_apply

  cp ../name_content_change.tf conf.tf

  result_line_count=$(get_automv_line_count 0.7)
  [[[ $result_line_count -eq 1 ]]]
}
