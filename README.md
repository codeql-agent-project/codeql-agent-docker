# CodeQL Agent for Docker
[![Actions Status](https://github.com/docker/compose-cli/workflows/Continuous%20integration/badge.svg)](https://hub.docker.com/repository/docker/doublevkay/codeql-agent)[![Docker Pulls](https://badgen.net/docker/pulls/doublevkay/codeql-agent?icon=docker&label=pulls)](https://hub.docker.com/repository/docker/doublevkay/codeql-agent)[![Docker Image Size](https://badgen.net/docker/size/doublevkay/codeql-agent?icon=docker&label=image%20size)](https://hub.docker.com/repository/docker/doublevkay/codeql-agent)![Github stars](https://badgen.net/github/stars/codeql-agent-project/codeql-agent-docker?icon=github&label=stars)

CodeQL Agent is a project aimed at automating the use of CodeQL. The project helps create database and execute CodeQL analysis. CodeQL Agent is a Docker image.

CodeQL Agent for Docker is also the base image of [CodeQL Agent for Visual Studio Code](https://github.com/vovikhangcdv/codeql-agent-extension) - an extension for [Visual Studio Code](https://code.visualstudio.com/) that simplifies CodeQL usage and executes code scanning automatically.

The CodeQL Agent image is released on **Docker Hub** under the name [`doublevkay/codeql-agent`](https://hub.docker.com/repository/docker/doublevkay/codeql-agent). You can use it without building locally.


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
- Auto sync the latest version of CodeQL CLI and CodeQL library.

## Getting Started
[Bind mounts](https://docs.docker.com/storage/bind-mounts/) the source, the results folder and run `codeql-agent` image with the following docker command.

```console
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  doublevkay/codeql-agent
```

You also can specify more options to run CodeQL Agent. See [Supported options](#supported-options) for more details. 


## Supported options
You can set environment variables to use the following supported options:
| Variable  | Description |
| ------- | ----------- |
`LANGUAGE`| Value `<language>`. Set project language to build database or execute SAST. The `<language>` must be: `go`, `java`, `cpp`, `csharp`, `python`, `javascript`, `ruby`.
`USERID` | Value `<id>`. Set the owner of the results folder to `<id>`.
`GROUPID` | Value `<group_id>`. Set the group owner of the results folder to `<group_id>`.
`THREADS` | Value `<number_of_threads>`. Use this many threads to build database and evaluate queries. Defaults to 1. You can pass 0 to use one thread per core on the machine.
`OVERWRITE_FLAG` | Value `--overwrite`. Enable/disable overwrite database when database path exists and not an empty directory. This flag is useful for forcibly rebuilding the database.
`QS`| Value `<queries-suite>`. Specify a list of queries to run over your database. The default value is `<language>-security-extended.qls`. For more details, please see [Analyzing databases with the CodeQL CLI](https://codeql.github.com/docs/codeql-cli/analyzing-databases-with-the-codeql-cli/#running-codeql-database-analyze).
`SAVE_CACHE_FLAG` | Value `--save-cache`. Aggressively save intermediate results to the disk cache. This may speed up subsequent queries if they are similar. Be aware that using this option will greatly increase disk usage and initial evaluation time. 
`ACTION` | Value `create-database-only`. Creating CodeQL database only without executing CodeQL analysis.
`COMMAND` | Value `<command>`. The variable used when you create a CodeQL database for one or more compiled languages, omit if the only languages requested are Python and JavaScript. This specifies the build commands needed to invoke the compiler. If you don't set this variable, CodeQL will attempt to detect the build system automatically, using a built-in autobuilder. 
-----

***Disclaimer:** CodeQL Agent directly forwards these options to the command arguments while running the container. Please take it as your security responsibility.*


## Examples usage

<details>
    <summary>Basic code scanning.</summary>

```bash
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  doublevkay/codeql-agent
```
</details>

<details>
    <summary>Code scanning with maximum threads available.</summary>

```bash
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  -e "THREADS=0" \
  doublevkay/codeql-agent
```
  </details>

<details>
    <summary>Create database only.</summary>

```bash
docker run --rm --name codeql-agent-docker \
  -v "$PWD:/opt/src" \
  -v "$PWD/codeql-agent-results:/opt/results" \
  -e "ACTION=create-database-only" \
  doublevkay/codeql-agent
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
  doublevkay/codeql-agent
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
  doublevkay/codeql-agent
```
</details>

<details>
    <summary> Specify the Java version and the build database command </summary>

By default, we use JDK 11 and Maven 3.6.3 for the CodeQL agent image. We can change the versions of Java and Maven by mounting a volume and setting the JAVA_HOME and MAVEN_HOME environment variables in the CodeQL agent container. For example:

1. Create a Dockerfile (named Dockerfile-java) for the specific versions of Java and Maven, and place it in the directory that will be used for mounting later:
   ```Dockerfile
    FROM --platform=amd64 maven:3-jdk-8-slim

    RUN mkdir -p /opt/jdk/ /opt/maven/

    RUN cp -r $JAVA_HOME/* /opt/jdk/

    RUN cp -r $MAVEN_HOME/* /opt/maven/

    CMD ["echo"]
   ```
2. Build and run the Docker container, mounting the JDK and Maven directories to the respective volumes:
   ```bash
    docker buildx build -t codeql-java -f Dockerfile-java .
    docker run --rm  -v "jdkvol:/opt/jdk" -v "mavenvol:/opt/maven" codeql-java
   ```
3. Finally, run codeql-agent container with mounted volumes and set env variable JAVA_HOME, MAVEN_HOME to the mounted volumes

  ```bash
  docker run --rm --name codeql-agent-docker \
    -v "$PWD:/opt/src" \
    -v "$PWD/codeql-agent-results:/opt/results" \
    -v "jdkvol:/opt/jdk" \
    -v "mavenvol:/opt/maven" \
    -e "LANGUAGE=java" \
    -e "JAVA_HOME=/opt/jdk" \
    -e "MAVEN_HOME=/opt/maven" \
    -e "COMMAND=mvn clean install" \
    doublevkay/codeql-agent
  ```
</details>

## Build
You can use [CodeQL Agent Image](https://hub.docker.com/repository/docker/doublevkay/codeql-agent) on **Docker Hub** or customize and [build it locally](#build-locally).
```bash
# Build codeql-agent docker image locally 
cd codeql-agent
docker build -t codeql-agent .
```


## How does it work?
CodeQL Agent is a Docker image. The following steps are done to achieve the goals of automating the use of CodeQL. 

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

>CodeQL Agent will convert the CodeQL result from [SARIF format](http://docs.oasis-open.org/sarif/sarif/v2.0/csprd01/sarif-v2.0-csprd01.html) to [Security Report Schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas) (provided by Gitlab). This step is done by mapping the fields of two formats. The details of implementation are in the [sarif2sast](https://github.com/vovikhangcdv/codeql-agent/blob/main/scripts/sarif2sast.py) script. You can use this script independently as a workaround to solve the [Gitlab Issue 118496](https://gitlab.com/gitlab-org/gitlab/-/issues/118496).

</details>

## Credits
This repo is based on [microsoft/codeql-container](https://github.com/microsoft/codeql-container) and [j3ssie/codeql-docker](https://github.com/j3ssie/codeql-docker) with more function options. Specifically:
- Enhance environment setup to increase reliability.
- Automatically detect language.
- Support helpful CodeQL options.
- Support Java language. 

## Support

You can open an issue on the [GitHub repo](https://github.com/codeql-agent-project/codeql-agent-docker/issues)

## Contributing

Contributions are always welcome! Just create a pull request or contact me  <a href="https://twitter.com/doublevkay">
    <img src="https://img.shields.io/twitter/url?style=for-the-badge&label=%40doublevkay&logo=twitter&logoColor=00AEFF&labelColor=black&color=7fff00&url=https%3A%2F%2Ftwitter.com%2Fdoublevkay">  </a>

## Contributors
<a href="https://github.com/vovikhangcdv/codeql-agent-extension/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=codeql-agent-project/codeql-agent-docker" />
</a>

## Release Notes

[See details](https://github.com/codeql-agent-project/codeql-agent-docker/releases)

## License

CodeQL Agent is use CodeQL CLI as the core engine. Please follow the [GitHub CodeQL Terms and Conditions](https://github.com/github/codeql-cli-binaries/blob/main/LICENSE.md) and take it as your own responsibility.
