import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

export function createEcsResources(
  vpcSubnets: pulumi.Output<string>[],
  securityGroup: pulumi.Output<string>,
  awsIamRole: pulumi.Output<string>,
  imageName: string,
  imageTag: string,
  tags?: any
) {
  // Create the ECS Cluster using Fargate
  const cluster = new aws.ecs.Cluster("cluster-maintenance", {
    settings: [
      {
        name: "containerInsights",
        value: "enabled",
      },
    ],
  });

  const task = new aws.ecs.TaskDefinition(
    "talos-bootstrap",
    {
      family: "talos-bootstrap",
      cpu: "512",
      memory: "1024",
      networkMode: "awsvpc",
      requiresCompatibilities: ["FARGATE"],
      runtimePlatform: {
        cpuArchitecture: "X86_64",
        operatingSystemFamily: "LINUX",
      },
      // Define the runtime container
      containerDefinitions: JSON.stringify([
        {
          name: "bootstrap",
          image: `${imageName}:${imageTag}`,
          cpu: 512,
          memory: 1024,
          essential: true,
        },
      ]),

      tags: tags, // Resource Tags
    },
    {
      dependsOn: [cluster],
    }
  );

  // Create the ECS Task Definition for bootstrapping Talos Linux
  const service = new aws.ecs.Service(
    "talos-bootstrap",
    {
      cluster: cluster.arn,
      launchType: "FARGATE",
      taskDefinition: "talos-bootstrap",
      desiredCount: 1,
      iamRole: awsIamRole,
      enableExecuteCommand: true,
      networkConfiguration: {
        subnets: vpcSubnets,
        securityGroups: [securityGroup],
      },
      tags: tags, // Resource Tags
    },
    {
      dependsOn: [task],
    }
  );
}
