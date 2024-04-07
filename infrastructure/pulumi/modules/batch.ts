import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

export function createBatchResources(
  vpcSubnets: pulumi.Output<string>[],
  securityGroup: pulumi.Output<string>,
  awsIamRole: pulumi.Output<string>,
  imageName: string,
  imageTag: string,
  tags?: any
) {
  // Create the Batch Compute
  const computeEnvironment = new aws.batch.ComputeEnvironment("talos-admin", {
    computeEnvironmentName: "talos-admin",
    type: "MANAGED",
    computeResources: {
      type: "FARGATE",
      minVcpus: 0,
      maxVcpus: 4,
      subnets: vpcSubnets,
      securityGroupIds: [securityGroup],
    },
    serviceRole: awsIamRole,
    tags: tags, // Resource Tags
  });

  // Create the Batch Job Queue
  const jobQueue = new aws.batch.JobQueue("talos-admin", {
    state: "ENABLED",
    priority: 1,
    computeEnvironments: [computeEnvironment.arn],
  });

  // Create the Batch Job Definition
  const jobDefinition = new aws.batch.JobDefinition(
    "talos-admin",
    {
      type: "container",
      containerProperties: pulumi.jsonStringify({
        image: `${imageName}:${imageTag}`,
        resourceRequirements: [
          {
            type: "VCPU",
            value: "1",
          },
          {
            type: "MEMORY",
            value: "2048",
          },
        ],
        environment: [],
        command: [],
      }),
    },
    {
      dependsOn: [jobQueue],
    }
  );
}
