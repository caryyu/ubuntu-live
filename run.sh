#!/bin/bash

apt-get update && apt-get -y install ssh && initctl start ssh
