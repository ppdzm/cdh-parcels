#!/bin/bash

PRESTO_DIRNAME=${PARCEL_DIRNAME:-"${project.build.finalName}"}
export CDH_PRESTO_HOME=${PARCELS_ROOT}/${PRESTO_DIRNAME}
export CDH_PRESTO_JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera
