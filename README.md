# CodeQL Agent

The CodeQL runner docker image. See the release version on [DockerHub](https://hub.docker.com/repository/docker/doublevkay/codeql-agent-dev).

## Usage
### Build and run local
```
cd codeql-agent
docker build -t codeql-agent-dev .
docker run --rm --name codeql-docker -v "$PWD/vulnerable-source-code:/opt/src" -e "LANGUAGE=python" -e "FORMAT=sarif-latest" codeql-agent-dev
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