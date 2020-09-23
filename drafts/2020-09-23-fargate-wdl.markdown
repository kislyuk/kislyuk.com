---
layout: single
title:  "Cromulent: WDL workflows with miniwdl and AWS Fargate"
date:   2020-09-23 21:19:35 -0700
categories: engineering
---

> *Cromulent: a workflow management toolkit that's perfectly adequate and not quite as daunting to set up as [Cromwell](https://cromwell.readthedocs.io/)*

In this post, I'm going to go over some of the technologies that power my day-to-day work as a bioinformatician, as well
as exciting developments that enable these technologies to serve bioinformaticians better going forward.

# Background
Bioinformatics workflows (often referred to as pipelines) typically process data using a series of Linux executables,
feeding the output of each one to the next. Each of the executables is a bioinformatics software package responsible for
(often very sophisticated and idiosyncratic) data processing steps such as filtering input DNA (cleaning data), aligning
DNA to a reference genome database, calling variants (identifying unique features in individual genomes), clustering
and normalizing DNA reads for quantitative DNA analysis assays, annotating genetic features, de novo genome assembly, etc.

At their basic level, bioinformatics workflows (just like many other scientific and business workflows) can be expressed
as shell scripts. A long time ago, scientists would submit these scripts to a batch job scheduler like
PBS, SGE, Condor or LSF. The scheduler would dispatch the script to run on a computer that was part of a cluster and
connected to a shared NFS filesystem. Today, these same scripts can be run on cloud APIs like
[AWS Batch](https://aws.amazon.com/batch/), which enable several key improvements:

- They use Docker containers, which empower developers to use whatever software they need, and play a key role in
  enabling reproducibility (a big deal in science).

- They provide on-demand compute capacity, which allows you to burst scale your "cluster" to very large numbers of VMs
  without paying for running them all the time (scientists tend to run workloads in very lumpy ways - the load on your
  system will often go from zero to many thousands of CPUs as experiments are prepared, run, analyzed and re-analyzed).

- They allow easy access to the resulting data (for example, by uploading it to S3, where any authorized web application
  can access it).

Shell scripts are great, but it's not clear how they can be used as units of reproducible/composable scientific
computing. The community has come up with a
[bewildering array](https://github.com/common-workflow-language/common-workflow-language/wiki/Existing-Workflow-systems)
of workflow description languages, which by and large attempt to address the key needs for describing workflow inputs
and outputs and establishing the runtime contract between the workflows and their execution environment. Given the
number of "mostly dead" projects on the list linked above, it is clear that the problem of workflow description and
management is very non-trivial and requires careful attention to software interfaces, abstractions, and community
engagement for any tool or project that hopes to succeed in this space.

[Subjectively](https://www.nature.com/articles/s41592-020-0886-9), the workflow description and management projects
with the most traction in the community are [Snakemake](https://snakemake.readthedocs.io/en/stable/),
[Nextflow](https://www.nextflow.io/), [CWL](https://www.commonwl.org/) and [WDL](https://openwdl.org/). Each of these 
projects boasts a vibrant user community, a reach feature set, and a sustained development history. In my day-to-day work
I have ended up using WDL extensively. This is in large part due to the excellent work of my colleague
[Mike Lin](https://www.mlin.net/). Thanks to Mike, WDL is the only workflow language with multiple production runtime
implementations, and one of very few with a formal, tested language specification. The next ingredient for success is a
deep focus on developer tooling provided by the [miniwdl](https://github.com/chanzuckerberg/miniwdl) project.

Miniwdl is a WDL interpreter and runtime (workflow runner). Like all foundational software, miniwdl started with a deep,
informed focus on developer productivity: it emphasizes speed of execution, usable interfaces and abstractions, and
good error messages that support the developer when something goes wrong. In fact, miniwdl started as a linter, which
reflects this focus on developer experience.

By itself, miniwdl is great at running workflows on a single computer, but it does not yet integrate well with
cloud-based systems like the AWS Batch API that I mentioned earlier. And this is where I finish setting the stage and
dive into the novel part of this blog post: a miniwdl plugin providing an execution backend to run WDL workflows on AWS
Fargate containers.

# Wiring up correctly
Great software is defined by its interfaces. The interfaces embody the commitment to the user (or developer). Stable,
well-specified, well-documented interfaces at well-chosen abstraction boundaries enable software to evolve and grow over
time. In the context of workflows, a workflow engine can easily fall into the trap of tying itself too closely to a
particular execution environment infrastructure (or conversely, under-specifying its execution environment contract). So
wherever reasonable, miniwdl provides a plugin interface to maintain and provide future flexibility as to which cloud
API the workflow tasks can run on, or what kinds of URLs can be given to the workflow as inputs.

I used the miniwdl task container backend plugin API to run WDL workflows on AWS Fargate. Why Fargate? Because of its
advantage in latency, or dispatch time. When developing workflows locally, miniwdl uses the Docker daemon on the local
computer to orchestrate tasks - one Docker container per task. This is excellent for local debugging - tasks start as
quickly as Docker can run them, within seconds. But if you want to run your workflow in a production-representative
environment, you're going to be dispatching it to a cloud container management API like Kubernetes or AWS Batch. And
in those APIs, it can take a long time - minutes - to provision a VM for your workflow. That will kill your development
velocity - and it will also pile up burst scaling latency and job dispatch overhead in production. With Fargate,
containers take about 10 seconds to start (not perfect, but still much faster than cold-starting containers with other
cloud APIs).

Another aspect of this work is to make these tools accessible to anybody with an AWS account - and to make sure that
the baseline compute capacity is zero, so there are no nasty billing surprises at the end of the month. To achieve this,
I used the functionality in the [aegea](https://github.com/kislyuk/aegea) package to enable automatic provisioning of a
Fargate ECS cluster and its associated resources.

# Running the workflow
So what does this look like in practice? To get started, we first need to create an Amazon EFS filesystem which will be
used to handle inputs and outputs for our workflow, and an Amazon EC2 instance which will orchestrate the workflow. You
can follow the [official AWS EFS guide](https://docs.aws.amazon.com/efs/latest/ug/getting-started.html), or install the
[aegea](https://github.com/kislyuk/aegea) tool and run `aegea efs create wdltest --tags mountpoint=/mnt/efs` followed by
`aegea launch wdltest --security-group aegea.efs` and `aegea ssh wdltest` to launch and connect to the EC2 instance.

After these steps are complete, let's mount the EFS filesystem on the orchestrator EC2 instance:

```
pip3 install git+https://github.com/chanzuckerberg/miniwdl-plugins@akislyuk-aws-fargate-executor#subdirectory=aws-fargate
```

For our first test workflow run, let's use the [Dockstore](https://dockstore.org/)
[md5 checksum test tool](https://github.com/briandoconnor/dockstore-tool-md5sum). Assuming the EFS filesystem is mounted
on `/mnt/efs`, use the following command to run the workflow and produce a checksum of the `/bin/bash` executable:

```
miniwdl run https://raw.githubusercontent.com/briandoconnor/dockstore-tool-md5sum/1.0.4/Dockstore.wdl inputFile=/bin/bash --verbose --dir /mnt/efs --as-me
```

Behind the scenes, there are several things that the `miniwdl` and `aegea` tools are managing for us. To access the EFS
filesystem, the orchestrator instance and the Fargate container must both be in a security group that provides network
connectivity to it. To run a Fargate task containing the WDL task, an ECS cluster must first be created. And to stream
WDL task logs while the container runs, miniwdl and the Fargate plugin must work together to monitor the runtime state.
All of these things are taken care of automatically, but if you want to find out more, have a look at the
[miniwdl](https://miniwdl.readthedocs.io/en/latest/WDL.html) and [aegea](https://github.com/kislyuk/aegea) docs.

# Next up
Amazon Web Services and Google Cloud Platform are the two main competitors pushing the state of the art in value-added
managed cloud orchestration services.
[A recent post by Tim Bray](https://www.tbray.org/ongoing/When/202x/2020/09/21/AWS-Step-Functions-vs-GCP-Workflows)
sheds some light on the "cloud glue" level workflow orchestration services that Amazon and Google provide, their advantages
and drawbacks. In production workloads that I am responsible for, we use AWS Step Functions to orchestrate cloud-level
workflows. This approach makes the managed API itself responsible for the top level state of your workflow; you no longer
have to worry about managing a central server and database (or distributed locking/state management system) to dispatch
your workflows and keep track of their state, and all the headaches that go along with that. You also gain
[a much tighter integration between workflow management and other cloud APIs](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-service-integrations.html).
We leverage this to great effect to string together AWS Batch jobs and AWS Lambda function executions - a powerful combination
that increases the dynamic range of our workflow resource management to span from sub-second dispatch latency, 128MB RAM,
fractional-core Lambda containers to 4TB RAM, 128-core instances if needed for heavy duty tasks. On the flip side, by using
these APIs you do lock yourself into a more cloud-specific ecosystem. So to keep our workflows portable and available to
the community, we combine the two approaches: we use Step Functions for cloud-level orchestration, and miniwdl/WDL for
instance-level orchestration. Step Functions ends up being responsible for managed resource provisioning and state tracking,
and miniwdl/WDL for type checking and I/O marshalling.

In my next post, I will cover the details of how we use AWS Step Functions, as well as spot (preemptible) instances - an
important cost optimization tool that is now integrated into both AWS Fargate and AWS Batch.
