FROM jenkins/inbound-agent:latest

USER root

#----------------------------------------------------
# Install Required Packages
#----------------------------------------------------
RUN apt-get update && \
    apt-get install -y \
    curl \
    unzip \
    jq \
    wget \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

#----------------------------------------------------
# Install Terraform
#----------------------------------------------------
ENV TERRAFORM_VERSION=1.13.0

RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

#----------------------------------------------------
# Install AWS CLI v2
#----------------------------------------------------
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

USER jenkins