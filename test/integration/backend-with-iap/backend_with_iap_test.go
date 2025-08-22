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

package backend_with_iap

import (
	"fmt"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"

	//test "github.com/terraform-google-modules/terraform-google-lb-http/test/integration"
)

func TestLbBackendServiceIap(t *testing.T) {
	backendServiceWithIAP := tft.NewTFBlueprintTest(t)

	backendServiceWithIAP.DefineVerify(func(assert *assert.Assertions) {
		
		projectID := backendServiceWithIAP.GetTFSetupStringOutput("project_id")
		serviceName := backendServiceWithIAP.GetStringOutput("service_name")
		
		backendServiceDescribeCmd := gcloud.Run(t, "compute backend-services describe", gcloud.WithCommonArgs([]string{serviceName, "--project", projectID, "--global", "--format", "json"}))
		
		//verify IAP is enabled in backend-services
		iapConfig := backendServiceDescribeCmd.Get("iap").Map()
		assert.Equal("true", iapConfig["enabled"].String(), fmt.Sprintf("IAP should be enabled"))
	})
	backendServiceWithIAP.Test()
}

