#!/usr/bin/env bash

fly -t tf set-pipeline -p tf-examples-lb-http-basic -c tests/pipelines/tf-examples-lb-http-basic.yaml -l tests/pipelines/values.yaml
fly -t tf set-pipeline -p tf-examples-lb-http-nat-gw -c tests/pipelines/tf-examples-lb-http-nat-gw.yaml -l tests/pipelines/values.yaml
fly -t tf set-pipeline -p tf-examples-lb-https-content -c tests/pipelines/tf-examples-lb-https-content.yaml -l tests/pipelines/values.yaml
fly -t tf set-pipeline -p tf-examples-lb-https-gke -c tests/pipelines/tf-examples-lb-https-gke.yaml -l tests/pipelines/values.yaml
fly -t tf set-pipeline -p tf-examples-lb-https-multi-cert -c tests/pipelines/tf-examples-lb-https-multi-cert.yaml -l tests/pipelines/values.yaml
fly -t tf set-pipeline -p tf-lb-http-pull-requests -c tests/pipelines/tf-lb-http-pull-requests.yaml -l tests/pipelines/values.yaml
fly -t tf set-pipeline -p tf-lb-http-regression -c tests/pipelines/tf-lb-http-regression.yaml -l tests/pipelines/values.yaml

fly -t tf expose-pipeline -p tf-examples-lb-http-basic
fly -t tf expose-pipeline -p tf-examples-lb-http-nat-gw
fly -t tf expose-pipeline -p tf-examples-lb-https-content
fly -t tf expose-pipeline -p tf-examples-lb-https-gke
fly -t tf expose-pipeline -p tf-examples-lb-https-multi-cert
fly -t tf expose-pipeline -p tf-lb-http-pull-requests
fly -t tf expose-pipeline -p tf-lb-http-regression