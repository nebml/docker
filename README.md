# customized docker container for gpr invesitagtions
## 1. install docker on your machine

ubuntu:
https://docs.docker.com/engine/install/ubuntu/

windows
https://docs.docker.com/docker-for-windows/install/


## 2a. pull image (if your uid/gid is 1000/1000)
You can make use of the prebuild image if the user you will use to start the container has uid=1000 and gid=1000.
Otherwise goto **2b.**
```bash
# check the uid/gid of current user
echo $(id -u) $(id -g)
# use prebuild image (which is configured for uid=1000 gid=1000)
docker pull quay.io/manstetten/theia-gpr:latest
```

## 2b. build this docker image (if your uid/gid is **not** 1000/1000)
```bash
# cd to root folder of this repo; using uid gid of current user
docker build -f Dockerfile --build-arg host_uid=$(id -u) --build-arg host_gid=$(id -g) -t theia-gpr:latest .
```


## 3. start theia backend server
```bash
# cd into folder (working dirctory) where your project lives (do not start in Home-folder as a lot of file-precaching happens then)
docker run --init -it -p 3007:3000 -v "$(pwd):/home/project:cached" quay.io/manstetten/theia-gpr:latest  
# when running memory sanitizer or debugger you need to launch
docker run --init -it -p 3007:3000 --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -v "$(pwd):/home/project:cached" quay.io/manstetten/theia-gpr:latest 
```

### 4. when also using X
```bash
# allow local user access to xhost (for X)
sudo xhost +local:root 
# start docker
docker run --init -it --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -p 3007:3000 --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -v "$(pwd):/home/project:cached" theia-gpr:latest
```

## 4. access theia IDE using your browser and the uri http://localhost:3007


## original docker image
```bash
wget https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-cpp-docker/latest.package.json
wget https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-cpp-docker/Dockerfile
```