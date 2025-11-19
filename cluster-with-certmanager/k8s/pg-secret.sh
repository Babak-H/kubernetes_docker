#!/bin/sh

kubectl create secret generic pgpassword --from-literal PGPASSWORD=123asdf
