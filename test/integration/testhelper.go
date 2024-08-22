// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package test

import (
	"io"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
)

func AssertResponseStatus(t *testing.T, assert *assert.Assertions, url string, statusCode int) {
	var resStatusCode int
	resStatusCode, _, _ = httpGetRequest(t, url)
	assert.Equal(statusCode, resStatusCode)
}

func httpGetRequest(t *testing.T, url string) (statusCode int, body string, err error) {
	t.Helper()
	res, err := http.Get(url)
	if err != nil {
		t.Fatalf("http get unexpected err: %v", err)
	}
	defer res.Body.Close()

	buffer, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatalf("reading response body unexpected err: %v", err)
	}
	return res.StatusCode, string(buffer), err
}
