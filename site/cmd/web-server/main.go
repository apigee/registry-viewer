// Copyright 2020 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"regexp"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	service := os.Getenv("APG_REGISTRY_AUDIENCES")
	if service != "" {
		b, err := ioutil.ReadFile("public/index.html")
		if err != nil {
			panic(err)
		}
		r := regexp.MustCompile(`<meta name="registry-service" content=.*>`)
		index := r.ReplaceAll(b,
			[]byte(`<meta name="registry-service" content="`+service+`">`))
		ioutil.WriteFile("public/index.html", index, 0644)
	}

	fs := http.FileServer(http.Dir("public"))
	log.Fatal(http.ListenAndServe(":"+port, fs))
}
