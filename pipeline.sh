#!/bin/bash

DOCKER_FILE_PATH=
IMAGE_NAME=
IMAGE_TAG=
CONTAINER_REGISTRY_USERNAME=
FLAVOUR=
CONTAINER_IDENTIFIER=
ENDPOINT= 
DEPLOYMENT_MANIFEST=
DOCKER_PORT=

usage() {
    echo "Valid pipeline options deploy | build | push | test . Valid for docker flavour -> start | stop | remove"
    echo "Usage: $0 option --help"
    echo "Ex: "
    echo "$0 build --help"
    exit 1
}

build_usage() {
    echo "Usage: $0 build [--dockerFilePath=<string>] [--imageName=<string>] [--imageTag=<string>] " 1>&2
    echo
    echo "Help:"
    echo "  --dockerFilePath=path/to/Dockerfile"
    echo "  --imageName=imageName"
    echo "  --imageTag=imageTag"
    echo
    echo "Ex:"
    echo "./pipeline.sh build --dockerFilePath=. --imageName=nginx --imageTag=latest"
    exit 1
}

push_usage() {
    echo "Usage: $0 push [--dockerFilePath=<string>] [--imageName=<string>] [--imageTag=<string>] " 1>&2
    echo
    echo "Help:"
    echo "  --containerRegistryUsername=dockerHub username"
    echo "  --imageName=imageName"
    echo "  --imageTag=imageTag"
    echo
    echo "Ex:"
    echo "./pipeline.sh push --containerRegistryUsername=anaaremere --imageName=nginx --imageTag=latest"
    exit 1
}

test_usage() {
    echo "Usage: $0 test [--endpoint=<string>]" 1>&2
    echo
    echo "Help:"
    echo "--endpoint=endpoint url"
    echo
    echo "Ex:"
    echo "./pipeline.sh test --endpoint=http://localhost:5000/something"
    exit 1
}

deploy_usage() {
    echo "Docker: "
    echo "Usage: $0 deploy [--flavour=<string>] [--imageName=<string>] [--imageTag=<string>] " 1>&2
    echo
    echo "Kubernetes: "
    echo "Usage: $0 deploy [--flavour=<string>] [--deploymentManifest=<string>] [--imageName=<string>] [--imageTag=<string>] " 1>&2
    echo
    echo "Help:"
    echo "  --flavour=docker"
    echo "  --imageName=imageName"
    echo "  --imageTag=imageTag"
    echo "Optional: "
    echo "  --port=8000:80"
    echo "For Kubernetes:"
    echo "  --deploymentManifest=path/to/manifest"
    echo
    echo "Ex for docker:"
    echo "./pipeline.sh deploy --flavour=docker --imageName=nginx --imageTag=latest"
    echo "Ex for kubernetes:"
    echo "./pipeline.sh deploy --flavour=kubernetes --deploymentManifest=path/to/manifest --imageName=nginx --imageTag=latest"
    exit 1
}

start_stop_remove_usage() {
    echo "Usage: $0 start | stop | remove [--containerIdentifier=<container_identifier>]"
    echo
    echo "Help:"
    echo "<container_identifier> can be the name or id of container"
    echo
    exit 1
}

if [ $# -lt 2 ]; then
    echo "Error: not enough arguments provided."
    usage
fi
# Validate pipeline option
case "$1" in
    deploy | build | push | test | start | stop | remove)
        # Save pipeline option
        PIPELINE_OPTION=${1,,}
        shift # shift arguments to left to be able to parse them
        ;;
    *)
        echo "Error: not a valid pipeline option \"$1\"."
        usage
        ;;
esac


# Parse long options
while [[ $# -gt 0 ]]; do
    # set IFS delimitator to = to separate argument from the value
    IFS="=" read -r option value <<< "$1"
    # remove quotes from value if present
    value="${value%\"}"
    value="${value#\"}"

    case "$option" in
    --dockerFilePath)
        if [[ -n $DOCKER_FILE_PATH ]]; then
            echo "Error: Duplicate argument for docker file path." >&2
            usage
        fi
        DOCKER_FILE_PATH=$value
        ;;
    --imageName)
        if [[ -n $IMAGE_NAME ]]; then
            echo "Error: Duplicate argument for image name." >&2
            usage
        fi
        IMAGE_NAME=$value # make all lower case
        ;;
    --imageTag)
        if [[ -n $IMAGE_TAG ]]; then
            echo "Error: Duplicate argument for image tag." >&2
            usage
        fi
        IMAGE_TAG=$value
        ;;
    --containerRegistryUsername)
        if [[ -n $CONTAINER_REGISTRY_USERNAME ]]; then
            echo "Error: Duplicate argument for container registry username." >&2
            usage
        fi
        CONTAINER_REGISTRY_USERNAME=$value
        ;;
    --flavour)
        if [[ -n $FLAVOUR ]]; then
            echo "Error: Duplicate argument for flavour." >&2
            usage
        fi
        FLAVOUR=$value
        ;;
    --containerIdentifier)
        if [[ -n $CONTAINER_IDENTIFIER ]]; then
            echo "Error: Duplicate argument for container." >&2
            usage
        fi
        CONTAINER_IDENTIFIER=$value
        ;;
    --endpoint)
        if [[ -n $ENDPOINT ]]; then
            echo "Error: Duplicate argument for endpoint." >&2
            usage
        fi
        ENDPOINT=$value
        ;;
    --deploymentManifest)
        if [[ -n $DEPLOYMENT_MANIFEST ]]; then
            echo "Error: Duplicate argument for deployment manifest." >&2
            usage
        fi
        DEPLOYMENT_MANIFEST=$value
        ;;
    --port)
        if [[ -n $DOCKER_PORT ]]; then
            echo "Error: Duplicate argument for docker port." >&2
            usage
        fi
        DOCKER_PORT=$value
        ;;
    --help)
        case "$PIPELINE_OPTION" in
            deploy)
                deploy_usage
                ;;
            build)
                build_usage
                ;;
            push)
                push_usage
                ;;
            test)
                test_usage
                ;;
            start|stop|remove)
                start_stop_remove_usage
                ;;
        esac
    ;;
    esac
    shift
