# CodeQL Agent

The CodeQL runner docker image. See the release version on [DockerHub](https://hub.docker.com/repository/docker/doublevkay/codeql-agent-dev).

## Usage
You can use [CodeQL Agent Image](https://hub.docker.com/repository/docker/doublevkay/codeql-agent-dev) on DockerHub or build it locally.
### Build and run local
```
# Build docker image
cd codeql-agent
docker build -t codeql-agent-dev .
# Run
docker run --rm --name codeql-agent-docker -v "$PWD:/opt/src" -e "USERID=$(id -u ${USER})" -e "GROUPID=$(id -g ${USER})" -v "$PWD/codeql-agent-results:/opt/results" -e "OVERWRITE_FLAG=--overwrite" -e "THREADS=0" -e "FORMAT=sarif-latest" doublevkay/codeql-agent-dev
```

### Gitlab CI/CD
```yml
codeql:
  image: doublevkay/codeql-agent-dev:latest
  script: /root/scripts/analyze.sh
  artifacts:
    reports:
      sast: gl-sast-report.json
```

## Documentation notes
- https://docs.gitlab.com/ee/ci/
- https://semgrep.dev/for/gitlab
- https://github.com/j3ssie/codeql-docker
- https://docs.github.com/en/code-security/code-scanning/automatically-scanning-your-code-for-vulnerabilities-and-errors/configuring-code-scanning
- https://github.com/github/codeql-action