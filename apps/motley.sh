#!/bin/sh

apg registry delete-project --name projects/motley

dart import-common-protos/bin/import-common-protos.dart 
dart import-googleapis/bin/import-googleapis.dart 
dart compute-summary/bin/compute-summary.dart 
dart label-apis/bin/label-apis.dart 
registry compute references projects/motley/apis/-/versions/-/specs/-
registry compute complexity projects/motley/apis/-/versions/-/specs/-
registry compute index projects/motley/apis/-/versions/-/specs/-
registry compute vocabulary projects/motley/apis/-/versions/-/specs/-
registry compute lint projects/motley/apis/-/versions/-/specs/-
registry compute lintstats projects/motley/apis/-/versions/-/specs/- --linter=aip

