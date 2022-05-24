# CodeQL Agent for Docker
[![Actions Status](https://github.com/docker/compose-cli/workflows/Continuous%20integration/badge.svg)](https://hub.docker.com/repository/docker/doublevkay/codeql-agent-dev)[![Docker Pulls](https://badgen.net/docker/pulls/doublevkay/codeql-agent-dev?icon=docker&label=pulls)](https://hub.docker.com/repository/docker/doublevkay/codeql-agent-dev)[![Docker Image Size](https://badgen.net/docker/size/doublevkay/codeql-agent-dev?icon=docker&label=image%20size)](https://hub.docker.com/repository/docker/doublevkay/codeql-agent-dev)![Github stars](https://badgen.net/github/stars/vovikhangcdv/codeql-agent?icon=github&label=stars)

CodeQL Agent is a project aimed at automating the use of CodeQL. The project helps create database and execute CodeQL analysis. CodeQL Agent is a Docker image. It is designed to be compatible with [SAST Gitlab CI/CD](https://docs.gitlab.com/ee/user/application_security/sast/).

CodeQL Agent for Docker is also the base image of [CodeQL Agent for Visual Studio Code](https://github.com/vovikhangcdv/codeql-agent-extension) - an extension for [Visual Studio Code](https://code.visualstudio.com/) that simplifies CodeQL usage and executes code scanning automatically.

The CodeQL Agent image is released on **Docker Hub** under the name [`doublevkay/codeql-agent-dev`](https://hub.docker.com/repository/docker/doublevkay/codeql-agent-dev). You can use it without building locally.


### Contents:
  - [What is this for?](#what-is-this-for)
  - [Getting started](#getting-started)
  - [Examples usage](#examples-usage)
  - [Supported options](#supported-options)
  - [Build](#build)
  - [How does it work?](#how-does-it-work)
  - [Support](#support)
  - [Contributing](#contributing)
  - [Contributors](#contributors)
  - [Release notes](#release-notes)
  - [License](#license)


## What is this for?

CodeQL Agent for Docker provides these key features:
- Detecting language automatically.
- Creating CodeQL database.
- Executing CodeQL database analysis.
- Integrating CodeQL to your CI/CD process.
- Integrating CodeQL code scanning to [Gitlab CI/CD](https://docs.gitlab.com/ee/user/application_security/sast/).


## Getting Started
[Bind mounts](https://docs.docker.com/storage/bind-mounts/) the source, the results folder and run `codeql-agent-dev` image with the following docker command.

```console
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  doublevkay/codeql-agent-dev
```

You also can specify more options to run CodeQL Agent. See [Supported options](#supported-options) for more details. 


## Supported options
You can set environment variables to use the following supported options:
| Variable  | Description |
| ------- | ----------- |
`LANGUAGE`| Value `<language>`. Set project language to build database or execute SAST. The `<language>` must be: `python`, `javascript`, `cpp`, `csharp`, `java`, `go`, `typescript`, `c`.
`USERID` | Value `<id>`. Set the owner of the results folder to `<id>`.
`GROUPID` | Value `<group_id>`. Set the group owner of the results folder to `<group_id>`.
`THREADS` | Value `<number_of_threads>`. Use this many threads to build database and evaluate queries. Defaults to 1. You can pass 0 to use one thread per core on the machine.
`OVERWRITE_FLAG` | Value `--overwrite`. Enable/disable overwrite database when database path exists and not an empty directory. This flag is useful for forcibly rebuilding the database.
`QS`| Value `<queries-suite>`. Specify a list of queries to run over your database. The default value is `<language>-security-extended.qls`. For more details, please see [Analyzing databases with the CodeQL CLI](https://codeql.github.com/docs/codeql-cli/analyzing-databases-with-the-codeql-cli/#running-codeql-database-analyze).
`SAVE_CACHE_FLAG` | Value `--save-cache`. Aggressively save intermediate results to the disk cache. This may speed up subsequent queries if they are similar. Be aware that using this option will greatly increase disk usage and initial evaluation time. 
`ACTION` | Value `create-database-only`. Creating CodeQL database only without executing CodeQL analysis.
`COMMAND` | Value `command`. The variable used when you create a CodeQL database for one or more compiled languages, omit if the only languages requested are Python and JavaScript. This specifies the build commands needed to invoke the compiler. If you don't set this variable, CodeQL will attempt to detect the build system automatically, using a built-in autobuilder. 
`JAVA_VERSION` | Value `<java_version>`. Set Java version. The default Java version is Java 11. The `<java_version>` must be `8` or `11`.
-----

***Disclaimer:** CodeQL Agent directly forwards these options to the command arguments while running the container. Please take it as your security responsibilities.*


## Examples usage

<details>
    <summary>Basic code scanning.</summary>

```bash
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  doublevkay/codeql-agent-dev
```
</details>

<details>
    <summary>Code scanning with maximum threads available.</summary>

```bash
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  -e "THREADS=0" \
  doublevkay/codeql-agent-dev
```
  </details>

<details>
    <summary>Create database only.</summary>

```bash
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  -e "ACTION=create-database-only" \
  doublevkay/codeql-agent-dev
```
  </details>

<details>
    <summary>Specify the queries suite for Java source.</summary>

```bash
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  -e "LANGUAGE=java" \
  -e "QS=java-security-and-quality.qls" \
  doublevkay/codeql-agent-dev
```
</details>

<details>
    <summary>Change owner of the results folder.</summary>
    Because CodeQL Agent runs the script as root in Docker containers. So maybe you need to change the results folder owner to your own.

```bash
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  -e "USERID=$(id -u ${USER})" -e "GROUPID=$(id -g ${USER}) \
  doublevkay/codeql-agent-dev
```
</details>

<details>
    <summary> Specify the Java version and the build database command </summary>

```bash
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  -e "LANGUAGE=java" \
  -e "JAVA_VERSION=8" \
  -e "COMMAND='mvn clean install'" \
  doublevkay/codeql-agent-dev

```
</details>

## Integrate CodeQL into GitLab CI/CD

![codeql-agent-gitlab-demo](media/codeql-agent-gitlab-demo.gif)

You can integrate CodeQL into Gitlab CI/CD by setting up the `.gitlab-ci.yml` file with the following template:

```yaml
codeql:
  image: doublevkay/codeql-agent-dev
  script: /root/scripts/analyze.sh
  artifacts:
    reports:
      sast: gl-sast-report.json
```

You can use [supported options](#supported-options) by setting environment variables (see [GitLab CI/CD variables](https://docs.gitlab.com/ee/ci/variables/)). For example, the following setup will use ***four threads*** to execute static application security testing in Gitlab CI/CD for ***Java*** language.

```yaml
codeql:
  image: doublevkay/codeql-agent-dev
  script: /root/scripts/analyze.sh
  artifacts:
    reports:
      sast: gl-sast-report.json
  variables:
    LANGUAGE: java
    THREADS: 4
```

## Build
You can use [CodeQL Agent Image](https://hub.docker.com/repository/docker/doublevkay/codeql-agent-dev) on **Docker Hub** or customize and [build it locally](#build-locally).
```bash
# Build codeql-agent-dev docker image locally 
cd codeql-agent
docker build -t codeql-agent-dev .
```


## How does it work?
CodeQL Agent is a Docker image. The following steps are done to achieve the goals of automating the use of CodeQL and integrating it to Gitlab CI/CD. 

<details><summary><b>Setting up environment</b></summary>

>In this step, the image prepares the environment for executing CodeQL. It includes: using Ubuntu base image; downloading and installing [CodeQL Bundle](https://github.com/github/codeql-action/releases) (which contains the CodeQL CLI and the precompiled library queries to reduce the CodeQL execution time); installing necessary softwares such as `java`, `maven`, `nodejs`, `typescript`,... to create a CodeQL database successfully.

</details>

<details> <summary><b> Detecting language</b></summary>

>CodeQL Agent uses [github/linguist](https://github.com/github/linguist) to detect the source code language.

</details>

<details> <summary><b> Creating database </b></summary>

> CodeQL Agent runs the CodeQL create database command.
  ```bash
  codeql database create --threads=$THREADS --language=$LANGUAGE $COMMAND $DB -s $SRC $OVERWRITE_FLAG
  ```

</details>

<details> <summary><b> Specifying  query suites </b></summary>

> Analyzing databases requires specifying a query suite. According to the goals of application static application security testing (SAST) goals, CodeQL Agent uses `<language>-security-extended.qls` as the default query suite.

</details>

<details> <summary><b> Analyzing database </b></summary>

> CodeQL Agent runs the CodeQL database analysis command.
```bash
codeql database analyze --format=$FORMAT --threads=$THREADS $SAVE_CACHE_FLAG --output=$OUTPUT/issues.$FORMAT $DB $QS
``` 

</details>

<details> <summary><b> Converting result format </b></summary>

>[Gitlab CI/CD](https://docs.gitlab.com/ee/ci/) does not support the SARIF format. Therefore, CodeQL Agent will convert the CodeQL result from [SARIF format](http://docs.oasis-open.org/sarif/sarif/v2.0/csprd01/sarif-v2.0-csprd01.html) to [Security Report Schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas) (provided by Gitlab). This step is done by mapping the fields of two formats. The details of implementation are in the [sarif2sast](https://github.com/vovikhangcdv/codeql-agent/blob/main/scripts/sarif2sast.py) script. You can use this script independently as a workaround  to solve the [Gitlab Issue 118496](https://gitlab.com/gitlab-org/gitlab/-/issues/118496).

</details>

## Credits
This repo is based on [microsoft/codeql-container](https://github.com/microsoft/codeql-container) and [j3ssie/codeql-docker](https://github.com/j3ssie/codeql-docker) with more function options. Specifically:
- Enhances environment setup to increase reliability.
- Automatically detect language.
- Support helpful CodeQL options.
- Support Java language. 

## Support

You can open an issue on the [GitHub repo](https://github.com/vovikhangcdv/codeql-agent/issues)

## Contributing

Contributions are always welcome! Just create a merge request or contact me  <a href="https://twitter.com/doublevkay">
    <img src="https://img.shields.io/twitter/url?style=for-the-badge&label=%40doublevkay&logo=twitter&logoColor=00AEFF&labelColor=black&color=7fff00&url=https%3A%2F%2Ftwitter.com%2Fdoublevkay">  </a>

## Contributors
<a href="https://github.com/vovikhangcdv/codeql-agent-extension/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=vovikhangcdv/codeql-agent" />
</a>

## Release Notes

[See details](https://github.com/vovikhangcdv/codeql-agent/releases)

## License

CodeQL Agent is licensed under the [MIT license](https://github.com/vovikhangcdv/codeql-agent-extension/blob/main/LICENSE).
