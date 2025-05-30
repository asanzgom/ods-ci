# Copyright 2020 kubeflow.org
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# source https://github.com/kubeflow/kfp-tekton/blob/master/samples/flip-coin/condition.py
#
# Update 2024: Flip coin pipeline for pip_index_url clusters
#
# This is an example of setting pip_index_url in a pipeline task
# obtaining the value from a ConfigMap, in order to be able to run
# the pipeline in a pip_index_url environment.
#
# The pipeline reads the values from a ConfigMap (ds-pipeline-custom-env-vars)
# and creates the environment variables PIP_INDEX_URL and PIP_TRUSTED_HOST
# in the pipeline task.
#
# Note: when compiling the pipeline, the resulting yaml file only uses
# PIP_INDEX_URL (this is a limitation of kfp 2.7.0). We need to manually
# modify the yaml file to use PIP_TRUSTED_HOST.
from kfp import compiler, dsl, kubernetes
from kfp.dsl import PipelineTask

common_base_image = (
    "registry.redhat.io/ubi9/python-312@sha256:e80ff3673c95b91f0dafdbe97afb261eab8244d7fd8b47e20ffcbcfee27fb168"
)


def add_pip_index_configuration(task: PipelineTask):
    kubernetes.use_config_map_as_env(
        task,
        config_map_name="ds-pipeline-custom-env-vars",
        config_map_key_to_env={"pip_index_url": "PIP_INDEX_URL", "pip_trusted_host": "PIP_TRUSTED_HOST"},
    )


@dsl.component(base_image=common_base_image, pip_index_urls=["$PIP_INDEX_URL"], pip_trusted_hosts=["$PIP_TRUSTED_HOST"])
def random_num(low: int, high: int) -> int:
    """Generate a random number between low and high."""
    import random  # noqa: PLC0415

    result = random.randint(low, high)
    print(result)
    return result


@dsl.component(base_image=common_base_image, pip_index_urls=["$PIP_INDEX_URL"], pip_trusted_hosts=["$PIP_TRUSTED_HOST"])
def flip_coin() -> str:
    """Flip a coin and output heads or tails randomly."""
    import random  # noqa: PLC0415

    result = "heads" if random.randint(0, 1) == 0 else "tails"
    print(result)
    return result


@dsl.component(base_image=common_base_image, pip_index_urls=["$PIP_INDEX_URL"], pip_trusted_hosts=["$PIP_TRUSTED_HOST"])
def print_msg(msg: str):
    """Print a message."""
    print(msg)


@dsl.pipeline(
    name="conditional-execution-pipeline",
    description="Shows how to use dsl.If().",
)
def flipcoin_pipeline():
    flip_task = flip_coin().set_caching_options(False)
    add_pip_index_configuration(flip_task)

    with dsl.If(flip_task.output == "heads"):
        random_num_head_task = random_num(low=0, high=9).set_caching_options(False)
        add_pip_index_configuration(random_num_head_task)

        with dsl.If(random_num_head_task.output > 5):
            print_msg_task = print_msg(msg="heads and %s > 5!" % random_num_head_task.output).set_caching_options(False)
            add_pip_index_configuration(print_msg_task)

        with dsl.If(random_num_head_task.output <= 5):
            print_msg_task = print_msg(msg="heads and %s <= 5!" % random_num_head_task.output)
            print_msg_task.set_caching_options(False)
            add_pip_index_configuration(print_msg_task)

    with dsl.If(flip_task.output == "tails"):
        random_num_tail_task = random_num(low=10, high=19).set_caching_options(False)
        add_pip_index_configuration(random_num_tail_task)

        with dsl.If(random_num_tail_task.output > 15):
            print_msg_task = print_msg(msg="tails and %s > 15!" % random_num_tail_task.output)
            print_msg_task.set_caching_options(False)
            add_pip_index_configuration(print_msg_task)

        with dsl.If(random_num_tail_task.output <= 15):
            print_msg_task = print_msg(msg="tails and %s <= 15!" % random_num_tail_task.output)
            print_msg_task.set_caching_options(False)
            add_pip_index_configuration(print_msg_task)


if __name__ == "__main__":
    compiler.Compiler().compile(flipcoin_pipeline, package_path=__file__.replace(".py", "_compiled.yaml"))
