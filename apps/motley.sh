#!/bin/sh

apg registry delete-project \
	--name projects/motley

apg registry create-project \
	--project_id motley \
	--project.display_name "Motley APIs" \
	--project.description "API descriptions from a variety of sources"

reg import common-protos --project projects/motley --path ~/Desktop/api-common-protos
reg import googleapis --project projects/motley --path ~/Desktop/googleapis
reg compute summary --project projects/motley
reg label apis --project projects/motley

registry compute references projects/motley/apis/-/versions/-/specs/-
registry compute complexity projects/motley/apis/-/versions/-/specs/-
registry compute index projects/motley/apis/-/versions/-/specs/-
registry compute vocabulary projects/motley/apis/-/versions/-/specs/-
registry compute lint projects/motley/apis/-/versions/-/specs/-
registry compute lintstats projects/motley/apis/-/versions/-/specs/- --linter=aip