done

# Docker manipulation options
case $PIPELINE_OPTION in
    start|stop|remove)
        # Basic parameter check 
        if [[ -z $CONTAINER_IDENTIFIER ]]; then
            echo "Error: Missing required argument for container identifier." >&2
            start_stop_remove_usage
        fi
        case $PIPELINE_OPTION in
            start|stop)
                docker container $PIPELINE_OPTION $CONTAINER_IDENTIFIER
                ;;
            remove)
                docker container rm -f $CONTAINER_IDENTIFIER
                ;;
        esac
        ;;
esac

# Main pipeline logic
case "$PIPELINE_OPTION" in 
    build|push|deploy|test)

    if [[ $PIPELINE_OPTION != "test" ]]; then
    # Verify if arguments are set
        if [[ -z $IMAGE_NAME ]]; then
            echo "Error: Missing required argument for image name." >&2
            usage
        fi
    # Set tag to latest if not specified
        if [[ -z $IMAGE_TAG ]]; then
            IMAGE_TAG="latest"
            echo "Using default image tag -> 'latest'"
        fi
    fi

    # Default docker options
    case "$PIPELINE_OPTION" in
        build)
            # Check required arguments for build option
            if [[ -z $DOCKER_FILE_PATH ]]; then
                echo "Error: Missing required argument for docker file path." >&2
                build_usage
            fi
            # Build the docker image
            docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_FILE_PATH}
            ;;
        push)
            # validate that the required variable is set
            if [[ -z $CONTAINER_REGISTRY_USERNAME ]]; then
                echo "Error: Missing required argument for container registry username." >&2
                push_usage
            fi
            # tag the created image after build to be deployed on the specified dockerhub registry
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${CONTAINER_REGISTRY_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
            # Validate that the tag was succesfull, ask to build the image first if fails
            if [ $? -eq 0 ]; then
                docker push ${CONTAINER_REGISTRY_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} 
            else
                echo "Error: tagging Docker image, try using build option first"
                push_usage
            fi
            ;;
        test)
            # Basic parameter check 
            if [[ -z $ENDPOINT ]]; then
                echo "Error: Missing required argument for endpoint." >&2
                test_usage
            fi
            curl -I $ENDPOINT
            curl $ENDPOINT
            ;;
        deploy)
            if [[ -z $FLAVOUR ]]; then
                echo "Error: Missing required argument for deploy flavour." >&2
                deploy_usage
            fi

            if [[ $FLAVOUR == "docker" ]]; then
            # "Deploy" the app   
            #docker run -d -p 8000:$(cat Dockerfile | grep EXPOSE | cut -d' ' -f2)  $IMAGE_NAME:$IMAGE_TAG
            if [[ -z $DOCKER_PORT ]]; then
                docker run -d -p 80:80 $IMAGE_NAME:$IMAGE_TAG
            else
                docker run -d -p $DOCKER_PORT $IMAGE_NAME:$IMAGE_TAG
            fi
            elif [[ $FLAVOUR == "kubernetes" ]]; then
                if [[ -z $DEPLOYMENT_MANIFEST ]]; then
                    echo "Error: Missing required argument for deployment manifest." >&2
                    deploy_usage
                fi
                if [[ $DEPLOYMENT_MANIFEST = *"service"* ]]; then
                    kubectl apply -f $DEPLOYMENT_MANIFEST
                    #kubectl port-forward service/my-service 8000:8000
                else
                    export KUBE_IMAGE_NAME=$IMAGE_NAME:$IMAGE_TAG
                    envsubst < $DEPLOYMENT_MANIFEST > manifests/deployment.yml
                    kubectl apply -f manifests/deployment.yml
                fi

            else
                echo "Error: Invalid flavour argument value"
                deploy_usage
            fi
    esac
        ;;
esac