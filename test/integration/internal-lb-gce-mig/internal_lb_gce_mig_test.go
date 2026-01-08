// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package internal_lb_gce_mig

import (
	"testing"

	"net/http"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
)

func TestInternalLbGCEMIG(t *testing.T) {
	bpt := tft.NewTFBlueprintTest(t)

	bpt.DefineVerify(func(assert *assert.Assertions) {
		bpt.DefaultVerify(assert)

		cloudRunURIs := bpt.GetStringOutputList("external_cloudrun_uris")

		assertHttp := utils.NewAssertHTTP()

		for _, uri := range cloudRunURIs {
			httpRequest, err := http.NewRequest("GET", uri, nil)
			if err != nil {
				t.Fatalf("Failed to create HTTP request for %s: %v", uri, err)
			}
			assertHttp.AssertResponse(t, httpRequest, http.StatusOK)
		}
	})

	bpt.Test()
}
