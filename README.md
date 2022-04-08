# CodeQL Agent

Source build docker image `codeql-agent`

## Usage
### Build and run local
```
cd codeql-agent
sudo docker build -t doublevkay/codeql-agent-dev:1.1.0 .
nohup sudo docker build -t doublevkay/codeql-agent-dev:1.1.0 .; telegram-send "Build image codeql v1.1.0 done"
docker run --rm --name codeql-docker -v "$PWD/vulnerable-source-code:/opt/src" -e "LANGUAGE=python" -e "FORMAT=sarif-latest" codeql-agent
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