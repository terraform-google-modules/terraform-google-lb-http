// Copyright 2025 Google LLC
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

package backend_with_psc_negs

import (
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
)

func TestLbBackendServiceWithPscNeg(t *testing.T) {
	backendServiceWithPscNegs := tft.NewTFBlueprintTest(t)

	backendServiceWithPscNegs.DefineVerify(func(assert *assert.Assertions) {
		projectID := backendServiceWithPscNegs.GetTFSetupStringOutput("project_id")
		pscNegURIs := backendServiceWithPscNegs.GetStringOutputList("psc_negs")

		serviceName := "backend-with-psc-negs"

		backendServiceDescribeCmd := gcloud.Run(t, "compute backend-services describe", gcloud.WithCommonArgs([]string{serviceName, "--project", projectID, "--global", "--format", "json"}))

		backends := backendServiceDescribeCmd.Get("backends").Array()
		assert.Len(backends, 1, "should have 1 PSC NEG backends attached")
		assert.Len(pscNegURIs, 1, "should return 1 PSC NEG as output")
	})
	backendServiceWithPscNegs.Test()
}

